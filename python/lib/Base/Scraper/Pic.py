

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

from PIL import Image
from PIL import UnidentifiedImageError

class Pic(CoreClass):
  width   = None
  caption = None

  # copied from 'alt' attribute
  alt     = None

  # sqlite imgs database file
  dbfile = None

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

  app     = None

  def __init__(pic,ref={}):
    super().__init__(ref)

    app = pic.app

    if not app:
      return 

    pic                    \
        .vars_from_app()   \
        .el_process()      \
        .get_caption()     \
        .url_check_saved() \
        .fill_data()       \
        .get_ext()         \

    pass

  def el_replace(pic):
    if not pic.el:
      return pic

    app = pic.app

    pic.el['src'] = pic.path_uri_srv
    
    n = app.soup.new_tag('img')

    n['src']     = pic.path_uri_srv
    n['rel-src'] = pic.url_rel

    w_max = 500
    w = pic.width or w_max
    n['width']   = min(w,w_max)

    if pic.caption:
      n['alt'] = pic.caption

    pic.el.wrap(app.soup.new_tag('p'))
    pic.el.replace_with(n)

    return pic

  def vars_from_app(pic):
    app = pic.app

    if not app:
      return pic

    if not pic.dbfile:
      pic.dbfile = app.dbfile.images

    if not pic.root:
      pic.root = app.img_root

    if not pic.url_parent:
      pic.url_parent = app.page.url

    if not pic.baseurl:
      pic.baseurl    = app.page.baseurl
      if app.page.imgbase:
        pic.baseurl = app.page.imgbase

    pic.tmp = { 
      'bare' : app._dir('tmp_img bs_img'),
      'png'  : app._dir('tmp_img bs_img.png'),
    }

    return pic

  def url_check_saved(pic):
    pic.img_saved = False

    url = pic.url

    if not url:
      return pic

    if not ( pic.dbfile and os.path.isfile(pic.dbfile) ):
      return pic
    else:
      q = '''SELECT img FROM imgs WHERE url = ?'''
      r = dbw.sql_fetchone(q,[url],{ 'db_file' : pic.dbfile })

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

  def el_process(pic):
    if not pic.el:
      return pic

    app = pic.app

    el = pic.el

    ok = 0
    for k in pic.src_attrs:
      if el.has_attr(k):
        ok = 1
        break

    if not ok:
      return pic

    for a in util.qw('width height alt'):
      if el.has_attr(a):
        v = el[a]
        if a in util.qw('width height'):
          m = re.match(r'^(\d+)$',v)
          if m:
            v = int(v)
          else:
            v = None

        if v:
          setattr(pic, a, v)

    for k in pic.src_attrs:
      if el.has_attr(k):
        src = el[k]
        src = src.strip()
        if not src:
          continue

    if (not src) or (src == '#'):
      return pic

    pic.url_rel = None
    u = util.url_parse(src)

    if not u['path']:
      return pic

    if not u['netloc']:
      pic.url     = util.url_join(pic.baseurl,src)
      pic.url_rel = src
    else:
      pic.url = u['url']

    return pic

  def load(pic):
    app = pic.app
    rid = app.page.rid

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

    if not pic.i:
      app                                                                \
        .log(f'FAIL[{rid}][Pic.grab] no Image.open instance: {pic.url}') \
        .on_fail()                                                       \

      return pic

    app.log(f'[{rid}][Pic.grab] Image format: {pic.i.format}')

    return pic

  def setup(pic):
    app = pic.app
    rid = app.page.rid

    dd = { 
      'url'  : pic.url,
      'ext'  : pic.ext,
    }
    if not pic.img_saved:
      dd.update({ 'opts' : 'new' })

    # fill pic.* attributes ( inum, path, ... ) from db calls
    pic.fill_data(dd)

    app.log(f'[{rid}][Pic.grab] Local path: {pic.path}')
    if os.path.isfile(pic.path):
      app.log(f'WARN[{rid}][Pic.grab] image file already exists: {pic.img}')

    return pic

  def save2fs(pic):
    app = pic.app
    rid = app.page.rid

    a = {}
    if pic.ext == 'gif':
      a['save_all'] = True

    pic.i.save(pic.path,**a)
    pic.i.close()

    Path(pic.tmp['bare']).unlink()

    app.log(f'[{rid}][Pic.grab] Saved image: {pic.img}')

    return pic

  def save2page(pic):
    app = pic.app
    page = app.page

    return pic

  def save2tmp(pic):
    app = pic.app
    rid = app.page.rid

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
            app.die(f'ERROR[{rid}] base64 decoding error')

        if decoded:
          with open(pic.tmp['bare'], 'wb') as f:
            f.write(decoded)
      else:
        pic.resp = requests.get(pic.url, stream = True)
    except:
      app.die(f'ERROR[{rid}][Pic.grab] {pic.url}')

    if pic.resp:
      pic.resp.raw.decoded_content = True
      pic.ct = pic.resp.headers['content-type']
  
      with open(pic.tmp['bare'], 'wb') as lf:
        shutil.copyfileobj(pic.resp.raw, lf)

    pic.bare_size = 0

    f = pic.tmp['bare']
    if (not os.path.isfile(f)) or os.stat(f).st_size == 0:
      app.log(f'FAIL[{app.page.rid}][Pic.grab] empty file: {pic.url}')
      app.on_fail()
      return pic

    pic.bare_size = os.stat(f).st_size

    if pic.ct:
      m = re.match(r'^text/html',pic.ct)

    app.log(f'[{rid}][Pic.grab] image file size: {pic.bare_size}')
    app.log(f'[{rid}][Pic.grab] content-type: {pic.ct}')

    return pic

  def db_add(pic):
    app = pic.app

    insert =  {
      'url_parent' : app.page.url,
    }

    for k in util.qw('url img inum ext caption width height md5'):
      insert[k] = getattr(pic,k,None)

    for k in util.qw('proj rootid'):
      insert[k] = getattr(app,k,None)

    insert.update({ 
      'tags' : app.page.tags,
      'sec'  : app.page.ii_full,
    })

    d = {
      'db_file' : pic.dbfile,
      'table'   : 'imgs',
      'insert'  : insert
    }

    dbw.insert_dict(d)

    insert = {
      'rid'     : app.page.rid,
      'url'     : app.page.url,
      'pic_url' : pic.url,
    }

    d = {
      'db_file' : app.dbfile.pages,
      'table'   : 'page_pics',
      'insert'  : insert
    }
    dbw.insert_dict(d)

    return pic

  def fill_data(pic,ref={}):
    opts_s = ref.get('opts','')
    opts   = opts_s.split(',')

    ext    = ref.get('ext','jpg')

    if not ( pic.dbfile and os.path.isfile(pic.dbfile) ):
      return 

    d = None

    img = None
    while 1:
      if 'new' in opts:
        q = '''SELECT MAX(inum) FROM imgs'''
        r = dbw.sql_fetchone(q,[],{ 'db_file' : pic.dbfile })
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
          r = dbw.sql_fetchone(q,p,{ 'db_file' : pic.dbfile })
  
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
    app = pic.app
    rid = app.page.rid

    pic.width  = pic.i.width
    pic.height = pic.i.height

    app.log(f"[{rid}][Pic.grab] Width: {pic.width}")
    app.log(f"[{rid}][Pic.grab] Height: {pic.height}")
    app.log(f"[{rid}][Pic.grab] Caption: {pic.caption}")

    return pic

  def get_md5(pic):
    app = pic.app
    rid = app.page.rid

    with open(pic.tmp['bare'],"rb") as f:
      b = f.read() # read file as bytes
      pic.md5 = hashlib.md5(b).hexdigest()

    app.log(f'[{rid}][Pic.get_md5] got md5: {pic.md5}' )

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
    app = pic.app
    rid = app.page.rid

    app.log(f"[{rid}][Pic.grab] Getting image: \n\t{pic.url}")

    # parse url, fetch url, save to tmp file
    pic.save2tmp()

    if not pic.bare_size:
      return pic

    pic.get_md5()

    # pic.i = Image.open(...)
    pic.load()
    
    if not pic.i:
      return pic

    pic                    \
        .i_process()       \
        .get_ext()         \
        .setup()           \
        .save2fs()         \
        .db_add()          \
        .url_check_saved() \
    
    return pic

