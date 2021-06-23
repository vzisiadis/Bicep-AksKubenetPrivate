param name string
param subnetId string
param region string
param tags object

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: 'pip-${name}'
  location: region
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2020-06-01' = {
  name: name
  location: region
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

output ipAddress string = publicIp.properties.ipAddress
