#!/usr/bin/env python3

from Base.Scraper.Engine import BS
import os

r = { 
  'files' : {
    'script' : os.path.realpath(__file__)
  },
}

BS(r).main()

#[method for method in dir(meta) if method.startswith('__') is False]
#https://code.activestate.com/recipes/577346-getattr-with-arbitrary-depth/
