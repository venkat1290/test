# Create a resource group if it doesn’t exist

resource "azurerm_resource_group" "myterraformgroup1" {
    name     = "myResourceGroup1"
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }

}



# Create virtual network

resource "azurerm_virtual_network" "myterraformnetwork1" {

    name                = "myVnet1"

    address_space       = ["10.0.0.0/16"]

    location            = "eastus"

    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"



    tags = {

        environment = "Terraform Demo"

    }

}



# Create subnet

resource "azurerm_subnet" "myterraformsubnet1" {

    name                 = "mySubnet1"

    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"

    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"

    address_prefix       = "10.0.1.0/24"

}



# Create public IPs

resource "azurerm_public_ip" "myterraformpublicip1" {

    name                         = "myPublicIP1"

    location                     = "eastus"

    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"

    allocation_method            = "Dynamic"



    tags = {

        environment = "Terraform Demo"

    }

}



# Create Network Security Group and rule

resource "azurerm_network_security_group" "myterraformnsg1" {

    name                = "myNetworkSecurityGroup1"

    location            = "eastus"

    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    

    security_rule {

        name                       = "SSH"

        priority                   = 1001

        direction                  = "Inbound"

        access                     = "Allow"

        protocol                   = "Tcp"

        source_port_range          = "*"

        destination_port_range     = "22"

        source_address_prefix      = "*"

        destination_address_prefix = "*"

    }



    tags = {

        environment = "Terraform Demo"

    }

}

#Create load Balancer

resource "azurerm_lb" "test" {
  name                = "TestLoadBalancer"
  location            = "West US"
  resource_group_name = "${azurerm_resource_group.test.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.test.id}"
  }
}



# Create network interface

resource "azurerm_network_interface" "myterraformnic1" {

    name                      = "myNIC1"

    location                  = "eastus"

    resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"

    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"



    ip_configuration {

        name                          = "myNicConfiguration1"

        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"

        private_ip_address_allocation = "Dynamic"

        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"

    }



    tags = {

        environment = "Terraform Demo"

    }

}



# Generate random text for a unique storage account name

resource "random_id" "randomId" {

    keepers = {

        # Generate a new ID only when a new resource group is defined

        resource_group = "${azurerm_resource_group.myterraformgroup.name}"

    }

    

    byte_length = 8

}



# Create storage account for boot diagnostics

resource "azurerm_storage_account" "mystorageaccount1" {

    name                        = "storeage1091"

    resource_group_name         = "${azurerm_resource_group.myterraformgroup.name}"

    location                    = "eastus"

    account_tier                = "Standard"

    account_replication_type    = "LRS"



    tags = {

        environment = "Terraform Demo"

    }

}



# Create virtual machine

resource "azurerm_virtual_machine" "myterraformvm1" {

    name                  = "myVM1"

    location              = "eastus"

    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"

    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]

    vm_size               = "Standard_DS1_v2"



    storage_os_disk {

        name              = "myOsDisk"

        caching           = "ReadWrite"

        create_option     = "FromImage"

        managed_disk_type = "Premium_LRS"

    }



    storage_image_reference {

        publisher = "OpenLogic"

        offer     = "CentOS"

        sku       = "7.5"

        version   = "latest"

    }



    os_profile {

        computer_name  = "myvm1"

        admin_username = "azureuser"

        admin_password = "Password1234!"

    }



    os_profile_linux_config {

        disable_password_authentication = false

    }

    boot_diagnostics {

        enabled = "true"

        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"

    }

    

    connection {

       type = "ssh"

       host = "myvm1"

       user = "azureuser"

       port = "22"

       agent = false

    }

    tags = {

        environment = "Terraform Demo"

    }
}
resource "azurerm_virtual_machine_extension" "myterraformextension" {
      name                 = "myVM1"
      location             = "East US"
      resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
      virtual_machine_name = "${azurerm_virtual_machine.myterraformvm.name}"
      publisher            = "Microsoft.OSTCExtensions"
      type                 = "CustomScriptForLinux"
      type_handler_version = "1.2"

      settings = <<SETTINGS
      {
	"commandToExecute": "yum install -y wget && wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins.io/redhat-stable/jenkins.repo && rpm --import http://pkg.jenkins.io/redhat-stable/jenkins.io.key && yum install -y java-1.8.0-openjdk && yum install -y jenkins && systemctl start jenkins && systemctl enable jenkins && yum install -y net-tools rsync && wgt https://bintray.com/jfrog/artifactory-rpms/download_file?file_path=jfrog-artifactory-oss-6.6.5.rpm && yum install -y download_file?file_path=jfrog-artifactory-oss-6.6.5.rpm && yum install -y git"
      }
    SETTINGS

    tags = {

        environment = "Terraform Demo"

    }
}
