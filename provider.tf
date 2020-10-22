provider "azurerm" {
  version = "~> 2.2"
  features {}

  subscription_id = var.azure_sub_id
  client_id       = var.azure_app_id
  client_secret   = var.azure_app_key
  tenant_id       = var.azure_dir_id

}