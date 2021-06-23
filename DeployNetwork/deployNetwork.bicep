// that's the default, but put it here for completeness
targetScope = 'resourceGroup'

// PARAMS General
param suffix string = 'AKSPrivateKubenet'

// params exported on param file
param resourceTags object

// PARAMS Vnet
param vnetAddressSpace string = '192.168.0.0/24'
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

//params VM
param vmJumpBox object

//VARS
// vars  Resource Names
var env = resourceTags.Environment
var vnetName = 'vnet-${env}-${suffix}'
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
    vnetAddressSpace: vnetAddressSpace
    tags: resourceTags
  }
}


module vm 'modules/vmjumpbox.module.bicep'  = {
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

module bastion 'modules/bastion.module.bicep' = {
  name: 'bastionDeployment'
  params: {
    name: bastionName
    region: resourceGroup().location
    tags: resourceTags
    subnetId: vnet.outputs.snetBastionID
  }
}

output aksSubnetID string = vnet.outputs.snetAksID
// output dataLakeID string = dataLake.outputs.id
// output akvID string = keyVault.outputs.id
// output akvURL string = 'https://${toLower(keyVault.outputs.name)}.vault.azure.net/'//https://kv-dev-databricksexplore.vault.azure.net/
