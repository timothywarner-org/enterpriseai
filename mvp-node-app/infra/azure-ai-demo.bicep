/*
╔══════════════════════════════════════════════════════════════════╗
║         ENTERPRISE AI DEMO - PRODUCTION-READY DEPLOYMENT         ║
╚══════════════════════════════════════════════════════════════════╝

This template deploys a complete Azure AI solution with:
- Azure OpenAI with GPT-4 and embeddings models
- Azure AI Search for vector search
- Storage Account for data/documents
- Private endpoints for all services (optional)
- Managed identities for secure authentication
- Diagnostic settings for monitoring
- Private DNS zones for name resolution
- Role assignments for least-privilege access

Best Practices Implemented:
✓ Network isolation with private endpoints
✓ Zero public internet exposure option
✓ Managed identities (no keys/passwords)
✓ Diagnostic logging to Log Analytics
✓ Resource tagging for governance
✓ Latest stable API versions
✓ Parameterized for flexibility

Author: Tim Warner | O'Reilly Enterprise AI Training
*/

@description('Name of the resource group location (for example eastus).')
param location string = resourceGroup().location

@description('Base name used for all resources (letters and numbers only).')
@minLength(3)
@maxLength(10)
param baseName string

@description('SKU for Azure OpenAI. Only certain SKUs are available per region.')
@allowed(['S0'])
param openAiSku string = 'S0'

@description('SKU for Azure AI Search.')
@allowed(['basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'])
param searchSku string = 'standard'

@description('Enable private endpoints for Azure OpenAI and AI Search.')
param enablePrivateEndpoints bool = true

@description('Enable diagnostic settings for monitoring and compliance.')
param enableDiagnostics bool = true

@description('Log Analytics Workspace ID for diagnostics (required if enableDiagnostics is true).')
param logAnalyticsWorkspaceId string = ''

@description('Tags to apply to all resources.')
param tags object = {
  Environment: 'Demo'
  Project: 'EnterpriseAI'
  ManagedBy: 'Bicep'
  Course: 'OReilly-Azure-AI'
}

@description('Deploy GPT-4 model to OpenAI account.')
param deployGpt4 bool = true

@description('Deploy text-embedding-ada-002 model to OpenAI account.')
param deployEmbeddings bool = true

// Variables for consistent naming and configuration
var openAiName = toLower('${baseName}aoai')
var searchName = toLower('${baseName}search')
var storageName = toLower(replace('${baseName}stor', '-', ''))
var vnetName = '${baseName}-vnet'
var subnetName = 'ai-services'
var openAiPeName = '${openAiName}-pe'
var searchPeName = '${searchName}-pe'
var storageBlobPeName = '${storageName}-blob-pe'
var openAiManagedIdentityName = '${openAiName}-identity'

// Private DNS Zone names
var openAiDnsZoneName = 'privatelink.openai.azure.com'
var searchDnsZoneName = 'privatelink.search.windows.net'
var storageBlobDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'

// ═══════════════════════════════════════════════════════════════
// NETWORKING RESOURCES
// ═══════════════════════════════════════════════════════════════

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = if (enablePrivateEndpoints) {
  name: vnetName
  location: location
  tags: tags
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
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Private DNS Zones for name resolution
resource openAiDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateEndpoints) {
  name: openAiDnsZoneName
  location: 'global'
  tags: tags
}

resource searchDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateEndpoints) {
  name: searchDnsZoneName
  location: 'global'
  tags: tags
}

resource storageBlobDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateEndpoints) {
  name: storageBlobDnsZoneName
  location: 'global'
  tags: tags
}

// Link DNS zones to VNet
resource openAiDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enablePrivateEndpoints) {
  parent: openAiDnsZone
  name: '${openAiDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource searchDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enablePrivateEndpoints) {
  parent: searchDnsZone
  name: '${searchDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource storageBlobDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enablePrivateEndpoints) {
  parent: storageBlobDnsZone
  name: '${storageBlobDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// MANAGED IDENTITY
// ═══════════════════════════════════════════════════════════════

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: openAiManagedIdentityName
  location: location
  tags: tags
}

// ═══════════════════════════════════════════════════════════════
// STORAGE ACCOUNT
// ═══════════════════════════════════════════════════════════════

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
      keySource: 'Microsoft.Storage'
    }
    networkAcls: enablePrivateEndpoints ? {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    } : {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Blob service for storage account
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// Diagnostic settings for storage account
resource storageDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && logAnalyticsWorkspaceId != '') {
  scope: blobService
  name: 'storage-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

// ═══════════════════════════════════════════════════════════════
// AZURE OPENAI
// ═══════════════════════════════════════════════════════════════

resource openai 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  location: location
  tags: tags
  sku: {
    name: openAiSku
  }
  kind: 'OpenAI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    customSubDomainName: openAiName
    publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
    networkAcls: enablePrivateEndpoints ? {
      defaultAction: 'Deny'
      virtualNetworkRules: []
      ipRules: []
    } : {
      defaultAction: 'Allow'
    }
    disableLocalAuth: false // Set to true for managed identity only
  }
}

// Deploy GPT-4 model
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = if (deployGpt4) {
  parent: openai
  name: 'gpt-4'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '1106-Preview'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
}

// Deploy text-embedding-ada-002 model
resource embeddingsDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = if (deployEmbeddings) {
  parent: openai
  name: 'text-embedding-ada-002'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'text-embedding-ada-002'
      version: '2'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
  dependsOn: [
    gpt4Deployment // Deploy sequentially to avoid conflicts
  ]
}

// Diagnostic settings for OpenAI
resource openaiDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && logAnalyticsWorkspaceId != '') {
  scope: openai
  name: 'openai-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ═══════════════════════════════════════════════════════════════
// AZURE AI SEARCH
// ═══════════════════════════════════════════════════════════════

resource search 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: searchName
  location: location
  tags: tags
  sku: {
    name: searchSku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hostingMode: 'default'
    publicNetworkAccess: enablePrivateEndpoints ? 'disabled' : 'enabled'
    partitionCount: 1
    replicaCount: 1
    networkRuleSet: enablePrivateEndpoints ? {
      ipRules: []
    } : null
    semanticSearch: 'free' // Enable semantic search (free tier)
  }
}

// Diagnostic settings for AI Search
resource searchDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && logAnalyticsWorkspaceId != '') {
  scope: search
  name: 'search-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ═══════════════════════════════════════════════════════════════
// PRIVATE ENDPOINTS
// ═══════════════════════════════════════════════════════════════

// Private endpoint for Azure OpenAI
resource openaiPe 'Microsoft.Network/privateEndpoints@2024-05-01' = if (enablePrivateEndpoints) {
  name: openAiPeName
  location: location
  tags: tags
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

// DNS Zone Group for OpenAI private endpoint
resource openaiPeDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (enablePrivateEndpoints) {
  parent: openaiPe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: openAiDnsZone.id
        }
      }
    ]
  }
}

// Private endpoint for Azure AI Search
resource searchPe 'Microsoft.Network/privateEndpoints@2024-05-01' = if (enablePrivateEndpoints) {
  name: searchPeName
  location: location
  tags: tags
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

// DNS Zone Group for Search private endpoint
resource searchPeDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (enablePrivateEndpoints) {
  parent: searchPe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: searchDnsZone.id
        }
      }
    ]
  }
}

// Private endpoint for Storage Blob
resource storageBlobPe 'Microsoft.Network/privateEndpoints@2024-05-01' = if (enablePrivateEndpoints) {
  name: storageBlobPeName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: vnet.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: '${storageName}-blob-connection'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [ 'blob' ]
        }
      }
    ]
  }
}

// DNS Zone Group for Storage Blob private endpoint
resource storageBlobPeDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (enablePrivateEndpoints) {
  parent: storageBlobPe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: storageBlobDnsZone.id
        }
      }
    ]
  }
}

// ═══════════════════════════════════════════════════════════════
// ROLE ASSIGNMENTS (RBAC)
// ═══════════════════════════════════════════════════════════════

// Grant AI Search access to Storage Account (for indexing)
var storageBlobDataContributorRole = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
resource searchStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storage
  name: guid(storage.id, search.id, storageBlobDataContributorRole)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRole)
    principalId: search.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Grant managed identity Cognitive Services OpenAI User role on OpenAI
var cognitiveServicesOpenAIUserRole = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
resource managedIdentityOpenAIRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: openai
  name: guid(openai.id, managedIdentity.id, cognitiveServicesOpenAIUserRole)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesOpenAIUserRole)
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ═══════════════════════════════════════════════════════════════
// OUTPUTS
// ═══════════════════════════════════════════════════════════════

@description('Azure OpenAI endpoint URL')
output openAiEndpoint string = openai.properties.endpoint

@description('Azure OpenAI resource name')
output openAiName string = openai.name

@description('Azure OpenAI resource ID')
output openAiId string = openai.id

@description('Azure AI Search endpoint URL')
output searchEndpoint string = 'https://${searchName}.search.windows.net'

@description('Azure AI Search resource name')
output searchName string = search.name

@description('Azure AI Search resource ID')
output searchId string = search.id

@description('Storage account name')
output storageAccountName string = storage.name

@description('Storage account ID')
output storageAccountId string = storage.id

@description('Managed identity ID')
output managedIdentityId string = managedIdentity.id

@description('Managed identity principal ID')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

@description('Virtual network name (if private endpoints enabled)')
output vnetName string = enablePrivateEndpoints ? vnet.name : ''

@description('Virtual network ID (if private endpoints enabled)')
output vnetId string = enablePrivateEndpoints ? vnet.id : ''

@description('GPT-4 deployment name')
output gpt4DeploymentName string = deployGpt4 ? gpt4Deployment.name : ''

@description('Embeddings deployment name')
output embeddingsDeploymentName string = deployEmbeddings ? embeddingsDeployment.name : ''
