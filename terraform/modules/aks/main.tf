# Unified AKS module that adapts based on environment

locals {
  # Environment-based defaults
  is_production = var.environment == "production" || var.environment == "prod"
  
  # Node pool settings based on environment
  node_count = local.is_production ? 3 : 1
  node_size  = local.is_production ? var.node_size : "Standard_B2s"
  min_nodes  = local.is_production ? 3 : 1
  max_nodes  = local.is_production ? 10 : 3
  
  # Features to enable based on environment
  enable_monitoring    = var.enable_monitoring != null ? var.enable_monitoring : true  # Default to true for all environments
  enable_autoscaling   = local.is_production ? true : var.enable_autoscaling
  enable_network_policy = local.is_production ? true : false
  load_balancer_sku    = local.is_production ? "standard" : "basic"
  acr_sku             = local.is_production ? "Standard" : "Basic"
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-${var.environment}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project_name}-${var.environment}"
  
  # Only set kubernetes version if specified
  kubernetes_version = var.kubernetes_version != "" ? var.kubernetes_version : null

  default_node_pool {
    name                = "default"
    vm_size             = local.node_size
    os_disk_size_gb     = local.is_production ? 100 : 30
    vnet_subnet_id      = var.subnet_id
    
    # Node count and autoscaling
    node_count          = local.enable_autoscaling ? local.node_count : var.node_count
    auto_scaling_enabled = local.enable_autoscaling
    min_count           = local.enable_autoscaling ? local.min_nodes : null
    max_count           = local.enable_autoscaling ? local.max_nodes : null
    
    node_labels = merge(
      {
        "environment" = var.environment
        "managed-by"  = "terraform"
      },
      var.additional_node_labels
    )
    
    tags = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = local.enable_network_policy ? "azure" : null
    load_balancer_sku = local.load_balancer_sku
    
    # Only add load balancer profile for standard SKU
    dynamic "load_balancer_profile" {
      for_each = local.load_balancer_sku == "standard" ? [1] : []
      content {
        managed_outbound_ip_count = 2
      }
    }
  }

  # Azure AD RBAC - optional
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = length(var.admin_group_ids) > 0 ? [1] : []
    content {
      azure_rbac_enabled     = true
      admin_group_object_ids = var.admin_group_ids
    }
  }

  # Azure Monitor metrics - always enabled
  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }

  # OMS Agent - enabled by default for all environments
  dynamic "oms_agent" {
    for_each = local.enable_monitoring && var.log_analytics_workspace_id != "" ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  # Auto-scaler profile - only for production or if explicitly enabled
  dynamic "auto_scaler_profile" {
    for_each = local.enable_autoscaling ? [1] : []
    content {
      scale_down_delay_after_add       = "10m"
      scale_down_unneeded             = "10m"
      scale_down_utilization_threshold = "0.5"
      skip_nodes_with_system_pods     = true
    }
  }

  # Maintenance window - only for production
  dynamic "maintenance_window" {
    for_each = local.is_production ? [1] : []
    content {
      allowed {
        day   = "Sunday"
        hours = [2, 3, 4]
      }
    }
  }

  tags = var.tags
}

# Optional user node pool for production
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count = local.is_production && var.create_user_node_pool ? 1 : 0
  
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = var.user_node_size != "" ? var.user_node_size : "Standard_D4s_v3"
  vnet_subnet_id       = var.subnet_id
  
  node_count          = 2
  auto_scaling_enabled = true
  min_count          = 2
  max_count          = 10
  node_labels = {
    "nodepool-type" = "user"
    "workload"      = "applications"
  }
  
  node_taints = var.user_node_taints
  
  tags = var.tags
}

# Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.project_name, "-", "")}${var.environment}acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = local.acr_sku
  admin_enabled       = !local.is_production  # Admin enabled for dev/staging only

  # Geo-replication for production only
  dynamic "georeplications" {
    for_each = local.is_production && var.enable_acr_geo_replication ? var.acr_geo_replications : []
    content {
      location = georeplications.value
      tags     = var.tags
    }
  }

  tags = var.tags
}

# Grant AKS access to ACR
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}