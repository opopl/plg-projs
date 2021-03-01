

import base64

import re,os,sys,stat

import cairosvg
import sqlite3

import shutil
import requests

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

  # BS element 
  el = None

  # local (saved) path 
  path     = None
  path_uri = None

  # image server path
  path_uri_srv = None

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
        .fill_data()        \

    pass

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

    if not el.has_attr('src'):
      return pic

    for a in util.qw('width alt'):
      if el.has_attr(a):
        v = el[a]
        setattr(pic, a, v)

    src = el['src'].strip()

    if src == '#':
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

    for k in util.qw('url img inum ext caption'):
      insert[k] = getattr(pic,k,None)

    for k in util.qw('proj rootid'):
      insert[k] = getattr(app,k,None)

    d = {
      'db_file' : pic.dbfile,
      'table'   : 'imgs',
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

    if img:
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

  def get_ext(pic):
    map = {
       'JPEG'  : 'jpg',
       'PNG'   : 'png',
       'GIF'   : 'gif',
    }
    pic.ext = map.get(pic.i.format,'jpg')
    return pic

  def grab(pic):
    app = pic.app
    rid = app.page.rid

    app.log(f"[{rid}][Pic.grab] Getting image: \n\t{pic.url}")

    pic.save2tmp()

    if not pic.bare_size:
      return pic

    pic.load()
    
    if not pic.i:
      return pic

    pic                    \
        .get_ext()         \
        .setup()           \
        .save2fs()         \
        .db_add()          \
        .url_check_saved() \
    
    return pic

