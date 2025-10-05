# Azure Infrastructure Hello World MCP Server

This standalone sample shows how to host a minimal Model Context Protocol (MCP) server on Azure infrastructure that is commonly used in AI projects. Use it as a classroom or workshop asset when teaching teams how Azure services support MCP-based agent workflows end to end.

## 🎯 Learning Goals

By the end of the walkthrough students should be able to:

1. Explain how an MCP server fits into an Azure-centric AI architecture.
2. Run and validate the FastMCP "hello world" server locally.
3. Containerize the server by using Azure Container Registry (ACR) Tasks.
4. Deploy the container to Azure Container Apps (ACA) or Azure Container Instances (ACI).
5. Satisfy agreed success criteria that prove the environment is ready for demos or further experimentation.

## 🧰 Tools Exposed by the Server

| Tool | Purpose | Notes |
|------|---------|-------|
| `hello` | Returns a friendly greeting and echoes the `AZURE_ENV_NAME` to reinforce environment awareness. | Great for showing how configuration travels with the container. |
| `server_info` | Shares runtime diagnostics such as timestamp, working directory, Python version, and registered tools. | Useful for teaching basic troubleshooting steps. |

The implementation lives in [`hello_world_mcp_server.py`](./hello_world_mcp_server.py) and uses the lightweight [FastMCP](https://github.com/modelcontextprotocol/fastmcp) framework.

## 📂 Project Layout

```
azure-infra-hello-world-mcp/
├── README.md
└── hello_world_mcp_server.py
```

Keep this folder separate from other sample agents so that students can clearly see the infrastructure-specific assets.

## 🚀 Step-by-Step Tutorial

### 1. Prerequisites

- Python 3.10+
- An Azure subscription with permission to create resource groups, Container Registries, and Container Apps/Instances
- Azure CLI (`az`) logged in with the correct subscription selected
- Docker CLI (optional for local builds, not required when using ACR Tasks)

### 2. Run Locally for Fast Feedback

```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install fastmcp
python hello_world_mcp_server.py
```

Open another terminal and verify the tools by connecting through your MCP client (for example, the Azure AI Foundry agent or Claude desktop) pointing at the local server endpoint.

### 3. Build the Container Image on Azure

1. **Create an Azure resource group** (skip if one already exists):
   ```bash
   az group create --name rg-mcp-hello --location eastus
   ```
2. **Provision Azure Container Registry**:
   ```bash
   az acr create --resource-group rg-mcp-hello --name mcphelloregistry --sku Basic --admin-enabled true
   ```
3. **Submit an ACR Task build** to compile and push the container without requiring Docker locally:
   ```bash
   az acr build --registry mcphelloregistry --image hello-mcp:latest .
   ```

> 📘 _Teaching tip_: highlight that ACR Tasks keep builds in Azure, which simplifies enterprise security reviews.

### 4. Deploy with Azure Container Apps

```bash
az containerapp env create \
  --name env-mcp-hello \
  --resource-group rg-mcp-hello \
  --location eastus

az containerapp create \
  --name hello-mcp-server \
  --resource-group rg-mcp-hello \
  --environment env-mcp-hello \
  --image mcphelloregistry.azurecr.io/hello-mcp:latest \
  --target-port 8000 \
  --ingress external \
  --env-vars AZURE_ENV_NAME="aca-demo"
```

Alternatively, replace the Container Apps commands with `az container create` if you prefer Azure Container Instances for simpler labs.

### 5. Validate Against Success Criteria

| Criteria | How to Verify |
|----------|---------------|
| Container starts and exposes MCP endpoint | `az containerapp logs show` (or ACI equivalent) reports the FastMCP startup message without errors. |
| `hello` tool returns environment tag | Invoke the tool via your MCP client and confirm the response includes `"environment": "aca-demo"`. |
| `server_info` shows Azure-specific context | Verify the working directory path and container hostname in the response. |
| Deployment reproducibility | Re-run the `az acr build` and `az containerapp create --revision-suffix` commands to demonstrate infrastructure-as-code discipline. |

When each row is satisfied, the environment is ready for stakeholders.

## 📚 Next Steps for Learners

- Swap FastMCP for your organization’s preferred MCP framework and note the differences.
- Extend the server with tools that call Azure AI services (Search, OpenAI, Cognitive Services) to connect infrastructure concepts to AI workloads.
- Automate the provisioning steps with Bicep or Terraform to reinforce infrastructure-as-code best practices.

Happy teaching, and enjoy showing how Azure powers MCP workloads!
