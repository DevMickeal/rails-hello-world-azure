#!/bin/bash
# Bootstrap Azure remote backend for Terraform
# This script creates the resource group, storage account, and blob container for Terraform state

set -e

RESOURCE_GROUP="terraform-state-rg"
STORAGE_ACCOUNT="tfstaterailsapp"
CONTAINER_NAME="tfstate"
LOCATION="northeurope"

# Create resource group if it doesn't exist
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account if it doesn't exist
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query '[0].value' -o tsv)

# Create blob container if it doesn't exist
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT --account-key $ACCOUNT_KEY

echo "Azure remote backend bootstrapped."
