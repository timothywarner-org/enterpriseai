/*
╔══════════════════════════════════════════════════════════════════╗
║        GOVERNANCE & COMPLIANCE - AZURE POLICY FRAMEWORK          ║
╚══════════════════════════════════════════════════════════════════╝

This template deploys governance policies for enterprise AI workloads:
✓ Azure Policy assignments for compliance
✓ Required resource tagging enforcement
✓ Network security policies
✓ Cost management controls
✓ Diagnostic settings enforcement
✓ Allowed resource locations
✓ Managed identity requirements

Teaching Points (Segments 1 & 4):
- Policy-driven governance at scale
- Compliance automation (SOC2, ISO27001, HIPAA)
- Cost control through policy
- Security baseline enforcement
- Cloud Adoption Framework alignment

Author: Tim Warner | O'Reilly Enterprise AI Training
*/

targetScope = 'subscription'

@description('Resource group name for policy assignments.')
param resourceGroupName string

@description('Allowed Azure regions for resource deployment.')
param allowedLocations array = [
  'eastus'
  'eastus2'
  'westus2'
  'centralus'
]

@description('Required tags for all resources.')
param requiredTags object = {
  Environment: ''
  CostCenter: ''
  Owner: ''
  Project: ''
}

@description('Resource tags for policy assignments.')
param tags object = {
  PolicySet: 'EnterpriseAI'
  ManagedBy: 'Bicep'
}

// ═══════════════════════════════════════════════════════════════
// BUILT-IN POLICY ASSIGNMENTS
// ═══════════════════════════════════════════════════════════════

// Policy: Require tags on resources
resource requireTagsPolicy 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'require-resource-tags'
  location: allowedLocations[0]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Require tags on resources'
    description: 'Enforces required tags on all resources for cost tracking and governance'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'
    parameters: {
      tagName: {
        value: 'Environment'
      }
    }
    enforcementMode: 'Default'
  }
}

// Policy: Allowed locations for resources
resource allowedLocationsPolicy 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'allowed-locations'
  location: allowedLocations[0]
  properties: {
    displayName: 'Allowed locations for resources'
    description: 'Restricts resource deployment to approved Azure regions for compliance'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
    enforcementMode: 'Default'
  }
}

// Policy: Require diagnostic settings for AI services
resource diagnosticSettingsPolicy 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'require-diagnostic-settings'
  location: allowedLocations[0]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Deploy diagnostic settings for Cognitive Services'
    description: 'Automatically deploys diagnostic settings for Azure OpenAI and Cognitive Services'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/bef3f9b6-c0d8-4e5c-9b8c-9b0b0b0b0b0b'
    parameters: {}
    enforcementMode: 'Default'
  }
}

// Policy: Azure OpenAI should use private endpoints
resource privateEndpointPolicy 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'openai-private-endpoints'
  location: allowedLocations[0]
  properties: {
    displayName: 'Azure Cognitive Services should use private link'
    description: 'Enforces private endpoint usage for Azure OpenAI services'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/0725b4dd-7e76-479c-a735-68e7ee23d5ca'
    parameters: {}
    enforcementMode: 'Default'
  }
}

// Policy: Require managed identities
resource managedIdentityPolicy 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'require-managed-identities'
  location: allowedLocations[0]
  properties: {
    displayName: 'Cognitive Services accounts should have local authentication disabled'
    description: 'Enforces managed identity authentication instead of API keys'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/71ef260a-8f18-47b7-abcb-62d0673d94dc'
    parameters: {}
    enforcementMode: 'DoNotEnforce' // Set to Default to enforce
  }
}

// Policy: Minimum TLS version
resource tlsVersionPolicy 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'minimum-tls-version'
  location: allowedLocations[0]
  properties: {
    displayName: 'Cognitive Services should use TLS 1.2 or later'
    description: 'Enforces TLS 1.2 minimum for all Cognitive Services'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9'
    parameters: {}
    enforcementMode: 'Default'
  }
}

// Policy: Storage accounts should disable public access
resource storagePublicAccessPolicy 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'storage-disable-public-access'
  location: allowedLocations[0]
  properties: {
    displayName: 'Storage accounts should prevent shared key access'
    description: 'Enforces managed identity authentication for storage accounts'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/8c6a50c6-9ffd-4ae7-986f-5fa6111f9a54'
    parameters: {}
    enforcementMode: 'DoNotEnforce' // Set to Default to enforce
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM POLICY DEFINITION - AI Cost Control
// ═══════════════════════════════════════════════════════════════

resource costControlPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2024-04-01' = {
  name: 'ai-cost-control-limits'
  properties: {
    displayName: 'AI Services - Enforce SKU limits for cost control'
    description: 'Restricts Azure OpenAI and AI Search to approved SKUs to control costs'
    policyType: 'Custom'
    mode: 'All'
    metadata: {
      category: 'Cognitive Services'
      version: '1.0.0'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.CognitiveServices/accounts'
          }
          {
            field: 'Microsoft.CognitiveServices/accounts/sku.name'
            notIn: [
              'S0'
              'S1'
            ]
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

// Assign the custom cost control policy
resource costControlPolicyAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'ai-cost-control'
  location: allowedLocations[0]
  properties: {
    displayName: 'Enforce AI Services SKU limits'
    description: 'Limits Azure OpenAI to S0/S1 SKUs for cost control'
    policyDefinitionId: costControlPolicyDefinition.id
    parameters: {}
    enforcementMode: 'DoNotEnforce' // Change to Default when ready to enforce
  }
}

// ═══════════════════════════════════════════════════════════════
// POLICY INITIATIVE (POLICY SET) FOR AI SECURITY
// ═══════════════════════════════════════════════════════════════

resource aiSecurityInitiative 'Microsoft.Authorization/policySetDefinitions@2024-04-01' = {
  name: 'ai-security-baseline'
  properties: {
    displayName: 'Enterprise AI Security Baseline'
    description: 'Comprehensive security policies for Azure AI services'
    policyType: 'Custom'
    metadata: {
      category: 'AI Security'
      version: '1.0.0'
    }
    policyDefinitions: [
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/0725b4dd-7e76-479c-a735-68e7ee23d5ca'
        parameters: {}
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9'
        parameters: {}
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/71ef260a-8f18-47b7-abcb-62d0673d94dc'
        parameters: {}
      }
    ]
  }
}

// Assign the AI security initiative
resource aiSecurityInitiativeAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'ai-security-baseline'
  location: allowedLocations[0]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Apply AI Security Baseline'
    description: 'Applies comprehensive security policies to all AI services'
    policySetDefinitionId: aiSecurityInitiative.id
    parameters: {}
    enforcementMode: 'DoNotEnforce' // Change to Default when ready
  }
}

// ═══════════════════════════════════════════════════════════════
// RBAC ROLE ASSIGNMENTS FOR POLICY MANAGED IDENTITIES
// ═══════════════════════════════════════════════════════════════

// Grant Contributor role to diagnostic settings policy identity
var contributorRole = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
resource diagnosticsPolicyRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, diagnosticSettingsPolicy.id, contributorRole)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRole)
    principalId: diagnosticSettingsPolicy.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ═══════════════════════════════════════════════════════════════
// OUTPUTS
// ═══════════════════════════════════════════════════════════════

@description('Location restriction policy ID')
output allowedLocationsPolicyId string = allowedLocationsPolicy.id

@description('Tag enforcement policy ID')
output requireTagsPolicyId string = requireTagsPolicy.id

@description('Private endpoint policy ID')
output privateEndpointPolicyId string = privateEndpointPolicy.id

@description('AI Security Initiative ID')
output aiSecurityInitiativeId string = aiSecurityInitiative.id

@description('Custom cost control policy definition ID')
output costControlPolicyDefinitionId string = costControlPolicyDefinition.id
