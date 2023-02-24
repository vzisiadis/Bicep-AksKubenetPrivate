// that's the default, but put it here for completeness
targetScope = 'resourceGroup'

// PARAMS General
param suffix string = 'AKS-TestBed'
// params exported on param file
param resourceTags object
param deployJumbBox bool
param deployBastion bool
param deployAgic bool
param appPrefix string

// PARAMS Vnet
param vnetAddressSpace string = '192.168.0.0/16'
param aksSubnet object = {
  name: 'snet-aksNodes'
  subnetPrefix: '192.168.0.0/25'
}

param snetPE object = {
  name: 'snet-PE'
  subnetPrefix: '192.168.0.128/26'
}

param snetAdmin object = {
  name: 'snet-Admin'
  subnetPrefix: '192.168.0.192/27'
}

param snetBastion object = {
  name: 'AzureBastionSubnet' //fixed name of subnet de-jure
  subnetPrefix: '192.168.0.224/27'
}

// Although a /24 subnet isn't required per Application Gateway v2 SKU deployment, it is highly recommended. 
// This is to ensure that Application Gateway v2 has sufficient space for autoscaling expansion and maintenance upgrades. 
// You should ensure that the Application Gateway v2 subnet has sufficient address space to accommodate the number of instances required to serve your maximum expected traffic. 
// If you specify the maximum instance count, then the subnet should have capacity for at least that many addresses.
param snetAgic object = {
  name: 'snet-agic'
  subnetPrefix: '192.168.1.0/24'
}

//params VM
param vmJumpBox object

//VARS
// vars  Resource Names
var env = resourceTags.Environment
var vnetName = 'vnet-${suffix}-${env}'
var bastionName = 'bastionHost${env}'



//Create Resources

//create the Virtual Network to host all resources and its subnets
module vnet 'modules/VNet.module.bicep' = {
  name: 'vnetDeployment-${vnetName}'
  params: {
    name: vnetName
    region: resourceGroup().location
    snetAKSNodes: aksSubnet
    snetPE: snetPE
    snetAdmin: snetAdmin
    snetBastion: snetBastion
    deployAgic: deployAgic
    snetAgic: snetAgic
    vnetAddressSpace: vnetAddressSpace
    tags: resourceTags
  }
}


module vm 'modules/vmjumpbox.module.bicep'  =  if (deployJumbBox) {
  name: 'vmJumpboxDeployment'
  params: {
    name: vmJumpBox.name
    region: resourceGroup().location
    tags: resourceTags
    adminUserName: vmJumpBox.adminUserName
    adminPassword: vmJumpBox.adminPassword
    dnsLabelPrefix: vmJumpBox.dnsLabelPrefix
    subnetId: vnet.outputs.snetAdminID
    vmSize:  vmJumpBox.vmSize
    windowsOSVersion: vmJumpBox.windowsOSVersion    
  }
}

module bastion 'modules/bastion.module.bicep' =  if (deployBastion){
  name: 'bastionDeployment'
  params: {
    name: bastionName
    region: resourceGroup().location
    tags: resourceTags
    subnetId: vnet.outputs.snetBastionID
  }
}

output aksSubnetID string = vnet.outputs.snetAksID
output vnetName string = vnet.outputs.vnetName
 output appPrefix string = appPrefix
output agicSubnetID string = vnet.outputs.snetAgicID
// output akvID string = keyVault.outputs.id
// output akvURL string = 'https://${toLower(keyVault.outputs.name)}.vault.azure.net/'//https://kv-dev-databricksexplore.vault.azure.net/
