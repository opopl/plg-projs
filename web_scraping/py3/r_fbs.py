#!/usr/bin/env python3

from Base.Scraper.FBS.FBS import FBS
from Base.Scraper.FBS.ShellFBS import ShellFBS
import os

dirname = os.path.dirname(__file__)
script  = os.path.realpath(__file__)

r = { 
  'files' : {
    'script' : script
  },
  'dirs' : {},
}

fbs = FBS(r)

fbs.main()
