// Azure AI Search service with private network access
param location string = resourceGroup().location
param searchName string = 'aisearch-<uniqueSuffix>'
param skuName string = 'standard'

resource searchService 'Microsoft.Search/searchServices@2023-07-01-preview' = {
  name: searchName
  location: location
  sku: {
    name: skuName
  }
  properties: {
    publicNetworkAccess: 'Disabled' // require private endpoints only
    hostingMode: 'default'
  }
}
