import { createServer } from "node:http";

const port = Number(process.env.PORT || 3000);

const server = createServer((request, response) => {
  const payload = {
    app: "demo-service",
    mode: "demo",
    method: request.method,
    url: request.url,
    status: "ok"
  };

  response.writeHead(200, { "content-type": "application/json; charset=utf-8" });
  response.end(JSON.stringify(payload, null, 2));
});

server.listen(port, () => {
  console.log(`demo-service listening on http://localhost:${port}`);
});