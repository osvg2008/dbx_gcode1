@description('Azure region for resources')
param location string

@description('Project name for resource naming')
param projectName string

@description('Environment name')
param environment string

@description('Resource tags')
param tags object

@description('Databricks pricing tier')
@allowed([
  'standard'
  'premium'
])
param sku string

@description('Enable VNet injection')
param enableVnetInjection bool

@description('VNet ID')
param vnetId string

@description('Public subnet name')
param publicSubnetName string

@description('Private subnet name')
param privateSubnetName string

@description('Storage account name for DBFS')
param storageAccountName string

// Variables
var workspaceName = 'dbw-${projectName}-${environment}'
var managedResourceGroupName = 'rg-${projectName}-${environment}-managed'

// Databricks Workspace with VNet Injection
resource databricksWorkspace 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: workspaceName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', managedResourceGroupName)
    parameters: enableVnetInjection ? {
      customVirtualNetworkId: {
        value: vnetId
      }
      customPublicSubnetName: {
        value: publicSubnetName
      }
      customPrivateSubnetName: {
        value: privateSubnetName
      }
      enableNoPublicIp: {
        value: true
      }
      storageAccountName: {
        value: storageAccountName
      }
    } : {
      storageAccountName: {
        value: storageAccountName
      }
    }
    publicNetworkAccess: 'Enabled'
    requiredNsgRules: 'AllRules'
  }
}

// Outputs
output workspaceId string = databricksWorkspace.id
output workspaceName string = databricksWorkspace.name
output workspaceUrl string = 'https://${databricksWorkspace.properties.workspaceUrl}'
output managedResourceGroupId string = databricksWorkspace.properties.managedResourceGroupId
