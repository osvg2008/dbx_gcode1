targetScope = 'subscription'

@description('Environment name (dev, staging, prod)')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = 'dev'

@description('Azure region for all resources')
param location string = 'eastus'

@description('Project name for resource naming')
@minLength(3)
@maxLength(10)
param projectName string

@description('Tags to apply to all resources')
param tags object = {}

@description('Enable VNet injection for Databricks workspace')
param enableVnetInjection bool = true

@description('Enable private endpoints')
param enablePrivateEndpoints bool = false

@description('Databricks pricing tier')
@allowed([
  'standard'
  'premium'
])
param databricksSku string = 'premium'

// Variables
var resourceGroupName = 'rg-${projectName}-${environment}-${location}'
var commonTags = union(tags, {
  Environment: environment
  Project: projectName
  ManagedBy: 'Bicep'
  DeployedFrom: 'GitHub-Actions'
})

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: commonTags
}

// Networking Module
module networking 'modules/networking.bicep' = {
  scope: rg
  name: 'networking-deployment'
  params: {
    location: location
    projectName: projectName
    environment: environment
    tags: commonTags
    enablePrivateEndpoints: enablePrivateEndpoints
  }
}

// Storage Module
module storage 'modules/storage.bicep' = {
  scope: rg
  name: 'storage-deployment'
  params: {
    location: location
    projectName: projectName
    environment: environment
    tags: commonTags
    vnetId: networking.outputs.vnetId
    privateEndpointSubnetId: enablePrivateEndpoints ? networking.outputs.privateEndpointSubnetId : ''
    enablePrivateEndpoints: enablePrivateEndpoints
  }
}

// Databricks Workspace Module
module databricks 'modules/databricks.bicep' = {
  scope: rg
  name: 'databricks-deployment'
  params: {
    location: location
    projectName: projectName
    environment: environment
    tags: commonTags
    sku: databricksSku
    enableVnetInjection: enableVnetInjection
    vnetId: enableVnetInjection ? networking.outputs.vnetId : ''
    publicSubnetName: enableVnetInjection ? networking.outputs.publicSubnetName : ''
    privateSubnetName: enableVnetInjection ? networking.outputs.privateSubnetName : ''
    storageAccountName: storage.outputs.storageAccountName
  }
}

// Monitoring Module
module monitoring 'modules/monitoring.bicep' = {
  scope: rg
  name: 'monitoring-deployment'
  params: {
    location: location
    projectName: projectName
    environment: environment
    tags: commonTags
    databricksWorkspaceId: databricks.outputs.workspaceId
  }
}

// Outputs
output resourceGroupName string = rg.name
output databricksWorkspaceUrl string = databricks.outputs.workspaceUrl
output databricksWorkspaceId string = databricks.outputs.workspaceId
output storageAccountName string = storage.outputs.storageAccountName
output vnetId string = networking.outputs.vnetId
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId
