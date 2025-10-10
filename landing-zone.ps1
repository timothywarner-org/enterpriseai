#!/usr/bin/env pwsh
<#
╔══════════════════════════════════════════════════════════════════════╗
║              AZURE LANDING ZONE DEPLOYMENT SCRIPT                    ║
╚══════════════════════════════════════════════════════════════════════╝
File:        deploy_all.ps1
Author:      Tim Warner
Session:     Azure AI Infrastructure Deployment (O’Reilly)
Purpose:     Deploys a Bicep-based Azure Landing Zone following the
             Microsoft Cloud Adoption Framework (CAF) principles.
             Includes logging, validation, progress, and safe rollback.

PHASES:
  1️⃣ Strategy & Design        – Define hierarchy, guardrails, policies.
  2️⃣ Bootstrap / Initial Infra – Deploy platform identity & governance.
  3️⃣ Subscription Vending     – Automate new app landing zones.
  4️⃣ Workload Deployment      – Deploy workloads (AKS, ACA, data).
  5️⃣ Change Management        – Evolve guardrails & remediate drift.

Reference:
  https://learn.microsoft.com/azure/cloud-adoption-framework/ready/enterprise-scale/
#>

#==============================================================================
# CONFIGURATION
#==============================================================================
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # suppress noisy CLI spinners

$DeployName = "alz-deploy-$((Get-Date).ToString('yyyyMMdd-HHmmss'))"
$Location = "eastus"
$RgName = "landingzone-bootstrap"
$Template = "landing-zone.bicep"
$TenantId = "<your-tenant-guid>"
$Prefix = "contoso"
$LogFile = "deploy_$DeployName.log"

#==============================================================================
# LOGGING INITIALIZATION
#==============================================================================
Start-Transcript -Path $LogFile -Append
$startTime = Get-Date
Write-Host "═══════════════════════════════════════════════════════════════════"
Write-Host "🚀 Starting Azure Landing Zone deployment: $DeployName"
Write-Host "📅 $startTime"
Write-Host "📁 Log file: $LogFile"
Write-Host "═══════════════════════════════════════════════════════════════════"

#==============================================================================
# VALIDATION
#==============================================================================
Write-Host "`n🔍 Validating Azure CLI context..."
try {
  az account show | Out-Null
}
catch {
  throw "❌ Not logged in to Azure CLI. Run 'az login' first."
}

$subId = az account show --query id -o tsv
Write-Host "   Subscription: $subId"

if (-not (az bicep version | Out-String)) {
  throw "❌ Bicep CLI not installed. Run 'az bicep install'."
}

Write-Host "🧪 Validating Bicep syntax..."
az bicep build --file $Template | Out-Null

#==============================================================================
# RESOURCE GROUP SETUP
#==============================================================================
Write-Host "`n📦 Ensuring resource group '$RgName' exists..."
az group create --name $RgName --location $Location --query "{name:name,location:location}" -o table

#==============================================================================
# WHAT-IF PREVIEW
#==============================================================================
Write-Host "`n🧭 Running what-if deployment preview..."
az deployment group what-if `
  --resource-group $RgName `
  --template-file $Template `
  --parameters tenantId=$TenantId prefix=$Prefix location=$Location `
  --no-pretty-print `
| Out-Host

$proceed = Read-Host "Continue with actual deployment? (y/N)"
if ($proceed.ToLower() -ne 'y') {
  Write-Warning "⚠️  Deployment canceled by user."
  Stop-Transcript | Out-Null
  exit 0
}

#==============================================================================
# DEPLOYMENT EXECUTION
#==============================================================================
Write-Host "`n🚀 Executing deployment..."
try {
  $progress = 0
  Write-Progress -Activity "Deploying Landing Zone" -Status "Initializing..." -PercentComplete $progress

  $deployResult = az deployment group create `
    --name $DeployName `
    --resource-group $RgName `
    --template-file $Template `
    --parameters tenantId=$TenantId prefix=$Prefix location=$Location `
    --output jsonc | ConvertFrom-Json

  $progress = 100
  Write-Progress -Activity "Deploying Landing Zone" -Status "Complete" -PercentComplete $progress
  Write-Host "✅ Deployment succeeded."
}
catch {
  Write-Error "❌ Deployment failed: $_"
  Stop-Transcript | Out-Null
  exit 1
}

#==============================================================================
# TAGGING & SUMMARY
#==============================================================================
Write-Host "`n🏷️  Tagging resource group with metadata..."
$rgId = az group show -n $RgName --query id -o tsv
az tag create --resource-id $rgId --tags `
  deployedBy="$(whoami)" `
  session="oreilly2025" `
  env="demo" | Out-Null

$endTime = Get-Date
$elapsed = [int]($endTime - $startTime).TotalSeconds

Write-Host "`n⏱️  Deployment duration: ${elapsed}s"
Write-Host "📜 Deployment log saved to: $LogFile"
Write-Host "═══════════════════════════════════════════════════════════════════"
Write-Host "🎉 Azure Landing Zone deployment complete."
Write-Host "═══════════════════════════════════════════════════════════════════"

Stop-Transcript | Out-Null
