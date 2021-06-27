#!/usr/bin/env python3

from Base.Scraper.FBS import FBS
import os

dirname = os.path.dirname(__file__)
script  = os.path.realpath(__file__)

r = { 
  'files' : {
    'script' : script
  },
  'dirs' : {}
}

FBS(r).main()
