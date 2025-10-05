@description('Name of the resource group location (for example eastus).')
param location string = resourceGroup().location

@description('Base name used for all resources (letters and numbers only).')
param baseName string

@description('SKU for Azure OpenAI. Only certain SKUs are available per region.')
param openAiSku string = 'S0'

@description('SKU for Azure AI Search.')
param searchSku string = 'standard'

@description('Enable private endpoints for Azure OpenAI and AI Search.')
param enablePrivateEndpoints bool = true

var openAiName = toLower('${baseName}aoai')
var searchName = toLower('${baseName}search')
var storageName = toLower('${baseName}storage')
var vnetName = '${baseName}-vnet'
var subnetName = 'ai-services'

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = if (enablePrivateEndpoints) {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/24'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.20.0.0/27'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: enablePrivateEndpoints ? {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    } : null
  }
}

resource openai 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAiName
  location: location
  sku: {
    name: openAiSku
  }
  kind: 'OpenAI'
  properties: {
    networkAcls: enablePrivateEndpoints ? {
      defaultAction: 'Deny'
      virtualNetworkRules: []
      ipRules: []
    } : null
  }
}

resource search 'Microsoft.Search/searchServices@2023-11-01' = {
  name: searchName
  location: location
  sku: {
    name: searchSku
  }
  properties: {
    hostingMode: 'default'
    networkRuleSet: enablePrivateEndpoints ? {
      ipRules: []
      virtualNetworkRules: []
    } : null
  }
}

resource openaiPe 'Microsoft.Network/privateEndpoints@2023-09-01' = if (enablePrivateEndpoints) {
  name: '${openAiName}-pe'
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: '${openAiName}-connection'
        properties: {
          privateLinkServiceId: openai.id
          groupIds: [ 'account' ]
        }
      }
    ]
  }
}

resource searchPe 'Microsoft.Network/privateEndpoints@2023-09-01' = if (enablePrivateEndpoints) {
  name: '${searchName}-pe'
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: '${searchName}-connection'
        properties: {
          privateLinkServiceId: search.id
          groupIds: [ 'searchService' ]
        }
      }
    ]
  }
}

output openAiEndpoint string = openai.properties.endpoint
output searchEndpoint string = 'https://${searchName}.search.windows.net'
output storageAccountName string = storage.name
