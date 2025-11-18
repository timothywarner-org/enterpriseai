# Node.js Development Guide for Azure AI Services

> **Author:** Tim Warner | **Course:** O'Reilly Enterprise AI Deployment on Azure
> **Last Updated:** 2025-01-18

This guide covers best practices for building Node.js applications with Azure OpenAI and Azure AI Services using the latest SDKs.

## Table of Contents

1. [SDK Overview](#sdk-overview)
2. [Project Setup](#project-setup)
3. [Authentication](#authentication)
4. [Azure OpenAI Integration](#azure-openai-integration)
5. [Azure AI Search Integration](#azure-ai-search-integration)
6. [RAG Implementation](#rag-implementation)
7. [Error Handling](#error-handling)
8. [Performance Optimization](#performance-optimization)
9. [Security Best Practices](#security-best-practices)
10. [Testing](#testing)

---

## SDK Overview

### Latest SDK Versions (January 2025)

| Package | Version | Purpose |
|---------|---------|---------|
| `@azure/openai` | `^2.0.0` | Azure OpenAI API client |
| `@azure/search-documents` | `^12.2.0` | Azure AI Search client |
| `@azure/identity` | `^4.5.0` | Azure authentication |
| `@azure/keyvault-secrets` | `^4.9.0` | Key Vault access |
| `express` | `^4.21.2` | Web framework |
| `dotenv` | `^16.4.7` | Environment variables |
| `zod` | `^3.25.76` | Schema validation |

### What's New in @azure/openai 2.0.0

- ✅ **Stable Release** - No longer in beta
- ✅ **Streaming Support** - Built-in streaming for chat completions
- ✅ **Function Calling** - Full support for OpenAI function calling
- ✅ **Vision Support** - GPT-4 Vision integration
- ✅ **DALL-E 3** - Image generation support
- ✅ **Better Error Handling** - Typed error responses
- ✅ **TypeScript First** - Full TypeScript support

---

## Project Setup

### Initialize a New Project

```bash
# Create project directory
mkdir my-ai-app && cd my-ai-app

# Initialize package.json
npm init -y

# Install dependencies
npm install @azure/openai @azure/identity @azure/search-documents dotenv express zod

# Install dev dependencies
npm install -D @types/node @types/express typescript tsx nodemon

# Initialize TypeScript
npx tsc --init
```

### Package.json Configuration

```json
{
  "name": "azure-ai-app",
  "version": "1.0.0",
  "description": "Enterprise AI application with Azure OpenAI",
  "main": "dist/index.js",
  "type": "module",
  "engines": {
    "node": ">=18.0.0"
  },
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "jest",
    "lint": "eslint src/**/*.ts"
  },
  "keywords": ["azure", "openai", "ai", "enterprise"],
  "author": "Your Name",
  "license": "MIT",
  "dependencies": {
    "@azure/identity": "^4.5.0",
    "@azure/openai": "^2.0.0",
    "@azure/search-documents": "^12.2.0",
    "dotenv": "^16.4.7",
    "express": "^4.21.2",
    "zod": "^3.25.76"
  },
  "devDependencies": {
    "@types/express": "^5.0.0",
    "@types/node": "^22.0.0",
    "tsx": "^4.19.2",
    "typescript": "^5.7.2"
  }
}
```

### Environment Variables

Create a `.env` file:

```bash
# Azure OpenAI Configuration
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4
AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT=text-embedding-ada-002
AZURE_OPENAI_API_VERSION=2024-10-21

# Azure AI Search Configuration
AZURE_SEARCH_ENDPOINT=https://your-search.search.windows.net
AZURE_SEARCH_INDEX_NAME=documents

# Authentication (choose one)
# Option 1: Managed Identity (Production - Recommended)
AZURE_CLIENT_ID=your-managed-identity-client-id

# Option 2: Service Principal (CI/CD)
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_SECRET=your-client-secret

# Option 3: API Keys (Development Only - Not Recommended)
AZURE_OPENAI_API_KEY=your-api-key
AZURE_SEARCH_API_KEY=your-search-key

# Application Configuration
PORT=3000
LOG_LEVEL=info
NODE_ENV=development
```

**⚠️ Security:** Never commit `.env` files to source control. Add to `.gitignore`:

```bash
echo ".env" >> .gitignore
```

---

## Authentication

### 1. Managed Identity (Production - Recommended)

```typescript
import { DefaultAzureCredential } from '@azure/identity';
import { OpenAIClient } from '@azure/openai';

const credential = new DefaultAzureCredential();
const endpoint = process.env.AZURE_OPENAI_ENDPOINT!;

const client = new OpenAIClient(endpoint, credential);
```

**Benefits:**
- ✅ No secrets to manage
- ✅ Automatic token refresh
- ✅ Works in Azure (VMs, App Service, AKS, etc.)
- ✅ Supports local development with Azure CLI

**Local Development Setup:**

```bash
# Login to Azure CLI
az login

# Set default subscription
az account set --subscription "your-subscription-id"

# Verify identity
az account show
```

### 2. Service Principal (CI/CD)

```typescript
import { ClientSecretCredential } from '@azure/identity';
import { OpenAIClient } from '@azure/openai';

const credential = new ClientSecretCredential(
  process.env.AZURE_TENANT_ID!,
  process.env.AZURE_CLIENT_ID!,
  process.env.AZURE_CLIENT_SECRET!
);

const endpoint = process.env.AZURE_OPENAI_ENDPOINT!;
const client = new OpenAIClient(endpoint, credential);
```

### 3. API Key (Development Only)

```typescript
import { AzureKeyCredential } from '@azure/openai';
import { OpenAIClient } from '@azure/openai';

const credential = new AzureKeyCredential(process.env.AZURE_OPENAI_API_KEY!);
const endpoint = process.env.AZURE_OPENAI_ENDPOINT!;

const client = new OpenAIClient(endpoint, credential);
```

**⚠️ Warning:** API keys should only be used for local development. Always use managed identities in production.

---

## Azure OpenAI Integration

### Basic Chat Completion

```typescript
import { OpenAIClient } from '@azure/openai';
import { DefaultAzureCredential } from '@azure/identity';

const client = new OpenAIClient(
  process.env.AZURE_OPENAI_ENDPOINT!,
  new DefaultAzureCredential()
);

async function chatCompletion(userMessage: string) {
  const deploymentName = process.env.AZURE_OPENAI_DEPLOYMENT_NAME!;

  try {
    const result = await client.getChatCompletions(deploymentName, [
      {
        role: 'system',
        content: 'You are a helpful AI assistant for enterprise applications.'
      },
      {
        role: 'user',
        content: userMessage
      }
    ]);

    const response = result.choices[0]?.message?.content;
    const tokensUsed = result.usage?.totalTokens ?? 0;

    console.log(`Response: ${response}`);
    console.log(`Tokens used: ${tokensUsed}`);

    return { response, tokensUsed };
  } catch (error) {
    console.error('OpenAI API error:', error);
    throw error;
  }
}

// Usage
await chatCompletion('What are Azure best practices?');
```

### Streaming Responses

```typescript
async function streamChatCompletion(userMessage: string) {
  const deploymentName = process.env.AZURE_OPENAI_DEPLOYMENT_NAME!;

  const events = await client.streamChatCompletions(deploymentName, [
    {
      role: 'system',
      content: 'You are a helpful AI assistant.'
    },
    {
      role: 'user',
      content: userMessage
    }
  ]);

  let fullResponse = '';

  for await (const event of events) {
    for (const choice of event.choices) {
      const delta = choice.delta?.content;
      if (delta) {
        fullResponse += delta;
        process.stdout.write(delta); // Stream to console
      }
    }
  }

  console.log('\n--- Streaming complete ---');
  return fullResponse;
}
```

### Function Calling

```typescript
import { FunctionDefinition } from '@azure/openai';

const functions: FunctionDefinition[] = [
  {
    name: 'get_current_weather',
    description: 'Get the current weather in a given location',
    parameters: {
      type: 'object',
      properties: {
        location: {
          type: 'string',
          description: 'The city and state, e.g. San Francisco, CA'
        },
        unit: {
          type: 'string',
          enum: ['celsius', 'fahrenheit']
        }
      },
      required: ['location']
    }
  }
];

async function chatWithFunctions(userMessage: string) {
  const deploymentName = process.env.AZURE_OPENAI_DEPLOYMENT_NAME!;

  const result = await client.getChatCompletions(
    deploymentName,
    [
      {
        role: 'user',
        content: userMessage
      }
    ],
    {
      functions,
      functionCall: 'auto' // Let the model decide when to call functions
    }
  );

  const choice = result.choices[0];

  if (choice.message?.functionCall) {
    const functionName = choice.message.functionCall.name;
    const functionArgs = JSON.parse(choice.message.functionCall.arguments);

    console.log(`Function called: ${functionName}`);
    console.log(`Arguments:`, functionArgs);

    // Execute the function (implement your logic here)
    const functionResult = await executeFunction(functionName, functionArgs);

    // Send function result back to the model
    const finalResult = await client.getChatCompletions(deploymentName, [
      {
        role: 'user',
        content: userMessage
      },
      choice.message,
      {
        role: 'function',
        name: functionName,
        content: JSON.stringify(functionResult)
      }
    ]);

    return finalResult.choices[0]?.message?.content;
  }

  return choice.message?.content;
}

async function executeFunction(name: string, args: any) {
  // Implement your function logic
  if (name === 'get_current_weather') {
    return {
      location: args.location,
      temperature: 72,
      unit: args.unit || 'fahrenheit',
      forecast: 'sunny'
    };
  }
}
```

### Generating Embeddings

```typescript
async function generateEmbedding(text: string): Promise<number[]> {
  const deploymentName = process.env.AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT!;

  const result = await client.getEmbeddings(deploymentName, [text]);

  return result.data[0].embedding;
}

// Usage
const embedding = await generateEmbedding('Azure OpenAI is powerful');
console.log(`Embedding dimensions: ${embedding.length}`); // 1536 for ada-002
```

---

## Azure AI Search Integration

### Initialize Search Client

```typescript
import { SearchClient, AzureKeyCredential } from '@azure/search-documents';
import { DefaultAzureCredential } from '@azure/identity';

interface Document {
  id: string;
  title: string;
  content: string;
  category: string;
  embedding?: number[];
}

const endpoint = process.env.AZURE_SEARCH_ENDPOINT!;
const indexName = process.env.AZURE_SEARCH_INDEX_NAME!;

// With Managed Identity (Recommended)
const credential = new DefaultAzureCredential();
const searchClient = new SearchClient<Document>(endpoint, indexName, credential);

// With API Key (Development)
// const credential = new AzureKeyCredential(process.env.AZURE_SEARCH_API_KEY!);
// const searchClient = new SearchClient<Document>(endpoint, indexName, credential);
```

### Upload Documents

```typescript
async function uploadDocuments(documents: Document[]) {
  const result = await searchClient.uploadDocuments(documents);

  console.log(`Uploaded ${result.results.length} documents`);

  // Check for errors
  const errors = result.results.filter(r => !r.succeeded);
  if (errors.length > 0) {
    console.error('Upload errors:', errors);
  }

  return result;
}

// Usage
await uploadDocuments([
  {
    id: '1',
    title: 'Azure Best Practices',
    content: 'Azure provides comprehensive cloud services...',
    category: 'cloud'
  }
]);
```

### Search Documents (Keyword Search)

```typescript
async function searchDocuments(query: string) {
  const searchResults = await searchClient.search(query, {
    top: 5,
    select: ['id', 'title', 'content', 'category'],
    searchFields: ['title', 'content'],
    orderBy: ['search.score() desc']
  });

  const results = [];
  for await (const result of searchResults.results) {
    results.push({
      score: result.score,
      document: result.document
    });
  }

  return results;
}
```

### Vector Search (Semantic Search)

```typescript
async function vectorSearch(query: string) {
  // Generate embedding for the query
  const queryEmbedding = await generateEmbedding(query);

  const searchResults = await searchClient.search(query, {
    vectorQueries: [
      {
        kind: 'vector',
        vector: queryEmbedding,
        fields: ['embedding'],
        kNearestNeighborsCount: 5
      }
    ],
    select: ['id', 'title', 'content', 'category'],
    top: 5
  });

  const results = [];
  for await (const result of searchResults.results) {
    results.push({
      score: result.score,
      document: result.document
    });
  }

  return results;
}
```

### Hybrid Search (Keyword + Vector)

```typescript
async function hybridSearch(query: string) {
  const queryEmbedding = await generateEmbedding(query);

  const searchResults = await searchClient.search(query, {
    vectorQueries: [
      {
        kind: 'vector',
        vector: queryEmbedding,
        fields: ['embedding'],
        kNearestNeighborsCount: 5
      }
    ],
    searchFields: ['title', 'content'],
    select: ['id', 'title', 'content', 'category'],
    top: 5
  });

  const results = [];
  for await (const result of searchResults.results) {
    results.push({
      score: result.score,
      document: result.document
    });
  }

  return results;
}
```

---

## RAG Implementation

### Complete RAG Pipeline

```typescript
import { OpenAIClient } from '@azure/openai';
import { SearchClient } from '@azure/search-documents';
import { DefaultAzureCredential } from '@azure/identity';

class RAGService {
  private openAIClient: OpenAIClient;
  private searchClient: SearchClient<Document>;
  private deploymentName: string;
  private embeddingsDeployment: string;

  constructor() {
    const credential = new DefaultAzureCredential();

    this.openAIClient = new OpenAIClient(
      process.env.AZURE_OPENAI_ENDPOINT!,
      credential
    );

    this.searchClient = new SearchClient<Document>(
      process.env.AZURE_SEARCH_ENDPOINT!,
      process.env.AZURE_SEARCH_INDEX_NAME!,
      credential
    );

    this.deploymentName = process.env.AZURE_OPENAI_DEPLOYMENT_NAME!;
    this.embeddingsDeployment = process.env.AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT!;
  }

  /**
   * Retrieve relevant documents using vector search
   */
  async retrieve(query: string, topK: number = 5): Promise<Document[]> {
    console.log(`🔍 Retrieving documents for query: "${query}"`);

    // Generate embedding for the query
    const embeddingResult = await this.openAIClient.getEmbeddings(
      this.embeddingsDeployment,
      [query]
    );
    const queryEmbedding = embeddingResult.data[0].embedding;

    // Vector search
    const searchResults = await this.searchClient.search(query, {
      vectorQueries: [
        {
          kind: 'vector',
          vector: queryEmbedding,
          fields: ['embedding'],
          kNearestNeighborsCount: topK
        }
      ],
      select: ['id', 'title', 'content', 'category'],
      top: topK
    });

    const documents: Document[] = [];
    for await (const result of searchResults.results) {
      documents.push(result.document);
    }

    console.log(`📚 Retrieved ${documents.length} relevant documents`);
    return documents;
  }

  /**
   * Augment the query with retrieved context
   */
  buildPrompt(query: string, documents: Document[]): string {
    const context = documents
      .map((doc, i) => `[${i + 1}] ${doc.title}\n${doc.content}`)
      .join('\n\n---\n\n');

    return `You are a helpful AI assistant. Answer the user's question based on the following context. If the answer is not in the context, say so.

Context:
${context}

User Question: ${query}

Answer:`;
  }

  /**
   * Generate response using retrieved context
   */
  async generate(
    query: string,
    documents: Document[]
  ): Promise<{ response: string; sources: Document[] }> {
    console.log(`🤖 Generating response...`);

    const prompt = this.buildPrompt(query, documents);

    const result = await this.openAIClient.getChatCompletions(
      this.deploymentName,
      [
        {
          role: 'system',
          content:
            'You are a helpful AI assistant that answers questions based on provided context.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      {
        temperature: 0.7,
        maxTokens: 800,
        topP: 0.95
      }
    );

    const response = result.choices[0]?.message?.content ?? 'No response generated.';

    console.log(`✅ Response generated (${result.usage?.totalTokens} tokens)`);

    return {
      response,
      sources: documents
    };
  }

  /**
   * Complete RAG pipeline: Retrieve + Augment + Generate
   */
  async query(userQuery: string, topK: number = 5) {
    const startTime = Date.now();

    // Step 1: Retrieve relevant documents
    const documents = await this.retrieve(userQuery, topK);

    // Step 2: Generate response with context
    const { response, sources } = await this.generate(userQuery, documents);

    const elapsed = Date.now() - startTime;
    console.log(`⏱️  Total time: ${elapsed}ms`);

    return {
      query: userQuery,
      response,
      sources: sources.map(doc => ({
        id: doc.id,
        title: doc.title
      })),
      elapsedMs: elapsed
    };
  }
}

// Usage
const ragService = new RAGService();
const result = await ragService.query('What are Azure OpenAI best practices?');

console.log('Response:', result.response);
console.log('Sources:', result.sources);
```

---

## Error Handling

### Robust Error Handling

```typescript
import { RestError } from '@azure/core-rest-pipeline';

async function safeChatCompletion(userMessage: string) {
  try {
    const result = await client.getChatCompletions(deploymentName, [
      { role: 'user', content: userMessage }
    ]);

    return result.choices[0]?.message?.content;
  } catch (error) {
    if (error instanceof RestError) {
      // Handle specific Azure errors
      if (error.statusCode === 429) {
        console.error('Rate limit exceeded. Retrying...');
        // Implement exponential backoff
        await sleep(2000);
        return safeChatCompletion(userMessage);
      } else if (error.statusCode === 401) {
        console.error('Authentication failed. Check credentials.');
      } else if (error.statusCode === 400) {
        console.error('Bad request:', error.message);
      } else {
        console.error(`Azure API error (${error.statusCode}):`, error.message);
      }
    } else {
      console.error('Unexpected error:', error);
    }

    throw error;
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

### Retry Logic with Exponential Backoff

```typescript
async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<T> {
  let lastError: Error;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;

      if (error instanceof RestError && error.statusCode === 429) {
        const delay = baseDelay * Math.pow(2, attempt);
        console.log(`Retry attempt ${attempt + 1} after ${delay}ms...`);
        await sleep(delay);
      } else {
        // Don't retry for non-rate-limit errors
        throw error;
      }
    }
  }

  throw lastError!;
}

// Usage
const response = await retryWithBackoff(() =>
  client.getChatCompletions(deploymentName, messages)
);
```

---

## Performance Optimization

### 1. Connection Pooling

Keep clients alive and reuse them:

```typescript
// ✅ GOOD - Singleton pattern
class OpenAIService {
  private static instance: OpenAIClient;

  static getClient(): OpenAIClient {
    if (!this.instance) {
      this.instance = new OpenAIClient(
        process.env.AZURE_OPENAI_ENDPOINT!,
        new DefaultAzureCredential()
      );
    }
    return this.instance;
  }
}

// ❌ BAD - Creating new client for each request
async function badPattern(message: string) {
  const client = new OpenAIClient(endpoint, credential); // Don't do this
  return await client.getChatCompletions(deploymentName, [/* ... */]);
}
```

### 2. Caching Responses

```typescript
import { createHash } from 'crypto';

class CachedRAGService extends RAGService {
  private cache = new Map<string, any>();

  private getCacheKey(query: string): string {
    return createHash('sha256').update(query.toLowerCase().trim()).digest('hex');
  }

  async query(userQuery: string, topK: number = 5) {
    const cacheKey = this.getCacheKey(userQuery);

    // Check cache
    if (this.cache.has(cacheKey)) {
      console.log('💾 Cache hit!');
      return this.cache.get(cacheKey);
    }

    // Execute query
    const result = await super.query(userQuery, topK);

    // Cache result (with TTL in production)
    this.cache.set(cacheKey, result);

    return result;
  }
}
```

### 3. Parallel Processing

```typescript
async function processMultipleQueries(queries: string[]) {
  // Process all queries in parallel
  const results = await Promise.all(
    queries.map(query => ragService.query(query))
  );

  return results;
}
```

---

## Security Best Practices

### 1. Input Validation

```typescript
import { z } from 'zod';

const chatRequestSchema = z.object({
  message: z.string().min(1).max(4000),
  conversationId: z.string().uuid().optional(),
  systemPrompt: z.string().max(2000).optional()
});

type ChatRequest = z.infer<typeof chatRequestSchema>;

async function handleChatRequest(req: any, res: any) {
  try {
    const validated = chatRequestSchema.parse(req.body);

    const response = await chatCompletion(validated.message);
    res.json({ response });
  } catch (error) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ error: 'Invalid request', details: error.errors });
    } else {
      res.status(500).json({ error: 'Internal server error' });
    }
  }
}
```

### 2. Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

app.use('/api/', apiLimiter);
```

### 3. Content Filtering

```typescript
async function chatWithContentFilter(userMessage: string) {
  const result = await client.getChatCompletions(deploymentName, [
    { role: 'user', content: userMessage }
  ]);

  // Check for content filtering
  const choice = result.choices[0];
  const contentFilterResults = choice.contentFilterResults;

  if (contentFilterResults) {
    const filtered = Object.values(contentFilterResults).some(
      (filter: any) => filter.severity === 'high'
    );

    if (filtered) {
      throw new Error('Content filtered due to policy violation');
    }
  }

  return choice.message?.content;
}
```

---

## Testing

### Unit Tests with Jest

```typescript
// ragService.test.ts
import { RAGService } from './ragService';

jest.mock('@azure/openai');
jest.mock('@azure/search-documents');

describe('RAGService', () => {
  let service: RAGService;

  beforeEach(() => {
    service = new RAGService();
  });

  it('should retrieve relevant documents', async () => {
    const documents = await service.retrieve('test query');

    expect(documents).toBeDefined();
    expect(Array.isArray(documents)).toBe(true);
  });

  it('should generate response with context', async () => {
    const mockDocuments = [
      { id: '1', title: 'Test', content: 'Test content', category: 'test' }
    ];

    const result = await service.generate('test query', mockDocuments);

    expect(result.response).toBeDefined();
    expect(result.sources).toEqual(mockDocuments);
  });

  it('should handle errors gracefully', async () => {
    // Mock an error
    jest.spyOn(service, 'retrieve').mockRejectedValue(new Error('API error'));

    await expect(service.query('test')).rejects.toThrow('API error');
  });
});
```

---

## Additional Resources

- [Azure OpenAI SDK Documentation](https://learn.microsoft.com/javascript/api/@azure/openai/)
- [Azure AI Search SDK Documentation](https://learn.microsoft.com/javascript/api/@azure/search-documents/)
- [Azure Identity SDK Documentation](https://learn.microsoft.com/javascript/api/@azure/identity/)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)

---

**Happy coding! 🚀**
