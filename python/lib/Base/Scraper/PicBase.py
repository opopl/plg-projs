

import base64

import re,os,sys,stat

import cairosvg
import sqlite3

import shutil
import requests

import hashlib

from pathlib import Path

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

from Base.Core import CoreClass

from Base.Mix.mixFileSys import mixFileSys

from PIL import Image
from PIL import UnidentifiedImageError

class PicBase(
      CoreClass,
      mixFileSys
  ):

  width   = None
  caption = None

  # copied from 'alt' attribute
  alt     = None

  # sqlite imgs database file
  dbpath = None

  # database fields, see 'imgs' database
  dbcols = None

  # directory with images
  root   = None

  url        = None
  url_rel    = None
  url_parent = None
  baseurl    = None

  data = {}

  # image's content-type header
  ct = None

  src_attrs = util.qw('src data-src')

  # image's extension
  ext = None

  # BS element 
  el = None

  # ext => content-type
  map_ext_ct = {
   'jpe?g' : 'image/jpeg',
   'gif'   : 'image/gif',
   'png'   : 'image/png',
  }

  md5     = None

  # local (saved) path 
  path     = None
  path_uri = None

  # image server path
  path_uri_srv = None

  # opened Image instance, see grab() => load() => Image.open call
  i = None

  # short image path within img_root, e.g. 22.jpg
  img      = None
  inum     = None

  def __init__(pic,ref={}):
    pic.img_root  = os.environ.get('IMG_ROOT')

    super().__init__(ref)

    for k in util.qw('img_root'):
      pic.dirs[k] = util.get(pic,k) 

    if (not pic.dbpath) and pic.img_root:
      pic.dbpath = os.path.join(pic.img_root,'img.db')

    pic.dbcols = dbw._cols({
      'db_file' : pic.dbpath,
      'table'   : 'imgs',
    })

    pass

  def url_check_saved(pic):
    pic.img_saved = False

    url = pic.url

    if not url:
      return pic

    if not ( pic.dbpath and os.path.isfile(pic.dbpath) ):
      return pic
    else:
      q = '''SELECT img FROM imgs WHERE url = ?'''
      r = dbw.sql_fetchone(q,[url],{ 'db_file' : pic.dbpath })

      if r:
        img = r.get('row',{}).get('img')
        if img:
          ipath = os.path.join(pic.root, img)
          if os.path.isfile(ipath):
            pic.img_saved = True

    return pic

  def get_caption(pic):
    pic.caption = pic.alt or None
    return pic

  def load(pic):

    pic.i = None
    try:
      pic.i = Image.open(pic.tmp['bare'])
    except UnidentifiedImageError:

      if pic.ct:
        if pic.ct in [ 'image/svg+xml' ]:
          cairosvg.svg2png( 
            file_obj = open(pic.tmp['bare'], "rb"),
            write_to = pic.tmp['png']
          )
          pic.i = Image.open(pic.tmp['png'])

        elif pic.ct in [ 'image/gif' ]:
          pass

    if not pic.i:
      #pic.log(f'FAIL[{rid}][Pic.grab] no Image.open instance: {pic.url}') \
         #.on_fail()                                                       \

      print(f'FAIL[Pic.grab] no Image.open instance: {pic.url}')

      return pic

    print(f'[Pic.grab] Image format: {pic.i.format}')

    return pic

  def setup(pic):

    dd = { 
      'url'  : pic.url,
      'ext'  : pic.ext,
    }

    if not pic.img_saved:
      dd.update({ 'opts' : 'new' })

    # fill pic.* attributes ( inum, path, ... ) from db calls
    pic.fill_data(dd)

    print(f'[Pic.grab] Local path: {pic.path}')
    if os.path.isfile(pic.path):
      pass
      print(f'WARN[Pic.grab] image file already exists: {pic.img}')

    return pic

  def save2fs(pic):

    a = {}
    if pic.ext == 'gif':
      a['save_all'] = True

    if pic.i.mode in ("RGBA", "P"):
      pic.i = pic.i.convert('RGB')

    pic.i.save(pic.path,**a)
    pic.i.close()

    Path(pic.tmp['bare']).unlink()

    print(f'[Pic.grab] Saved image: {pic.img}')

    return pic

  def save2tmp(pic):

    pic.resp = None
    try:
      u = util.url_parse(pic.url)
      if u['scheme'] == 'data':
        data = u['path']

        m = re.match(r'^(image/svg\+xml);base64,(.*)$',u['path'])

        decoded = None
        if m:
          pic.ct = m.group(1)
          data = m.group(2)
          try:
            decoded = base64.decodestring(bytes(data,encoding='utf-8'))
          except:
            app.die(f'ERROR base64 decoding error')

        if decoded:
          with open(pic.tmp['bare'], 'wb') as f:
            f.write(decoded)
      else:
        pic.resp = requests.get(pic.url, stream = True)
#        pic.resp = app._requests_get({ 
            #'url'  : pic.url,
            #'args' : {
                #'stream' : True 
            #}
        #})
    except:
      print(f'ERROR[Pic.grab] {pic.url}')
      raise

    if pic.resp:
      pic.resp.raw.decoded_content = True
      pic.ct = util.get(pic.resp.headers, 'content-type', '')
  
      with open(pic.tmp['bare'], 'wb') as lf:
        shutil.copyfileobj(pic.resp.raw, lf)

    pic.bare_size = 0

    f = pic.tmp['bare']
    if (not os.path.isfile(f)) or os.stat(f).st_size == 0:
      #app.log(f'FAIL[{app.page.rid}][Pic.grab] empty file: {pic.url}')
      #app.on_fail()
      return pic

    pic.bare_size = os.stat(f).st_size

    if pic.ct:
      m = re.match(r'^text/html',pic.ct)

    print(f'[Pic.grab] image file size: {pic.bare_size}')
    print(f'[Pic.grab] content-type: {pic.ct}')

    return pic

  def db_add(pic):

    if not pic.dbpath:
      return pic

    for k in pic.dbcols:
      insert[k] = getattr(pic,k,None)

    d = {
      'db_file' : pic.dbpath,
      'table'   : 'imgs',
      'insert'  : insert
    }

    dbw.insert_dict(d)

    return pic

  def fill_data(pic,ref={}):
    opts_s = ref.get('opts','')
    opts   = opts_s.split(',')

    ext    = ref.get('ext','jpg')

    if not ( pic.dbpath and os.path.isfile(pic.dbpath) ):
      return 

    d = None

    img = None
    while 1:
      if 'new' in opts:
        q = '''SELECT MAX(inum) FROM imgs'''
        r = dbw.sql_fetchone(q,[],{ 'db_file' : pic.dbpath })
        inum = list(r.get('row',{}).values())[0]
        inum += 1
        img = f'{inum}.{ext}'
        break
      else:
        q = None
        if pic.url:
          q = '''SELECT * FROM imgs WHERE url = ?'''
          p = [ pic.url ]

        elif pic.inum:
          q = '''SELECT * FROM imgs WHERE inum = ?'''
          p = [ pic.inum ]

        if q:
          r = dbw.sql_fetchone(q,p,{ 'db_file' : pic.dbpath })
  
          if r:
            rw = r.get('row',{})

            img = rw['img']
            inum = rw['inum']

            pic.url = rw['url']
      break

    if not img:
      return pic

    ipath = os.path.join(pic.root, img)

    d = { 
      'inum'         : inum                 ,
      'img'          : img                  ,
      'path'         : ipath                ,
      'path_uri'     : Path(ipath).as_uri() ,
      'path_uri_srv' : f'/img/{inum}'       ,
    }

    for k, v in d.items():
      setattr(pic, k, v)

    return pic

  def get_ct(pic):
    if not pic.ext:
      return pic

    for k in pic.map_ext_ct.keys():
      v = pic.map_ext_ct.get(k)
      if re.match(rf'{k}',pic.ext):
        pic.ct = v

    return pic

  # process pic.i (Image instance)
  def i_process(pic):
    pic.width  = pic.i.width
    pic.height = pic.i.height

    print(f"[Pic.grab] Width: {pic.width}")
    print(f"[Pic.grab] Height: {pic.height}")
    print(f"[Pic.grab] Caption: {pic.caption}")

    return pic

  def get_md5(pic):

    with open(pic.tmp['bare'],"rb") as f:
      b = f.read() # read file as bytes
      pic.md5 = hashlib.md5(b).hexdigest()

    print(f'[Pic.get_md5] got md5: {pic.md5}' )

    return pic

  def get_ext(pic):
    map = {
       'JPEG'  : 'jpg',
       'PNG'   : 'png',
       'GIF'   : 'gif',
    }

    if pic.i:
      pic.ext = map.get(pic.i.format,'jpg')
    elif pic.path:
      sf = Path(pic.path).suffix
      pic.ext = re.sub(r'\.(\w+)$', r'\1', sf)

    # get image's pic.ct (content-type) from pic.ext (extension)
    pic.get_ct()

    return pic

  def grab(pic):

    print(f"[Pic.grab] Getting image: \n\t{pic.url}")

    # parse url, fetch url, save to tmp file
    pic.save2tmp()

    if not pic.bare_size:
      return pic

    pic.get_md5()

    # pic.i = Image.open(...)
    pic.load()
    
    if not pic.i:
      return pic

    acts = [
        'i_process',       
        'get_ext',         
        'setup',           
        'save2fs',         
        'db_add',          
        'url_check_saved', 
    ]

    util.call(pic,acts)

    return pic

