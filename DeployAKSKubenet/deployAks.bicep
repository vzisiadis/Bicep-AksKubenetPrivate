// that's the default, but put it here for completeness
//targetScope = 'resourceGroup'

// PARAMS General
// param suffix string = 'AKSPrivateKubenet'
// params exported on param file
param resourceTags object
param snetID string 
param attachACR bool
// param vnetName string
// param vnetRG string

// //Role assignment params
// @description('A new GUID used to identify the role assignment')
// param roleNameGuid string = guid(resourceGroup().id)

//VARS
var aksName = 'aks-kubenet-${uniqueString(resourceGroup().id)}'
var acrName = 'acrtt${uniqueString(resourceGroup().id)}' // must be globally unique
//var NetworkContributorRoleAssignment = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'

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

module acr 'Modules/acr.module.bicep' = if (attachACR) {
  name: 'acrDeployment'
  params: {
    name: acrName
    region: resourceGroup().location
    tags: resourceTags
  }
}
// ATTENTION: if the vnet is on other RG you cannot get a reference to that, so the below snippet fails
// // //get a reference of the existing Vnet (which possibly resides on a different RG)
// resource vnetRef 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
//   scope: resourceGroup(vnetRG)
//   name: vnetName
// }

// //assign
// resource roleAssignmentNetworkContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
//   scope: vnetRef
//   name: roleNameGuid
//   properties: {
//     roleDefinitionId: NetworkContributorRoleAssignment
//     principalId: aks.outputs.identity.principalId
//   }
// }


output aksID string = aks.outputs.aksID
output aksName string = aks.outputs.aksName
//output apiServerAddress string = aks.outputs.apiServerAddress
output aksNodesRG string = aks.outputs.aksNodesRG
output aksTenantID string = aks.outputs.identity.tenantId
output aksSPID string = aks.outputs.identity.principalId
output aksIdentityType string = aks.outputs.identity.type
output acrID string = attachACR ? acr.outputs.acrID : ''
output acrLoginServer string = attachACR ? acr.outputs.acrLoginServer  : ''
