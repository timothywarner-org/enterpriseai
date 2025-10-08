# Example: Deploy Azure AI Foundry resource and project using Azure SDK for Python

from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.foundry import FoundryManagementClient

subscription_id = "<your-subscription-id>"
resource_group = "<your-resource-group>"
location = "eastus"
foundry_name = "<your-foundry-name>"
project_name = "<your-project-name>"

credential = DefaultAzureCredential()
resource_client = ResourceManagementClient(credential, subscription_id)
foundry_client = FoundryManagementClient(credential, subscription_id)


# Create Foundry resource
def create_foundry():
    foundry_params = {
        "location": location,
        "sku": {"name": "Standard", "tier": "Standard"},
        "properties": {},
    }
    foundry = foundry_client.accounts.begin_create_or_update(
        resource_group, foundry_name, foundry_params
    ).result()
    return foundry


# Create Project resource
def create_project():
    project_params = {"location": location, "properties": {}}
    project = foundry_client.projects.begin_create_or_update(
        resource_group, foundry_name, project_name, project_params
    ).result()
    return project


if __name__ == "__main__":
    foundry = create_foundry()
    print(f"Foundry created: {foundry.id}")
    project = create_project()
    print(f"Project created: {project.id}")
