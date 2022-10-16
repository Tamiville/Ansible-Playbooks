resource "azurerm_resource_group" "elite_general_resources" {
  name     = local.elite_general_resources
  location = var.location
}

resource "azurerm_network_interface" "labnic" {
  name                = join("-", [local.server, "lab", "nic"])
  location            = local.buildregion
  resource_group_name = azurerm_resource_group.elite_general_resources.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.application_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.labpip.id
  }
}

resource "azurerm_public_ip" "labpip" {
  name                = join("-", [local.server, "lab", "pip"])
  resource_group_name = azurerm_resource_group.elite_general_resources.name
  location            = local.buildregion
  allocation_method   = "Static"

  tags = local.common_tags
}


resource "azurerm_linux_virtual_machine" "Linuxvm" {
  name                = join("-", [local.server, "linux", "vm"])
  resource_group_name = azurerm_resource_group.elite_general_resources.name
  location            = local.buildregion
  size                = "Standard_DS1"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.labnic.id,
  ]

  connection {
    type        = "ssh"
    user        = var.user
    private_key = file(var.path_privatekey)
    host        = self.public_ip_address
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/x5Tg/HahPf8wbLJD+pdZ8NuLryCBUGUzKO+89u0kCr7NSBLqBN2fbNUywkCHkvIILyvTLAY8Bzs31J2fYK0f5EiPP1jaeM3fNvdmiPOlrTyYA7E2xiTl/wZ/gvyXi/eWq6kGfS948fALk/Mfnfm4dmdq5zcgLDCiO7xHg2rCW+G9naa3SUbRTqxFPi/YXkmHc3GLyBfOplLE05nMOx15h4fUqQ2ctBiqANqrYoc+u9ePlnER8tIklyB6yq0H7yJk1iEyT0wWP4JS8EOAcRuQX34shFtzQQfipG8zjuu9KgIYyln8zZN7ibMgSTyjcYc0EWdWrY4SOvJ88Bvxpj7laTDeRU9ViNvr0uey6cj2Ynvexnc4hg8Plj+jN3180xCBMtvJfJMBlOb9WwD8cBqF2fpLGRuWUhSoAX/W89UL/17lOZKoPYsfBsRgCvXyd4Xl2rB2a4t4nFi8FX5NhikjmP2lpIJ5NKAqaj4sGZA0ecHOPcGuTsjfx8jHGsbZvwU= apple@Tamie-Emmanuel"
  }
  # provisioner "file" {
  #   source      = "./scripts/script.sh"
  #   destination = "/tmp/script.sh"
  # }
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.user} -i '${self.public_ip_address},' --private-key ${var.path_privatekey} ansibleplaybooks/nginx.yml -vv"
  # }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    offer     = "0001-com-ubuntu-server-focal"
    publisher = "Canonical"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}
