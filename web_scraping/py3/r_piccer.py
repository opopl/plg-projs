#!/usr/bin/env python3

from Base.Scraper.Piccer.Piccer import Piccer
import os

dirname = os.path.dirname(__file__)
script  = os.path.realpath(__file__)

r = { 
  'files' : {
    'script' : script
  },
  'dirs' : {}
}

Piccer(r).main()
