#!/usr/bin/env python3
"""Localhost CGI front for a private WIMS tree. Does not bind 18431."""
import http.server, subprocess, os, sys, urllib.parse
ROOT = sys.argv[1]
PORT = int(sys.argv[2])
HOST = "127.0.0.1"
WIMS = os.path.join(ROOT, "wims")

class H(http.server.SimpleHTTPRequestHandler):
    def __init__(s, *a, **k):
        super().__init__(*a, directory=ROOT, **k)

    def translate_path(s, p):
        p = p.split("?", 1)[0]
        if p.startswith("/wims/"):
            p = p[5:]
        return super().translate_path(p)

    def cgi(s, method):
        u = urllib.parse.urlsplit(s.path)
        if "wims.cgi" not in u.path and not u.path.rstrip("/").endswith("/wims"):
            return False
        body = s.rfile.read(int(s.headers.get("Content-Length") or 0)) if method == "POST" else b""
        env = dict(
            os.environ,
            GATEWAY_INTERFACE="CGI/1.1",
            SERVER_SOFTWARE="mw-http",
            SERVER_NAME=HOST,
            SERVER_PORT=str(PORT),
            SERVER_PROTOCOL="HTTP/1.0",
            REQUEST_METHOD=method,
            QUERY_STRING=u.query,
            SCRIPT_NAME="/wims/wims.cgi",
            SCRIPT_FILENAME=os.path.join(ROOT, "wims.cgi"),
            REMOTE_ADDR="127.0.0.1",
            HTTP_HOST=f"{HOST}:{PORT}",
            HTTP_USER_AGENT=s.headers.get("User-Agent", "mw-http"),
            HTTP_COOKIE=s.headers.get("Cookie", ""),
            HTTP_ACCEPT_LANGUAGE=s.headers.get("Accept-Language", "fr"),
            CONTENT_TYPE=s.headers.get("Content-Type", ""),
            CONTENT_LENGTH=str(len(body)),
            DOCUMENT_ROOT=ROOT,
            REQUEST_URI=s.path,
        )
        p = subprocess.run([WIMS], input=body, capture_output=True, cwd=ROOT, env=env, timeout=120)
        out = p.stdout
        hdr, _, b = out.partition(b"\r\n\r\n") if b"\r\n\r\n" in out[:8000] else out.partition(b"\n\n")
        st = 200
        hs = []
        for l in hdr.decode("latin-1").splitlines():
            if ":" not in l:
                continue
            k, v = l.split(":", 1)
            if k.lower() == "status":
                try:
                    st = int(v.split()[0])
                except ValueError:
                    st = 200
            else:
                hs.append((k, v.strip()))
        s.send_response(st)
        for k, v in hs:
            s.send_header(k, v)
        s.end_headers()
        s.wfile.write(b)
        return True

    def do_GET(s):
        if not s.cgi("GET"):
            super().do_GET()

    def do_POST(s):
        s.cgi("POST")
    def do_HEAD(s):
        if not s.cgi("GET"):
            super().do_HEAD()

if __name__ == "__main__":
    http.server.ThreadingHTTPServer((HOST, PORT), H).serve_forever()
