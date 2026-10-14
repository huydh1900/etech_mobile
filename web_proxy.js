// Reverse proxy cho Flutter web (etech_lab):
//  - Serve build static từ build/web (cùng origin => không CORS, cookie session tự chạy)
//  - Forward các path backend (/web, /api, /websocket, /longpolling, /mail, /report)
//    sang Odoo. Chạy: node web_proxy.js
const http = require('http');
const fs = require('fs');
const path = require('path');

// 0.0.0.0: nghe mọi interface → không chết khi IP LAN đổi (DHCP). Ghi đè: PROXY_HOST=...
const HOST = process.env.PROXY_HOST || '0.0.0.0';
const PORT = 5000;
const ODOO_HOST = '127.0.0.1';
const ODOO_PORT = 8001;
const WEB_ROOT = path.join(__dirname, 'build', 'web');

// Dev mode: nếu set FLUTTER_DEV_PORT, forward phần frontend sang Flutter dev
// server (flutter run -d web-server) thay vì serve build/web tĩnh => có hot
// restart, không cần `flutter build web` mỗi lần. Backend (/api,/web...) vẫn
// proxy về Odoo như cũ, cùng origin :5000 nên cookie session vẫn chạy.
const DEV_PORT = process.env.FLUTTER_DEV_PORT ? Number(process.env.FLUTTER_DEV_PORT) : 0;
const DEV_HOST = '127.0.0.1';

// Path nào thuộc backend Odoo (còn lại serve static / SPA fallback)
const BACKEND_PREFIXES = ['/web', '/api', '/websocket', '/longpolling', '/mail', '/report'];
const isBackend = (p) => BACKEND_PREFIXES.some((x) => p === x || p.startsWith(x + '/') || p.startsWith(x + '?'));

const MIME = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.css': 'text/css', '.json': 'application/json', '.wasm': 'application/wasm',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.gif': 'image/gif',
  '.svg': 'image/svg+xml', '.ico': 'image/x-icon', '.woff': 'font/woff', '.woff2': 'font/woff2',
  '.ttf': 'font/ttf', '.otf': 'font/otf', '.map': 'application/json',
};

function serveStatic(req, res) {
  let urlPath = decodeURIComponent(req.url.split('?')[0]);
  if (urlPath === '/') urlPath = '/index.html';
  let filePath = path.join(WEB_ROOT, urlPath);
  // chặn path traversal
  if (!filePath.startsWith(WEB_ROOT)) { res.writeHead(403); return res.end('Forbidden'); }
  fs.readFile(filePath, (err, data) => {
    if (err) {
      // SPA fallback: route không phải file -> trả index.html
      return fs.readFile(path.join(WEB_ROOT, 'index.html'), (e2, html) => {
        if (e2) { res.writeHead(404); return res.end('Not found'); }
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(html);
      });
    }
    const ext = path.extname(filePath).toLowerCase();
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
    res.end(data);
  });
}

function proxyTo(host, port, label, req, res) {
  const headers = { ...req.headers, host: `${host}:${port}` };
  const upstream = http.request(
    { host, port, method: req.method, path: req.url, headers },
    (up) => {
      res.writeHead(up.statusCode, up.headers); // truyền nguyên set-cookie
      up.pipe(res);
    }
  );
  upstream.on('error', (e) => {
    res.writeHead(502, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Bad gateway (' + label + ' ' + host + ':' + port + '): ' + e.message);
  });
  req.pipe(upstream);
}

const proxyToOdoo = (req, res) => proxyTo(ODOO_HOST, ODOO_PORT, 'Odoo', req, res);
const proxyToDev = (req, res) => proxyTo(DEV_HOST, DEV_PORT, 'Flutter dev', req, res);

http.createServer((req, res) => {
  if (isBackend(req.url.split('?')[0])) proxyToOdoo(req, res);
  else if (DEV_PORT) proxyToDev(req, res); // dev: forward sang flutter dev server
  else serveStatic(req, res);             // prod: serve build/web tĩnh
}).listen(PORT, HOST, () => {
  const front = DEV_PORT ? `Flutter dev :${DEV_PORT} (hot restart)` : `static build/web`;
  console.log(`Proxy ready: http://${HOST}:${PORT}  ->  Odoo ${ODOO_HOST}:${ODOO_PORT}  | frontend: ${front}`);
});
