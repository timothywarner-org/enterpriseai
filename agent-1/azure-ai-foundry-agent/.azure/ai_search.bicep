param aiSearchName string
param resourceGroupName string
param location string
param sku string = 'Standard'
param replicaCount int = 1

resource aiSearch 'Microsoft.Search/searchServices@2020-08-01' = {
  name: aiSearchName
  location: location
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    replicaCount: replicaCount
    partitionCount: 1
    hostingMode: 'Default'
  }
}

output aiSearchEndpoint string = aiSearch.properties.endpoint