provider "azurerm" {
  skip_provider_registration = false
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.environment}-aks-env-out-new"
  location = var.location

}

resource "random_id" "name" {
  byte_length = 8
}

# data "azurerm_virtual_network" "network" {
#   name                = "${var.environment}-env-out"
#   resource_group_name = "${var.environment}-env-out"

#   depends_on = [null_resource.deployment_trigger]
# }

# data "terraform_remote_state" "vpc" {
#   backend = "local"

#   config = {
#     path = "../terraform.tfstate"
#   }

#   depends_on = [null_resource.deployment_trigger]
# }


module "cluster" {
  source  = "Azure/aks/azurerm"
  version = "8.0.0"

  # Cluster base config
  resource_group_name     = azurerm_resource_group.main.name
  prefix                  = "dev2-aks-cluster"
  sku_tier                = "Standard"
  node_os_channel_upgrade = "NodeImage"

  # Cluster system pool
  agents_availability_zones = [1, 2, 3]
  enable_auto_scaling       = true
  agents_max_count          = 4
  agents_min_count          = 3

  # Cluster networking
  # vnet_subnet_id = var.vnet_subnet_id
  vnet_subnet_id = data.terraform_remote_state.vpc.outputs.aks_subnet_id
  network_plugin = "azure"

  # Cluster node pools
  node_pools = {
    nodepool1 = {
      name                = "pool1"
      vm_size             = "Standard_DS3_v2"
      enable_auto_scaling = true
      max_count           = 4
      min_count           = 1
      # vnet_subnet_id      = var.vnet_subnet_id
      vnet_subnet_id = data.terraform_remote_state.vpc.outputs.aks_subnet_id
      zones          = [1, 2, 3]
    }
  }

  # Cluster Authentication
  role_based_access_control_enabled = true
  rbac_aad                          = false

  depends_on = [azurerm_resource_group.main]
}

