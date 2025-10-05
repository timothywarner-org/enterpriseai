const env = require('./environment');
const { loadKnowledgeBase, saveVectorStore } = require('./vectorStore');
const { createEmbedding } = require('./azureOpenAI');

async function main() {
  console.log('Using Azure OpenAI endpoint:', env.endpoint);
  const documents = await loadKnowledgeBase();
  console.log(`Loaded ${documents.length} knowledge chunks.`);

  const vectors = [];
  for (const doc of documents) {
    console.log(`Embedding chunk ${doc.id}`);
    const embedding = await createEmbedding(`${doc.heading}\n${doc.content}`);
    vectors.push({
      ...doc,
      embedding
    });
  }

  await saveVectorStore(vectors);
  console.log('Vector store generated at data/vector-store.json');
}

main().catch((error) => {
  console.error('Failed to prepare vector store:', error);
  process.exit(1);
});
