terraform {
#  required_version = ">=1.8.4"
  required_providers {
    azurerm = {
      "source" = "hashicorp/azurerm"
      version  = "3.43.0"
    }
  }
  cloud {
    organization = "5atech"

    workspaces {
      name = "TerraformCI"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}


locals {
  prefix     = "terraform"
  location1  = "eastus"
  vm_size1   = "Standard_B1ms"
  rg1        = "${local.prefix}-${local.location1}-resources"
  subnet1_id = azurerm_subnet.subnet1.id
  virtual_machines = {
    "vm1" = { size = local.vm_size1, location = local.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm2" = { size = local.vm_size1, location = local.location1, resource_group = local.rg1, subnet_id = local.subnet1_id }
  }
}

resource "azurerm_resource_group" "rg1" {
  name     = local.rg1
  location = local.location1
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "${local.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}

module "virtual_machines" {

  source   = "./modules/virtual_machines"
  for_each = local.virtual_machines

  vm_name   = each.key
  location  = each.value.location
  vm_size   = each.value.size
  rg_name   = each.value.resource_group
  subnet_id = each.value.subnet_id
  prefix    = local.prefix
}
