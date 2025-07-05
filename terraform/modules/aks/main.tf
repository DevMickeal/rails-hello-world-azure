# Azure Kubernetes Service configuration

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-${var.environment}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project_name}-${var.environment}"
  //kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "system"
    node_count          = var.system_node_count
    vm_size             = var.system_node_size
    os_disk_size_gb     = var.os_disk_size_gb
    vnet_subnet_id      = var.aks_subnet_id
    type                = "VirtualMachineScaleSets"
    auto_scaling_enabled = var.system_node_min_count != var.system_node_max_count
    min_count           = var.system_node_min_count != var.system_node_max_count ? var.system_node_min_count : null
    max_count           = var.system_node_min_count != var.system_node_max_count ? var.system_node_max_count : null
    max_pods            = var.system_node_max_pods

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
      "nodepoolos"    = "linux"
    }

    tags = merge(
      var.common_tags,
      {
        "nodepool-type" = "system"
      }
    )
  }

  # Enable Azure AD integration
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"

    load_balancer_profile {
      managed_outbound_ip_count = 2
    }
  }

  azure_policy_enabled = true

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  ingress_application_gateway {
    gateway_name = "${var.project_name}-${var.environment}-appgw"
    subnet_id    = var.appgw_subnet_id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  auto_scaler_profile {
    balance_similar_node_groups      = false
    expander                         = "random"
    max_graceful_termination_sec     = 600
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "30s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = "0.5"
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [22, 23]
    }
  }

  tags = var.common_tags
}

# User Node Pool for Applications
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_node_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.aks_subnet_id
  auto_scaling_enabled  = var.user_node_min_count != var.user_node_max_count
  min_count             = var.user_node_min_count != var.user_node_max_count ? var.user_node_min_count : null
  max_count             = var.user_node_min_count != var.user_node_max_count ? var.user_node_max_count : null
  max_pods              = 110
  os_disk_size_gb       = 100

  node_labels = {
    "nodepool-type" = "user"
    "environment"   = var.environment
    "workload-type" = "applications"
  }

  node_taints = [
    "workload=applications:NoSchedule"
  ]

  tags = merge(
    var.common_tags,
    {
      "nodepool-type" = "user"
    }
  )
}

# Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${var.project_name}${var.environment}acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = false

  tags = var.common_tags
}

# Grant AKS access to ACR
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}

# Grant AKS access to Key Vault
resource "azurerm_role_assignment" "aks_keyvault" {
  principal_id                     = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = var.key_vault_id
  skip_service_principal_aad_check = true
}