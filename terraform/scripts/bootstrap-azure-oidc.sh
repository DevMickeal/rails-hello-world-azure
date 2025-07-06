#!/bin/bash

set -e

# --- CONFIGURATION ---

# Prompt for App Registration name
read -p "Enter a name for your Azure AD App Registration (e.g. rails-hello-world-azure-sp): " APP_NAME

# Prompt for GitHub repo
read -p "Enter your GitHub repo (e.g. DevMickeal/rails-hello-world-azure): " REPO

# Prompt for Subscription ID
read -p "Enter your Azure Subscription ID: " SUBSCRIPTION_ID

FED_CRED_NAME="github-oidc-wildcard"
SUBJECT="repo:${REPO}:*"
ISSUER="https://token.actions.githubusercontent.com"
AUDIENCE="api://AzureADTokenExchange"

# --- CREATE APP REGISTRATION ---
echo "Checking for existing App Registration named '$APP_NAME'..."
APP_ID=$(az ad app list --display-name "$APP_NAME" --query '[0].appId' -o tsv)

if [ -z "$APP_ID" ]; then
  echo "App Registration not found. Creating..."
  APP_ID=$(az ad app create --display-name "$APP_NAME" --query 'appId' -o tsv)
  echo "App Registration created with client ID: $APP_ID"
else
  echo "App Registration already exists with client ID: $APP_ID"
fi

# --- CREATE SERVICE PRINCIPAL ---
echo "Checking for Service Principal..."
SP_OBJECT_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query '[0].id' -o tsv)
if [ -z "$SP_OBJECT_ID" ]; then
  echo "Service Principal not found. Creating..."
  az ad sp create --id "$APP_ID"
  SP_OBJECT_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query '[0].id' -o tsv)
  echo "Service Principal created."
else
  echo "Service Principal already exists."
fi

# --- ADD FEDERATED CREDENTIAL ---
echo "Checking for existing federated credential '$FED_CRED_NAME'..."
EXISTING=$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$FED_CRED_NAME']" -o tsv)

if [ -n "$EXISTING" ]; then
  echo "Federated credential '$FED_CRED_NAME' already exists. Skipping creation."
else
  echo "Creating federated credential '$FED_CRED_NAME'..."
  az ad app federated-credential create \
    --id "$APP_ID" \
    --parameters '{
      "name": "'"$FED_CRED_NAME"'",
      "issuer": "'"$ISSUER"'",
      "subject": "'"$SUBJECT"'",
      "audiences": ["'"$AUDIENCE"'"]
    }'
  echo "Federated credential created."
fi

# --- ASSIGN ROLES AT SUBSCRIPTION LEVEL ---
declare -a ROLES=("User Access Administrator" "Contributor")

for ROLE in "${ROLES[@]}"; do
  echo "Assigning '$ROLE' role to the Service Principal at the subscription scope..."
  az role assignment create \
    --assignee "$SP_OBJECT_ID" \
    --role "$ROLE" \
    --scope "/subscriptions/$SUBSCRIPTION_ID" \
    --only-show-errors || echo "Role assignment for '$ROLE' may already exist. Skipping error."
done

# --- LIST AND SELECT KEY VAULTS ---
echo ""
echo "Fetching all Key Vaults in your subscription..."
VAULTS=$(az keyvault list --subscription "$SUBSCRIPTION_ID" --query '[].{name:name, rg:resourceGroup}' -o tsv)

if [ -z "$VAULTS" ]; then
  echo "No Key Vaults found in this subscription."
else
  echo "Available Key Vaults:"
  IFS=$'\n' read -rd '' -a VAULT_ARRAY <<<"$VAULTS"
  for i in "${!VAULT_ARRAY[@]}"; do
    VAULT_NAME=$(echo "${VAULT_ARRAY[$i]}" | awk '{print $1}')
    VAULT_RG=$(echo "${VAULT_ARRAY[$i]}" | awk '{print $2}')
    echo "  [$i] $VAULT_NAME (Resource Group: $VAULT_RG)"
  done

  read -p "Enter the numbers (comma-separated) of the Key Vaults to assign 'Key Vault Administrator' (or leave blank to skip): " VAULT_SELECTION

  if [ -n "$VAULT_SELECTION" ]; then
    IFS=',' read -ra SELECTED <<< "$VAULT_SELECTION"
    for idx in "${SELECTED[@]}"; do
      VAULT_NAME=$(echo "${VAULT_ARRAY[$idx]}" | awk '{print $1}')
      VAULT_RG=$(echo "${VAULT_ARRAY[$idx]}" | awk '{print $2}')
      VAULT_ID=$(az keyvault show --name "$VAULT_NAME" --resource-group "$VAULT_RG" --query id -o tsv)
      echo "Assigning 'Key Vault Administrator' to $VAULT_NAME ($VAULT_ID)..."
      az role assignment create \
        --assignee "$SP_OBJECT_ID" \
        --role "Key Vault Administrator" \
        --scope "$VAULT_ID" \
        --only-show-errors || echo "Role assignment for 'Key Vault Administrator' may already exist on $VAULT_NAME. Skipping error."
    done
  else
    echo "No Key Vaults selected for role assignment."
  fi
fi

# --- OUTPUT DETAILS ---
TENANT_ID=$(az account show --query tenantId -o tsv)

echo ""
echo "---------------------------------------------"
echo "Azure AD App Registration and OIDC setup done!"
echo "---------------------------------------------"
echo "App Registration Name: $APP_NAME"
echo "Client ID (APP_ID):    $APP_ID"
echo "Tenant ID:             $TENANT_ID"
echo "SP Object ID:          $SP_OBJECT_ID"
echo "Subscription ID:       $SUBSCRIPTION_ID"
echo ""
echo "Use these values in your GitHub Actions secrets or pipeline configuration."
echo "---------------------------------------------"