// The name of the private DNS Zone
param privateDnsZoneName string
param tags object
param vnetName string 
param vnetID string
param registrationEnabled bool = false

var privateDnsFqdn = substring(privateDnsZoneName, indexOf(privateDnsZoneName, '.') + 1, length(privateDnsZoneName)-(indexOf(privateDnsZoneName, '.') + 1))

resource privatednsvnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsFqdn}/link-to-${vnetName}'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: vnetID
    }
    registrationEnabled: registrationEnabled
  }
}
