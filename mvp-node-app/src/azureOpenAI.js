const { OpenAIClient, AzureKeyCredential } = require('@azure/openai');
const env = require('./environment');

const client = new OpenAIClient(env.endpoint, new AzureKeyCredential(env.apiKey));

async function createEmbedding(input) {
  const response = await client.getEmbeddings(env.embeddingDeployment, [input]);
  return response.data[0].embedding;
}

async function createChatCompletion(messages) {
  const response = await client.getChatCompletions(env.chatDeployment, messages, {
    temperature: 0.2,
    maxTokens: 600,
    topP: 0.9
  });
  const choice = response.choices?.[0];
  if (!choice) {
    throw new Error('No completion choices returned from Azure OpenAI.');
  }
  return choice.message.content;
}

module.exports = {
  createEmbedding,
  createChatCompletion
};
