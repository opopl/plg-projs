
from peewee import SqliteDatabase, Model
from peewee import TextField, AutoField, IntegerField, ForeignKeyField

import os,re,sys

html_root = os.environ.get('HTML_ROOT')
lts_root  = os.environ.get('P_SR')

home = os.environ.get('HOME')
backup_db = os.path.join(home,'backup', 'db')

db_pages_path = os.path.join(backup_db,'h.db')
db_pages = SqliteDatabase(db_pages_path)

db_projs_path = os.path.join(backup_db,'projs.sqlite')
db_projs = SqliteDatabase(db_projs_path)

class BaseModel(Model):
  pass
  #@classmethod
  #def find(cls,**args):
    #return list(cls.select().where(**args).dicts())

def fAuthors():
  pass

class mAuthors(BaseModel):
  description = TextField(null   = True)
  id          = TextField(unique = True)
  name        = TextField(null   = True)
  plain       = TextField(null   = True)
  url         = TextField(null   = True)

  class Meta:
    database = db_pages
    table_name = 'authors'
    primary_key = False

class mProjs(BaseModel):
    author_id = TextField(null    = True)
    date      = TextField(null    = True)
    fid       = AutoField(null    = True)
    file      = TextField(unique  = True)
    id        = TextField(null    = True)
    parent    = TextField(null    = True)
    pic       = TextField(null    = True)
    pid       = IntegerField(null = True)
    proj      = TextField()
    projtype  = TextField(null    = True)
    rootid    = TextField(null    = True)
    sec       = TextField(null    = True)
    tags      = TextField(null    = True)
    title     = TextField(null    = True)
    url       = TextField(null    = True)

    class Meta:
      database = db_projs
      table_name = 'projs'

class mPages(BaseModel):
    author_bare     = TextField(null    = True)
    author_id       = TextField(null    = True)
    author_id_first = TextField(null    = True)
    baseurl         = TextField(null    = True)
    date            = TextField(null    = True)
    day             = IntegerField(null = True)
    encoding        = TextField(null    = True)
    host            = TextField(null    = True)
    ii              = TextField(null    = True)
    ii_full         = TextField(null    = True)
    ii_num          = IntegerField(null = True)
    month           = IntegerField(null = True)
    notes           = TextField(null    = True)
    ok              = IntegerField(null = True)
    phrases         = TextField(null    = True)
    rid             = IntegerField(null = True, unique = True)
    site            = TextField(null    = True)
    tags            = TextField(null    = True)
    title           = TextField(null    = True)
    title_h         = TextField(null    = True)
    url             = TextField(unique  = True)
    year            = IntegerField(null = True)

    class Meta:
        database = db_pages
        table_name = 'pages'
        primary_key = False

class mPageTags(BaseModel):
    rid = IntegerField(null=True)
    tag = TextField(null=True)
    url = ForeignKeyField(column_name='url', field='url', model=mPages, null=True)

    class Meta:
        database = db_pages
        table_name = 'page_tags'
        primary_key = False

