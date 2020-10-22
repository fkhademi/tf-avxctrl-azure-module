resource "azurerm_resource_group" "main" {
  name     = "${var.name}-rg"
  location = var.location
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
  address_prefixes       = [var.vnet_subnet_cidr]
}

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

resource "null_resource" "accept_license" {
  provisioner "local-exec" {
    command = "python3 ./accept_license.py"
  }
}

resource "azurerm_virtual_machine" "avxctrl" {
  name                  = "AviatrixController"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = ["${azurerm_network_interface.main.id}"]
  vm_size               = "Standard_A4_v2"

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
    managed_disk_type = "Standard_LRS"
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
##################
#### CO-PILOT ####
##################
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