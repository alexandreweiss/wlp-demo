module "r1-fw-1-vm" {
  source               = "github.com/alexandreweiss/misc-tf-modules/azr-linux-vm"
  environment          = "fw"
  location             = var.azure_r1_location
  location_short       = var.azure_r1_location_short
  index_number         = 01
  resource_group_name  = azurerm_resource_group.ars-lab-r1.name
  subnet_id            = azurerm_subnet.fw-vm-subnet.id
  admin_ssh_key        = var.ssh_public_key
  enable_ip_forwarding = true
  custom_data          = data.template_cloudinit_config.fw-config.rendered
  enable_lb            = true
  lb_backend_pool_id   = azurerm_lb_backend_address_pool.be_lb.id
}

data "template_file" "cloudconfig-fw" {
  template = file("${path.module}/cloud-init-fw.tpl")

  vars = {
  }
}

data "template_cloudinit_config" "fw-config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.cloudconfig-fw.rendered
  }
}

resource "azurerm_lb" "fw_lb" {
  name                = "fw-lb"
  location            = azurerm_resource_group.ars-lab-r1.location
  resource_group_name = azurerm_resource_group.ars-lab-r1.name
  sku                 = "Standard"
  sku_tier            = "Regional"

  frontend_ip_configuration {
    name                          = "PrivateIp"
    subnet_id                     = azurerm_subnet.fw-vm-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "be_lb" {
  loadbalancer_id = azurerm_lb.fw_lb.id
  name            = "BackEndAddressPool"
}

# Insert inbound rule for FW LB with Port 0 and protocol all
resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.fw_lb.id
  name                           = "HAPort"
  frontend_ip_configuration_name = azurerm_lb.fw_lb.frontend_ip_configuration[0].name
  frontend_port                  = 0
  backend_port                   = 0
  protocol                       = "All"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.be_lb.id]
  probe_id                       = azurerm_lb_probe.lb_probe.id
}

resource "azurerm_lb_probe" "lb_probe" {
  loadbalancer_id     = azurerm_lb.fw_lb.id
  name                = "tcpProbe"
  protocol            = "Tcp"
  port                = 22
  interval_in_seconds = 5
  number_of_probes    = 2
}
