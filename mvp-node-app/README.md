# Enterprise AI MVP Node App

A live-teachable Retrieval Augmented Generation (RAG) microservice that showcases Azure OpenAI, secure Azure infrastructure patterns, and Model Context Protocol (MCP) integration. Use it as a classroom-ready demo for the *Enterprise AI Deployment on Azure* course.

## 🎯 Capabilities

- **Azure OpenAI RAG API** – Express endpoints that ground answers in Markdown course notes.
- **Vector preparation script** – Generate embeddings with a single `npm run prep` command.
- **Model Context Protocol server** – Expose the same RAG logic as MCP tools and resources.
- **Azure infrastructure starter** – Bicep template for OpenAI, AI Search, storage, and private networking.

## 🧱 Project Structure

```text
mvp-node-app/
├── data/
│   └── knowledge-base/         # Markdown sources for retrieval
├── infra/                      # Azure resource templates
├── src/                        # Express API, RAG pipeline, MCP server
├── .env.example
├── package.json
└── README.md
```

## ⚙️ Prerequisites

- Node.js 20+
- Azure subscription with an Azure OpenAI resource (with a chat and embedding deployment)
- Optional: Azure AI Search resource if you want to extend beyond the local JSON vector store

## 🚀 Quick Start

1. **Install dependencies**
   ```bash
   npm install
   cp .env.example .env
   ```
2. **Configure environment variables** in `.env`:
   - `AZURE_OPENAI_ENDPOINT` – e.g. `https://contoso-aoai.openai.azure.com/`
   - `AZURE_OPENAI_API_KEY`
   - `AZURE_OPENAI_CHAT_DEPLOYMENT` – name of your chat model deployment (for example `gpt-4o-mini`)
   - `AZURE_OPENAI_EMBEDDING_DEPLOYMENT` – name of your embedding deployment (for example `text-embedding-3-large`)
3. **Generate the local vector store**
   ```bash
   npm run prep
   ```
4. **Start the API**
   ```bash
   npm run dev
   ```
5. **Ask a question**
   ```bash
   curl -X POST http://localhost:3000/chat \
     -H "Content-Type: application/json" \
     -d '{"question":"How do we secure Azure OpenAI?"}'
   ```

### Retrieve-only endpoint

Use `/retrieve` to show the similarity matches without generating an LLM answer:

```bash
curl -X POST http://localhost:3000/retrieve \
  -H "Content-Type: application/json" \
  -d '{"question":"What is the live demo flow?", "topK": 2}'
```

## 🧠 Classroom Demo Flow

1. `npm run prep` – narrate how embeddings are created and cached to `data/vector-store.json`.
2. `npm run dev` – open the Express server logs and highlight the `healthz`, `retrieve`, and `chat` endpoints.
3. `curl` or Postman – ask a question and point out the `matches` array with cosine similarity scores.
4. `npm run mcp` – switch to MCP mode so learners can see the same tooling surface inside their AI assistants.
5. Discuss how the Bicep file (`infra/azure-ai-demo.bicep`) provisions private endpoints, storage, and Azure AI Search.

## 🤖 Model Context Protocol Server

```bash
npm run mcp
```

This command launches an MCP server over stdio with two tools:

| Tool | Purpose |
| --- | --- |
| `ask-course-assistant` | Generates a grounded answer and lists the matching sources. |
| `retrieve-references` | Returns the top semantic matches without invoking the LLM. |

It also exposes a `knowledge://{slug}` resource template so MCP clients can load the markdown sources directly into context.

Use it with any MCP-compatible client (Claude Desktop, VS Code MCP, etc.) by pointing to the command `node src/mcp-server.js`.

## ☁️ Azure Infrastructure Template

The `infra/azure-ai-demo.bicep` file provisions the core services needed to productionize this demo:

- Azure OpenAI with optional private endpoint
- Azure AI Search (Standard SKU)
- Storage account for document staging
- Virtual network and subnet ready for private endpoints

Deploy with Azure CLI:

```bash
az deployment group create \
  --resource-group <rg-name> \
  --template-file infra/azure-ai-demo.bicep \
  --parameters baseName=<shortname> enablePrivateEndpoints=true
```

## 🔧 Extensibility Ideas

- Swap the JSON vector store for Azure AI Search or Cosmos DB.
- Add Azure Monitor Application Insights telemetry.
- Introduce authentication (Azure AD) for the Express API.
- Extend the MCP server with tools that create GitHub issues or run deployment scripts.

## 🧹 Maintenance Commands

| Command | Action |
| --- | --- |
| `npm run prep` | Regenerate embeddings after editing Markdown content. |
| `npm run dev` | Start the Express API with file watching. |
| `npm run mcp` | Launch the MCP server over stdio. |

## ✅ Troubleshooting

- **`Missing required environment variable`** – copy `.env.example` and populate your Azure OpenAI settings.
- **`Vector store missing`** – run `npm run prep` after configuring credentials.
- **Azure 401 errors** – verify the API key is scoped to the Azure OpenAI resource and the deployment names are correct.
- **Private network access** – if using private endpoints, run this app from within the same VNet or via VPN/ExpressRoute.

Happy teaching! 🚀
