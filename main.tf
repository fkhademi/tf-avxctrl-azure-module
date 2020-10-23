provider "azurerm" {
  features {}
}
### RG, VNET, Subnet ###
resource "azurerm_resource_group" "main" {
  name       = "${var.name}-rg"
  location   = var.location
  depends_on = [azurerm_marketplace_agreement.controller, azurerm_marketplace_agreement.copilot]
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.name}-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = [var.vnet_cidr]
}

resource "azurerm_subnet" "internal" {

  name                 = "${var.name}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.vnet_subnet_cidr]
}

resource "azurerm_marketplace_agreement" "controller" {
  count     = var.agreement ? 1 : 0
  publisher = "aviatrix-systems"
  offer     = "aviatrix-bundle-payg"
  plan      = "aviatrix-enterprise-bundle-byol"
}

resource "azurerm_marketplace_agreement" "copilot" {
  count     = var.agreement ? 1 : 0
  publisher = "aviatrix-systems"
  offer     = "aviatrix-copilot"
  plan      = "avx-cplt-byol-01"
}

### Controller ###
resource "azurerm_network_interface" "main" {
  name                = "avx-ctrl-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "avx-ctrl-nic"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_public_ip" "main" {
  name                    = "avx-ctrl-public-ip"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}

resource "azurerm_network_security_group" "ctrl-nsg" {
  name                = "ctrl-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "HTTPS"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_interface_security_group_association" "ctrl_nsg" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.ctrl-nsg.id
}

resource "azurerm_virtual_machine" "avxctrl" {
  name                  = "AviatrixController"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = ["${azurerm_network_interface.main.id}"]
  vm_size               = "Standard_D8s_v3"

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "aviatrix-systems"
    offer     = "aviatrix-bundle-payg"
    sku       = "aviatrix-enterprise-bundle-byol"
    version   = "latest"
  }

  plan {
    name      = "aviatrix-enterprise-bundle-byol"
    publisher = "aviatrix-systems"
    product   = "aviatrix-bundle-payg"
  }

  storage_os_disk {
    name              = "avxdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "1025"
  }

  os_profile {
    computer_name  = "avx-controller"
    admin_username = "avx2020"
    admin_password = var.os_pw
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_storage_account" "backup" {
  name                     = "avxctrlbackup"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "backup" {
  name                  = "backup"
  storage_account_name  = azurerm_storage_account.backup.name
  container_access_type = "private"
}

##################
#### CO-PILOT ####
##################

resource "azurerm_network_security_group" "copilot-nsg" {
  name                = "copilot-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "NetFlow"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "UDP"
    source_port_range          = "*"
    destination_port_range     = "31283"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Syslog"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "UDP"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTPS"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_interface_security_group_association" "copilot_nsg" {
  network_interface_id      = azurerm_network_interface.avx-copilot-nic.id
  network_security_group_id = azurerm_network_security_group.copilot-nsg.id
}

resource "azurerm_network_interface" "avx-copilot-nic" {
  name                = "avx-copilot-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "avx-copilot-nic"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.avx-copilot-pub.id
  }
}

resource "azurerm_public_ip" "avx-copilot-pub" {
  name                    = "avx-copilot-public-ip"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}
resource "azurerm_virtual_machine" "avxcopilot" {
  name                  = "AviatrixCoPilot"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = ["${azurerm_network_interface.avx-copilot-nic.id}"]
  vm_size               = "Standard_B8ms"

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "aviatrix-systems"
    offer     = "aviatrix-copilot"
    sku       = "avx-cplt-byol-01"
    version   = "latest"
  }

  plan {
    name      = "avx-cplt-byol-01"
    publisher = "aviatrix-systems"
    product   = "aviatrix-copilot"
  }

  storage_os_disk {
    name              = "avx-copilot-disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "avx-copilot"
    admin_username = "avx2020"
    admin_password = var.os_pw
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}