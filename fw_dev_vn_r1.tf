## First region

## Creation of FW VNET ARS and FIREWALL
resource "azurerm_virtual_network" "fw-2-vn" {
  address_space       = ["10.96.0.0/24"]
  location            = azurerm_resource_group.ars-lab-r1.location
  name                = "fw-2-vn"
  resource_group_name = azurerm_resource_group.ars-lab-r1.name
}

resource "azurerm_subnet" "fw-2-vm-subnet" {
  address_prefixes     = ["10.96.0.32/27"]
  name                 = "fw-2-vm-subnet"
  resource_group_name  = azurerm_resource_group.ars-lab-r1.name
  virtual_network_name = azurerm_virtual_network.fw-2-vn.name
}

module "fw-2-ars-vn-peering" {
  source = "github.com/alexandreweiss/terraform-azurerm-vnetpeering"

  left_vnet_resource_group_name  = azurerm_resource_group.ars-lab-r1.name
  left_vnet_name                 = azurerm_virtual_network.ars-vn.name
  right_vnet_resource_group_name = azurerm_resource_group.ars-lab-r1.name
  right_vnet_name                = azurerm_virtual_network.fw-2-vn.name
  allow_forwarded_traffic        = true
  left_allow_gateway_transit     = true
  left_use_remote_gateways       = false
  right_allow_gateway_transit    = false
  right_use_remote_gateways      = true

  depends_on = [
    azurerm_virtual_network.ars-vn,
    azurerm_virtual_network.fw-2-vn
  ]
}

## Creation of SPOKE VNET containing Spoke GW
resource "azurerm_virtual_network" "spoke-2-vn" {
  address_space       = ["10.97.0.0/24"]
  location            = azurerm_resource_group.ars-lab-r1.location
  name                = "spoke-2-vn"
  resource_group_name = azurerm_resource_group.ars-lab-r1.name
}

resource "azurerm_subnet" "spoke-2-vm-subnet" {
  address_prefixes     = ["10.97.0.0/28"]
  name                 = "spoke-vm-subnet"
  resource_group_name  = azurerm_resource_group.ars-lab-r1.name
  virtual_network_name = azurerm_virtual_network.spoke-2-vn.name
}


# Create a VM in spoke-vn in the vm-subnet
module "spoke-2-vm" {
  source              = "github.com/alexandreweiss/misc-tf-modules/azr-linux-vm"
  environment         = "spoke"
  location            = var.azure_r1_location
  location_short      = var.azure_r1_location_short
  index_number        = 02
  resource_group_name = azurerm_resource_group.ars-lab-r1.name
  subnet_id           = azurerm_subnet.spoke-2-vm-subnet.id
  admin_ssh_key       = var.ssh_public_key
  vm_size             = "Standard_B1ms"
}


module "spoke-2-vn-peering" {
  source = "github.com/alexandreweiss/terraform-azurerm-vnetpeering"

  left_vnet_resource_group_name  = azurerm_resource_group.ars-lab-r1.name
  left_vnet_name                 = azurerm_virtual_network.fw-2-vn.name
  right_vnet_resource_group_name = azurerm_resource_group.ars-lab-r1.name
  right_vnet_name                = azurerm_virtual_network.spoke-2-vn.name
  allow_forwarded_traffic        = true


  depends_on = [
    azurerm_virtual_network.ars-vn,
    azurerm_virtual_network.spoke-2-vn
  ]
}
