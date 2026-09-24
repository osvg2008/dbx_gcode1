# 🚀 Quick Start Guide

Get your Azure Databricks infrastructure up and running in 15 minutes!

## Prerequisites Checklist

- [ ] Azure subscription
- [ ] GitHub account
- [ ] Basic understanding of Azure and Databricks

## 5-Minute Setup

### 1️⃣ Install Tools (2 minutes)

```bash
# Run the automated setup
./scripts/setup.sh

# Login to Azure
az login
az account set --subscription <your-subscription-id>
```

### 2️⃣ Configure GitHub (3 minutes)

```bash
# Create service principal
az ad sp create-for-rbac --name "github-databricks" \
  --role contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth
```

**Add to GitHub Secrets:**
* Go to your repo → Settings → Secrets → Actions
* Add `AZURE_CREDENTIALS` (entire JSON output)
* Add `AZURE_SUBSCRIPTION_ID` (your subscription ID)

### 3️⃣ Customize Parameters (5 minutes)

Edit `bicep/parameters/parameters.dev.json`:

```json
{
  "parameters": {
    "projectName": {"value": "mydbx"},
    "location": {"value": "eastus"}
  }
}
```

### 4️⃣ Deploy (5 minutes)

```bash
# Validate first
./scripts/validate.sh

# Deploy
git add .
git commit -m "Deploy Databricks infrastructure"
git push origin main
```

Watch deployment in GitHub Actions tab! 🎉

## What Gets Deployed?

* ✅ Databricks Premium Workspace
* ✅ Virtual Network with VNet injection
* ✅ Storage Account for DBFS
* ✅ Log Analytics for monitoring
* ✅ All networking and security components

## Access Your Workspace

After deployment completes:

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to Resource Groups → `rg-mydbx-dev-eastus`
3. Click on Databricks workspace
4. Click "Launch Workspace"
5. Start building! 🎉

## Next Steps

* Create a compute cluster
* Upload notebooks
* Configure Unity Catalog (Premium)
* Set up CI/CD for notebooks
* Explore monitoring dashboards

## Need Help?

* 📖 Read [README.md](README.md) for detailed documentation
* 📚 Check [docs/deployment-guide.md](docs/deployment-guide.md) for advanced scenarios
* 🐛 Open an issue in this repository

---

**Congratulations!** Your Azure Databricks infrastructure is ready! 🎊
