param name string
param region string
param tags object
param vnetAddressSpace string 
param enableVmProtection bool = false
param enableDdosProtection bool = false
param snetAKSNodes object
param snetPE object
param snetAdmin object
param snetBastion object
param snetAgic object
param deployAgic bool = false


var fixedSubnets = [
  {
    name: snetAKSNodes.name
    properties: {
      addressPrefix: snetAKSNodes.subnetPrefix
      privateEndpointNetworkPolicies: 'Enabled'
    }
  }     
  {
    name: snetPE.name
    properties: {
      addressPrefix: snetPE.subnetPrefix
      privateEndpointNetworkPolicies: 'Disabled'          
    }
  }
  {
    name: snetAdmin.name
    properties: {
      addressPrefix: snetAdmin.subnetPrefix
      privateEndpointNetworkPolicies: 'Enabled'
    }
  }
  {
    name: snetBastion.name
    properties: {
      addressPrefix: snetBastion.subnetPrefix
      privateEndpointNetworkPolicies: 'Enabled'
    }
  }]

var subnets = deployAgic ? union(fixedSubnets, [
  {
    name: snetAgic.name
    properties: {
      addressPrefix: snetAgic.subnetPrefix
      privateEndpointNetworkPolicies: 'Enabled'
    }
  }]) : fixedSubnets

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: name
  location: region
  tags: tags
  properties: {
    enableVmProtection: enableVmProtection
    enableDdosProtection: enableDdosProtection
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }  
    subnets: subnets
  }  
}


output vnetID string = vnet.id
output vnetName string = vnet.name
output snetAksID string = vnet.properties.subnets[0].id
output snetPEID string = vnet.properties.subnets[1].id
output snetAdminID string = vnet.properties.subnets[2].id
output snetBastionID string = vnet.properties.subnets[3].id
output snetAgicID string = deployAgic ? vnet.properties.subnets[4].id : ''

