param defaultResourceNamePrefix string
param functionAppName string = '${defaultResourceNamePrefix}func'
param webAppName string = '${defaultResourceNamePrefix}api'
param storageAccountName string {
  default: '${defaultResourceNamePrefix}sta${uniqueString(resourceGroup().id)}'
  maxLength: 24
}
param cosmosAccountName string = '${defaultResourceNamePrefix}cos${uniqueString(resourceGroup().id)}' // this must be globally unique, so added uniqueString()
param cosmosDatabaseName string = 'media'
param cosmosCollectionName string = 'metadata'
param applicationInsightsName string = '${defaultResourceNamePrefix}insights'
param cognitiveServiceName string = '${defaultResourceNamePrefix}ai'

var functionStorageAccountName = '${functionAppName}${uniqueString(resourceGroup().id)}'
var functionAppHostingPlanName = '${functionAppName}-hosting-plan'
var webAppHostingPlanName = '${webAppName}-hosting-plan'
var webAppSku = 'P1v2'
var cognitiveServiceSku = 'S0'

resource stg 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  tags: {
    displayName: storageAccountName // do you need this tag?
  }
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2020-04-01' = {
  name: cosmosAccountName
  location: resourceGroup().location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Eventual'
      maxStalenessPrefix: 1
      maxIntervalInSeconds: 5
    }
    locations: [
      {
        locationName: resourceGroup().location
        failoverPriority: 0
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: true
  }
}

resource db 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2020-04-01' = {
  name: '${cosmos.name}/${cosmosDatabaseName}'
  properties: {
    resource: {
      id: cosmosDatabaseName
    }
    options: {
      throughput: 400
    }
  }
}

resource collection 'Microsoft.DocumentDb/databaseAccounts/sqlDatabases/containers@2020-04-01' = {
  name: '${db.name}/${cosmosCollectionName}'
  properties: {
    resource: {
      id: cosmosCollectionName
      partitionKey: {
        paths: [
          '/filePath'
        ]
        kind: 'hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
            indexes: [
              {
                kind: 'Hash'
                dataType: 'String'
                precision: -1
              }
            ]
          }
        ]
        excludedPaths: [
          {
            path: '/PathToNotIndex/*'
          }
        ]
      }
    }
    options: {} // is this required?
  }
}

resource ai 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: applicationInsightsName
  location: resourceGroup().location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource funcStg 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: functionStorageAccountName
  tags: {
    displayName: functionStorageAccountName
  }
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2018-02-01' = {
  name: functionAppHostingPlanName
  location: resourceGroup().location
  properties: {
    name: functionAppHostingPlanName
    computeMode: 'Dynamic'
  }
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
}

resource funcApp 'Microsoft.Web/sites@2018-11-01' = {
  name: functionAppName
  location: resourceGroup().location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsDashboard'
          value: 'DefaultEndpointsProtocol=https;AccountName=${funcStg.name};AccountKey=${listKeys(funcStg.id, funcStg.apiVersion).keys[0].value}'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${funcStg.name};AccountKey=${listKeys(funcStg.id, funcStg.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${funcStg.name};AccountKey=${listKeys(funcStg.id, funcStg.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: ai.properties.InstrumentationKey // this will add an additional item to the dependsOn array. I think this dependency was missing before.
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
      ]
    }
  }
}

resource webAppHostingPlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: webAppHostingPlanName
  location: resourceGroup().location
  properties: {
    name: webAppHostingPlanName
  }
  sku: {
    name: webAppSku
    capacity: 1
  }
}

resource webApp 'Microsoft.Web/sites@2018-11-01' = {
  name: webAppName
  location: resourceGroup().location
  properties: {
    name: webAppName
    serverFarmId: webAppHostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: ai.properties.InstrumentationKey
          slotSetting: true
        }
        {
          name: 'APPINSIGHTS_PROFILERFEATURE_VERSION'
          value: '1.0.0'
          slotSetting: true
        }
        {
          name: 'APPINSIGHTS_SNAPSHOTFEATURE_VERSION'
          value: '1.0.0'
          slotSetting: true
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${ai.properties.InstrumentationKey};IngestionEndpoint=https://westeurope-1.in.applicationinsights.azure.com/'
          slotSetting: false
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
          slotSetting: true
        }
        {
          name: 'Cosmos:PrimaryKey'
          value: listKeys(cosmos.id, cosmos.apiVersion).primaryMasterKey
          slotSetting: false
        }
        {
          name: 'DiagnosticServices_EXTENSION_VERSION'
          value: '~3'
          slotSetting: true
        }
        {
          name: 'InstrumentationEngine_EXTENSION_VERSION'
          value: 'disabled'
          slotSetting: true
        }
        {
          name: 'SnapshotDebugger_EXTENSION_VERSION'
          value: 'disabled'
          slotSetting: true
        }
        {
          name: 'WEBSITE_HTTPLOGGING_RETENTION_DAYS'
          value: '7'
          slotSetting: false
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '6.9.1'
          slotSetting: false
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_BaseExtensions'
          value: 'disabled'
          slotSetting: true
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
          slotSetting: true
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_PreemptSdk'
          value: '1'
          slotSetting: true
        }
      ]
    }
  }
}

resource cognitiveService 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: cognitiveServiceName
  location: resourceGroup().location
  sku: {
    name: cognitiveServiceSku
  }
  kind: 'CognitiveServices'
  properties: {
    statisticsEnabled: false
  }
}