const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT ? Number(process.env.PORT) : 5173;
const baseDir = path.resolve(__dirname);

const mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

function safeJoin(base, target) {
  const targetPath = path.posix.normalize(target).replace(/^\/+/, '');
  return path.join(base, targetPath);
}

const server = http.createServer((req, res) => {
  try {
    const urlPath = req.url.split('?')[0];
    let filePath = safeJoin(baseDir, urlPath);

    // If root, serve an index-like page list
    if (urlPath === '/' || urlPath === '') {
      const indexHtml = `<!doctype html><html><head><meta charset="utf-8"><title>CDS528 Frontend</title></head><body><h1>CDS528 Frontend</h1><ul><li><a href="/achievement_reward_admin.html">achievement_reward_admin.html</a></li><li><a href="/achievement_reward_front.html">achievement_reward_front.html</a></li></ul></body></html>`;
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(indexHtml);
      return;
    }

    // If the path ends with '/', attempt index.html
    if (urlPath.endsWith('/')) {
      filePath = path.join(filePath, 'index.html');
    }

    fs.stat(filePath, (err, stats) => {
      if (err || !stats.isFile()) {
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('Not Found');
        return;
      }

      const ext = path.extname(filePath).toLowerCase();
      const contentType = mimeTypes[ext] || 'application/octet-stream';
      res.writeHead(200, { 'Content-Type': contentType });
      fs.createReadStream(filePath).pipe(res);
    });
  } catch (e) {
    res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Internal Server Error');
  }
});

server.listen(PORT, () => {
  console.log(`Dev server running at http://localhost:${PORT}/`);
  console.log(`Admin page: http://localhost:${PORT}/achievement_reward_admin.html`);
  console.log(`Front page: http://localhost:${PORT}/achievement_reward_front.html`);
});