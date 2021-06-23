param name string
param region string
param tags object
param vnetSubnetID string 

@description('Whether to enable Kubernetes Role-Based Access Control')
param enableRBAC bool = true

@description('DNS prefix specified when creating the managed cluster')
param dnsPrefix string = 'cluster01'

@description(' Name of the resource group containing agent pool nodes')
param nodeResourceGroup string = 'rg-TestAKS-MC-${name}-${dnsPrefix}'

@minValue(0)
@maxValue(1023)
@description('OS Disk Size in GB to be used to specify the disk size for every machine in this master/agent pool. If you specify 0, it will apply the default osDisk size according to the vmSize specified.')
param osDiskSizeGB int = 0

@minValue(0)
@maxValue(1000)
@description('Number of agents (VMs) to host docker containers. Allowed values must be in the range of 0 to 1000 (inclusive) for user pools and in the range of 1 to 1000 (inclusive) for system pools. The default value is 1.')
param agentCount int = 3

@minValue(30)
@maxValue(250)
@description('Maximum number of pods that can run on a node')
param maxPods int = 110

//todo: add some reccomendations here
param agentVMSize string = 'Standard_D2s_v4'

@description('A CIDR notation IP range from which to assign service cluster IPs. It must not overlap with any Subnet IP ranges. It can be any private network CIDR such as, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 ')
param serviceCidr string = '10.0.0.0/16'

@description('An IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr')
param dnsServiceIP string = '10.0.0.10'

@description('A CIDR notation IP range from which to assign pod IPs when kubenet is used.')
param podCidr string = '10.244.0.0/16'

@description('A CIDR notation IP range assigned to the Docker bridge network. It must not overlap with any Subnet IP ranges or the Kubernetes service address range.')
param dockerBridgeCidr string = '172.17.0.1/16'


var aksLawsName = 'laws-${name}'


//TODO 1: conditional handling of enableAutoScaling: false
//TODO 2: Check if gpuInstanceProfile is needed
//TODO 3: check enableUltraSSD
//TODO 4: check if osDiskType is needed for forcing ephemeral disks
//TODO 5: check ContainerServiceNetworkProfile.outboundType if needed
resource aks 'Microsoft.ContainerService/managedClusters@2021-03-01' = {
  name: name
  location: region
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enableRBAC: enableRBAC
    dnsPrefix: dnsPrefix
    nodeResourceGroup: nodeResourceGroup
    agentPoolProfiles: [
      {
        name: 'systempool'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        maxPods: maxPods
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
        enableAutoScaling: false
        vnetSubnetID: vnetSubnetID
      }
    ]
    // apiServerAccessProfile:{
    //   enablePrivateCluster:true
    // }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    networkProfile: {
      networkPlugin: 'kubenet'
      loadBalancerSku: 'standard'
      // outboundType: 'loadBalancer'
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      podCidr: podCidr
      dockerBridgeCidr: dockerBridgeCidr
    }
    addonProfiles:{
      omsagent:{
        config:{
          logAnalyticsWorkspaceResourceID: aks_workspace.id
        }
        enabled: true
      }
    }
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


output aksID string = aks.id
//output apiServerAddress string = aks.properties.privateFQDN
output aksNodesRG string = aks.properties.nodeResourceGroup
output identity object = {
  tenantId: aks.identity.tenantId
  principalId: aks.identity.principalId
  type: aks.identity.type
}
