# app.py
from http.server import BaseHTTPRequestHandler, HTTPServer

class handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        message = {
            "email": "yourname@example.com",
            "current_datetime": "2025-10-22T03:50:00Z",
            "github_url": "https://github.com/Collinsthegreat/hng13-stage1-devops"
        }
        import json
        self.wfile.write(json.dumps(message).encode())

if __name__ == "__main__":
    server = HTTPServer(('', 8000), handler)
    print("Server running on port 8000...")
    server.serve_forever()
