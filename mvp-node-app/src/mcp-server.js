const { McpServer, ResourceTemplate } = require('@modelcontextprotocol/sdk/server/mcp.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { z } = require('zod');
const path = require('path');
const { promises: fs } = require('fs');
const env = require('./environment');
const { answerQuestion, retrieveRelevantChunks } = require('./ragService');
const { loadKnowledgeBase } = require('./vectorStore');

async function startServer() {
  const server = new McpServer({
    name: 'enterpriseai-mvp',
    version: '1.0.0'
  });

  server.registerTool(
    'ask-course-assistant',
    {
      title: 'Ask the Enterprise AI course assistant',
      description: 'Answers Azure AI deployment questions grounded in the course FAQ.',
      inputSchema: {
        question: z.string().describe('Question about Azure AI, infrastructure, or the live demo flow')
      }
    },
    async ({ question }) => {
      const { answer, matches } = await answerQuestion(question);
      const sources = matches
        .map((match, index) => `${index + 1}. ${match.source} > ${match.heading} (score ${match.score})`)
        .join('\n');

      return {
        content: [
          { type: 'text', text: answer },
          { type: 'text', text: `Sources:\n${sources}` }
        ]
      };
    }
  );

  server.registerTool(
    'retrieve-references',
    {
      title: 'Retrieve Azure AI reference chunks',
      description: 'Returns the top semantic matches without generating an LLM answer.',
      inputSchema: {
        question: z.string().describe('Search query to match against the knowledge base'),
        topK: z
          .number()
          .int()
          .min(1)
          .max(10)
          .optional()
          .describe('How many results to return (default 3)')
      }
    },
    async ({ question, topK }) => {
      const matches = await retrieveRelevantChunks(question, topK ?? 3);
      return {
        content: [
          {
            type: 'text',
            text: matches
              .map(
                (match, index) =>
                  `${index + 1}. ${match.source} > ${match.heading}\nScore: ${match.score.toFixed(4)}\n${match.content}`
              )
              .join('\n\n')
          }
        ]
      };
    }
  );

  const knowledgeTemplate = new ResourceTemplate('knowledge://{slug}', {
    list: async () => {
      const docs = await loadKnowledgeBase();
      const slugs = new Map();
      for (const doc of docs) {
        const [file] = doc.source.split('#');
        slugs.set(file.replace(/\.md$/, ''), file);
      }
      return {
        resources: Array.from(slugs.entries()).map(([slug, file]) => ({
          uri: `knowledge://${slug}`,
          name: slug,
          description: `Markdown source file ${file}`
        }))
      };
    }
  });

  server.registerResource(
    'knowledge-base',
    knowledgeTemplate,
    {
      title: 'Course knowledge base',
      description: 'Markdown sources used to ground the RAG responses.'
    },
    async (uri) => {
      const slug = uri.pathname.replace(/^\//, '');
      const fileName = `${slug}.md`;
      const fullPath = path.resolve(__dirname, '..', 'data', 'knowledge-base', fileName);
      const text = await fs.readFile(fullPath, 'utf-8');
      return {
        contents: [
          {
            uri: uri.href,
            text
          }
        ]
      };
    }
  );

  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('MCP server ready. Connect your MCP-compatible client.');
  console.error(`Vector store: ${path.resolve(__dirname, '..', 'data', 'vector-store.json')}`);
  console.error(`Azure endpoint: ${env.endpoint}`);
}

startServer().catch((error) => {
  console.error('Failed to start MCP server:', error);
  process.exit(1);
});
