const express = require('express');
const env = require('./environment');
const { answerQuestion, retrieveRelevantChunks } = require('./ragService');

const app = express();
app.use(express.json({ limit: '1mb' }));

app.get('/healthz', (_, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.post('/chat', async (req, res) => {
  const { question } = req.body;
  if (!question) {
    return res.status(400).json({ error: 'Missing `question` in request body.' });
  }

  try {
    const response = await answerQuestion(question);
    res.json(response);
  } catch (error) {
    console.error('Failed to answer question', error);
    res.status(500).json({
      error: error.message,
      hint: 'Confirm Azure OpenAI credentials and that `npm run prep` has been executed.'
    });
  }
});

app.post('/retrieve', async (req, res) => {
  const { question, topK } = req.body;
  if (!question) {
    return res.status(400).json({ error: 'Missing `question` in request body.' });
  }

  try {
    const matches = await retrieveRelevantChunks(question, topK ?? 3);
    res.json({ matches: matches.map(({ heading, content, source, score }) => ({
      heading,
      content,
      source,
      score: Number(score.toFixed(4))
    })) });
  } catch (error) {
    res.status(500).json({
      error: error.message,
      hint: 'Run `npm run prep` before calling /retrieve or /chat.'
    });
  }
});

app.listen(env.port, () => {
  console.log(`Enterprise AI MVP API listening on port ${env.port}`);
});
