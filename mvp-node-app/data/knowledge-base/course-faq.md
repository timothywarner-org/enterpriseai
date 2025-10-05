# Enterprise AI Deployment on Azure - FAQ

## Course Outcomes
- Deploy Azure OpenAI with private networking and managed identities.
- Combine Azure AI Search, Cognitive Services, and custom prompts for RAG.
- Accelerate infra automation with GitHub Copilot and Bicep.
- Implement monitoring, compliance, and cost guardrails.

## Azure Security Guardrails
- Always use private endpoints when exposing Azure OpenAI.
- Store secrets in Azure Key Vault and use managed identities.
- Capture diagnostics with Azure Monitor and enable NSG logging.

## RAG Architecture Basics
1. Ingest enterprise documents and split them into semantic chunks.
2. Generate embeddings with Azure OpenAI's text-embedding-3-large.
3. Store vectors in Azure AI Search, Cosmos DB, or a simple file cache.
4. Retrieve top matches for each user query and ground the prompt.

## Azure Infrastructure Quick Start
- Resource group per environment (dev, test, prod).
- Bicep modules for networking, security, and AI services.
- Use deployment scripts to seed Azure AI Search indexes.

## Live Demo Flow
1. Run `npm run prep` to embed the knowledge base locally.
2. Start the Express API with `npm run dev`.
3. Use `curl` or a REST client to post a question.
4. Highlight the similarity scores and retrieved sources.
5. Switch to `npm run mcp` to expose the same logic as MCP tools.

## Troubleshooting Tips
- Check that `AZURE_OPENAI_ENDPOINT` ends with `/openai/deployments/{deployment}`? No: use the base endpoint only.
- Verify the deployment names match your Azure resources.
- Delete `data/vector-store.json` if you rotate embeddings.

