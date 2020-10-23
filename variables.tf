# Azure
variable "location" { default = "Germany West Central" }
variable "name" { default = "avx-shared" }
variable "vnet_cidr" { default = "10.0.0.0/20" }
variable "vnet_subnet_cidr" { default = "10.0.0.0/24" }
variable "os_pw" { default = "Password1234!" }
variable "agreement" { default = true }