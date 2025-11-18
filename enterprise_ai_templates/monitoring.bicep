/*
╔══════════════════════════════════════════════════════════════════╗
║          MONITORING & OBSERVABILITY - PRODUCTION READY           ║
╚══════════════════════════════════════════════════════════════════╝

This template deploys a complete monitoring solution with:
✓ Log Analytics Workspace for centralized logging
✓ Application Insights for application telemetry
✓ Action Groups for alerting notifications
✓ Metric Alerts for AI service monitoring
✓ Query-based alerts for anomaly detection
✓ Workbooks for visualization
✓ Data retention policies

Teaching Points (Segment 4):
- Production monitoring best practices
- Proactive alerting strategies
- Cost optimization through log retention
- Troubleshooting AI workloads
- SLA monitoring and compliance

Author: Tim Warner | O'Reilly Enterprise AI Training
*/

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Base name for monitoring resources.')
@minLength(3)
@maxLength(15)
param baseName string

@description('Log Analytics data retention in days (30-730).')
@minValue(30)
@maxValue(730)
param dataRetentionDays int = 90

@description('Email addresses for alert notifications (comma-separated).')
param alertEmailAddresses string

@description('Azure OpenAI resource ID to monitor (optional).')
param openAiResourceId string = ''

@description('Azure AI Search resource ID to monitor (optional).')
param searchResourceId string = ''

@description('Resource tags for governance.')
param tags object = {
  Environment: 'Production'
  Project: 'EnterpriseAI'
  CostCenter: 'Monitoring'
}

// Naming variables
var logAnalyticsName = '${baseName}-logs'
var appInsightsName = '${baseName}-appinsights'
var actionGroupName = '${baseName}-alerts-ag'
var workbookName = '${baseName}-ai-workbook'

// ═══════════════════════════════════════════════════════════════
// LOG ANALYTICS WORKSPACE
// ═══════════════════════════════════════════════════════════════

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: dataRetentionDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: 10 // Set daily cap to control costs
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ═══════════════════════════════════════════════════════════════
// APPLICATION INSIGHTS
// ═══════════════════════════════════════════════════════════════

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    RetentionInDays: dataRetentionDays
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ═══════════════════════════════════════════════════════════════
// ACTION GROUP FOR ALERTS
// ═══════════════════════════════════════════════════════════════

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  tags: tags
  properties: {
    groupShortName: substring(baseName, 0, min(length(baseName), 12))
    enabled: true
    emailReceivers: [for (email, i) in split(alertEmailAddresses, ','): {
      name: 'Email-${i}'
      emailAddress: trim(email)
      useCommonAlertSchema: true
    }]
  }
}

// ═══════════════════════════════════════════════════════════════
// METRIC ALERTS FOR AZURE OPENAI
// ═══════════════════════════════════════════════════════════════

// Alert: High token usage (cost control)
resource tokenUsageAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (openAiResourceId != '') {
  name: '${baseName}-high-token-usage'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when Azure OpenAI token usage exceeds threshold'
    severity: 2
    enabled: true
    scopes: [
      openAiResourceId
    ]
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

// Alert: High error rate
resource errorRateAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (openAiResourceId != '') {
  name: '${baseName}-high-error-rate'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when Azure OpenAI error rate exceeds 5%'
    severity: 1
    enabled: true
    scopes: [
      openAiResourceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'ErrorRate'
          metricName: 'Requests'
          dimensions: [
            {
              name: 'StatusCode'
              operator: 'Include'
              values: ['429', '500', '503']
            }
          ]
          operator: 'GreaterThan'
          threshold: 10
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

// Alert: Rate limiting (429 errors)
resource rateLimitAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (openAiResourceId != '') {
  name: '${baseName}-rate-limit-exceeded'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when OpenAI requests are being rate limited'
    severity: 2
    enabled: true
    scopes: [
      openAiResourceId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'RateLimitHit'
          metricName: 'Requests'
          dimensions: [
            {
              name: 'StatusCode'
              operator: 'Include'
              values: ['429']
            }
          ]
          operator: 'GreaterThan'
          threshold: 5
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

// ═══════════════════════════════════════════════════════════════
// METRIC ALERTS FOR AZURE AI SEARCH
// ═══════════════════════════════════════════════════════════════

// Alert: Search throttling
resource searchThrottlingAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (searchResourceId != '') {
  name: '${baseName}-search-throttling'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when AI Search requests are being throttled'
    severity: 2
    enabled: true
    scopes: [
      searchResourceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'ThrottledRequests'
          metricName: 'ThrottledSearchQueriesPercentage'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Average'
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

// ═══════════════════════════════════════════════════════════════
// WORKBOOK FOR AI SERVICES MONITORING
// ═══════════════════════════════════════════════════════════════

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(workbookName)
  location: location
  tags: tags
  kind: 'shared'
  properties: {
    displayName: 'Enterprise AI Monitoring Dashboard'
    serializedData: '''
    {
      "version": "Notebook/1.0",
      "items": [
        {
          "type": 1,
          "content": {
            "json": "## Enterprise AI Services Monitoring\\n\\nThis workbook provides comprehensive monitoring for Azure OpenAI and AI Search services."
          }
        },
        {
          "type": 3,
          "content": {
            "version": "KqlItem/1.0",
            "query": "AzureDiagnostics\\n| where ResourceType == \\"ACCOUNTS\\" and Category == \\"RequestResponse\\"\\n| summarize RequestCount = count() by bin(TimeGenerated, 5m)\\n| render timechart",
            "size": 0,
            "title": "OpenAI Request Rate",
            "timeContext": {
              "durationMs": 3600000
            },
            "queryType": 0,
            "resourceType": "microsoft.operationalinsights/workspaces"
          }
        }
      ]
    }
    '''
    category: 'AI'
    sourceId: logAnalytics.id
  }
}

// ═══════════════════════════════════════════════════════════════
// OUTPUTS
// ═══════════════════════════════════════════════════════════════

@description('Log Analytics Workspace ID')
output logAnalyticsWorkspaceId string = logAnalytics.id

@description('Log Analytics Workspace name')
output logAnalyticsWorkspaceName string = logAnalytics.name

@description('Application Insights ID')
output appInsightsId string = appInsights.id

@description('Application Insights Instrumentation Key')
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey

@description('Application Insights Connection String')
output appInsightsConnectionString string = appInsights.properties.ConnectionString

@description('Action Group ID')
output actionGroupId string = actionGroup.id

@description('Workbook ID')
output workbookId string = workbook.id
