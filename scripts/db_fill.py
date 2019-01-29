
import sys,os
import getopt,argparse

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("-p", "--proj", help="select_project",default="")
parser.add_argument("-r", "--root",help="root",default="")
parser.add_argument("--rootid", help="rootid",default="")
parser.add_argument("--db_file", help="db_file",default="")

args=parser.parse_args()

dirname=os.path.dirname(os.path.realpath(__file__))
pylib=os.path.join(dirname,'..','python','lib')
sys.path.append(pylib)
import plg.projs.db as db

root=os.path.abspath("")
if args.root:
    root=args.root

rootid=""
if args.rootid:
    rootid=args.rootid

db_file = os.path.join(root,'projs.sqlite')
if args.db_file:
    db_file=args.db_file

proj = ''

def logfun(e):
    print(e)

db.drop_tables(db_file)
db.create_tables(db_file)
db.fill_from_files(db_file,root,rootid,proj,logfun)
