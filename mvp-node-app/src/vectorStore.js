const { promises: fs } = require('fs');
const path = require('path');
const { marked } = require('marked');

const VECTOR_STORE_PATH = path.resolve(__dirname, '..', 'data', 'vector-store.json');
const KNOWLEDGE_BASE_DIR = path.resolve(__dirname, '..', 'data', 'knowledge-base');

function chunkMarkdown(markdown, source) {
  const tokens = marked.lexer(markdown);
  const chunks = [];
  let currentHeading = 'Overview';
  let currentContent = [];

  for (const token of tokens) {
    if (token.type === 'heading' && token.depth <= 3) {
      if (currentContent.length > 0) {
        chunks.push({
          id: `${source}#${currentHeading.replace(/\s+/g, '-').toLowerCase()}`,
          heading: currentHeading,
          content: currentContent.join('\n').trim(),
          source
        });
      }
      currentHeading = token.text;
      currentContent = [];
    } else if (token.type === 'paragraph' || token.type === 'list') {
      currentContent.push(token.raw.trim());
    }
  }

  if (currentContent.length > 0) {
    chunks.push({
      id: `${source}#${currentHeading.replace(/\s+/g, '-').toLowerCase()}`,
      heading: currentHeading,
      content: currentContent.join('\n').trim(),
      source
    });
  }

  return chunks;
}

async function loadKnowledgeBase() {
  const entries = await fs.readdir(KNOWLEDGE_BASE_DIR);
  const documents = [];
  for (const entry of entries) {
    const fullPath = path.join(KNOWLEDGE_BASE_DIR, entry);
    const stats = await fs.stat(fullPath);
    if (!stats.isFile()) continue;
    const markdown = await fs.readFile(fullPath, 'utf-8');
    const chunks = chunkMarkdown(markdown, entry);
    documents.push(...chunks);
  }
  return documents;
}

async function saveVectorStore(vectors) {
  const payload = {
    generatedAt: new Date().toISOString(),
    vectors
  };
  await fs.writeFile(VECTOR_STORE_PATH, JSON.stringify(payload, null, 2), 'utf-8');
}

async function loadVectorStore() {
  try {
    const content = await fs.readFile(VECTOR_STORE_PATH, 'utf-8');
    return JSON.parse(content);
  } catch (error) {
    return null;
  }
}

function cosineSimilarity(a, b) {
  const dot = a.reduce((acc, val, idx) => acc + val * b[idx], 0);
  const normA = Math.sqrt(a.reduce((acc, val) => acc + val * val, 0));
  const normB = Math.sqrt(b.reduce((acc, val) => acc + val * val, 0));
  return dot / (normA * normB);
}

module.exports = {
  loadKnowledgeBase,
  saveVectorStore,
  loadVectorStore,
  cosineSimilarity,
  VECTOR_STORE_PATH
};
