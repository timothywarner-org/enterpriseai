#!/usr/bin/env bash
#==============================================================================
#  Azure Landing Zone Deployment Script
#==============================================================================
#  File: deploy_all.sh
#  Author: Tim Warner
#  Session: Azure AI Infrastructure Deployment (O’Reilly)
#------------------------------------------------------------------------------
#  PURPOSE:
#  This script deploys a Bicep-based Azure Landing Zone following Cloud
#  Adoption Framework (CAF) principles. It includes rich logging, validation,
#  progress metering, and error handling for repeatable, idempotent runs.
#
#  PHASES OVERVIEW:
#   1. Strategy & Design        – Define hierarchy, guardrails, and policies.
#   2. Bootstrap / Initial Infra – Deploy platform services and governance.
#   3. Subscription Vending     – Automate new app landing zones.
#   4. Workload Deployment      – Deploy workloads (AKS, ACA, etc.).
#   5. Change Management        – Evolve guardrails and monitor drift.
#
#  Reference:
#    https://learn.microsoft.com/azure/cloud-adoption-framework/ready/enterprise-scale/
#==============================================================================

set -euo pipefail

#------------------------------------------------------------------------------
# CONFIGURATION
#------------------------------------------------------------------------------
DEPLOY_NAME="alz-deploy-$(date +%Y%m%d-%H%M%S)"
LOCATION="eastus"
RG_DEPLOY="landingzone-bootstrap"
TEMPLATE_FILE="main.bicep"
PARAMS_FILE="params.json"         # optional; can override below
TENANT_ID="<your-tenant-guid>"
PREFIX="contoso"

#------------------------------------------------------------------------------
# LOGGING SETUP
#------------------------------------------------------------------------------
LOG_FILE="deploy_${DEPLOY_NAME}.log"
exec > >(tee -i "${LOG_FILE}")
exec 2>&1
START_TIME=$(date +%s)
echo "═══════════════════════════════════════════════════════════════════════"
echo "🚀 Starting Azure Landing Zone Deployment: ${DEPLOY_NAME}"
echo "📅 $(date)"
echo "📁 Logging to: ${LOG_FILE}"
echo "═══════════════════════════════════════════════════════════════════════"

#------------------------------------------------------------------------------
# VALIDATION
#------------------------------------------------------------------------------
echo "🔍 Validating Azure CLI context..."
if ! az account show >/dev/null 2>&1; then
  echo "❌ Not logged in to Azure CLI. Run 'az login' first."
  exit 1
fi

echo "🔍 Checking subscription and permissions..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "   Subscription: ${SUBSCRIPTION_ID}"

# Check for Bicep CLI availability
if ! az bicep version >/dev/null 2>&1; then
  echo "❌ Bicep CLI not installed. Run 'az bicep install'."
  exit 1
fi

# Validate Bicep syntax
echo "🧪 Validating Bicep template..."
az bicep build --file "${TEMPLATE_FILE}"

#------------------------------------------------------------------------------
# RESOURCE GROUP
#------------------------------------------------------------------------------
echo "📦 Ensuring resource group '${RG_DEPLOY}' exists..."
az group create --name "${RG_DEPLOY}" --location "${LOCATION}" --query "{name:name,location:location}" -o table

#------------------------------------------------------------------------------
# PRE-DEPLOYMENT DRY RUN
#------------------------------------------------------------------------------
echo "🧭 Running what-if deployment preview..."
# Deployment modes:
#   --mode Incremental   # Only adds or updates resources (default)
#   --mode Complete      # Removes resources not in template (potentially destructive)
az deployment group what-if \
  --resource-group "${RG_DEPLOY}" \
  --template-file "${TEMPLATE_FILE}" \
  --parameters tenantId="${TENANT_ID}" prefix="${PREFIX}" location="${LOCATION}" \
  --no-pretty-print \
  # --mode Incremental   # Uncomment to specify deployment mode
  # --mode Complete      # Uncomment for complete mode (use with caution)
  || true

read -p "Continue with actual deployment? (y/N): " confirm
if [[ "${confirm,,}" != "y" ]]; then
  echo "⚠️  Deployment canceled by user."
  exit 0
fi

#------------------------------------------------------------------------------
# DEPLOYMENT
#------------------------------------------------------------------------------
echo "🚀 Executing deployment..."
if az deployment group create \
  --name "${DEPLOY_NAME}" \
  --resource-group "${RG_DEPLOY}" \
  --template-file "${TEMPLATE_FILE}" \
  --parameters tenantId="${TENANT_ID}" prefix="${PREFIX}" location="${LOCATION}" \
  --output jsonc; then
    echo "✅ Deployment succeeded."
else
    echo "❌ Deployment failed. Check ${LOG_FILE} for details."
    exit 1
fi

#------------------------------------------------------------------------------
# TAGGING & SUMMARY
#------------------------------------------------------------------------------
echo "🏷️  Tagging resource group with metadata..."
az tag create --resource-id "$(az group show -n ${RG_DEPLOY} --query id -o tsv)" \
  --tags deployedBy="$(whoami)" session="oreilly2025" env="demo"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "⏱️  Deployment duration: ${ELAPSED}s"
echo "📜 Deployment log saved to: ${LOG_FILE}"
echo "═══════════════════════════════════════════════════════════════════════"
echo "🎉 Azure Landing Zone deployment complete."
echo "═══════════════════════════════════════════════════════════════════════"
