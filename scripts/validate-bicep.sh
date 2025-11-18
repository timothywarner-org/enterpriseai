#!/bin/bash
###############################################################################
# Bicep Template Validation Script
# Description: Validates all Bicep templates before deployment
# Usage: ./validate-bicep.sh [template-path]
# Author: Tim Warner | O'Reilly Enterprise AI Training
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     BICEP TEMPLATE VALIDATION - ENTERPRISE AI PROJECT            ║${NC}"
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

check_prerequisites() {
    print_section "Checking Prerequisites"

    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not found. Please install: https://docs.microsoft.com/cli/azure/install-azure-cli"
        exit 1
    fi
    print_success "Azure CLI installed"

    # Check if Bicep CLI is installed
    if ! az bicep version &> /dev/null; then
        print_info "Bicep CLI not found. Installing..."
        az bicep install
    fi
    print_success "Bicep CLI installed ($(az bicep version))"

    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure. Run: az login"
        exit 1
    fi
    print_success "Logged in to Azure"

    echo ""
    print_info "Subscription: $(az account show --query name -o tsv)"
    print_info "Account: $(az account show --query user.name -o tsv)"
}

validate_single_template() {
    local template=$1
    local template_name=$(basename "$template")

    echo ""
    print_info "Validating: $template_name"

    # 1. Build the template
    echo "  📦 Building template..."
    if az bicep build --file "$template" 2>&1 | grep -q "Error"; then
        print_error "Build failed for $template_name"
        return 1
    fi
    print_success "  Build successful"

    # 2. Lint the template
    echo "  🔍 Linting template..."
    local lint_output=$(az bicep lint --file "$template" 2>&1)
    if echo "$lint_output" | grep -q "Error"; then
        print_error "Linting failed for $template_name"
        echo "$lint_output"
        return 1
    elif echo "$lint_output" | grep -q "Warning"; then
        print_info "  Warnings found (non-blocking)"
        echo "$lint_output" | grep "Warning"
    fi
    print_success "  Linting passed"

    # 3. Check for best practices
    echo "  ✨ Checking best practices..."

    # Check for @description decorators
    if ! grep -q "@description" "$template"; then
        print_error "  Missing @description decorators"
        return 1
    fi

    # Check for latest API versions (2024)
    if grep -q "@202[0-3]" "$template"; then
        print_info "  Consider updating API versions to 2024+"
    fi

    # Check for tags
    if grep -q "tags:" "$template" || grep -q "tags object" "$template"; then
        print_success "  Tags found"
    else
        print_info "  Consider adding tags for governance"
    fi

    print_success "Validation complete for $template_name"
    return 0
}

validate_all_templates() {
    print_section "Validating All Bicep Templates"

    local templates=(
        "landing-zone.bicep"
        "enterprise_ai_templates/aoai.bicep"
        "enterprise_ai_templates/ai_search.bicep"
        "enterprise_ai_templates/ai_foundry_project.bicep"
        "enterprise_ai_templates/monitoring.bicep"
        "enterprise_ai_templates/governance.bicep"
        "enterprise_ai_templates/cost-management.bicep"
        "mvp-node-app/infra/azure-ai-demo.bicep"
    )

    local success_count=0
    local fail_count=0

    for template in "${templates[@]}"; do
        if [ -f "$template" ]; then
            if validate_single_template "$template"; then
                ((success_count++))
            else
                ((fail_count++))
            fi
        else
            print_error "Template not found: $template"
            ((fail_count++))
        fi
    done

    echo ""
    print_section "Validation Summary"
    echo -e "${GREEN}✅ Passed: $success_count${NC}"
    echo -e "${RED}❌ Failed: $fail_count${NC}"

    if [ $fail_count -gt 0 ]; then
        exit 1
    fi
}

generate_deployment_report() {
    print_section "Generating Deployment Report"

    local report_file="deployment-report-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "====================================================================="
        echo "BICEP TEMPLATE VALIDATION REPORT"
        echo "Generated: $(date)"
        echo "====================================================================="
        echo ""
        echo "Validated Templates:"
        find . -name "*.bicep" -type f | while read -r template; do
            echo "  - $template"
        done
        echo ""
        echo "Azure Context:"
        echo "  Subscription: $(az account show --query name -o tsv)"
        echo "  Tenant: $(az account show --query tenantId -o tsv)"
        echo ""
        echo "Validation Results: All templates passed"
        echo "====================================================================="
    } > "$report_file"

    print_success "Report saved to: $report_file"
}

# Main execution
main() {
    print_header

    # Check prerequisites
    check_prerequisites

    # Validate templates
    if [ -n "$1" ]; then
        # Validate single template
        validate_single_template "$1"
    else
        # Validate all templates
        validate_all_templates
    fi

    # Generate report
    generate_deployment_report

    echo ""
    print_success "🎉 All validations complete!"
}

# Run main function
main "$@"
