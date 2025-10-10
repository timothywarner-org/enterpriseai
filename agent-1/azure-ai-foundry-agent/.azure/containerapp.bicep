param location string = resourceGroup().location
param containerAppName string
param acrName string
param cosmosDbName string
param aiSearchName string
param environmentName string

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  properties: {
    environmentId: resourceId('Microsoft.App/managedEnvironments', environmentName)
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        traffic: [
          {
            revisionName: '${containerAppName}-revision'
            weight: 100
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: '${acrName}.azurecr.io/${containerAppName}:latest'
          resources: {
            cpu: 0.5
            memory: '1.0Gi'
          }
          env: [
            {
              name: 'COSMOS_DB_CONNECTION_STRING'
              value: 'AccountEndpoint=https://${cosmosDbName}.documents.azure.com:443/;AccountKey=<your-account-key>;'
            }
            {
              name: 'AZURE_SEARCH_ENDPOINT'
              value: 'https://${aiSearchName}.search.windows.net'
            }
            {
              name: 'GITHUB_API_KEY'
              value: '<your-github-api-key>'
            }
          ]
        }
      ]
    }
  }
}

output containerAppUrl string = containerApp.properties.configuration.ingress.fqdn