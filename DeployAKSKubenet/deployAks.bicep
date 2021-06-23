// that's the default, but put it here for completeness
targetScope = 'resourceGroup'

// PARAMS General
// param suffix string = 'AKSPrivateKubenet'
// params exported on param file
param resourceTags object
param snetID string 

//VARS
var aksName = 'aks-kubenet-${uniqueString(resourceGroup().id)}'

//Create Resources
module aks 'Modules/aks-kubenet.module.bicep' = {
  name: 'AKSDeployment'
  params: {
    name: aksName
    region: resourceGroup().location
    tags: resourceTags
    vnetSubnetID: snetID
  }
}


output aksID string = aks.outputs.aksID
//output apiServerAddress string = aks.outputs.apiServerAddress
output aksNodesRG string = aks.outputs.aksNodesRG
