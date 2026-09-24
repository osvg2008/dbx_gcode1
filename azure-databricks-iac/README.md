# Azure Databricks Infrastructure as Code (Bicep)

## 📋 Overview

This repository contains Infrastructure as Code (IaC) for deploying Azure Databricks workspace and related resources using **Azure Bicep**. The infrastructure is deployed via **GitHub Actions** workflows with support for multiple environments.

## 🏗️ Architecture

The deployment creates the following Azure resources:

* **Databricks Workspace** (Premium tier with VNet injection)
* **Virtual Network** with dedicated subnets for Databricks
* **Storage Account** for DBFS and data lake
* **Log Analytics Workspace** for monitoring
* **Application Insights** for observability
* **Network Security Groups** for network isolation

## 📁 Project Structure

```
azure-databricks-iac/
├── .github/
│   └── workflows/
│       ├── validate.yml      # PR validation workflow
│       ├── deploy.yml         # Deployment workflow
│       └── destroy.yml        # Infrastructure destruction
├── bicep/
│   ├── main.bicep            # Main orchestration template
│   ├── modules/
│   │   ├── networking.bicep  # VNet, subnets, NSG
│   │   ├── storage.bicep     # Storage account setup
│   │   ├── databricks.bicep  # Databricks workspace
│   │   └── monitoring.bicep  # Log Analytics, App Insights
│   └── parameters/
│       ├── parameters.dev.json     # Dev environment
│       ├── parameters.staging.json # Staging environment
│       └── parameters.prod.json    # Production environment
├── scripts/
│   ├── setup.sh              # Development setup script
│   └── validate.sh           # Local validation script
├── docs/
│   └── deployment-guide.md   # Detailed deployment guide
├── bicepconfig.json          # Bicep linter configuration
├── .gitignore
└── README.md
```

## 🚀 Prerequisites

### Required Tools

1. **Azure CLI** (v2.40.0+)
   ```bash
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

2. **Bicep CLI**
   ```bash
   curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
   chmod +x ./bicep
   sudo mv ./bicep /usr/local/bin/bicep
   ```

3. **Bicep Extension for Azure CLI**
   ```bash
   az extension add --name bicep
   az bicep install
   ```

### Azure Requirements

* Azure subscription with appropriate permissions
* Service Principal with Contributor role
* Resource providers registered:
  * Microsoft.Databricks
  * Microsoft.Storage
  * Microsoft.Network
  * Microsoft.OperationalInsights

## ⚙️ Setup

### 1. Clone and Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd azure-databricks-iac

# Run setup script
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 2. Configure Azure Credentials

#### For GitHub Actions:

Create a service principal:

```bash
az ad sp create-for-rbac --name "github-actions-databricks" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth
```

Add the following secrets to your GitHub repository:

* `AZURE_CREDENTIALS` - Full JSON output from above command
* `AZURE_SUBSCRIPTION_ID` - Your Azure subscription ID

#### For Local Development:

```bash
az login
az account set --subscription <subscription-id>
```

### 3. Update Parameters

Edit `bicep/parameters/parameters.dev.json`:

```json
{
  "parameters": {
    "projectName": {
      "value": "myproject"
    },
    "location": {
      "value": "eastus"
    },
    "databricksSku": {
      "value": "premium"
    }
  }
}
```

## 🔧 Local Development

### Validate Bicep Templates

```bash
# Lint and build
bicep build bicep/main.bicep

# Validate against Azure
az deployment sub validate \
  --location eastus \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/parameters.dev.json

# Or use the validation script
./scripts/validate.sh
```

### What-If Analysis

Preview changes before deployment:

```bash
az deployment sub what-if \
  --location eastus \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/parameters.dev.json
```

### Deploy Locally

```bash
az deployment sub create \
  --location eastus \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/parameters.dev.json \
  --name local-deployment
```

## 🚢 Deployment via GitHub Actions

### Automatic Deployments

Pushes to `main` branch automatically trigger deployment to dev environment.

### Manual Deployments

1. Go to **Actions** tab in GitHub
2. Select **Deploy Infrastructure** workflow
3. Click **Run workflow**
4. Select environment (dev/staging/prod)
5. Click **Run workflow** button

### Workflow Features

* **validate.yml**: Runs on PRs, validates Bicep syntax and security
* **deploy.yml**: Deploys infrastructure with what-if analysis
* **destroy.yml**: Safely destroys infrastructure (requires confirmation)

## 📊 Monitoring

After deployment, monitoring is automatically configured:

* **Log Analytics**: Collects Databricks logs (jobs, notebooks, clusters)
* **Application Insights**: Tracks performance metrics
* **Diagnostic Settings**: Enabled for all resources

Access monitoring:

```bash
# Get Log Analytics workspace details
az monitor log-analytics workspace show \
  --resource-group rg-<project>-<env>-<location> \
  --workspace-name log-<project>-<env>
```

## 🔐 Security Best Practices

1. **VNet Injection**: Isolates Databricks in your own VNet
2. **No Public IP**: Disables public IPs on cluster nodes
3. **Private Endpoints**: Optional for storage accounts
4. **NSG Rules**: Controls inbound/outbound traffic
5. **Secure Storage**: HTTPS-only, no public blob access
6. **Diagnostic Logging**: All activities are logged

## 🧪 Bicep Graph Extension

Visualize your deployment:

```bash
# Install extension
az bicep install

# Generate deployment graph
az bicep generate-params --file bicep/main.bicep --output-format json

# Visualize in VS Code with Bicep extension
code bicep/main.bicep
```

## 📝 Customization

### Add New Modules

1. Create module in `bicep/modules/<module-name>.bicep`
2. Reference in `main.bicep`:

```bicep
module myModule 'modules/mymodule.bicep' = {
  scope: rg
  name: 'mymodule-deployment'
  params: {
    // parameters
  }
}
```

### Environment-Specific Configuration

Create new parameter files:

```bash
cp bicep/parameters/parameters.dev.json bicep/parameters/parameters.prod.json
# Edit with production values
```

## 🐛 Troubleshooting

### Common Issues

**Issue**: Bicep validation fails
```bash
# Solution: Check Bicep version
bicep --version
az bicep upgrade
```

**Issue**: Deployment fails with quota limits
```bash
# Solution: Check and request quota increase
az vm list-usage --location eastus -o table
```

**Issue**: VNet injection fails
```bash
# Solution: Ensure subnets are properly delegated
az network vnet subnet update \
  --resource-group <rg> \
  --vnet-name <vnet> \
  --name <subnet> \
  --delegations Microsoft.Databricks/workspaces
```

## 📚 Additional Resources

* [Azure Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
* [Azure Databricks Documentation](https://docs.microsoft.com/azure/databricks/)
* [Bicep GitHub Repository](https://github.com/Azure/bicep)
* [GitHub Actions for Azure](https://github.com/Azure/actions)

## 🤝 Contributing

1. Create a feature branch
2. Make changes
3. Submit PR (triggers validation workflow)
4. After approval, merge to main (triggers deployment)

## 📄 License

This project is licensed under the MIT License.

## 👥 Support

For issues or questions:
* Create an issue in this repository
* Contact the infrastructure team
* Refer to documentation in `docs/` folder
