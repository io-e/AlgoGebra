#!/usr/bin/env python3
# GROK_V1 minimal localhost CGI front for a COPY of WIMS 4.31b (GB-R5). Serves /wims/wims.cgi + static public_html.
import http.server, subprocess, os, sys, urllib.parse
ROOT=sys.argv[1]; PORT=int(sys.argv[2])
class H(http.server.SimpleHTTPRequestHandler):
    def __init__(s,*a,**k): super().__init__(*a,directory=ROOT,**k)
    def translate_path(s,p):
        p=p.split('?')[0]
        if p.startswith('/wims/'): p=p[5:]
        return super().translate_path(p)
    def cgi(s,method):
        u=urllib.parse.urlsplit(s.path)
        if not u.path.endswith('wims.cgi'): return False
        body=s.rfile.read(int(s.headers.get('Content-Length') or 0)) if method=='POST' else b''
        env=dict(os.environ,GATEWAY_INTERFACE='CGI/1.1',SERVER_SOFTWARE='gvpy',SERVER_NAME='127.0.0.1',SERVER_PORT=str(PORT),
          SERVER_PROTOCOL='HTTP/1.0',REQUEST_METHOD=method,QUERY_STRING=u.query,SCRIPT_NAME='/wims/wims.cgi',SCRIPT_FILENAME=ROOT+'/wims.cgi',
          REMOTE_ADDR='127.0.0.1',HTTP_HOST=f'127.0.0.1:{PORT}',HTTP_USER_AGENT=s.headers.get('User-Agent','gv'),HTTP_COOKIE=s.headers.get('Cookie',''),
          CONTENT_TYPE=s.headers.get('Content-Type',''),CONTENT_LENGTH=str(len(body)),DOCUMENT_ROOT=ROOT,REQUEST_URI=s.path)
        p=subprocess.run([ROOT+'/wims'],input=body,capture_output=True,cwd=ROOT,env=env,timeout=60)
        out=p.stdout; hdr,_,b=out.partition(b'\r\n\r\n') if b'\r\n\r\n' in out[:4000] else out.partition(b'\n\n')
        st=200; hs=[]
        for l in hdr.decode('latin-1').splitlines():
            if ':' not in l: continue
            k,v=l.split(':',1)
            if k.lower()=='status': st=int(v.split()[0])
            else: hs.append((k,v.strip()))
        s.send_response(st)
        for k,v in hs: s.send_header(k,v)
        s.end_headers(); s.wfile.write(b); return True
    def do_GET(s):
        if not s.cgi('GET'): super().do_GET()
    def do_POST(s): s.cgi('POST')
http.server.ThreadingHTTPServer(('127.0.0.1',PORT),H).serve_forever()
