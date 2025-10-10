// This Bicep file defines the configuration for Microsoft Web Application Firewall (WAF) to secure the Azure AI Foundry agent application.

param location string = resourceGroup().location
param wafName string = 'myWAF'
param skuName string = 'WAF_v2'
param skuTier string = 'Standard_v2'

resource waf 'Microsoft.Network/applicationGateways@2021-02-01' = {
  name: wafName
  location: location
  sku: {
    name: skuName
    tier: skuTier
    capacity: 2
  }
  properties: {
    enabled: true
    frontendIPConfigurations: [
      {
        name: 'frontendIPConfig'
        properties: {
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', 'myPublicIP')
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'frontendPort'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: 'myapp.azurecontainerapps.net'
            }
          ]
        }
      }
    ]
    httpListeners: [
      {
        name: 'httpListener'
        properties: {
          frontendIPConfiguration: {
            id: waf.frontendIPConfigurations[0].id
          }
          frontendPort: {
            id: waf.frontendPorts[0].id
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'routingRule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: waf.httpListeners[0].id
          }
          backendAddressPool: {
            id: waf.backendAddressPools[0].id
          }
          backendHttpSettings: {
            id: waf.backendHttpSettings[0].id
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
      customRules: []
    }
  }
}

output wafId string = waf.id