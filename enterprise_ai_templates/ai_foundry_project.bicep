// Azure AI Foundry Bicep deployment template
// This template deploys an Azure AI Foundry resource and a project

param location string = resourceGroup().location
param foundryName string
param projectName string

resource foundry 'Microsoft.Foundry/accounts@2024-05-01-preview' = {
  name: foundryName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    // Add additional properties as needed
  }
}

resource project 'Microsoft.Foundry/accounts/projects@2024-05-01-preview' = {
  name: '${foundry.name}/${projectName}'
  location: location
  properties: {
    // Add additional project properties as needed
  }
  dependsOn: [
    foundry
  ]
}
