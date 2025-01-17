module "azure_transit_ars" {
  source = "terraform-aviatrix-modules/mc-transit/aviatrix"
  //version = "2.5.1"

  cloud                         = "azure"
  region                        = var.azure_r1_location
  cidr                          = "10.110.0.0/23"
  account                       = var.azure_account
  name                          = "azr-${var.azure_r1_location_short}-ars-transit"
  local_as_number               = var.asn_transit
  resource_group                = azurerm_resource_group.ars-lab-r1.name
  bgp_lan_interfaces_count      = 1
  enable_bgp_over_lan           = true
  instance_size                 = "Standard_B2ms"
  insane_mode                   = true
  enable_advertise_transit_cidr = true
}

# This is the BGP over LAN connection creation on Aviatrix side
resource "aviatrix_spoke_external_device_conn" "transit-ars-bgp" {
  vpc_id                    = module.azure_transit_ars.vpc.vpc_id
  connection_name           = "ars"
  gw_name                   = module.azure_transit_ars.transit_gateway.gw_name
  connection_type           = "bgp"
  tunnel_protocol           = "LAN"
  bgp_local_as_num          = var.asn_transit
  bgp_remote_as_num         = "65515"
  remote_lan_ip             = "10.90.0.69"
  local_lan_ip              = module.azure_transit_ars.transit_gateway.bgp_lan_ip_list[0]
  remote_vpc_name           = "${azurerm_virtual_network.ars-vn.name}:${azurerm_resource_group.ars-lab-r1.name}:${data.azurerm_subscription.current.subscription_id}"
  backup_local_lan_ip       = module.azure_transit_ars.transit_gateway.ha_bgp_lan_ip_list[0]
  backup_remote_lan_ip      = "10.90.0.68"
  backup_bgp_remote_as_num  = "65515"
  ha_enabled                = true
  depends_on                = [module.vn-peering]
  enable_bgp_lan_activemesh = true
  //manual_bgp_advertised_cidrs = ["10.0.0.0/16"]
}

module "transit-ars-peering" {
  source = "github.com/alexandreweiss/terraform-azurerm-vnetpeering"

  left_vnet_resource_group_name  = azurerm_resource_group.ars-lab-r1.name
  left_vnet_name                 = azurerm_virtual_network.ars-vn.name
  right_vnet_resource_group_name = azurerm_resource_group.ars-lab-r1.name
  right_vnet_name                = module.azure_transit_ars.vpc.name
  allow_forwarded_traffic        = true
  left_allow_gateway_transit     = true
  left_use_remote_gateways       = false
  right_allow_gateway_transit    = false
  right_use_remote_gateways      = true

  depends_on = [
    azurerm_virtual_network.ars-vn,
    module.azure_transit_ars
  ]
}

module "transit-fw-peering" {
  source = "github.com/alexandreweiss/terraform-azurerm-vnetpeering"

  left_vnet_resource_group_name  = azurerm_resource_group.ars-lab-r1.name
  left_vnet_name                 = azurerm_virtual_network.fw-vn.name
  right_vnet_resource_group_name = azurerm_resource_group.ars-lab-r1.name
  right_vnet_name                = module.azure_transit_ars.vpc.name
  allow_forwarded_traffic        = true

  depends_on = [
    azurerm_virtual_network.fw-vn,
    module.azure_transit_ars
  ]
}

module "transit-fw-2-peering" {
  source = "github.com/alexandreweiss/terraform-azurerm-vnetpeering"

  left_vnet_resource_group_name  = azurerm_resource_group.ars-lab-r1.name
  left_vnet_name                 = azurerm_virtual_network.fw-2-vn.name
  right_vnet_resource_group_name = azurerm_resource_group.ars-lab-r1.name
  right_vnet_name                = module.azure_transit_ars.vpc.name
  allow_forwarded_traffic        = true

  depends_on = [
    azurerm_virtual_network.fw-2-vn,
    module.azure_transit_ars
  ]
}
