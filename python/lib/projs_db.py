
import sqlite3
import re
import pprint

pp = pprint.PrettyPrinter(indent=4)

p={}

p['texfile'] = re.compile('^(\w+)\.(?:(.*)\.|)tex')
p['tags']   = re.compile('^\s*%%tags (.*)$')
p['author'] = re.compile('^\s*%%author (.*)$')

def create_tables(db_file):
	conn = sqlite3.connect(db_file)
	c = conn.cursor()
	
	c.execute('''DROP TABLE IF EXISTS projs''')
	c.execute('''CREATE TABLE IF NOT EXISTS projs (
		proj text not null, 
		file text not null unique,
		root text not null,
		sec text, 
		tags text, 
		parent text,
		author text,
		pic text,
		rootid text )''')
	
	conn.commit()
	conn.close()

def get_data(filename):
	data={}
	with open(filename) as lines:
		for line in lines:
			m = p['tags'].match(line)
			if m:
				data['tags']=m.group(1)
			m = p['author'].match(line)
			if m:
				data['author']=m.group(1)
	return data

def fill_from_files(db_file,root,rootid,proj_select):
	conn = sqlite3.connect(db_file)
	c = conn.cursor()

	f = []
	for (dirpath, dirnames, filenames) in os.walk(root):
		pp.pprint(dirnames)
		pp.pprint(filenames)
		f.extend(filenames)
		break
	
	x = 0
	h_projs = []
	for file in f:
		fpath = os.path.join(root,file)
		m = p['texfile'].match(file)
		if m:
			x+=1
			proj = m.group(1)					
			if not ((proj_select) and ( proj == proj_select  )):
				continue
			sec = m.group(2)					
			if not sec: 
				sec = '_main_' 
			data   = get_data(fpath)
			tags   = data.get('tags','')
			author = data.get('author','')
			v_projs = [proj,sec,file,root,rootid,tags,author]
			q = '''insert or ignore into projs (proj,sec,file,root,rootid,tags,author) values (?,?,?,?,?,?,?)'''
			try:
				c.execute(q,v_projs)
			except sqlite3.IntegrityError, e:
				vim.command('let e="' + e +'"')
				vim.command('call base#log(e)')
	conn.commit()
	conn.close()

