resource "azurerm_resource_group" "test" {
name = "aditya-test"
location = "eastus"
}

resource "azurerm_virtual_network" "test" {
name = "aditya-vnet"
location = "${azurerm_resource_group.test.location}"
resource_group_name = "${azurerm_resource_group.test.name}"
address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "test" {
name = "subnet1"
resource_group_name = "${azurerm_resource_group.test.name}"
virtual_network_name = "${azurerm_virtual_network.test.name}"
address_prefix = "10.0.1.0/24"
}

resource "azurerm_public_ip" "test" {
name = "AdityaVMPubIp"
location = "${azurerm_resource_group.test.location}"
resource_group_name = "${azurerm_resource_group.test.name}"
allocation_method = "Static"
}

resource "azurerm_lb" "test" {
name = "adityaloadbalancer"
resource_group_name = "${azurerm_resource_group.test.name}"
location = "${azurerm_resource_group.test.location}"

frontend_ip_configuration {
name="frontendIp"
public_ip_address_id = "${azurerm_public_ip.test.id}"
}
}

resource "azurerm_lb_backend_address_pool" "test" {
resource_group_name = "${azurerm_resource_group.test.name}"
loadbalancer_id = "${azurerm_lb.test.id}"
name = "backendpool"
}

resource "azurerm_lb_rule" "test" {
  resource_group_name            = "${azurerm_resource_group.test.name}"
  loadbalancer_id                = "${azurerm_lb.test.id}"
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 3389
  backend_port                   = 3389
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_network_interface" "test" {
name = "aditya-vm-nic"
resource_group_name = "${azurerm_resource_group.test.name}"
location = "${azurerm_resource_group.test.location}"
ip_configuration {
name = "ipconfig1"
subnet_id = "${azurerm_subnet.test.id}"
private_ip_address_allocation = "dynamic"
load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.test.id}"]
}
}

resource "azurerm_managed_disk" "test" {
name = "adityavmdisk1"
resource_group_name = "${azurerm_resource_group.test.name}"
location = "${azurerm_resource_group.test.location}"
disk_size_gb = 100
storage_account_type = "Standard_LRS"
create_option = "Empty"
}

resource "azurerm_availability_set" "avset" {
 name = "avset"
 location = "${azurerm_resource_group.test.location}"
 resource_group_name = "${azurerm_resource_group.test.name}"
 platform_fault_domain_count = 2
 platform_update_domain_count = 2
 managed = true
}

resource "azurerm_virtual_machine" "test" {
 name = "adityavm1"
 location = "${azurerm_resource_group.test.location}"
 availability_set_id = "${azurerm_availability_set.avset.id}"
 resource_group_name = "${azurerm_resource_group.test.name}"
 network_interface_ids =  ["${azurerm_network_interface.test.id}"]
 vm_size = "Standard_DS1_v2"
 delete_os_disk_on_termination = true
 delete_data_disks_on_termination = true
 storage_image_reference {
 publisher = "Canonical"
 offer = "UbuntuServer"
 sku = "16.04-LTS"
 version = "latest"
 }
 storage_os_disk {
   name = "myvmosdisk"
   caching = "ReadWrite"
   create_option = "FromImage"
   managed_disk_type = "Standard_LRS"
 }
 storage_data_disk {
   name = "datadisknew"
   managed_disk_type = "Standard_LRS"
   create_option = "Empty"
   lun = 0
   disk_size_gb = "1023"
 }
 os_profile {
   computer_name  = "hostname"
   admin_username = "testadmin"
   admin_password = "Password1234!"
   }
    os_profile_linux_config {
   disable_password_authentication = false
 }
 }