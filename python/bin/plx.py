#!/usr/bin/env python3

#from Extern.Pylatex.document import Document
from Extern.Pylatex.document import *

geometry_options = {
   "landscape"       : True,
   "margin"          : "1.5in",
   "headheight"      : "20pt",
   "headsep"         : "10pt",
   "includeheadfoot" : True
}

doc = Document('basic',page_numbers=True, geometry_options=geometry_options)

doc.packages.append(Package("caratula"))
doc.generate_tex('base')

#d = Document()
#d.generate_tex()
doc.generate_tex('a')
import pdb; pdb.set_trace()
