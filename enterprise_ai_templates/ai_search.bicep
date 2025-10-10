// Azure AI Search service with private network access
@description('Name of the resource group location (for example eastus).')
param location string = resourceGroup().location

@description('Base name used for all resources (letters and numbers only).')
param baseName string

@description('SKU for Azure AI Search.')
@allowed(['basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'])
param searchSku string = 'standard'

@description('Enable private endpoints for Azure AI Search (disables public network access).')
param enablePrivateEndpoints bool = true

// Use variables for consistent naming
var searchName = toLower('${baseName}search')

resource searchService 'Microsoft.Search/searchServices@2023-11-01' = {
  name: searchName
  location: location
  sku: {
    name: searchSku
  }
  properties: {
    hostingMode: 'default'
    publicNetworkAccess: enablePrivateEndpoints ? 'disabled' : 'enabled'
    networkRuleSet: enablePrivateEndpoints ? {
      ipRules: []
    } : null
  }
}

@description('The endpoint URL for the Azure AI Search service.')
output searchEndpoint string = 'https://${searchName}.search.windows.net'

@description('The name of the Azure AI Search service.')
output searchName string = searchService.name
