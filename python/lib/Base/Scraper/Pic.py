

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

    pic.tmp = { 
       'bare' : app._dir('tmp_img bs_img'),
       'png'  : app._dir('tmp_img bs_img.png'),
    }

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

    rid = app.page.rid

    app.log(f"[{rid}][Pic.grab] Getting image: \n\t{pic.url}")

    i = None
    resp = None
    try:
      u = util.url_parse(pic.url)
      if u['scheme'] == 'data':
        data = u['path']
        m = re.match(r'^image/svg\+xml;base64,(.*)$',u['path'])

        decoded = None
        if m:
          data = m.group(1)
          try:
            decoded = base64.decodestring(bytes(data,encoding='utf-8'))
          except:
            app.die(f'ERROR[{rid}] base64 decoding error')
          import pdb; pdb.set_trace()

        if decoded:
          with open(pic.tmp['bare'], 'wb') as f:
            f.write(decoded)
      else:
        resp = requests.get(pic.url, stream = True)
    except:
      app.die(f'ERROR[{rid}][Pic.grab] {pic.url}')

    if resp:
      resp.raw.decoded_content = True
  
      with open(pic.tmp['bare'], 'wb') as lf:
        shutil.copyfileobj(resp.raw, lf)

    f = pic.tmp['bare']
    if (not os.path.isfile(f)) or os.stat(f).st_size == 0:
      app.log(f'FAIL[{rid}][Pic.grab] empty file: {pic.url}')
      self.on_fail()
      return self

    f_size = os.stat(f).st_size
    ct = resp.headers['content-type']

    app.log(f'[{rid}][Pic.grab] image file size: {f_size}')
    app.log(f'[{rid}][Pic.grab] content-type: {ct}')

    m = re.match(r'^text/html',ct)

    i = None
    try:
      i = Image.open(pic.tmp['bare'])
    except UnidentifiedImageError:

      if ct in [ 'image/svg+xml' ]:
        cairosvg.svg2png( 
          file_obj = open(pic.tmp['bare'], "rb"),
          write_to = pic.tmp['png']
        )
        i = Image.open(pic.tmp['png'])
      
    if not i:
      app                                                                \
        .log(f'FAIL[{rid}][Pic.grab] no Image.open instance: {pic.url}') \
        .on_fail()                                                       \

      return pic
      
    app.log(f'[{rid}][Pic.grab] Image format: {i.format}')
    pic.ext = app._img_ext(i)

    dd = { 
      'url'  : pic.url,
      'ext'  : pic.ext,
    }
    if not pic.img_saved:
      dd.update({ 'opts' : 'new' })

    pic.idata = app._img_data(dd)

    for k in util.qw('img inum path'):
      v = pic.idata(get,'')
      setattr(pic, k, v)

    app.log(f'[{rid}][Pic.grab] Local path: {pic.idata.get("path","")}')
    if os.path.isfile(pic.ipath):
      app.log(f'WARN[{rid}][Pic.grab] image file already exists: {pic.img}')

    a = {}
    if pic.ext == 'gif':
      a['save_all'] = True

    i.save(pic.ipath,**a)
    i.close()

    Path(pic.tmp['bare']).unlink()

    app.log(f'[{rid}][Pic.grab] Saved image: {pic.img}')

    pic.db_add()
    
    return pic

