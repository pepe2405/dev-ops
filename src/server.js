import express from 'express';

const app = express();
app.disable('x-powered-by');

app.get('/healthz', (_req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Example endpoint (kept intentionally simple)
app.get('/', (_req, res) => {
  res.type('text/plain').send('secure-ci-cd-pipeline-demo');
});

export function createServer() {
  return app;
}

// Only listen when invoked directly (not during tests)
if (import.meta.url === `file://${process.argv[1]}`) {
  const port = process.env.PORT ? Number(process.env.PORT) : 3000;
  app.listen(port, () => {
    console.log(`Listening on :${port}`);
  });
}
