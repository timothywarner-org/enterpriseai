const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

module.exports = {
  endpoint: requireEnv('AZURE_OPENAI_ENDPOINT'),
  apiKey: requireEnv('AZURE_OPENAI_API_KEY'),
  chatDeployment: requireEnv('AZURE_OPENAI_CHAT_DEPLOYMENT'),
  embeddingDeployment: requireEnv('AZURE_OPENAI_EMBEDDING_DEPLOYMENT'),
  port: process.env.PORT || 3000
};
