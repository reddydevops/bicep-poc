@description('PostgreSQL Server Name')
param serverName string = uniqueString(resourceGroup().id)

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the key vault')
param keyVaultName string = 'bicepkv2'



@description('The name of the key vault secret that contains the admin login')
@secure()
param LoginSecretName string 

// resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
//   scope: resourceGroup(keyVaultResourceGroupName)
//   name: keyVaultName
// }



@description('PostgreSQL Server administrator login password')
@secure()
param administratorLoginPassword string

@description('PostgreSQL version')
@allowed([
  '11'
  '12'
  '13'
  '14'
  '15'
])
param version string = '15'

@description('PostgreSQL SKU')
@allowed([
  'Standard_B1ms'
  'Standard_B2s'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_D8s_v3'
])
param skuName string = 'Standard_B2s'

@description('PostgreSQL Storage Size in MB')
@minValue(32768)
@maxValue(65536)
param storageSizeGB int = 32768


/*
@description('Virtual Network Name')
param virtualNetworkName string

@description('Subnet Name')
param subnetName string


resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: virtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: '${virtualNetworkName}/${subnetName}'
}

// Delegating subnet for PostgreSQL Flexible Server
resource subnetDelegation 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: subnet.properties.addressPrefix
    delegations: [
      {
        name: 'Microsoft.DBforPostgreSQL.flexibleServers'
        properties: {
          serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
        }
      }
    ]
  }
}

// Private DNS Zone for PostgreSQL
resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'private.postgres.database.azure.com'
  location: 'global'
}

// Link the Private DNS Zone to the Virtual Network
resource privateDNSZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDNSZone
  name: uniqueString(vnet.id)
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}
  */

// PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: contains(skuName, 'Standard_B') ? 'Burstable' : 'GeneralPurpose'
  }
  properties: {
    version: version
    administratorLogin: '@Microsoft.KeyVault(SecretUri=${'https://${keyVaultName}.vault.net'}/secrets/${LoginSecretName})'
    administratorLoginPassword: administratorLoginPassword
    storage: {
      storageSizeGB: storageSizeGB
    }
    
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
  
}

// Firewall rule to allow Azure services
resource firewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-12-01' = {
  parent: postgresServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

@description('The PostgreSQL server name.')
output serverName string = postgresServer.name

@description('The PostgreSQL server FQDN.')
output fullyQualifiedDomainName string = postgresServer.properties.fullyQualifiedDomainName
