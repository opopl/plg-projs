#!/usr/bin/env python3

from Base.Scraper.LTS.LTS import LTS
import os

dirname = os.path.dirname(__file__)
script  = os.path.realpath(__file__)

r = { 
  'files' : {
    'script' : script
  },
  'dirs' : {}
}

LTS(r).main()

#[method for method in dir(meta) if method.startswith('__') is False]
#https://code.activestate.com/recipes/577346-getattr-with-arbitrary-depth/
