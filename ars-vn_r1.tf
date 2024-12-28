## First region

## RG Creation
resource "azurerm_resource_group" "ars-lab-r1" {
  location = var.azure_r1_location
  name     = "ars-lab-${var.azure_r1_location_short}"
}

## Creation of ARS VNET ARS and FIREWALL
resource "azurerm_virtual_network" "ars-vn" {
  address_space       = ["10.90.0.0/24"]
  location            = azurerm_resource_group.ars-lab-r1.location
  name                = "ars-vn"
  resource_group_name = azurerm_resource_group.ars-lab-r1.name
}

resource "azurerm_subnet" "gw-subnet" {
  address_prefixes     = ["10.90.0.0/27"]
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.ars-lab-r1.name
  virtual_network_name = azurerm_virtual_network.ars-vn.name
}

resource "azurerm_subnet" "vm-subnet" {
  address_prefixes     = ["10.90.0.32/27"]
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.ars-lab-r1.name
  virtual_network_name = azurerm_virtual_network.ars-vn.name
}

resource "azurerm_subnet" "ars-subnet" {
  address_prefixes     = ["10.90.0.64/27"]
  name                 = "RouteServerSubnet"
  resource_group_name  = azurerm_resource_group.ars-lab-r1.name
  virtual_network_name = azurerm_virtual_network.ars-vn.name
}

module "vn-peering" {
  source = "github.com/alexandreweiss/terraform-azurerm-vnetpeering"

  left_vnet_resource_group_name  = azurerm_resource_group.ars-lab-r1.name
  left_vnet_name                 = azurerm_virtual_network.ars-vn.name
  right_vnet_resource_group_name = azurerm_resource_group.ars-lab-r1.name
  right_vnet_name                = module.azure_transit_ars.vpc.name
  allow_forwarded_traffic        = true

  depends_on = [
    azurerm_virtual_network.ars-vn,
    module.azure_transit_ars
  ]
}
