/**
 * @module appinsights-v1
 * @description Azure Application Insights resource.
 */

// ------------------
//    PARAMETERS
// ------------------

@description('The suffix to append to the Application Insights name.')
param resourceSuffix string = uniqueString(subscription().id, resourceGroup().id)

@description('Name of the Application Insights resource.')
param applicationInsightsName string = 'insights-${resourceSuffix}'

@description('Location of the Application Insights resource.')
param applicationInsightsLocation string = resourceGroup().location

@description('The custom metrics opted in type.')
@allowed([
  'WithDimensions'
  'NoDimensions'
  'NoMeasurements'
  'Off'
])
param customMetricsOptedInType string = 'Off'

@description('Log Analytics Workspace Id')
param lawId string

// ------------------
//    RESOURCES
// ------------------

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: applicationInsightsLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: lawId
    #disable-next-line BCP037
    CustomMetricsOptedInType: customMetricsOptedInType
  }
}

// ------------------
//    OUTPUTS
// ------------------

output id string = applicationInsights.id
output name string = applicationInsights.name
output instrumentationKey string = applicationInsights.properties.InstrumentationKey
output appId string = applicationInsights.properties.AppId
output applicationInsightsName string = applicationInsightsName
