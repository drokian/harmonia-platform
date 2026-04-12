import { createServer } from "node:http";

const port = Number(process.env.PORT || 4000);

const server = createServer((request, response) => {
  const payload = {
    app: "commercial-service",
    mode: "commercial",
    method: request.method,
    url: request.url,
    status: "ok",
    edition: process.env.APP_EDITION || "standard"
  };

  response.writeHead(200, { "content-type": "application/json; charset=utf-8" });
  response.end(JSON.stringify(payload, null, 2));
});

server.listen(port, () => {
  console.log(`commercial-service listening on http://localhost:${port}`);
});