
import sys,os
import getopt,argparse

import re

import Base.String as string

usage='''
This script will fill the "projs" sqlite database
'''
parser = argparse.ArgumentParser(usage=usage)

parser.add_argument("-p", "--proj", help="select_project", default="")
parser.add_argument("-r", "--root", help="root", default="")
parser.add_argument("--rootid", help="rootid", default="")
parser.add_argument("--dbfile", help="dbfile", default="")
parser.add_argument("-l", "--list", help="list of projects", default="")
parser.add_argument("-i", "--info", help="db info", action="store_true")
parser.add_argument("-e", "--ext", help="list of extensions (use with: --all)", default="")

parser.add_argument("-d", "--delete", help="delete from database absent files", action="store_true")

parser.add_argument("-c", "--create", help="create tables anew", action="store_true")
parser.add_argument("-a", "--all",    help="fill all projects", action="store_true")

args = parser.parse_args()

def logfun(e):
  print(e)

if len(sys.argv) == 1:
  parser.print_help()
  sys.exit()

dirname = os.path.dirname(os.path.realpath(__file__))
pylib   = os.path.join(dirname,'..','python','lib')

sys.path.append(pylib)
import plg.projs.db as db

root = os.path.abspath("")
if args.root:
  root = args.root

rootid = os.path.split(root)[-1]
if args.rootid:
  rootid = args.rootid

dbfile = os.path.join(root,'projs.sqlite')
if args.dbfile:
  dbfile = args.dbfile

proj = ''
if args.proj:
  proj = args.proj
  db.fill_from_files( dbfile, root, rootid, proj, logfun )

#create tables anew
###_create
if args.create:
  db.drop_tbl({ 'db_file' : dbfile, 'tbl' : 'projs' })
  sql_dir = os.path.join(dirname, '..', 'data', 'sql')
  f = []
  for (dirpath, dirnames, filenames) in os.walk(sql_dir):
    f.extend(filenames)
    break
  pt = re.compile('^create_table_(\w+)\.sql')
  for file in f:
    m = pt.match(file)
    if m:
      sql_file = os.path.join(sql_dir,file)
      db.create_tables(dbfile, sql_file)

if args.info:
  db.info(dbfile)
  exit(0)

if args.delete:
  db_files = []
  exit(0)

###_all
if args.all:
  exts = string.split_n_trim(txt = args.ext, sep = ',')
  r = {
    'db_file' : dbfile,
    'root'    : root,
    'root_id' : rootid,
    'proj'    : '',
    'logfun'  : logfun,
    'exts'    : exts,
  }
  db.fill_from_files( **r )

# fill the selected list of projects
###_list
if args.list:
  list = args.list
  projs = list.split(",")
  for proj in projs:
    db.fill_from_files( dbfile, root, rootid, proj, logfun )

print('OK')
exit(0)
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
