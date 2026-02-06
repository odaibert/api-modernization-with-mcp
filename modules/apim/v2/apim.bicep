/**
 * @module apim-v2
 * @description Azure API Management (APIM) resource – v2 SKUs (Basicv2, Standardv2, Premiumv2).
 */

// ------------------
//    PARAMETERS
// ------------------

@description('The suffix to append to the API Management instance name.')
param resourceSuffix string = uniqueString(subscription().id, resourceGroup().id)

@description('The name of the API Management instance.')
param apiManagementName string = 'apim-${resourceSuffix}'

@description('The location of the API Management instance.')
param location string = resourceGroup().location

@description('The email address of the publisher.')
param publisherEmail string = 'noreply@microsoft.com'

@description('The name of the publisher.')
param publisherName string = 'Microsoft'

@description('The pricing tier of this API Management service')
@allowed([
  'Consumption'
  'Developer'
  'Basic'
  'Basicv2'
  'Standard'
  'Standardv2'
  'Premium'
])
param apimSku string = 'Basicv2'

@description('Configuration array for APIM subscriptions')
param apimSubscriptionsConfig array = []

@description('The Log Analytics Workspace ID for diagnostic settings')
param lawId string = ''

@description('The instrumentation key for Application Insights')
param appInsightsInstrumentationKey string = ''

@description('The resource ID for Application Insights')
param appInsightsId string = ''

// ------------------
//    RESOURCES
// ------------------

resource apimService 'Microsoft.ApiManagement/service@2024-06-01-preview' = {
  name: apiManagementName
  location: location
  sku: {
    name: apimSku
    capacity: 1
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource apimDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(length(lawId) > 0) {
  scope: apimService
  name: 'apimDiagnosticSettings'
  properties: {
    workspaceId: lawId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'AllLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource apimLogger 'Microsoft.ApiManagement/service/loggers@2024-06-01-preview' = if(length(lawId) > 0) {
  parent: apimService
  name: 'azuremonitor'
  properties: {
    loggerType: 'azureMonitor'
    isBuffered: false
  }
}

resource apimAppInsightsLogger 'Microsoft.ApiManagement/service/loggers@2021-12-01-preview' = if (!empty(appInsightsId) && !empty(appInsightsInstrumentationKey)) {
  name: 'appinsights-logger'
  parent: apimService
  properties: {
    credentials: {
      instrumentationKey: appInsightsInstrumentationKey
    }
    description: 'APIM Logger for Application Insights'
    isBuffered: false
    loggerType: 'applicationInsights'
    resourceId: appInsightsId
  }
}

@batchSize(1)
resource apimSubscription 'Microsoft.ApiManagement/service/subscriptions@2024-06-01-preview' = [for subscription in apimSubscriptionsConfig: if(length(apimSubscriptionsConfig) > 0) {
  name: subscription.name
  parent: apimService
  properties: {
    allowTracing: true
    displayName: '${subscription.displayName}'
    scope: '/apis'
    state: 'active'
  }
}]

// ------------------
//    OUTPUTS
// ------------------

output id string = apimService.id
output name string = apimService.name
output principalId string = apimService.identity.principalId
output gatewayUrl string = apimService.properties.gatewayUrl
output loggerId string = (length(lawId) > 0) ? apimLogger.id : ''

#disable-next-line outputs-should-not-contain-secrets
output apimSubscriptions array = [for (subscription, i) in apimSubscriptionsConfig: {
  name: subscription.name
  displayName: subscription.displayName
  key: apimSubscription[i].listSecrets().primaryKey
}]
