

import base64

import re,os,sys,stat

import cairosvg

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
  url     = None
  width   = None
  caption = None
  dbfile  = None

  idata = {}

  app     = None

  def __init__(pic,ref={}):
    super().__init__(ref)

    app = pic.app

    if not app:
      return 

    pic.tmp = { 
      'bare' : app._dir('tmp_img bs_img'),
      'png'  : app._dir('tmp_img bs_img.png'),
    }

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

    return pic

  def _has_bare(pic):



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

    pic.idata = app._img_data(dd)

    for k in util.qw('img inum path'):
      v = pic.idata.get(k,'')
      setattr(pic, k, v)

    app.log(f'[{rid}][Pic.grab] Local path: {pic.idata.get("path","")}')
    if os.path.isfile(pic.ipath):
      app.log(f'WARN[{rid}][Pic.grab] image file already exists: {pic.img}')

    return pic

  def save2tmp(pic):
    app = pic.app

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

    pic.has_bare = False

    f = pic.tmp['bare']
    if (not os.path.isfile(f)) or os.stat(f).st_size == 0:
      app.log(f'FAIL[{app.page.rid}][Pic.grab] empty file: {pic.url}')
      app.on_fail()
      return pic

    pic.has_bare = True
    pic.bare_size = os.stat(f).st_size

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
      'db_file' : app.dbfile.images,
      'table'   : 'imgs',
      'insert'  : insert
    }
    dbw.insert_dict(d)

    return pic

  def grab(pic):
    app = pic.app

    app.log(f"[{rid}][Pic.grab] Getting image: \n\t{pic.url}")

    pic.save2tmp()

    if not pic.has_bare:
      return pic

    if pic.ct:
      m = re.match(r'^text/html',pic.ct)

    app.log(f'[{rid}][Pic.grab] image file size: {pic.bare_size}')
    app.log(f'[{rid}][Pic.grab] content-type: {pic.ct}')

    pic.load()
      
    if not pic.i:
      app                                                                \
        .log(f'FAIL[{rid}][Pic.grab] no Image.open instance: {pic.url}') \
        .on_fail()                                                       \

      return pic
      
    app.log(f'[{rid}][Pic.grab] Image format: {pic.i.format}')

    pic.ext = app._img_ext(pic.i)

    pic.setup()

    a = {}
    if pic.ext == 'gif':
      a['save_all'] = True

    pic.i.save(pic.ipath,**a)
    pic.i.close()

    Path(pic.tmp['bare']).unlink()

    app.log(f'[{rid}][Pic.grab] Saved image: {pic.img}')

    pic.db_add()
    
    return pic
