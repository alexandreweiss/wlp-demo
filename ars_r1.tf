## ARS creation in region 1

module "ars_r1" {
  source = "github.com/alexandreweiss/misc-tf-modules.git/ars"

  resource_group_name = azurerm_resource_group.ars-lab-r1.name
  location            = var.azure_r1_location
  subnet_id           = azurerm_subnet.ars-subnet.id
  ars_name            = "ars-${var.azure_r1_location_short}"
  enable_b2b          = true
}

output "ars_r1" {
  value = module.ars_r1.ars
}

resource "azurerm_route_server_bgp_connection" "avx-gw" {
  name            = "we-bgp-transit-gw"
  peer_asn        = var.asn_transit
  peer_ip         = module.azure_transit_ars.transit_gateway.bgp_lan_ip_list[0]
  route_server_id = module.ars_r1.ars.id
}

resource "azurerm_route_server_bgp_connection" "avx-hagw" {
  name            = "we-bgp-transit-hagw"
  peer_asn        = var.asn_transit
  peer_ip         = module.azure_transit_ars.transit_gateway.ha_bgp_lan_ip_list[0]
  route_server_id = module.ars_r1.ars.id
}

resource "azurerm_route_server_bgp_connection" "inject-vm" {
  name            = "vm-inject"
  peer_asn        = var.asn_inject
  peer_ip         = module.r1_inject_vm.vm_private_ip
  route_server_id = module.ars_r1.ars.id
}

module "r1_inject_vm" {
  source              = "github.com/alexandreweiss/misc-tf-modules/azr-linux-vm"
  environment         = "injec"
  location            = var.azure_r1_location
  location_short      = var.azure_r1_location_short
  index_number        = 01
  resource_group_name = azurerm_resource_group.ars-lab-r1.name
  subnet_id           = azurerm_subnet.vm-subnet.id
  admin_ssh_key       = var.ssh_public_key
  custom_data         = data.template_cloudinit_config.config.rendered
}

data "template_file" "cloudconfig-inject" {
  template = file("${path.module}/cloud-init.tpl")

  vars = {
    bgp_peer_1_ip       = tolist(module.ars_r1.ars.virtual_router_ips)[0]
    bgp_peer_2_ip       = tolist(module.ars_r1.ars.virtual_router_ips)[1]
    peer_ilb_ip_address = azurerm_lb.fw_lb.private_ip_address
    asn_inject          = var.asn_inject
    asn_transit         = var.asn_transit
    spoke_vnet_cidr     = azurerm_subnet.spoke-vm-subnet.address_prefixes[0]
    ars_asn             = module.ars_r1.ars.virtual_router_asn
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.cloudconfig-inject.rendered
  }
}
