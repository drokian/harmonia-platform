from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        payload = {
            "app": "commercial-service",
            "mode": "commercial",
            "path": self.path,
            "status": "ok",
            "edition": os.getenv("APP_EDITION", "standard"),
        }
        body = json.dumps(payload).encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8100"))
    server = HTTPServer(("127.0.0.1", port), Handler)
    print(f"commercial-service listening on http://127.0.0.1:{port}")
    server.serve_forever()