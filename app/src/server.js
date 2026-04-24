import express from 'express';
import os from 'os';

const app = express();
const port = parseInt(process.env.PORT ?? '8080', 10);

const region = process.env.REGION ?? 'unknown';
const env = process.env.ENV ?? 'unknown';
const podName = process.env.POD_NAME ?? os.hostname();
const nodeName = process.env.NODE_NAME ?? 'unknown';
const version = process.env.APP_VERSION ?? 'dev';

let ready = false;
let shuttingDown = false;

app.disable('x-powered-by');

app.get('/healthz', (_req, res) => {
  if (shuttingDown) {
    res.status(503).json({ status: 'shutting-down' });
    return;
  }
  res.status(200).json({ status: 'ok' });
});

app.get('/readyz', (_req, res) => {
  if (ready && !shuttingDown) {
    res.status(200).json({ status: 'ready' });
  } else {
    res.status(503).json({ status: shuttingDown ? 'shutting-down' : 'starting' });
  }
});

app.get('/', (_req, res) => {
  const started = process.uptime().toFixed(1);
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.status(200).send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>web-${env}-${region}</title>
  <style>
    :root { color-scheme: light dark; font-family: system-ui, sans-serif; }
    body { max-width: 640px; margin: 4rem auto; padding: 0 1rem; }
    h1 { margin-bottom: 0; }
    dl { display: grid; grid-template-columns: auto 1fr; gap: 0.25rem 1rem; }
    dt { font-weight: 600; color: #666; }
    code { font-family: ui-monospace, monospace; }
  </style>
</head>
<body>
  <h1>web front-end</h1>
  <p>Served from <strong>${region}</strong> (${env})</p>
  <dl>
    <dt>env</dt><dd><code>${env}</code></dd>
    <dt>region</dt><dd><code>${region}</code></dd>
    <dt>pod</dt><dd><code>${podName}</code></dd>
    <dt>node</dt><dd><code>${nodeName}</code></dd>
    <dt>version</dt><dd><code>${version}</code></dd>
    <dt>uptime</dt><dd><code>${started}s</code></dd>
  </dl>
</body>
</html>
`);
});

const server = app.listen(port, () => {
  console.log(JSON.stringify({ msg: 'listening', port, env, region, pod: podName, version }));
  setTimeout(() => {
    ready = true;
    console.log(JSON.stringify({ msg: 'ready' }));
  }, 2000);
});

function shutdown(signal) {
  if (shuttingDown) return;
  shuttingDown = true;
  console.log(JSON.stringify({ msg: 'shutdown', signal }));
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(1), 15000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
