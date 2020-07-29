
import sys,os
import getopt,argparse

import argparse

usage='''
This script will fill the "projs" sqlite database
'''
parser = argparse.ArgumentParser(usage=usage)

parser.add_argument("-p", "--proj", help="select_project",default="")
parser.add_argument("-r", "--root",help="root",default="")
parser.add_argument("--rootid", help="rootid",default="")
parser.add_argument("--dbfile", help="dbfile",default="")
parser.add_argument("-a", "--all", help="fill all projects",default=1)
parser.add_argument("-l","--list", help="list of projects",default="")

args = parser.parse_args()

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

rootid=""
if args.rootid:
  rootid = args.rootid

dbfile = os.path.join(root,'projs.sqlite')
if args.dbfile:
  dbfile = args.dbfile

proj = ''

def logfun(e):
  print(e)

if args.list:
  list = args.list
  projs = list.split(",")
  for proj in projs:
    db.fill_from_files( dbfile, root, rootid, proj, logfun )
else:
  db.drop_tables(dbfile)
  db.create_tables(dbfile)
  db.fill_from_files( dbfile, root, rootid, proj, logfun )
