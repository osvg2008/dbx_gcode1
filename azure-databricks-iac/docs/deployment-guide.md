# Deployment Guide

## Quick Start

### 1. Prerequisites Check

Before starting, ensure you have:

- [ ] Azure subscription with Owner or Contributor role
- [ ] Azure CLI installed and logged in
- [ ] Bicep CLI installed (v0.20.0+)
- [ ] GitHub repository created
- [ ] Service Principal created for GitHub Actions

### 2. Initial Setup

#### A. Install Required Tools

```bash
# Run the setup script
./scripts/setup.sh

# Verify installations
az --version
bicep --version
```

#### B. Create Azure Service Principal

```bash
# Replace with your subscription ID
SUBSCRIPTION_ID="your-subscription-id"

# Create service principal
az ad sp create-for-rbac \
  --name "sp-databricks-iac" \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth > azure-credentials.json

# View the output (needed for GitHub secrets)
cat azure-credentials.json
```

⚠️ **Important**: Save this JSON - you'll need it for GitHub secrets!

#### C. Register Resource Providers

```bash
az provider register --namespace Microsoft.Databricks
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.OperationalInsights

# Check registration status
az provider show -n Microsoft.Databricks --query "registrationState"
```

### 3. Configure GitHub Repository

#### A. Add Repository Secrets

Navigate to: **Settings → Secrets and variables → Actions → New repository secret**

Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `AZURE_CREDENTIALS` | Full JSON from service principal creation |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID |

#### B. Configure Environments

Navigate to: **Settings → Environments**

Create three environments:
- `dev` (no protection rules)
- `staging` (require reviewers: 1)
- `prod` (require reviewers: 2)

### 4. Customize Parameters

Edit parameter files for each environment:

```bash
# Development
nano bicep/parameters/parameters.dev.json

# Update:
{
  "parameters": {
    "projectName": {"value": "yourproject"},
    "location": {"value": "eastus"},
    "environment": {"value": "dev"}
  }
}
```

Create staging and prod parameter files:

```bash
cp bicep/parameters/parameters.dev.json bicep/parameters/parameters.staging.json
cp bicep/parameters/parameters.dev.json bicep/parameters/parameters.prod.json

# Edit each file with appropriate values
```

### 5. Validate Locally

```bash
# Validate Bicep syntax
./scripts/validate.sh

# Preview changes (What-If)
az deployment sub what-if \
  --location eastus \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/parameters.dev.json
```

### 6. Deploy

#### Option A: Via GitHub Actions (Recommended)

```bash
# Commit and push
git add .
git commit -m "Initial Bicep infrastructure"
git push origin main

# Deployment will trigger automatically
```

Monitor deployment:
- Go to **Actions** tab
- Click on the running workflow
- View logs and deployment progress

#### Option B: Local Deployment

```bash
az deployment sub create \
  --location eastus \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/parameters.dev.json \
  --name "manual-deployment-$(date +%Y%m%d-%H%M%S)"
```

### 7. Post-Deployment

#### A. Verify Resources

```bash
# List resource groups
az group list --query "[?contains(name, 'dbxproj')].name" -o table

# Check Databricks workspace
RG_NAME="rg-yourproject-dev-eastus"
az databricks workspace list --resource-group $RG_NAME -o table
```

#### B. Access Databricks

```bash
# Get workspace URL
az databricks workspace show \
  --resource-group $RG_NAME \
  --name dbw-yourproject-dev \
  --query "workspaceUrl" -o tsv
```

Visit the URL in your browser and log in with Azure AD.

#### C. Configure Databricks

1. **Create Compute Cluster**:
   - Navigate to Compute
   - Click "Create Cluster"
   - Configure as needed

2. **Set Up Unity Catalog** (Premium tier):
   - Navigate to Data
   - Configure Unity Catalog metastore

3. **Configure Security**:
   - Set up Azure AD groups
   - Assign workspace permissions
   - Configure cluster policies

## Advanced Configurations

### Custom VNet CIDR

Edit `bicep/modules/networking.bicep`:

```bicep
addressSpace: {
  addressPrefixes: [
    '10.10.0.0/16'  // Change to your CIDR
  ]
}
```

### Enable Private Link

Update parameters:

```json
{
  "enablePrivateEndpoints": {"value": true}
}
```

### Add Additional Modules

Create new module in `bicep/modules/`:

```bicep
// bicep/modules/keyvault.bicep
param location string
param projectName string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: 'kv-${projectName}'
  location: location
  properties: {
    sku: { family: 'A', name: 'standard' }
    tenantId: subscription().tenantId
  }
}
```

Reference in `main.bicep`:

```bicep
module keyVault 'modules/keyvault.bicep' = {
  scope: rg
  name: 'keyvault-deployment'
  params: {
    location: location
    projectName: projectName
  }
}
```

## Troubleshooting

### Issue: Deployment Fails with "Quota Exceeded"

**Solution**: Request quota increase

```bash
az vm list-usage --location eastus --query "[?currentValue >= @.limit]" -o table
```

### Issue: VNet Injection Fails

**Cause**: Subnet not properly delegated

**Solution**:
```bash
az network vnet subnet update \
  --resource-group $RG_NAME \
  --vnet-name vnet-yourproject-dev \
  --name public-subnet \
  --delegations Microsoft.Databricks/workspaces
```

### Issue: GitHub Actions Fails Authentication

**Cause**: Service principal expired or incorrect format

**Solution**:
1. Create new service principal
2. Update `AZURE_CREDENTIALS` secret
3. Ensure JSON format is correct (sdk-auth format)

### Issue: Bicep Build Errors

**Solution**: Update Bicep

```bash
az bicep upgrade
bicep --version  # Should be v0.20.0+
```

## Maintenance

### Update Infrastructure

1. Modify Bicep files
2. Create PR (triggers validation)
3. After approval, merge to main
4. GitHub Actions deploys changes automatically

### Backup Strategy

```bash
# Export ARM template
az group export \
  --resource-group $RG_NAME \
  --output-path backup-$(date +%Y%m%d).json
```

### Destroy Infrastructure

⚠️ **Caution**: This permanently deletes all resources!

Via GitHub Actions:
1. Go to **Actions**
2. Select **Destroy Infrastructure**
3. Type `DELETE` to confirm
4. Select environment
5. Run workflow

Via CLI:
```bash
az group delete --name $RG_NAME --yes --no-wait
```

## Best Practices

1. **Always use What-If** before production deployments
2. **Tag resources** appropriately for cost tracking
3. **Enable diagnostic logging** for all resources
4. **Use separate service principals** per environment
5. **Store sensitive parameters** in Azure Key Vault
6. **Review PR validation** results before merging
7. **Test in dev** before promoting to production
8. **Document changes** in commit messages
9. **Use semantic versioning** for releases
10. **Regular security audits** with PSRule

## Next Steps

- [ ] Configure Unity Catalog
- [ ] Set up CI/CD for notebooks/jobs
- [ ] Implement cost monitoring and alerts
- [ ] Configure backup and disaster recovery
- [ ] Set up network security (NSG rules, firewall)
- [ ] Integrate with Azure DevOps or other tools
- [ ] Configure RBAC and access policies
- [ ] Set up monitoring dashboards

## Support Resources

* [Azure Databricks Best Practices](https://docs.microsoft.com/azure/databricks/administration-guide/)
* [Bicep Language Specification](https://github.com/Azure/bicep/blob/main/docs/spec/bicep.md)
* [GitHub Actions Documentation](https://docs.github.com/actions)
* Internal documentation: Check `docs/` folder
