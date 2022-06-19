import http.server
import socketserver
import os

build_web_dir = os.path.join(os.path.dirname(__file__), 'build/web')
os.chdir(build_web_dir)

with socketserver.TCPServer(("", 9000), http.server.SimpleHTTPRequestHandler) as server:
    print('serve')     
    server.serve_forever()
