#!/usr/bin/env python3
"""
Simple HTTP server to serve the frontend files
"""

import http.server
import socketserver
import os
from pathlib import Path

# Get the frontend directory
FRONTEND_DIR = Path(__file__).parent / "frontend"

# Change to the frontend directory
os.chdir(FRONTEND_DIR)

# Set up a simple HTTP server
PORT = 8080
Handler = http.server.SimpleHTTPRequestHandler

print(f"Starting server at http://localhost:{PORT}")
print(f"Serving files from: {FRONTEND_DIR}")

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print("Server started. Press Ctrl+C to stop.")
    httpd.serve_forever()
