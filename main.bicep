@description('Name of the AKS cluster')
param aksClusterName string = 'myAksCluster'

@description('Location for the AKS cluster')
param location string = resourceGroup().location

@description('Kubernetes version')
param kubernetesVersion string = '1.27.7'

@description('Agent pool VM size')
param agentVMSize string = 'Standard_DS2_v2'

@description('Number of nodes in the default node pool')
param agentCount int = 3


@description('Enable RBAC')
param enableRBAC bool = true

resource aks 'Microsoft.ContainerService/managedClusters@2023-08-01' = {
  name: aksClusterName
  location: location
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: '${aksClusterName}-dns'
    agentPoolProfiles: [
      {
        name: 'nodepool1'
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
      }
    ]
    
    enableRBAC: enableRBAC
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output aksClusterName string = aks.name
