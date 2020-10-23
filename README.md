# tf-avxctrl-azure-module
Terraform Module to eploy an Aviatrix Controller in Azure

### Description

This will deploy a Resource Group, Shared Services VNET, Subnet, Controller and Co-Pilot in a specified Azure region

### Diagram

<img src="https://raw.githubusercontent.com/fkhademi/tf-avxctrl-azure-module/main/img.png">

### Variables
The following variables are required:

key | value
--- | ---
azure_sub_id | 
azure_app_id |
azure_app_key |
azure_dir_id |


The following variables are optional:

key | default | value
--- | --- | ---
agreement | true | accept marketplace agreement
