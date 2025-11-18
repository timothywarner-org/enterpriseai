/*
╔══════════════════════════════════════════════════════════════════╗
║          AZURE AI STUDIO (FOUNDRY) - ENTERPRISE SETUP            ║
╚══════════════════════════════════════════════════════════════════╝

This template demonstrates Azure AI Studio (formerly AI Foundry) deployment with:
✓ AI Hub (workspace) for centralized governance
✓ AI Project for team collaboration
✓ Managed identity for secure access
✓ Connections to Azure OpenAI and AI Search
✓ Storage account for artifacts
✓ Key Vault for secrets management
✓ Application Insights for monitoring
✓ Latest stable API versions

Teaching Points:
- Azure AI Studio architecture and resource hierarchy
- Hub and spoke model for AI projects
- Centralized governance and policy enforcement
- Integration with Azure OpenAI and AI Search
- MLOps and AI lifecycle management

Author: Tim Warner | O'Reilly Enterprise AI Training
*/

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Base name for Azure AI Studio resources.')
@minLength(3)
@maxLength(12)
param baseName string

@description('Existing Azure OpenAI resource ID (optional).')
param openAiResourceId string = ''

@description('Existing Azure AI Search resource ID (optional).')
param searchResourceId string = ''

@description('Enable diagnostic logging to Log Analytics.')
param enableDiagnostics bool = true

@description('Log Analytics Workspace ID (required if diagnostics enabled).')
param logAnalyticsWorkspaceId string = ''

@description('Resource tags for governance and cost tracking.')
param tags object = {
  Environment: 'Production'
  Project: 'EnterpriseAI'
  Service: 'AIStudio'
}

// Naming variables
var hubName = toLower('${baseName}-aihub')
var projectName = toLower('${baseName}-aiproject')
var storageName = toLower(replace('${baseName}aist', '-', ''))
var keyVaultName = toLower('${baseName}-kv')
var appInsightsName = '${baseName}-appinsights'
var managedIdentityName = '${baseName}-ai-identity'

// ═══════════════════════════════════════════════════════════════
// SUPPORTING RESOURCES
// ═══════════════════════════════════════════════════════════════

// Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

// Storage Account
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
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Application Insights for monitoring
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: enableDiagnostics && logAnalyticsWorkspaceId != '' ? logAnalyticsWorkspaceId : null
  }
}

// ═══════════════════════════════════════════════════════════════
// AZURE AI STUDIO HUB
// ═══════════════════════════════════════════════════════════════

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: hubName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  kind: 'Hub'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    friendlyName: 'Enterprise AI Hub'
    description: 'Central hub for AI project governance and shared resources'
    storageAccount: storage.id
    keyVault: keyVault.id
    applicationInsights: appInsights.id
    publicNetworkAccess: 'Enabled'
    managedNetwork: {
      isolationMode: 'AllowInternetOutbound'
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// AZURE AI STUDIO PROJECT
// ═══════════════════════════════════════════════════════════════

resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: projectName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  kind: 'Project'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    friendlyName: 'Enterprise AI Project'
    description: 'AI project for building and deploying AI solutions'
    hubResourceId: aiHub.id
    publicNetworkAccess: 'Enabled'
  }
}

// ═══════════════════════════════════════════════════════════════
// CONNECTIONS (if resources provided)
// ═══════════════════════════════════════════════════════════════

// Connection to Azure OpenAI
resource openAiConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-10-01' = if (openAiResourceId != '') {
  parent: aiHub
  name: 'aoai-connection'
  properties: {
    category: 'AzureOpenAI'
    authType: 'AAD'
    isSharedToAll: true
    target: openAiResourceId
    metadata: {
      ApiType: 'Azure'
      ResourceId: openAiResourceId
    }
  }
}

// Connection to Azure AI Search
resource searchConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-10-01' = if (searchResourceId != '') {
  parent: aiHub
  name: 'search-connection'
  properties: {
    category: 'CognitiveSearch'
    authType: 'AAD'
    isSharedToAll: true
    target: searchResourceId
    metadata: {
      ResourceId: searchResourceId
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// RBAC - Grant managed identity access to Key Vault
// ═══════════════════════════════════════════════════════════════

var keyVaultSecretsOfficerRole = 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, managedIdentity.id, keyVaultSecretsOfficerRole)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsOfficerRole)
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ═══════════════════════════════════════════════════════════════
// OUTPUTS
// ═══════════════════════════════════════════════════════════════

@description('Azure AI Hub resource ID')
output aiHubId string = aiHub.id

@description('Azure AI Hub name')
output aiHubName string = aiHub.name

@description('Azure AI Project resource ID')
output aiProjectId string = aiProject.id

@description('Azure AI Project name')
output aiProjectName string = aiProject.name

@description('Storage account name')
output storageAccountName string = storage.name

@description('Key Vault name')
output keyVaultName string = keyVault.name

@description('Application Insights name')
output appInsightsName string = appInsights.name

@description('Managed identity ID')
output managedIdentityId string = managedIdentity.id

@description('Managed identity principal ID')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
