
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
parser.add_argument("-l","--list", help="list of projects",default="")
parser.add_argument("-c","--create", help="create tables anew",default="")

parser.add_argument("-a", "--all", help="fill all projects",action="store_true")

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

if args.all:
  db.fill_from_files( dbfile, root, rootid, '', logfun )

#create tables anew
if args.create:
  db.drop_tables(dbfile)
  db.create_tables(dbfile)

# fill the selected list of projects
if args.list:
  list = args.list
  projs = list.split(",")
  for proj in projs:
    db.fill_from_files( dbfile, root, rootid, proj, logfun )


#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
