// params
@minLength(5)
@maxLength(50)
@description('Specifies the name of the azure container registry.')
param name string
param region string
param tags object

@description('Enable admin user that have push / pull permission to the registry.')
param acrAdminUserEnabled bool = false


@allowed([
  'Basic'
  'Standard'
  'Premium'
])
@description('Tier of your Azure Container Registry.')
param acrSku string = 'Basic'

// azure container registry
resource acr 'Microsoft.ContainerRegistry/registries@2019-12-01-preview' = {
  name: name
  location: region
  tags: tags
  sku: {
    name: acrSku
  }
  identity:{
    type:'SystemAssigned'
  }
  properties: {
    adminUserEnabled: acrAdminUserEnabled
  }
}

output acrLoginServer string = acr.properties.loginServer
output acrID string = acr.id
