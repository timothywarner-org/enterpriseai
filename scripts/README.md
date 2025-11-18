# Deployment Scripts

This directory contains automated scripts for validating and deploying Bicep templates.

## Scripts Overview

### `validate-bicep.sh`

Validates all Bicep templates for syntax, linting, and best practices.

**Usage:**
```bash
# Validate all templates
./scripts/validate-bicep.sh

# Validate a specific template
./scripts/validate-bicep.sh enterprise_ai_templates/aoai.bicep
```

**What it checks:**
- ✅ Template builds successfully
- ✅ No linting errors
- ✅ Parameters have `@description` decorators
- ✅ Latest API versions
- ✅ Resource tagging
- ✅ Best practices compliance

**Prerequisites:**
- Azure CLI installed
- Bicep CLI installed (auto-installed if missing)
- Logged in to Azure (`az login`)

---

### `deploy-templates.sh`

Deploys Bicep templates to Azure with validation and what-if analysis.

**Usage:**
```bash
./scripts/deploy-templates.sh <environment> <template-name>
```

**Examples:**
```bash
# Deploy complete AI demo to dev environment
./scripts/deploy-templates.sh dev azure-ai-demo

# Deploy monitoring stack to production
./scripts/deploy-templates.sh prod monitoring

# Deploy governance policies to test
./scripts/deploy-templates.sh test governance
```

**Available Templates:**
- `azure-ai-demo` - Complete AI solution (OpenAI + Search + Storage)
- `aoai` - Azure OpenAI with private endpoint
- `ai-search` - Azure AI Search service
- `ai-studio` - Azure AI Studio (Foundry)
- `monitoring` - Monitoring and observability stack
- `governance` - Azure Policy assignments
- `cost-management` - Budgets and cost controls

**Environments:**
- `dev` - Development environment
- `test` - Testing environment
- `prod` - Production environment

**Deployment Flow:**
1. ✅ Check prerequisites
2. ✅ Set environment variables
3. ✅ Create/verify resource group
4. ✅ Build and validate template
5. ✅ Show what-if analysis
6. ✅ Confirm deployment
7. ✅ Deploy template
8. ✅ Show deployment outputs
9. ✅ Optional cleanup (dev only)

**Prerequisites:**
- Azure CLI installed
- Logged in to Azure (`az login`)
- Appropriate permissions on subscription

---

## Quick Start

### 1. Validate All Templates

Before deploying, always validate:

```bash
./scripts/validate-bicep.sh
```

### 2. Deploy to Development

Deploy the complete AI demo to dev:

```bash
./scripts/deploy-templates.sh dev azure-ai-demo
```

### 3. Deploy to Production

For production deployments:

```bash
# 1. Deploy monitoring first
./scripts/deploy-templates.sh prod monitoring

# 2. Deploy governance policies
./scripts/deploy-templates.sh prod governance

# 3. Deploy AI services
./scripts/deploy-templates.sh prod azure-ai-demo

# 4. Set up cost management
./scripts/deploy-templates.sh prod cost-management
```

---

## Troubleshooting

### Issue: "Azure CLI not found"

**Solution:**
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Or on macOS
brew install azure-cli
```

### Issue: "Not logged in to Azure"

**Solution:**
```bash
az login
az account set --subscription "your-subscription-id"
```

### Issue: "Permission denied when running scripts"

**Solution:**
```bash
chmod +x scripts/*.sh
```

### Issue: "Template validation fails"

**Solution:**
Check the specific error message and refer to `BICEP_BEST_PRACTICES.md` for guidance.

---

## CI/CD Integration

These scripts can be integrated into CI/CD pipelines:

### GitHub Actions Example

```yaml
name: Deploy Bicep Templates

on:
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - name: Validate Templates
        run: ./scripts/validate-bicep.sh

  deploy:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - name: Deploy
        run: ./scripts/deploy-templates.sh prod azure-ai-demo
```

---

## Best Practices

1. **Always validate before deploying**
   ```bash
   ./scripts/validate-bicep.sh && ./scripts/deploy-templates.sh dev azure-ai-demo
   ```

2. **Use what-if analysis**
   - The deployment script automatically shows what-if results
   - Review changes before confirming

3. **Tag resources appropriately**
   - All deployments include environment tags
   - Add custom tags via template parameters

4. **Test in dev first**
   - Always test in dev environment before prod
   - Use cleanup option to remove test resources

5. **Monitor deployments**
   - Check Azure Portal deployment history
   - Review deployment outputs
   - Verify resources were created correctly

---

## Additional Resources

- [Azure CLI Documentation](https://learn.microsoft.com/cli/azure/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [BICEP_BEST_PRACTICES.md](../BICEP_BEST_PRACTICES.md)
- [NODE_DEVELOPMENT.md](../NODE_DEVELOPMENT.md)

---

**Happy deploying! 🚀**
