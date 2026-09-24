# Architecture Overview

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │           Resource Group (rg-project-env-region)        │ │
│  │                                                         │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │        Virtual Network (10.0.0.0/16)             │  │ │
│  │  │                                                   │  │ │
│  │  │  ┌────────────────────┐  ┌──────────────────┐  │  │ │
│  │  │  │  Public Subnet     │  │ Private Subnet   │  │  │ │
│  │  │  │  (10.0.1.0/24)     │  │ (10.0.2.0/24)    │  │  │ │
│  │  │  │  Delegated to      │  │ Delegated to     │  │  │ │
│  │  │  │  Databricks        │  │ Databricks       │  │  │ │
│  │  │  └────────────────────┘  └──────────────────┘  │  │ │
│  │  │                                                   │  │ │
│  │  │  ┌─────────────────────────────────────────┐    │  │ │
│  │  │  │  Private Endpoint Subnet (10.0.3.0/24)  │    │  │ │
│  │  │  └─────────────────────────────────────────┘    │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  │                                                         │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │     Databricks Workspace (Premium)               │  │ │
│  │  │     - VNet Injection Enabled                     │  │ │
│  │  │     - No Public IP                               │  │ │
│  │  │     - Unity Catalog Ready                        │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  │                                                         │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │     Storage Account                              │  │ │
│  │  │     - DBFS Root                                  │  │ │
│  │  │     - Data Lake Gen2                             │  │ │
│  │  │     - Private Endpoint (optional)                │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  │                                                         │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │     Monitoring                                   │  │ │
│  │  │     - Log Analytics Workspace                    │  │ │
│  │  │     - Application Insights                       │  │ │
│  │  │     - Diagnostic Settings                        │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  │                                                         │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘

        ▲                                    ▲
        │                                    │
        │ GitHub Actions                     │ Azure AD
        │ (CI/CD)                           │ (Authentication)
        │                                    │
```

## Component Details

### Databricks Workspace
* **SKU**: Premium (configurable to Standard)
* **Features**: 
  * VNet injection for network isolation
  * No public IPs on cluster nodes
  * Unity Catalog support
  * SCIM provisioning ready

### Networking
* **VNet**: /16 CIDR block
* **Public Subnet**: For Databricks control plane communication
* **Private Subnet**: For Databricks data plane
* **NSG**: Applied to both subnets with required rules
* **Private Endpoints**: Optional for storage

### Storage
* **Type**: Azure Data Lake Gen2
* **Replication**: LRS (configurable)
* **Access**: HTTPS only, no public blob access
* **Features**: 
  * Hierarchical namespace enabled
  * Soft delete enabled (7 days)
  * Versioning enabled

### Monitoring
* **Log Analytics**: Central logging for all resources
* **App Insights**: Performance monitoring
* **Diagnostics**: Captures jobs, notebooks, clusters, DBFS, accounts logs
* **Retention**: 30 days (configurable)

## Data Flow

1. **User Access** → Azure AD → Databricks Workspace
2. **Compute** → VNet Isolated → Data Access via Private Endpoints
3. **Logs** → Diagnostic Settings → Log Analytics
4. **Storage** → Secured via Private Endpoints/Service Endpoints

## Security Layers

| Layer | Implementation |
|-------|---------------|
| Network | VNet injection, NSG rules, No public IPs |
| Identity | Azure AD integration, RBAC |
| Data | Encryption at rest & in transit, Private endpoints |
| Monitoring | All activities logged, alerts configured |
| Compliance | Diagnostic logging, audit trails |

## Module Dependencies

```
main.bicep
├── networking.bicep (deployed first)
│   └── outputs: vnetId, subnetNames
├── storage.bicep (depends on networking)
│   └── uses: vnetId for private endpoints
├── databricks.bicep (depends on networking & storage)
│   └── uses: vnetId, subnetNames, storageAccountName
└── monitoring.bicep (depends on databricks)
    └── uses: databricksWorkspaceId
```

## GitHub Actions Workflow

```
Pull Request
    │
    ├─► Validate Workflow
    │   ├─ Bicep Lint
    │   ├─ Build Templates
    │   ├─ Validate against Azure
    │   └─ Security Scan (PSRule)
    │
Merge to Main
    │
    └─► Deploy Workflow
        ├─ Build Bicep
        ├─ What-If Analysis
        ├─ Deploy Infrastructure
        ├─ Post-deployment Validation
        └─ Generate Summary
```

## Scalability Considerations

* **Compute**: Auto-scaling clusters
* **Storage**: Unlimited scale with ADLS Gen2
* **Monitoring**: Log Analytics scales automatically
* **Multi-region**: Template supports any Azure region

## Cost Optimization

* **Storage**: LRS for non-critical data
* **Databricks**: Premium tier for production, Standard for dev
* **Monitoring**: 30-day retention, adjust as needed
* **Compute**: Use auto-termination on clusters

## Disaster Recovery

* **Backup**: Export notebooks/jobs regularly
* **Infrastructure**: Version-controlled IaC for rapid rebuild
* **Data**: Enable geo-replication for critical storage
* **Monitoring**: Retain logs for compliance period
