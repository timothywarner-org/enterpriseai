/*
╔══════════════════════════════════════════════════════════════════╗
║       AZURE AI SEARCH - ENTERPRISE CONFIGURATION                 ║
╚══════════════════════════════════════════════════════════════════╝

This template demonstrates enterprise-grade Azure AI Search deployment with:
✓ System-assigned managed identity
✓ Optional private endpoint configuration
✓ Semantic search enabled (free tier)
✓ Diagnostic settings for monitoring
✓ Resource tagging for governance
✓ Network access controls
✓ Latest stable API versions

Teaching Points:
- Vector search capabilities for RAG
- Semantic ranking and hybrid search
- Network isolation options
- Managed identity for secure indexing
- Cost optimization with SKU selection

Author: Tim Warner | O'Reilly Enterprise AI Training
*/

@description('Name of the resource group location (for example eastus).')
param location string = resourceGroup().location

@description('Base name used for all resources (letters and numbers only).')
@minLength(2)
@maxLength(10)
param baseName string

@description('SKU for Azure AI Search.')
@allowed(['basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'])
param searchSku string = 'standard'

@description('Enable private endpoints for Azure AI Search (disables public network access).')
param enablePrivateEndpoints bool = false

@description('Virtual Network ID for private endpoint (required if enablePrivateEndpoints is true).')
param vnetId string = ''

@description('Subnet ID for private endpoint (required if enablePrivateEndpoints is true).')
param subnetId string = ''

@description('Enable diagnostic logging to Log Analytics.')
param enableDiagnostics bool = true

@description('Log Analytics Workspace ID (required if diagnostics enabled).')
param logAnalyticsWorkspaceId string = ''

@description('Resource tags for governance and cost tracking.')
param tags object = {
  Environment: 'Production'
  Project: 'EnterpriseAI'
  Service: 'AISearch'
}

// Use variables for consistent naming
var searchName = toLower('${baseName}search')
var privateEndpointName = '${searchName}-pe'
var dnsZoneName = 'privatelink.search.windows.net'

// ═══════════════════════════════════════════════════════════════
// AZURE AI SEARCH
// ═══════════════════════════════════════════════════════════════

resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' = {
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
      bypass: 'None'
    } : null
    semanticSearch: 'free' // Enable semantic search (free tier)
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    disableLocalAuth: false // Set to true to require managed identity only
  }
}

// ═══════════════════════════════════════════════════════════════
// PRIVATE ENDPOINT (Optional)
// ═══════════════════════════════════════════════════════════════

// Private DNS Zone
resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateEndpoints && vnetId != '') {
  name: dnsZoneName
  location: 'global'
  tags: tags
}

// Link DNS zone to VNet
resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enablePrivateEndpoints && vnetId != '') {
  parent: dnsZone
  name: '${dnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// Private Endpoint
resource searchPe 'Microsoft.Network/privateEndpoints@2024-05-01' = if (enablePrivateEndpoints && subnetId != '') {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${searchName}-connection'
        properties: {
          privateLinkServiceId: searchService.id
          groupIds: [ 'searchService' ]
        }
      }
    ]
  }
}

// DNS Zone Group for automatic DNS registration
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (enablePrivateEndpoints && subnetId != '') {
  parent: searchPe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: dnsZone.id
        }
      }
    ]
  }
}

// ═══════════════════════════════════════════════════════════════
// MONITORING
// ═══════════════════════════════════════════════════════════════

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && logAnalyticsWorkspaceId != '') {
  scope: searchService
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
// OUTPUTS
// ═══════════════════════════════════════════════════════════════

@description('The endpoint URL for the Azure AI Search service.')
output searchEndpoint string = 'https://${searchName}.search.windows.net'

@description('The name of the Azure AI Search service.')
output searchName string = searchService.name

@description('The resource ID of the Azure AI Search service.')
output searchId string = searchService.id

@description('The principal ID of the search service managed identity.')
output searchPrincipalId string = searchService.identity.principalId

@description('Private endpoint ID (if created).')
output privateEndpointId string = enablePrivateEndpoints && subnetId != '' ? searchPe.id : ''
