// based on AKS Secure Baseline https://github.com/mspnp/aks-secure-baseline/blob/main/cluster-stamp.json

param name string
param region string
param tags object
param vnetSubnetID string
param isAksPrivate bool

@description('Whether to enable Kubernetes Role-Based Access Control')
param enableRBAC bool = true

@description('DNS prefix specified when creating the managed cluster')
param aksDnsPrefix string

@description('Name of the resource group containing agent pool nodes')
param aksManagedRG string

@minValue(0)
@maxValue(1023)
@description('OS Disk Size in GB to be used to specify the disk size for every machine in this master/agent pool. If you specify 0, it will apply the default osDisk size according to the vmSize specified.')
param systemOsDiskSizeGB int = 80

@minValue(0)
@maxValue(1000)
@description('Number of agents (VMs) to host docker containers. Allowed values must be in the range of 0 to 1000 (inclusive) for user pools and in the range of 1 to 1000 (inclusive) for system pools. The default value is 1.')
param systemAgentCount int = 2

@minValue(30)
@maxValue(250)
@description('Maximum number of pods that can run on a node')
param systemMaxPods int = 30

//todo: add some reccomendations here
param systemAgentVMSize string

@minValue(0)
@maxValue(1023)
@description('OS Disk Size in GB to be used to specify the disk size for every machine in this master/agent pool. If you specify 0, it will apply the default osDisk size according to the vmSize specified.')
param userOsDiskSizeGB int = 120

@minValue(0)
@maxValue(1000)
@description('Number of agents (VMs) to host docker containers. Allowed values must be in the range of 0 to 1000 (inclusive) for user pools and in the range of 1 to 1000 (inclusive) for system pools. The default value is 1.')
param userAgentCount int = 3

@minValue(30)
@maxValue(250)
@description('Maximum number of pods that can run on a node')
param userMaxPods int = 90

//todo: add some reccomendations here
param userAgentVMSize string 

@description('A CIDR notation IP range from which to assign service cluster IPs. It must not overlap with any Subnet IP ranges. It can be any private network CIDR such as, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 ')
param serviceCidr string = '10.255.0.0/16'

@description('An IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr')
param dnsServiceIP string = '10.255.0.10'

@description('A CIDR notation IP range from which to assign pod IPs when kubenet is used.')
param podCidr string = '10.254.0.0/16'

@description('A CIDR notation IP range assigned to the Docker bridge network. It must not overlap with any Subnet IP ranges or the Kubernetes service address range.')
param dockerBridgeCidr string = '172.31.0.1/16'



@description('The log analytics workspace of AKS (for container monitoring etc)')
param aksLawsName string 

@description('A flag to define if AGIC Controller should be deployed')
param deployAgic bool = false

@description('AGIC Subnet - Created only if AGIC is deployed.')
param agicSubnet string

//TODO 1: conditional handling of enableAutoScaling: false
//TODO 2: Check if gpuInstanceProfile is needed
//TODO 3: check enableUltraSSD
//TODO 4: check if osDiskType is needed for forcing ephemeral disks
//TODO 5: check ContainerServiceNetworkProfile.outboundType if needed


//Create a private IP to attach to the Application Gateway
resource pip 'Microsoft.Network/publicIPAddresses@2020-06-01' = if (deployAgic) {
  name: 'pip-agic-${name}'
  location: region
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static' 
  }
}


var agicName='agic-${name}'

//Create the application Gateway resource to be used for AGIC
resource agic 'Microsoft.Network/applicationGateways@2021-02-01' = if (deployAgic) {
  name: agicName
  location: region
  tags: {
    'managed-by-k8s-ingress': 'true'
  }
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 4
    }
    gatewayIPConfigurations: [
      {
        name: 'agicName-ip-configuration' 
        properties: {
          subnet: {
            id:  agicSubnet
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: '${agicName}-ip-configuration' 
        properties: {
          publicIPAddress: {
            id: pip.id //Attach the public IP
          }
        }
      }
    ]
    frontendPorts: [
      { //Create the HTTP ports configurations (only HTTPS is assigned to a listener, HTTP is not used)
        name: 'httpsPort'
        properties: {
          port: 443 
        }
        
      }
      {
        name: 'httpPort'
        properties: {
          port: 80
        }
        
      }      
    ]
    backendAddressPools: [
      {
        name: 'bepool'
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      { //Configure the backend HTTP Settings for Ingest Function App
        name: 'setting'
        properties: {
          port: 80
          protocol: 'Http'
        }
      }
    ]
    // sslCertificates: [
    //   {
    //     name: resourceNames.frontendAgwCertificateName
    //     properties: sslCertificateProperties  //Attach the SSL certificate
    //   }
    // ]
    //Tie together all the pieces to configure the listener and rules
     httpListeners: [
      { 
        name: 'httpListener'
        properties: {
          frontendIPConfiguration: { //Use the above configured front end IP configuration
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', agicName, '${agicName}-ip-configuration')
          }
          frontendPort: {   //Use the above configured HTTPS port
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', agicName, 'httpPort')
          }
          protocol: 'Http'
          // protocol: 'Https'
          // sslCertificate:{ //Use the above configured certificate
          //   id: resourceId('Microsoft.Network/applicationGateways/sslCertificates',name,resourceNames.frontendAgwCertificateName)
          // } 
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          // ruleType: 'Basic'
          httpListener: {  //Use the above configured listener
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', agicName, 'httpListener')
          }
          backendAddressPool: {  //Send all trafic to the Ingest Function App backend
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', agicName, 'bepool')
          }
          backendHttpSettings: { //Use the above configured back end settings
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', agicName, 'setting')
          }
        }
      }
    ]
  }
}

// resources
resource aks_workspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: aksLawsName
  location: region
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2021-03-01' = {
  name: name
  location: region
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enableRBAC: enableRBAC
    dnsPrefix: aksDnsPrefix
    nodeResourceGroup: aksManagedRG
    agentPoolProfiles: [
      {
        name: 'systempool'
        osDiskSizeGB: systemOsDiskSizeGB
        osDiskType: 'Ephemeral'
        count: systemAgentCount
        vmSize: systemAgentVMSize
        osType: 'Linux'
        maxPods: systemMaxPods
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
        enableAutoScaling: true
        minCount: systemAgentCount
        maxCount: systemAgentCount + 2
        vnetSubnetID: vnetSubnetID
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
      }
      {
        name: 'userpool'
        osDiskSizeGB: userOsDiskSizeGB
        osDiskType: 'Ephemeral'
        count: userAgentCount
        vmSize: userAgentVMSize
        osType: 'Linux'
        maxPods: userMaxPods
        type: 'VirtualMachineScaleSets'
        mode: 'User'
        enableAutoScaling: true
        minCount: userAgentCount
        maxCount: 5 * userAgentCount + 1
        vnetSubnetID: vnetSubnetID
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
      }
    ]
    apiServerAccessProfile: {
      enablePrivateCluster: isAksPrivate
    }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    networkProfile: {
      networkPlugin: 'kubenet'
      loadBalancerSku: 'standard'
      // outboundType: 'loadBalancer'   TODO: 
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      podCidr: podCidr
      dockerBridgeCidr: dockerBridgeCidr
    }
    addonProfiles: {
      omsagent: {
        config: {
          logAnalyticsWorkspaceResourceID: aks_workspace.id
        }
        enabled: true
      }
      ingressApplicationGateway: deployAgic ?{
        enabled: true
        config: {
            applicationGatewayId: agic.id
        }      
       } : {
        enabled: false
          }
  }
 }
}


output aksID string = aks.id
output aksName string = aks.name
output apiServerAddress string = isAksPrivate ? aks.properties.privateFQDN : ''
output aksNodesRG string = aks.properties.nodeResourceGroup
output identity object = {
  tenantId: aks.identity.tenantId
  principalId: aks.identity.principalId
  type: aks.identity.type
}
