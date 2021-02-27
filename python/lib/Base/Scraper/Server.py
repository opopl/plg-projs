
import os,sys,re

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

import json

from Base.Zlan import Zlan
from Base.Core import CoreClass

from http.server import BaseHTTPRequestHandler, HTTPServer

class Srv(CoreClass,BaseHTTPRequestHandler):
    def __init__(self,ref={}):
      super().__init__(ref)

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(bytes("<html><head><title>https://pythonbasics.org</title></head>", "utf-8"))
        self.wfile.write(bytes("<p>Request: %s</p>" % self.path, "utf-8"))
        self.wfile.write(bytes("<body>", "utf-8"))
        self.wfile.write(bytes("<p>This is an example web server.</p>", "utf-8"))
        self.wfile.write(bytes("</body></html>", "utf-8"))


