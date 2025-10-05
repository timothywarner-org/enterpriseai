// Azure OpenAI with private endpoint and VNet integration

param location string = resourceGroup().location
param openAiName string = 'aoai-<uniqueSuffix>'
param vnetName string = 'aoaiVnet'
param subnetName string = 'openaiSubnet'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ '10.0.0.0/16' ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource openai 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAiName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
  properties: {
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          // Associate OpenAI service with the subnet for private access
          subnet: {
            id: vnet.properties.subnets[0].id
          }
        }
      ]
    }
  }
}

// Private endpoint to connect to Azure OpenAI
resource openaiPe 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: '${openAiName}-pe'
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: 'openaiLink'
        properties: {
          privateLinkServiceId: openai.id
          groupIds: [ 'account' ]
          requestMessage: 'Grant access to OpenAI via private endpoint'
        }
      }
    ]
  }
}
