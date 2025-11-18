# Bicep Best Practices for Enterprise AI Deployment

> **Author:** Tim Warner | **Course:** O'Reilly Enterprise AI Deployment on Azure
> **Last Updated:** 2025-01-18

This guide provides comprehensive best practices for writing production-grade Bicep templates for Azure AI workloads.

## Table of Contents

1. [Template Structure & Organization](#template-structure--organization)
2. [Naming Conventions](#naming-conventions)
3. [Parameter Design](#parameter-design)
4. [Security Best Practices](#security-best-practices)
5. [Networking & Connectivity](#networking--connectivity)
6. [Monitoring & Observability](#monitoring--observability)
7. [Cost Optimization](#cost-optimization)
8. [Testing & Validation](#testing--validation)
9. [CI/CD Integration](#cicd-integration)
10. [Common Patterns](#common-patterns)

---

## Template Structure & Organization

### File Organization

```
project/
├── main.bicep                    # Main orchestration template
├── parameters/
│   ├── dev.bicepparam           # Development parameters
│   ├── prod.bicepparam          # Production parameters
│   └── test.bicepparam          # Test parameters
├── modules/
│   ├── networking/
│   │   ├── vnet.bicep
│   │   ├── private-endpoint.bicep
│   │   └── dns-zone.bicep
│   ├── ai/
│   │   ├── openai.bicep
│   │   ├── ai-search.bicep
│   │   └── ai-studio.bicep
│   ├── security/
│   │   ├── managed-identity.bicep
│   │   ├── key-vault.bicep
│   │   └── rbac.bicep
│   └── monitoring/
│       ├── log-analytics.bicep
│       ├── app-insights.bicep
│       └── alerts.bicep
└── scripts/
    ├── deploy.sh
    ├── validate.sh
    └── teardown.sh
```

### Template Header Documentation

Every Bicep file should start with comprehensive header documentation:

```bicep
/*
╔══════════════════════════════════════════════════════════════════╗
║                    TEMPLATE PURPOSE & SCOPE                      ║
╚══════════════════════════════════════════════════════════════════╝

Description: Brief description of what this template deploys
Version: 1.0.0
Author: Your Name
Last Updated: YYYY-MM-DD

Prerequisites:
  - Prerequisite 1
  - Prerequisite 2

Resources Deployed:
  ✓ Resource type 1
  ✓ Resource type 2

Dependencies:
  - External dependency 1
  - External dependency 2

Teaching Points:
  - Key concept 1
  - Key concept 2
*/
```

### Resource Organization

Group resources logically with section headers:

```bicep
// ═══════════════════════════════════════════════════════════════
// NETWORKING RESOURCES
// ═══════════════════════════════════════════════════════════════

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  // ...
}

// ═══════════════════════════════════════════════════════════════
// COMPUTE RESOURCES
// ═══════════════════════════════════════════════════════════════

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  // ...
}
```

---

## Naming Conventions

### Resource Naming Standards

Follow Microsoft's naming conventions with environment and purpose indicators:

```bicep
// Naming pattern: {workload}-{environment}-{region}-{resource-type}-{instance}
var openAiName = '${baseName}-${environment}-${location}-aoai-001'
var storageAccountName = toLower(replace('${baseName}${environment}stor', '-', ''))
var vnetName = '${baseName}-${environment}-vnet'
```

### Parameter Naming

Use descriptive, self-documenting parameter names:

```bicep
// ✅ GOOD - Clear and descriptive
@description('Base name for all resources (3-10 characters, alphanumeric only).')
@minLength(3)
@maxLength(10)
param baseName string

@description('Environment name (dev, test, prod).')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

// ❌ BAD - Unclear and no constraints
param name string
param env string
```

### Variable Naming

Use camelCase for variables and be descriptive:

```bicep
// ✅ GOOD
var openAiPrivateEndpointName = '${openAiName}-pe'
var storageBlobDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'

// ❌ BAD
var pe = '${name}-pe'
var dns = 'privatelink.blob.core.windows.net'
```

---

## Parameter Design

### Use Decorators for Validation

Always validate parameters with decorators:

```bicep
@description('Azure region for all resources.')
@allowed([
  'eastus'
  'eastus2'
  'westus2'
  'centralus'
])
param location string = 'eastus'

@description('Monthly budget in USD.')
@minValue(100)
@maxValue(100000)
param monthlyBudget int

@description('Email addresses for alerts (comma-separated).')
@minLength(5)
param alertEmails string
```

### Provide Sensible Defaults

Use defaults for optional parameters:

```bicep
@description('Enable diagnostic logging.')
param enableDiagnostics bool = true

@description('Log retention in days.')
@minValue(30)
@maxValue(730)
param logRetentionDays int = 90

@description('Resource tags.')
param tags object = {
  Environment: 'Production'
  ManagedBy: 'Bicep'
  CostCenter: 'AI-Platform'
}
```

### Secure Parameters

Use `@secure()` for sensitive data and document it clearly:

```bicep
@description('Admin password for the resource.')
@secure()
@minLength(12)
param adminPassword string

@description('API key for external service (stored in Key Vault recommended).')
@secure()
param apiKey string
```

**⚠️ Best Practice:** Never use secure parameters directly. Always store secrets in Azure Key Vault and reference them:

```bicep
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'api-key'
  properties: {
    value: apiKey
  }
}
```

---

## Security Best Practices

### 1. Managed Identities (Not API Keys)

Always use managed identities instead of keys:

```bicep
// ✅ GOOD - Managed identity
resource openai 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    disableLocalAuth: true  // Disable API key authentication
    publicNetworkAccess: 'Disabled'
  }
}

// ❌ BAD - Relying on keys
resource openai 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  properties: {
    publicNetworkAccess: 'Enabled'
    // No identity, defaults to API keys
  }
}
```

### 2. Private Endpoints (Zero Trust Networking)

Always deploy with private endpoints for production:

```bicep
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${resourceName}-pe'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'connection'
        properties: {
          privateLinkServiceId: resource.id
          groupIds: [ 'account' ]
        }
      }
    ]
  }
}

// Always include DNS zone group for automatic registration
resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}
```

### 3. Network Access Controls

Implement defense-in-depth with network ACLs:

```bicep
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  properties: {
    allowBlobPublicAccess: false  // ✅ Disable public blob access
    minimumTlsVersion: 'TLS1_2'   // ✅ Enforce TLS 1.2+
    supportsHttpsTrafficOnly: true // ✅ HTTPS only
    publicNetworkAccess: 'Disabled' // ✅ Private endpoint only
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}
```

### 4. RBAC Role Assignments

Use least-privilege role assignments:

```bicep
// Built-in role IDs (never hardcode - use variables)
var cognitiveServicesOpenAIUserRole = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
var storageBlobDataContributorRole = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: openai
  name: guid(openai.id, managedIdentity.id, cognitiveServicesOpenAIUserRole)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesOpenAIUserRole)
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
```

**Common Azure AI RBAC Roles:**

| Role | ID | Use Case |
|------|----| ---------|
| Cognitive Services OpenAI User | `5e0bd9bd-7b93-4f28-af87-19fc36ad61bd` | Application access to OpenAI |
| Cognitive Services OpenAI Contributor | `a001fd3d-188f-4b5d-821b-7da978bf7442` | Deploy models, manage service |
| Storage Blob Data Contributor | `ba92f5b4-2d11-453d-a403-e96b0029c9fe` | AI Search indexing storage |
| Search Index Data Contributor | `8ebe5a00-799e-43f5-93ac-243d3dce84a7` | Write to search indexes |
| Search Service Contributor | `7ca78c08-252a-4471-8644-bb5ff32d4ba0` | Manage search service |

---

## Networking & Connectivity

### Virtual Network Design

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'  // Use RFC 1918 private address space
      ]
    }
    subnets: [
      {
        name: 'ai-services-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'  // Required for private endpoints
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: [
            {
              service: 'Microsoft.CognitiveServices'
            }
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: 'app-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: [
            {
              name: 'webapp-delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}
```

### Private DNS Zones

Always create and link private DNS zones:

```bicep
var privateDnsZones = [
  'privatelink.openai.azure.com'
  'privatelink.search.windows.net'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.vaultcore.azure.net'
]

resource dnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for zone in privateDnsZones: {
  name: zone
  location: 'global'
  tags: tags
}]

resource dnsZoneLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (zone, i) in privateDnsZones: {
  parent: dnsZones[i]
  name: '${zone}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}]
```

---

## Monitoring & Observability

### Diagnostic Settings

Enable diagnostics for all resources:

```bicep
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: openai
  name: 'diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        categoryGroup: 'audit'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 365  // Keep audit logs longer
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
  }
}
```

### Metric Alerts

Create proactive alerts for AI services:

```bicep
resource tokenUsageAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'high-token-usage'
  location: 'global'
  properties: {
    description: 'Alert when token usage exceeds threshold'
    severity: 2
    enabled: true
    scopes: [openai.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'TokenUsage'
          metricName: 'GeneratedTokens'
          operator: 'GreaterThan'
          threshold: 100000
          timeAggregation: 'Total'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}
```

---

## Cost Optimization

### 1. Right-Sizing Resources

```bicep
// Use appropriate SKUs for your workload
@allowed(['S0'])
param openAiSku string = 'S0'  // S0 provides good balance

@allowed(['basic', 'standard', 'standard2'])
param searchSku string = 'standard'  // Start with standard
```

### 2. Resource Lifecycle

Use deployment conditions to save costs:

```bicep
@description('Deploy non-production resources.')
param deployDevResources bool = false

resource devStorage 'Microsoft.Storage/storageAccounts@2023-05-01' = if (deployDevResources) {
  name: '${baseName}devstor'
  // ...
}
```

### 3. Auto-Shutdown Policies

For development environments:

```bicep
resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-compute-vm'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '1900'  // Shutdown at 7 PM
    }
    timeZoneId: 'Eastern Standard Time'
    targetResourceId: vm.id
  }
}
```

### 4. Budget Alerts

Always set up budgets:

```bicep
resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: 'monthly-ai-budget'
  scope: resourceGroup
  properties: {
    category: 'Cost'
    amount: 1000
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: utcNow('yyyy-MM-01')
    }
    notifications: {
      Alert80Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: split(alertEmails, ',')
      }
    }
  }
}
```

---

## Testing & Validation

### Pre-Deployment Validation

```bash
#!/bin/bash
# validate.sh - Pre-deployment validation script

echo "🔍 Validating Bicep template..."

# Build the template
az bicep build --file main.bicep

# Run what-if analysis
az deployment group what-if \
  --resource-group $RG_NAME \
  --template-file main.bicep \
  --parameters @parameters/prod.bicepparam

# Validate the deployment
az deployment group validate \
  --resource-group $RG_NAME \
  --template-file main.bicep \
  --parameters @parameters/prod.bicepparam

echo "✅ Validation complete!"
```

### Linting with Bicep CLI

Enable strict linting:

```bicep
// bicepconfig.json
{
  "analyzers": {
    "core": {
      "enabled": true,
      "verbose": true,
      "rules": {
        "no-unused-params": {
          "level": "error"
        },
        "no-unused-vars": {
          "level": "error"
        },
        "prefer-interpolation": {
          "level": "warning"
        },
        "secure-parameter-default": {
          "level": "error"
        },
        "adminusername-should-not-be-literal": {
          "level": "error"
        }
      }
    }
  }
}
```

### Unit Testing with Pester (PowerShell)

```powershell
# test-bicep.Tests.ps1
Describe "Bicep Template Tests" {
    Context "Template Validation" {
        It "Should build without errors" {
            az bicep build --file main.bicep
            $LASTEXITCODE | Should -Be 0
        }

        It "Should have required parameters" {
            $template = Get-Content main.bicep -Raw
            $template | Should -Match "param baseName"
            $template | Should -Match "param location"
        }
    }
}
```

---

## CI/CD Integration

### GitHub Actions Workflow

```yaml
name: Deploy Bicep Templates

on:
  push:
    branches: [main]
    paths:
      - '**.bicep'
      - '.github/workflows/bicep-deploy.yml'
  pull_request:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Validate Bicep
        run: |
          az bicep build --file main.bicep
          az deployment group validate \
            --resource-group ${{ vars.RESOURCE_GROUP }} \
            --template-file main.bicep \
            --parameters @parameters/prod.bicepparam

  deploy:
    needs: validate
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy Bicep
        run: |
          az deployment group create \
            --resource-group ${{ vars.RESOURCE_GROUP }} \
            --template-file main.bicep \
            --parameters @parameters/prod.bicepparam \
            --mode Incremental
```

---

## Common Patterns

### Pattern: Conditional Private Endpoints

```bicep
@description('Enable private endpoints.')
param enablePrivateEndpoints bool = true

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = if (enablePrivateEndpoints) {
  name: vnetName
  // ...
}

resource openai 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  properties: {
    publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
    networkAcls: enablePrivateEndpoints ? {
      defaultAction: 'Deny'
    } : {
      defaultAction: 'Allow'
    }
  }
}
```

### Pattern: Modular Deployments

```bicep
// main.bicep
module networking './modules/networking/vnet.bicep' = {
  name: 'networking-deployment'
  params: {
    vnetName: vnetName
    location: location
    tags: tags
  }
}

module aiServices './modules/ai/openai.bicep' = {
  name: 'ai-services-deployment'
  params: {
    openAiName: openAiName
    location: location
    subnetId: networking.outputs.subnetId
    tags: tags
  }
  dependsOn: [networking]
}
```

### Pattern: Multi-Region Deployment

```bicep
@description('Regions for multi-region deployment.')
param regions array = [
  'eastus'
  'westus2'
]

resource openai 'Microsoft.CognitiveServices/accounts@2024-10-01' = [for (region, i) in regions: {
  name: '${baseName}-aoai-${region}'
  location: region
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  // ...
}]
```

---

## Additional Resources

- [Microsoft Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Architecture Center](https://learn.microsoft.com/azure/architecture/)
- [Azure OpenAI Best Practices](https://learn.microsoft.com/azure/ai-services/openai/best-practices)
- [Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [Azure AI Landing Zones](https://learn.microsoft.com/azure/cloud-adoption-framework/scenarios/ai/)

---

## Quick Reference Checklist

Before deploying to production, ensure:

- [ ] All parameters have `@description` decorators
- [ ] Sensitive parameters use `@secure()`
- [ ] Resources use latest stable API versions
- [ ] Managed identities are configured (no API keys)
- [ ] Private endpoints are deployed
- [ ] Private DNS zones are linked to VNets
- [ ] Diagnostic settings are enabled
- [ ] Metric alerts are configured
- [ ] RBAC role assignments use least privilege
- [ ] Resources are tagged appropriately
- [ ] Budgets and cost alerts are set up
- [ ] Templates pass `az bicep build` without errors
- [ ] `what-if` analysis reviewed
- [ ] Deployment tested in non-production environment

---

**Happy deploying! 🚀**
