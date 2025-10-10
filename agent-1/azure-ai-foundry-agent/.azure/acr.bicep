param acrName string
param location string = resourceGroup().location

resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

output acrLoginServer string = acr.properties.loginServer
output acrAdminUser string = acr.properties.adminUserEnabled ? 'Enabled' : 'Disabled'