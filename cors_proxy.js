/**
 * Local CORS proxy for Flutter Web → platform API.
 *
 * Usage:
 *   node cors_proxy.js
 *
 * Then in .env set:
 *   WEB_BASE_URL=http://localhost:3110/api/v1/sachi
 */
const http = require('http');
const https = require('https');
const { URL } = require('url');

const LISTEN_PORT = Number(process.env.CORS_PROXY_PORT || 3110);
const TARGET_ORIGIN =
  process.env.PLATFORM_API_ORIGIN || 'https://anwaya.mediastra.ai';
const target = new URL(TARGET_ORIGIN);
const transport = target.protocol === 'https:' ? https : http;

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers':
    'Content-Type, Authorization, Accept, x-tenant-id, x-user-id, x-gateway-authenticated, x-permissions, x-user-permissions, x-service-code, x-client-id',
  'Access-Control-Max-Age': '86400',
};

const server = http.createServer((req, res) => {
  Object.entries(CORS_HEADERS).forEach(([key, value]) => {
    res.setHeader(key, value);
  });

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const forwardedHeaders = { ...req.headers };
  forwardedHeaders.host = target.host;
  delete forwardedHeaders.origin;
  delete forwardedHeaders.referer;
  delete forwardedHeaders['content-length'];

  const options = {
    protocol: target.protocol,
    hostname: target.hostname,
    port: target.port || (target.protocol === 'https:' ? 443 : 80),
    path: req.url,
    method: req.method,
    headers: forwardedHeaders,
  };

  const proxyReq = transport.request(options, (proxyRes) => {
    const headers = { ...proxyRes.headers };
    delete headers['access-control-allow-origin'];
    delete headers['access-control-allow-credentials'];
    delete headers['access-control-allow-headers'];
    delete headers['access-control-allow-methods'];
    delete headers['cross-origin-resource-policy'];
    delete headers['cross-origin-opener-policy'];

    Object.entries(CORS_HEADERS).forEach(([key, value]) => {
      headers[key.toLowerCase()] = value;
    });

    res.writeHead(proxyRes.statusCode || 502, headers);
    proxyRes.pipe(res, { end: true });
  });

  proxyReq.on('error', (error) => {
    console.error('Proxy Error:', error.message);
    if (!res.headersSent) {
      res.writeHead(502, { 'Content-Type': 'application/json' });
    }
    res.end(
      JSON.stringify({
        success: false,
        error: {
          code: 'PROXY_ERROR',
          message: error.message,
        },
      }),
    );
  });

  req.pipe(proxyReq, { end: true });
});

server.listen(LISTEN_PORT, () => {
  console.log(`CORS proxy listening on http://localhost:${LISTEN_PORT}`);
  console.log(`Forwarding to ${TARGET_ORIGIN}`);
});
