
function! projs#bs#cmd#run ()
  
endfunction

function! projs#bs#cmd#site_view ()
python3 << eof
import vim
import os
import Base.Util as util
from Base.Scraper.Engine import BS

plg = os.environ.get('PLG')
libs = []
lib = os.path.join(plg,'projs web_scraping py3')
libs.append(lib)
util.add_libs(libs)

eof
  
endfunction
