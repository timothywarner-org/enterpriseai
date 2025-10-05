const { loadVectorStore, cosineSimilarity } = require('./vectorStore');
const { createEmbedding, createChatCompletion } = require('./azureOpenAI');

let cachedVectors = null;

async function getVectorStore() {
  if (!cachedVectors) {
    const store = await loadVectorStore();
    if (!store || !store.vectors) {
      throw new Error('Vector store missing. Run `npm run prep` to generate embeddings.');
    }
    cachedVectors = store.vectors;
  }
  return cachedVectors;
}

async function retrieveRelevantChunks(question, topK = 3) {
  const vectors = await getVectorStore();
  const queryEmbedding = await createEmbedding(question);

  const scored = vectors.map((vector) => ({
    ...vector,
    score: cosineSimilarity(queryEmbedding, vector.embedding)
  }));

  scored.sort((a, b) => b.score - a.score);
  return scored.slice(0, topK);
}

function buildPrompt(question, contextChunks) {
  const context = contextChunks
    .map((chunk, index) => `Source ${index + 1}: ${chunk.source} > ${chunk.heading}\n${chunk.content}`)
    .join('\n\n');

  return [
    { role: 'system', content: 'You are an Azure AI solutions architect who grounds every answer in the provided sources.' },
    {
      role: 'user',
      content: `Use only the information in the sources to answer the question.\n\nSources:\n${context}\n\nQuestion: ${question}`
    }
  ];
}

async function answerQuestion(question) {
  const matches = await retrieveRelevantChunks(question);
  const messages = buildPrompt(question, matches);
  const answer = await createChatCompletion(messages);

  return {
    answer,
    matches: matches.map(({ heading, content, source, score }) => ({
      heading,
      content,
      source,
      score: Number(score.toFixed(4))
    }))
  };
}

module.exports = {
  retrieveRelevantChunks,
  answerQuestion
};
