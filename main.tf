# Create a resource group if it doesn’t exist

resource "azurerm_resource_group" "testgroup" {
    name     = "TestGroup"
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }

}



# Create virtual network

resource "azurerm_virtual_network" "testnetwork" {

    name                = "testVnet"

    address_space       = ["10.0.0.0/16"]

    location            = "eastus"

    resource_group_name = "${azurerm_resource_group.testgroup.name}"



    tags = {

        environment = "Terraform Demo"

    }

}



# Create subnet

resource "azurerm_subnet" "testsubnet" {

    name                 = "testSubnet"

    resource_group_name  = "${azurerm_resource_group.testgroup.name}"

    virtual_network_name = "${azurerm_virtual_network.testnetwork.name}"

    address_prefix       = "10.0.1.0/24"

}



# Create public IPs

resource "azurerm_public_ip" "testpublicip" {

    name                         = "testPublicIP"

    location                     = "eastus"

    resource_group_name          = "${azurerm_resource_group.testgroup.name}"

    allocation_method            = "Dynamic"



    tags = {

        environment = "Terraform Demo"

    }

}



# Create Network Security Group and rule

resource "azurerm_network_security_group" "testnsg" {

    name                = "testSecurityGroup"

    location            = "eastus"

    resource_group_name = "${azurerm_resource_group.testgroup.name}"

    

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
  resource_group_name = "${azurerm_resource_group.testgroup.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.testpublicip.id}"
  }
}



# Create network interface

resource "azurerm_network_interface" "testnic" {

    name                      = "testNIC"

    location                  = "eastus"

    resource_group_name       = "${azurerm_resource_group.testgroup.name}"

    network_security_group_id = "${azurerm_network_security_group.testnsg.id}"



    ip_configuration {

        name                          = "testnicConfiguration"

        subnet_id                     = "${azurerm_subnet.testsubnet.id}"

        private_ip_address_allocation = "Dynamic"

        public_ip_address_id          = "${azurerm_public_ip.testpublicip.id}"

    }



    tags = {

        environment = "Terraform Demo"

    }

}



# Generate random text for a unique storage account name

resource "random_id" "testrandomId" {

    keepers = {

        # Generate a new ID only when a new resource group is defined

        resource_group = "${azurerm_resource_group.testgroup.name}"

    }

    

    byte_length = 8

}



# Create storage account for boot diagnostics

resource "azurerm_storage_account" "teststorageaccount" {

    name                        = "storeage1091"

    resource_group_name         = "${azurerm_resource_group.testgroup.name}"

    location                    = "eastus"

    account_tier                = "Standard"

    account_replication_type    = "LRS"



    tags = {

        environment = "Terraform Demo"

    }

}



# Create virtual machine

resource "azurerm_virtual_machine" "testvm" {

    name                  = "testVM"

    location              = "eastus"

    resource_group_name   = "${azurerm_resource_group.testgroup.name}"

    network_interface_ids = ["${azurerm_network_interface.testnic.id}"]

    vm_size               = "Standard_DS1_v2"



    storage_os_disk {

        name              = "testDisk"

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

        computer_name  = "testvm"

        admin_username = "azureuser"

        admin_password = "Password1234!"

    }



    os_profile_linux_config {

        disable_password_authentication = false

    }

    boot_diagnostics {

        enabled = "true"

        storage_uri = "${azurerm_storage_account.teststorageaccount.primary_blob_endpoint}"

    }

    

    connection {

       type = "ssh"

       host = "testvm"

       user = "azureuser"

       port = "22"

       agent = false

    }

    tags = {

        environment = "Terraform Demo"

    }
}
resource "azurerm_virtual_machine_extension" "testextension" {
      name                 = "testVM"
      location             = "East US"
      resource_group_name  = "${azurerm_resource_group.testgroup.name}"
      virtual_machine_name = "${azurerm_virtual_machine.testvm.name}"
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
