/*
╔══════════════════════════════════════════════════════════════════╗
║         COST MANAGEMENT & FINOPS - AI WORKLOAD BUDGETS           ║
╚══════════════════════════════════════════════════════════════════╝

This template deploys cost management and FinOps controls for AI workloads:
✓ Monthly budget with alerts at 50%, 80%, 100%
✓ Cost anomaly detection alerts
✓ Resource group level cost tracking
✓ Tag-based cost allocation
✓ Email notifications for budget thresholds
✓ Token usage cost optimization recommendations

Teaching Points (Segment 4 - Production Excellence & Cost Control):
- Azure Cost Management for AI workloads
- Token usage optimization strategies
- Budget alerts and forecasting
- FinOps best practices for AI
- Cost allocation and chargeback
- Cost vs performance tradeoffs

Author: Tim Warner | O'Reilly Enterprise AI Training
*/

targetScope = 'subscription'

@description('Resource group name for budget scope.')
param resourceGroupName string

@description('Monthly budget amount in USD.')
@minValue(1)
param monthlyBudgetAmount int = 1000

@description('Email addresses for budget alerts (comma-separated).')
param budgetAlertEmails string

@description('Budget start date (YYYY-MM-DD).')
param budgetStartDate string = utcNow('yyyy-MM-01')

@description('Budget end date (YYYY-MM-DD), leave empty for no end date.')
param budgetEndDate string = ''

@description('Resource tags for cost allocation.')
param tags object = {
  CostCenter: 'AI-Platform'
  Project: 'EnterpriseAI'
  BudgetOwner: ''
}

// Email addresses array
var emailAddresses = split(budgetAlertEmails, ',')

// ═══════════════════════════════════════════════════════════════
// RESOURCE GROUP REFERENCE
// ═══════════════════════════════════════════════════════════════

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' existing = {
  name: resourceGroupName
}

// ═══════════════════════════════════════════════════════════════
// MONTHLY BUDGET WITH MULTI-THRESHOLD ALERTS
// ═══════════════════════════════════════════════════════════════

resource monthlyBudget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: '${resourceGroupName}-monthly-budget'
  scope: resourceGroup
  properties: {
    category: 'Cost'
    amount: monthlyBudgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
      endDate: budgetEndDate != '' ? budgetEndDate : null
    }
    filter: {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: [
          resourceGroupName
        ]
      }
    }
    notifications: {
      // Alert at 50% of budget
      Alert50Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        contactEmails: [for email in emailAddresses: trim(email)]
        contactRoles: [
          'Owner'
          'Contributor'
        ]
        thresholdType: 'Actual'
      }
      // Alert at 80% of budget
      Alert80Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [for email in emailAddresses: trim(email)]
        contactRoles: [
          'Owner'
          'Contributor'
        ]
        thresholdType: 'Actual'
      }
      // Alert at 90% of budget (forecasted)
      ForecastAlert90Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 90
        contactEmails: [for email in emailAddresses: trim(email)]
        contactRoles: [
          'Owner'
          'Contributor'
        ]
        thresholdType: 'Forecasted'
      }
      // Alert at 100% of budget
      Alert100Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: [for email in emailAddresses: trim(email)]
        contactRoles: [
          'Owner'
          'Contributor'
        ]
        thresholdType: 'Actual'
      }
      // Alert at 110% (overspend)
      Alert110Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 110
        contactEmails: [for email in emailAddresses: trim(email)]
        contactRoles: [
          'Owner'
          'Contributor'
        ]
        thresholdType: 'Actual'
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// QUARTERLY BUDGET (FOR LONGER-TERM PLANNING)
// ═══════════════════════════════════════════════════════════════

resource quarterlyBudget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: '${resourceGroupName}-quarterly-budget'
  scope: resourceGroup
  properties: {
    category: 'Cost'
    amount: monthlyBudgetAmount * 3
    timeGrain: 'Quarterly'
    timePeriod: {
      startDate: budgetStartDate
      endDate: budgetEndDate != '' ? budgetEndDate : null
    }
    filter: {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: [
          resourceGroupName
        ]
      }
    }
    notifications: {
      Alert80Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [for email in emailAddresses: trim(email)]
        contactRoles: [
          'Owner'
        ]
        thresholdType: 'Actual'
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// AI SERVICES SPECIFIC BUDGET (OPENAI + SEARCH)
// ═══════════════════════════════════════════════════════════════

resource aiServicesBudget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: '${resourceGroupName}-ai-services-budget'
  scope: resourceGroup
  properties: {
    category: 'Cost'
    amount: monthlyBudgetAmount * 0.7 // 70% of total budget allocated to AI services
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
      endDate: budgetEndDate != '' ? budgetEndDate : null
    }
    filter: {
      and: [
        {
          dimensions: {
            name: 'ResourceGroupName'
            operator: 'In'
            values: [
              resourceGroupName
            ]
          }
        }
        {
          dimensions: {
            name: 'ServiceName'
            operator: 'In'
            values: [
              'Cognitive Services'
              'Azure AI Search'
            ]
          }
        }
      ]
    }
    notifications: {
      Alert75Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 75
        contactEmails: [for email in emailAddresses: trim(email)]
        contactRoles: [
          'Owner'
          'Contributor'
        ]
        thresholdType: 'Actual'
      }
      Alert90Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 90
        contactEmails: [for email in emailAddresses: trim(email)]
        contactRoles: [
          'Owner'
          'Contributor'
        ]
        thresholdType: 'Actual'
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// TAG-BASED BUDGET (FOR COST ALLOCATION)
// ═══════════════════════════════════════════════════════════════

resource projectBudget 'Microsoft.Consumption/budgets@2023-11-01' = if (tags.Project != '') {
  name: '${resourceGroupName}-${tags.Project}-budget'
  scope: resourceGroup
  properties: {
    category: 'Cost'
    amount: monthlyBudgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
    }
    filter: {
      and: [
        {
          dimensions: {
            name: 'ResourceGroupName'
            operator: 'In'
            values: [
              resourceGroupName
            ]
          }
        }
        {
          tags: {
            name: 'Project'
            operator: 'In'
            values: [
              tags.Project
            ]
          }
        }
      ]
    }
    notifications: {
      Alert80Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [for email in emailAddresses: trim(email)]
        thresholdType: 'Actual'
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// OUTPUTS - COST OPTIMIZATION GUIDANCE
// ═══════════════════════════════════════════════════════════════

@description('Monthly budget ID')
output monthlyBudgetId string = monthlyBudget.id

@description('Monthly budget name')
output monthlyBudgetName string = monthlyBudget.name

@description('AI services budget ID')
output aiServicesBudgetId string = aiServicesBudget.id

@description('Quarterly budget ID')
output quarterlyBudgetId string = quarterlyBudget.id

@description('Cost optimization tips')
output costOptimizationTips array = [
  'Use GPT-3.5-turbo for simple tasks instead of GPT-4 (10x cheaper)'
  'Implement token usage monitoring and set per-user limits'
  'Cache common queries to reduce API calls'
  'Use semantic caching for similar prompts'
  'Optimize prompt engineering to reduce token consumption'
  'Set up provisioned throughput for predictable costs (PTU)'
  'Use Azure Reserved Instances for stable workloads'
  'Implement request throttling to prevent cost spikes'
  'Monitor and alert on anomalous token usage patterns'
  'Use Azure AI Search semantic ranking selectively (costs extra)'
]

@description('FinOps best practices for AI')
output finOpsBestPractices array = [
  'Tag all resources with CostCenter, Project, and Owner tags'
  'Set up cost allocation reports by project/department'
  'Review Azure Cost Management recommendations weekly'
  'Implement chargeback/showback for AI service consumption'
  'Use Azure Cost Management Power BI connector for reporting'
  'Establish clear token budgets per application/user'
  'Monitor cost per request and cost per user metrics'
  'Implement automated cost anomaly detection'
  'Review and optimize model selection regularly'
  'Set up regular FinOps review meetings with stakeholders'
]
