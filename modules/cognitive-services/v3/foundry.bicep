/**
 * @module foundry-v3
 * @description Azure AI Services (Cognitive Services) with Azure AI Foundry project and model deployments.
 */

// ------------------
//    PARAMETERS
// ------------------

@description('The suffix for resource names.')
param resourceSuffix string = uniqueString(subscription().id, resourceGroup().id)

@description('Configuration array for AI Services accounts.')
param aiServicesConfig array = []

@description('Configuration array for model deployments.')
param modelsConfig array = []

@description('The APIM managed identity principal ID for RBAC role assignment.')
param apimPrincipalId string = ''

@description('The name of the AI Foundry project.')
param foundryProjectName string = 'default'

// ------------------
//    VARIABLES
// ------------------

var cognitiveServicesOpenAIContributorRoleId = resourceId('Microsoft.Authorization/roleDefinitions', 'a001fd3d-188f-4b5d-821b-7da978bf7442')

// ------------------
//    RESOURCES
// ------------------

resource aiServicesAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = [for (config, i) in aiServicesConfig: {
  name: '${config.name}-${resourceSuffix}'
  location: config.location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: toLower('${config.name}-${resourceSuffix}')
    disableLocalAuth: false
    publicNetworkAccess: 'Enabled'
  }
}]

resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = [for (config, i) in aiServicesConfig: {
  parent: aiServicesAccount[i]
  #disable-next-line BCP334
  name: '${foundryProjectName}-${config.name}'
  location: config.location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}]

@batchSize(1)
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = [for (model, i) in modelsConfig: {
  parent: aiServicesAccount[0]
  name: model.name
  sku: {
    name: model.sku
    capacity: model.capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: model.name
      version: model.version
    }
  }
}]

// RBAC: Grant APIM the Cognitive Services OpenAI Contributor role
resource apimRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (config, i) in aiServicesConfig: if (!empty(apimPrincipalId)) {
  scope: aiServicesAccount[i]
  name: guid(aiServicesAccount[i].id, apimPrincipalId, cognitiveServicesOpenAIContributorRoleId)
  properties: {
    roleDefinitionId: cognitiveServicesOpenAIContributorRoleId
    principalId: apimPrincipalId
    principalType: 'ServicePrincipal'
  }
}]

// ------------------
//    OUTPUTS
// ------------------

output extendedAIServicesConfig array = [for (config, i) in aiServicesConfig: {
  name: config.name
  location: config.location
  endpoint: aiServicesAccount[i].properties.endpoint
  resourceId: aiServicesAccount[i].id
  foundryProjectEndpoint: 'https://${config.name}-${resourceSuffix}.services.ai.azure.com/api/projects/${foundryProjectName}'
}]
