# Azure AI Foundry Agent Application

This repository contains the Azure AI Foundry agent application, designed to leverage the GPT-4o base model, Azure AI Search for retrieval-augmented generation (RAG), and Azure Cosmos DB for memory persistence. The application is structured to facilitate easy deployment to Azure Container Registry (ACR) and run in Azure Container Apps.

## Project Structure

```
azure-ai-foundry-agent
├── src
│   ├── main.py               # Entry point for the application
│   ├── agent
│   │   └── __init__.py       # Main class for the AI agent
│   ├── models
│   │   └── gpt4o.py          # Interface with the GPT-4o model
│   ├── rag
│   │   └── azure_search.py    # Interaction with Azure AI Search
│   ├── memory
│   │   └── cosmosdb.py       # Memory persistence using Cosmos DB
│   ├── tools
│   │   └── mcp_github.py     # Interactions with GitHub via MCP tool
│   └── config
│       └── settings.py       # Configuration settings for the application
├── Dockerfile                 # Instructions for building the Docker image
├── requirements.txt           # Python dependencies for the project
├── README.md                  # Documentation for the project
└── .azure
    ├── containerapp.bicep    # Bicep template for Azure Container App deployment
    ├── acr.bicep             # Bicep template for Azure Container Registry setup
    ├── cosmosdb.bicep        # Bicep template for Azure Cosmos DB provisioning
    ├── ai_search.bicep       # Bicep template for Azure AI Search configuration
    └── waf.bicep             # Bicep template for Web Application Firewall rules
```

## Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd azure-ai-foundry-agent
   ```

2. **Install Dependencies**
   Ensure you have Python 3.8 or higher installed. Then, install the required packages:
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure Environment Variables**
   Set up the necessary environment variables for sensitive information such as API keys and connection strings in the `src/config/settings.py` file.

4. **Build the Docker Image**
   Use the following command to build the Docker image:
   ```bash
   docker build -t <image-name> .
   ```

5. **Deploy to Azure**
   Use the provided Bicep templates in the `.azure` directory to deploy the application to Azure services.

## Usage

To run the application, execute the following command:
```bash
python src/main.py
```

## Architecture Overview

The application is designed to be modular, with separate components handling different functionalities:

- **Agent**: The core logic of the AI agent, responsible for processing user inputs and orchestrating interactions.
- **Models**: Interfaces with the GPT-4o model to generate responses.
- **RAG**: Utilizes Azure AI Search to retrieve relevant documents for enhanced responses.
- **Memory**: Manages memory persistence using Azure Cosmos DB.
- **Tools**: Integrates with GitHub through the MCP tool for additional functionalities.

## Teaching Example

This project serves as an effective teaching example for an O'Reilly class, demonstrating best practices in building and deploying AI applications on Azure, including architecture design, modular coding, and cloud deployment strategies.