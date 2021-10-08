#!/usr/bin/env python3

from Base.Scraper.FBS.FBS import FBS
from Base.Scraper.FBS.ShellFBS import ShellFBS
import os

dirname = os.path.dirname(__file__)
script  = os.path.realpath(__file__)

r = { 
  'files' : { 'script' : script },
  'dirs' : {},
}
#fbs = FBS(r)
#fbs.main()

from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
  return "Hello World!"

@app.route("/members/<string:name>/")
def getMember(name):
  return name

if __name__ == "__main__":
  app.run()
