/*
╔══════════════════════════════════════════════════════════════════╗
║              AZURE LANDING ZONE DEPLOYMENT PATTERN               ║
╚══════════════════════════════════════════════════════════════════╝
This Bicep file represents a condensed, production-grade pattern for
enterprise landing zone deployment. It follows the Microsoft Cloud
Adoption Framework (CAF) and Enterprise-Scale design principles.

───────────────────────────── PHASES ───────────────────────────────
1️⃣ Strategy & Design
   • Define management group hierarchy, subscription model, and guardrails.
   • Establish naming, policy, network, and identity baselines.

2️⃣ Bootstrap / Initial Infra
   • Deploy foundational platform services (Entra ID, policy, logging, hub VNet).
   • Enforce root governance and monitoring standards.

3️⃣ Subscription “Vending”
   • Automate creation of new subscriptions under governance.
   • Use modular IaC (Bicep/ARM) for repeatable, policy-compliant landing zones.

4️⃣ Workload Deployment
   • Deploy application resources (AKS, Container Apps, data services).
   • Integrate with shared networking, monitoring, and security boundaries.

5️⃣ Change Management & Evolution
   • Version modules, apply policy updates, manage drift, expand regions.
   • Use CI/CD pipelines and canary environments for controlled rollout.

────────────────────────────────────────────────────────────────────
Author: Tim Warner  |  Session: Azure AI Infrastructure Deployment (O’Reilly)
Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/enterprise-scale/
────────────────────────────────────────────────────────────────────
*/

param tenantId string
param location string = 'eastus'
param prefix string = 'contoso'
param platformSubscriptionId string

// Deploy management groups
module mg_hub 'modules/managementGroups.bicep' = {
  name: 'mgHub'
  params: {
    prefix: prefix
  }
}

// Deploy foundational policies and guardrails
module policy_root 'modules/policies/rootPolicies.bicep' = {
  name: 'rootPolicies'
  params: {
    prefix: prefix
  }
  dependsOn: [mg_hub]
}

// Deploy connectivity / network hub
module networking 'modules/network/hub.bicep' = {
  name: 'hubNet'
  params: {
    prefix: prefix
    location: location
  }
  dependsOn: [policy_root]
}

// Subscription vending (for app zones)
module sub_vending 'modules/vending/subscriptionVending.bicep' = {
  name: 'subVend'
  params: {
    prefix: prefix
    location: location
  }
  dependsOn: [networking]
}
