const http = require('http');

const server = http.createServer((req, res) => {
  // Set CORS headers for Flutter Web
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-tenant-id');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Forward the request to the SACHI backend
  // We MUST delete the 'origin' header so the backend doesn't trigger its strict CORS checks
  const forwardedHeaders = { ...req.headers, host: 'localhost:3109' };
  delete forwardedHeaders['origin'];

  const options = {
    hostname: 'localhost',
    port: 3109,
    path: req.url,
    method: req.method,
    headers: forwardedHeaders
  };

  const proxyReq = http.request(options, (proxyRes) => {
    // We don't want the backend's strict CORS headers to override ours
    const headers = proxyRes.headers;
    delete headers['access-control-allow-origin'];
    delete headers['access-control-allow-credentials'];

    res.writeHead(proxyRes.statusCode, headers);
    proxyRes.pipe(res, { end: true });
  });

  req.pipe(proxyReq, { end: true });
  
  proxyReq.on('error', (e) => {
    console.error('Proxy Error:', e.message);
    res.writeHead(500);
    res.end();
  });
});

server.listen(3110, () => {
  console.log('✅ Local CORS Proxy running on http://localhost:3110');
  console.log('Forwarding requests to http://localhost:3109');
});
