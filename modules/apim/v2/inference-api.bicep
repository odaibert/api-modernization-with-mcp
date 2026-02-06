/**
 * @module inference-api-v2
 * @description APIM API definition for routing LLM inference calls to Azure AI Services backends.
 */

// ------------------
//    PARAMETERS
// ------------------

@description('The suffix for resource names.')
param resourceSuffix string = uniqueString(subscription().id, resourceGroup().id)

@description('The name of the APIM service.')
param apimServiceName string = 'apim-${resourceSuffix}'

@description('The policy XML for the inference API.')
param policyXml string

@description('The APIM logger ID for diagnostics.')
param apimLoggerId string = ''

@description('Extended AI Services configuration with endpoints.')
param aiServicesConfig array = []

@description('The type of inference API.')
@allowed([
  'AzureOpenAI'
  'AzureAI'
  'OpenAI'
  'PassThrough'
])
param inferenceAPIType string = 'AzureOpenAI'

@description('The path for the inference API.')
param inferenceAPIPath string = 'inference'

// ------------------
//    RESOURCES
// ------------------

resource apim 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apimServiceName
}

// Create backends for each AI Services endpoint
resource aiBackend 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = [for (config, i) in aiServicesConfig: {
  parent: apim
  name: '${config.name}-backend'
  properties: {
    protocol: 'http'
    url: '${config.endpoint}openai'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
    type: 'Single'
  }
}]

// Create the inference API
resource inferenceAPI 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  parent: apim
  name: 'inference-api'
  properties: {
    displayName: 'Azure OpenAI Inference API'
    path: empty(inferenceAPIPath) ? 'openai' : inferenceAPIPath
    protocols: [
      'https'
    ]
    subscriptionRequired: true
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'subscription-key'
    }
    serviceUrl: '${aiServicesConfig[0].endpoint}openai'
    format: 'openapi-link'
    value: 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable/2024-10-21/inference.json'
  }
}

// Apply the policy
resource inferenceAPIPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-12-01-preview' = {
  parent: inferenceAPI
  name: 'policy'
  properties: {
    value: replace(policyXml, '{backend-id}', aiBackend[0].name)
    format: 'rawxml'
  }
}
