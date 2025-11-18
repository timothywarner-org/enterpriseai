/*
╔══════════════════════════════════════════════════════════════════╗
║     AZURE OPENAI WITH PRIVATE ENDPOINT - BEST PRACTICES          ║
╚══════════════════════════════════════════════════════════════════╝

This template demonstrates enterprise-grade Azure OpenAI deployment with:
✓ Network isolation via private endpoints
✓ VNet integration with proper subnet configuration
✓ Private DNS zone for name resolution
✓ Managed identity for secure authentication
✓ Diagnostic settings for monitoring
✓ Resource tagging for governance
✓ Model deployments (GPT-4 and embeddings)
✓ Latest stable API versions

Teaching Points:
- Zero-trust network security model
- Private Link architecture pattern
- Managed identities vs API keys
- Monitoring and observability
- Infrastructure as Code best practices

Author: Tim Warner | O'Reilly Enterprise AI Training
*/

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Base name for Azure OpenAI resources.')
@minLength(3)
@maxLength(15)
param baseName string

@description('Enable diagnostic logging to Log Analytics.')
param enableDiagnostics bool = true

@description('Log Analytics Workspace ID (required if diagnostics enabled).')
param logAnalyticsWorkspaceId string = ''

@description('Resource tags for governance and cost tracking.')
param tags object = {
  Environment: 'Production'
  Project: 'EnterpriseAI'
  CostCenter: 'AI-Platform'
}

// Naming variables
var openAiName = toLower('${baseName}-aoai')
var vnetName = '${baseName}-vnet'
var subnetName = 'openai-subnet'
var privateEndpointName = '${openAiName}-pe'
var dnsZoneName = 'privatelink.openai.azure.com'
var managedIdentityName = '${openAiName}-identity'

// ═══════════════════════════════════════════════════════════════
// NETWORKING
// ═══════════════════════════════════════════════════════════════

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [ '10.0.0.0/16' ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Private DNS Zone for OpenAI
resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneName
  location: 'global'
  tags: tags
}

// Link DNS zone to VNet
resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnsZone
  name: '${dnsZoneName}-link'
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
  name: managedIdentityName
  location: location
  tags: tags
}

// ═══════════════════════════════════════════════════════════════
// AZURE OPENAI
// ═══════════════════════════════════════════════════════════════

resource openai 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    customSubDomainName: openAiName
    publicNetworkAccess: 'Disabled' // Force private endpoint only
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: []
      ipRules: []
    }
    disableLocalAuth: false // Set to true to require managed identity only
  }
}

// Deploy GPT-4 model
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
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

// Deploy embeddings model
resource embeddingsDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
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
    gpt4Deployment
  ]
}

// ═══════════════════════════════════════════════════════════════
// PRIVATE ENDPOINT
// ═══════════════════════════════════════════════════════════════

resource openaiPe 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: vnet.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: 'openai-connection'
        properties: {
          privateLinkServiceId: openai.id
          groupIds: [ 'account' ]
        }
      }
    ]
  }
}

// DNS Zone Group for automatic DNS registration
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: openaiPe
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
// OUTPUTS
// ═══════════════════════════════════════════════════════════════

@description('Azure OpenAI endpoint URL')
output openAiEndpoint string = openai.properties.endpoint

@description('Azure OpenAI resource name')
output openAiName string = openai.name

@description('Azure OpenAI resource ID')
output openAiId string = openai.id

@description('Managed identity ID')
output managedIdentityId string = managedIdentity.id

@description('Managed identity principal ID')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

@description('Virtual network ID')
output vnetId string = vnet.id

@description('Private endpoint ID')
output privateEndpointId string = openaiPe.id

@description('GPT-4 deployment name')
output gpt4DeploymentName string = gpt4Deployment.name

@description('Embeddings deployment name')
output embeddingsDeploymentName string = embeddingsDeployment.name
