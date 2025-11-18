#!/bin/bash
###############################################################################
# Bicep Template Deployment Script
# Description: Deploys Bicep templates to Azure with validation
# Usage: ./deploy-templates.sh <environment> <template-name>
# Example: ./deploy-templates.sh dev azure-ai-demo
# Author: Tim Warner | O'Reilly Enterprise AI Training
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Functions
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        BICEP TEMPLATE DEPLOYMENT - ENTERPRISE AI                 ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

usage() {
    echo "Usage: $0 <environment> <template-name>"
    echo ""
    echo "Arguments:"
    echo "  environment   : dev, test, or prod"
    echo "  template-name : Name of the template to deploy"
    echo ""
    echo "Available templates:"
    echo "  - azure-ai-demo      : Complete AI demo (OpenAI + Search + Storage)"
    echo "  - aoai               : Azure OpenAI with private endpoint"
    echo "  - ai-search          : Azure AI Search service"
    echo "  - ai-studio          : Azure AI Studio (Foundry)"
    echo "  - monitoring         : Monitoring and observability stack"
    echo "  - governance         : Azure Policy and governance"
    echo "  - cost-management    : Budgets and cost controls"
    echo ""
    echo "Examples:"
    echo "  $0 dev azure-ai-demo"
    echo "  $0 prod monitoring"
    exit 1
}

check_prerequisites() {
    print_section "Checking Prerequisites"

    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not found"
        exit 1
    fi
    print_success "Azure CLI installed"

    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure. Run: az login"
        exit 1
    fi
    print_success "Logged in to Azure"
}

set_environment_variables() {
    local env=$1

    print_section "Setting Environment Variables"

    case $env in
        dev)
            LOCATION="eastus"
            RG_PREFIX="rg-ai-dev"
            BASE_NAME="aidev"
            ;;
        test)
            LOCATION="eastus"
            RG_PREFIX="rg-ai-test"
            BASE_NAME="aitest"
            ;;
        prod)
            LOCATION="eastus"
            RG_PREFIX="rg-ai-prod"
            BASE_NAME="aiprod"
            ;;
        *)
            print_error "Invalid environment: $env"
            usage
            ;;
    esac

    RESOURCE_GROUP="${RG_PREFIX}-$(date +%Y%m%d)"

    print_info "Environment: $env"
    print_info "Location: $LOCATION"
    print_info "Resource Group: $RESOURCE_GROUP"
    print_info "Base Name: $BASE_NAME"
}

create_resource_group() {
    print_section "Creating Resource Group"

    if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        print_info "Resource group already exists"
    else
        print_info "Creating resource group: $RESOURCE_GROUP"
        az group create \
            --name "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --tags Environment="$ENVIRONMENT" Project="EnterpriseAI" ManagedBy="Bicep"

        print_success "Resource group created"
    fi
}

get_template_path() {
    local template_name=$1

    case $template_name in
        azure-ai-demo)
            echo "$PROJECT_ROOT/mvp-node-app/infra/azure-ai-demo.bicep"
            ;;
        aoai)
            echo "$PROJECT_ROOT/enterprise_ai_templates/aoai.bicep"
            ;;
        ai-search)
            echo "$PROJECT_ROOT/enterprise_ai_templates/ai_search.bicep"
            ;;
        ai-studio)
            echo "$PROJECT_ROOT/enterprise_ai_templates/ai_foundry_project.bicep"
            ;;
        monitoring)
            echo "$PROJECT_ROOT/enterprise_ai_templates/monitoring.bicep"
            ;;
        governance)
            echo "$PROJECT_ROOT/enterprise_ai_templates/governance.bicep"
            ;;
        cost-management)
            echo "$PROJECT_ROOT/enterprise_ai_templates/cost-management.bicep"
            ;;
        *)
            print_error "Unknown template: $template_name"
            usage
            ;;
    esac
}

validate_template() {
    local template_path=$1

    print_section "Validating Template"

    print_info "Building template..."
    az bicep build --file "$template_path"
    print_success "Build successful"

    print_info "Running what-if analysis..."
    az deployment group what-if \
        --resource-group "$RESOURCE_GROUP" \
        --template-file "$template_path" \
        --parameters baseName="$BASE_NAME" location="$LOCATION"

    echo ""
    read -p "Continue with deployment? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled"
        exit 0
    fi
}

deploy_template() {
    local template_path=$1
    local deployment_name="${TEMPLATE_NAME}-$(date +%Y%m%d-%H%M%S)"

    print_section "Deploying Template"

    print_info "Deployment name: $deployment_name"
    print_info "Template: $template_path"

    # Start deployment
    az deployment group create \
        --name "$deployment_name" \
        --resource-group "$RESOURCE_GROUP" \
        --template-file "$template_path" \
        --parameters baseName="$BASE_NAME" location="$LOCATION" \
        --verbose

    print_success "Deployment complete!"
}

show_deployment_outputs() {
    local deployment_name=$1

    print_section "Deployment Outputs"

    az deployment group show \
        --name "$deployment_name" \
        --resource-group "$RESOURCE_GROUP" \
        --query properties.outputs \
        --output json

    print_success "Deployment details retrieved"
}

cleanup() {
    print_section "Cleanup (Optional)"

    read -p "Do you want to delete the resource group after testing? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deleting resource group: $RESOURCE_GROUP"
        az group delete --name "$RESOURCE_GROUP" --yes --no-wait
        print_success "Delete initiated (running in background)"
    else
        print_info "Resource group preserved"
    fi
}

# Main execution
main() {
    print_header

    # Check arguments
    if [ $# -lt 2 ]; then
        usage
    fi

    ENVIRONMENT=$1
    TEMPLATE_NAME=$2

    # Run deployment steps
    check_prerequisites
    set_environment_variables "$ENVIRONMENT"
    create_resource_group

    TEMPLATE_PATH=$(get_template_path "$TEMPLATE_NAME")

    if [ ! -f "$TEMPLATE_PATH" ]; then
        print_error "Template not found: $TEMPLATE_PATH"
        exit 1
    fi

    validate_template "$TEMPLATE_PATH"
    deploy_template "$TEMPLATE_PATH"

    DEPLOYMENT_NAME="${TEMPLATE_NAME}-$(date +%Y%m%d-%H%M%S)"
    show_deployment_outputs "$DEPLOYMENT_NAME"

    # Optional cleanup
    if [ "$ENVIRONMENT" = "dev" ]; then
        cleanup
    fi

    echo ""
    print_success "🎉 Deployment workflow complete!"
    print_info "Resource Group: $RESOURCE_GROUP"
    print_info "Location: $LOCATION"
}

# Run main function
main "$@"
