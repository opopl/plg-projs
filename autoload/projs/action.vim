if 0
BaseDatView 
endif

function! projs#action#thisproj_cd_src (...)

  let proj = projs#proj#name()
  let root = projs#root()
  let dir  = base#file#catfile([ root,'src',proj ])

  if !isdirectory(dir)
    return
  endif

  call base#cd(dir)
endf

function! projs#action#thisproj_copy_to_a_new_project (...)
  let proj    = projs#proj#name()
  let newproj = input('New project:','','custom,projs#complete')

  let ff      = projs#proj#files()
  let root    = projs#root()
  for f in ff
     let newf=substitute(f,'^'.proj.'.',newproj.'.','g')

     let old = base#file#catfile([ root , f ])
     let new = base#file#catfile([ root , newf ])

     call base#file#copy(old,new)
  endfor

  call projs#proj#name(newproj)
  let list = projs#varget('list',[])
  call add(list,newproj)
  call projs#varset('list',list)

  call projs#viewproj(newproj)

endf

"""PrjAct_thisprojs_newfile

function! projs#action#thisproj_newfile (...)
  let proj  = projs#proj#name()

  let name = input('Filename:','')
  let ext  = input('Extension:','')
  let dot = '.'

  let file = join([proj,name,ext],dot)

  echo 'File to be created: ' . file

  let fpath = projs#path([ file ])

  call base#fileopen({ 'files' : [fpath] })

endfunction

function! projs#action#preamble_add_centered_toc (...)
  let t = base#qw#catpath('plg','projs data tex makeatother centered_toc.tex')
  let l = base#file#lines(f)

endfunction

"""PrjAct_thisprojs_tags_replace

function! projs#action#thisproj_tags_replace (...)
  let proj  = projs#proj#name()

  let ref_def = { 'proj' : proj }
  let ref_a   = get(a:000,0,{})
  let ref     = ref_def

  call extend(ref,ref_a)

  let proj = get(ref,'proj',proj)
  
  let files = projs#proj#files({ 'proj' : proj })
  let pdir  = projs#root()

  for f in files
    let done = 0

    let p = base#file#catfile([ pdir, f ])
    if !filereadable(p)
      continue
    endif
    echo p

    let lines  = readfile(p)
    let nlines = []

    let pat    = '^%%file\s\+f_\(.*\)$'

    for l in lines
      if l =~ pat
        let l = substitute(l, pat, '%%file \1' , 'g')
        let done = 1
      endif
      call add(nlines,l)
    endfor

    if !done
      let sec = matchstr(f, '^\w\+\.\zs\(\w\+\)\ze\..*\.tex$')    
      " insert before the first item
      if strlen(sec)
        call extend(nlines,[ ' ', '%%file ' . sec , ' ' ],0)
      endif
    endif

    call writefile(nlines,p)
  endfor

endfunction

"""PrjAct_thisproj_saveas
function! projs#action#thisproj_saveas (...)
  let proj  = projs#proj#name()

  let ref_def = { 'proj' : proj }
  let ref     = get(a:000,0,ref_def)

  let proj  = get(ref,'proj',proj)

  let files = projs#proj#files({ 'proj' : proj })
  let pdir  = projs#root()

endfunction

function! projs#action#projs_tags_replace ()
  let list = projs#varget('list',[])

  let oldproj=projs#proj#name()

  for proj in list
    call projs#action#thisproj_tags_replace({ 'proj': proj })
  endfor

endfunction

function! projs#action#mk_tab ()
  let proj   = projs#proj#name()
endfunction

function! projs#action#mkdir_pics ()
  let proj   = projs#proj#name()
  let bdir   = projs#path([ 'pics' , proj ])

  if !isdirectory(bdir)
     call base#mkdir(bdir)
  endif
endfunction

function! projs#action#cd_builds ()
  let proj   = projs#proj#name()
  let bdir   = projs#path([ 'builds' , proj ])

  if !isdirectory(bdir)
     call base#mkdir(bdir)
  endif

  call base#cd(bdir)

endfunction

function! projs#action#git_add_pics ()
  PrjAct cd_pics
  exe '! git add * -f'
endfunction

function! projs#action#cd_pics ()
  let proj   = projs#proj#name()
  let bdir   = projs#path([ 'pics' , proj ])

  if !isdirectory(bdir)
     call base#mkdir(bdir)
  endif

  call base#cd(bdir)

endfunction

function! projs#action#cd_csvdir ()
  let proj   = projs#proj#name()
  let csvdir = projs#path([ 'csv' , proj ])

  if !isdirectory(csvdir)
     call base#mkdir(csvdir)
  endif

  call base#cd(csvdir)

endfunction

function! projs#action#maps_update ()
  call projs#maps()
endfunction

function! projs#action#git_save ()

endfunction

"""prjact_status
function! projs#action#status ()
  let proj = projs#proj#name()
  let root = projs#root()
  call base#cd(root)

  let status = []

  let cmds = []
  call add(cmds,'git status')

  let ok = base#sys({ "cmds" : cmds })
  call add(status, base#varget('sysout') )

  call base#buf#open_split({ 'lines' : status })

endfunction

"""prjact_git_commit
function! projs#action#git_commit ()
  let proj = projs#proj#name()
  let root = projs#root()
  call base#cd(root)

  let msg = ''
  let msg = input('git commit msg: ',msg)
  let msg = '#'.proj.' '.msg

  let cmds = []
  call add(cmds,'git add '.proj.'.*.tex')
  call add(cmds,'git add '.proj.'.tex')
  call add(cmds,'git commit -m "'.msg.'"')

  let ok = base#sys({ 
    \ "cmds"         : cmds,
    \ "split_output" : 1,
    \ })
  let out    = base#varget('sysout',[])
  let outstr = base#varget('sysoutstr','')

endfunction

"""prjact_git_add_texfiles
function! projs#action#git_add_texfiles ()
  let cmd = 'git add *.tex'

  let root = projs#root()
  call base#cd(root)

  let env = { 'cmd' : cmd }
  function env.get(temp_file) dict
    let code = self.return_code
    let cmd  = get(self,'cmd','')
  
    if code == 0
      call base#rdw(printf('OK: %s',cmd))
    endif
  endfunction
  
  call asc#run({ 
    \ 'cmd' : cmd, 
    \ 'Fn'  : asc#tab_restore(env) 
    \ })

endfunction

function! projs#action#vim_files_adjust ()
python3 << eof
import vim,os,re
import in_place

projs = vim.eval('projs#list()')
root  = vim.eval('projs#root()')

p = re.compile(r'^%%(file|parent)\s+(.*)$')
j = 0
for proj in projs:
  vim_file = '/'.join([ root, proj + '.vim' ])
  if os.path.isfile(vim_file):
    with in_place.InPlace(vim_file) as f:
      for line in f:
        if re.match(p,line):
          line = re.sub(p,r'"""\1 \2',line)
        f.write(line)
  
eof
endfunction

function! projs#action#buf_update ()
  call projs#buf#update()
endfunction

function! projs#action#url_view_html ()
  if !exists("b:url")
    call base#rdwe('b:url does not exist! abort')
    return
  endif

  let ofile = projs#buf#url_file()
  if !filereadable(ofile)
    let do_fetch = input('do URL fetching via CURL? (1/0):',1)
    if do_fetch
      call projs#action#url_fetch()
    else
      let do_open_empty = input('open empty file? (1/0):',1)
    endif
  endif

  let s:obj = { 
    \ 'proj' : b:proj ,
    \ 'sec'  : b:sec  ,
    \ 'url'  : b:url  ,
    \ }

  function! s:obj.init () dict
    let b:proj = self.proj
    let b:sec  = self.sec
    let b:url  = self.url
  endfunction
  
  let Fc = s:obj.init
  let r = { 
    \ 'files'    : [ ofile ],
    \ 'load_buf' : 1,
    \ 'Fc'       : Fc,
    \ }
  call base#fileopen(r)
endfunction

function! projs#action#url_view_txt ()
  if !exists("b:url")
    call base#rdwe('b:url does not exist! abort')
    return
  endif
endfunction

function! projs#action#url_delete_fetched ()
  if !exists("b:url")
    call base#rdwe('b:url does not exist! abort')
    return
  endif

  let ofile = projs#buf#url_file()

  if filereadable(ofile)
    call delete(ofile)
    if !filereadable(ofile)
      call base#rdw('OK: deleting url fetched file.')
    endif
  else
      call base#rdw('url_delete_fetched: nothing to delete!','Title')
  endif
endfunction

function! projs#action#url_insert ()

	let url = projs#db#url()

  call projs#sec#insert_url({ 
        \ 'url' : url, 
        \ 'sec' : projs#buf#sec() })

endfunction

function! projs#action#url_fetch ()
		let proj = b:proj 
		let file = b:basename

		let url = ''
		let urls = [
				\	exists('b:url') ? b:url : '',
				\	projs#db#url(),
				\	projs#buf#url(),
				\	] 

		while !strlen(url) && len(urls)
			let url = remove(urls,0)
			if strlen(url)
				break
			endif
		endw

		if !strlen(url)
			let url = projs#select#url()
			let b:url = url
			call projs#db#url_set({
				\	'url' : url
		 		\		})

      call projs#sec#insert_url({ 
        \ 'url' : url, 
        \ 'sec' : projs#buf#sec() })
		endif

  let ofile = projs#buf#url_file()

  call base#rdw(ofile)

  let old_mtime = filereadable(ofile) ? base#file#mtime(ofile) : ''

  let s:obj = {}
  function! s:obj.init (...) dict
    let ref = get(a:000,0,{})

    let ofile     = get(ref,'ofile','')
    let old_mtime = get(ref,'old_mtime','')

    let mtime = base#file#mtime(ofile)

    let ok = 0 

    """ file exists already
    if len(old_mtime) 
     if (str2nr(mtime) > str2nr(old_mtime) )
      let ok = 1
     endif
    else
      if filereadable(ofile)
        let ok = 1
      endif
    endif

    if ok
      call base#rdw('SUCCESS: URL FETCH')
    else
      call base#rdwe('FAIL: URL FETCH')
    endif

    "let cmd = printf('htw --file %s --cmd vh_convert',shellescape(ofile))
    let cmd = printf('links -dump -force-html -html-tables 1 %s',shellescape(ofile))

    let env = {}
    function env.get(temp_file) dict
      let code = self.return_code
    
      if filereadable(a:temp_file)
        let out = readfile(a:temp_file)
        "call base#buf#open_split({ 'lines' : out })
				call append('$',out)
      endif
    endfunction
    
    call asc#run({ 
      \  'cmd' : cmd, 
      \  'Fn'  : asc#tab_restore(env) 
      \  })

  endfunction
  
  let Fc = s:obj.init
  let Fc_args = [{ 
    \ 'ofile'     : ofile,
    \ 'old_mtime' : old_mtime,
    \ }]

  call idephp#curl#run({ 
    \ 'url'         : url,
    \ 'insecure'    : 1 ,
    \ 'output_file' : ofile,
    \ 'Fc'          : Fc,
    \ 'Fc_args'     : Fc_args,
    \ })

endfunction

"""prjact_csv_query
function! projs#action#csv_query ()
  let proj   = projs#proj#name()
  let csvdir = projs#path([ 'csv' , proj ])

perl << eof
  use DBI;

  my $warn = sub { VimWarn(@_); };

  my $csvdir = VimVar('csvdir');

  my $dbh = DBI->connect("dbi:CSV:", undef, undef, {
    f_schema         => undef,
    f_dir            => $csvdir,
    f_dir_search     => [],
    f_ext            => ".csv/r",
    f_lock           => 2,
    f_encoding       => "utf8",
    csv_eol          => "\r\n",
    csv_sep_char     => ",",
    csv_quote_char   => '"',
    csv_escape_char  => '"',
    csv_class        => "Text::CSV_XS",
    csv_null         => 1,
    csv_tables       => {
      info => { 
        f_file => "info.csv" 
      }
    },
    RaiseError       => 1,
    PrintError       => 1,
    FetchHashKeyName => "NAME_lc",
  }) or $warn->( $DBI::errstr );
eof

endfunction

function! projs#action#pics_convert_to_jpg ()
  let proj   = projs#proj#name()
  let picdir = projs#proj#dir_pics()

  let exts=base#qw('jpg png')
  
  let pics={}
  for ext in exts
    call extend(pics,{ 
        \ ext   : base#find({ 
            \ "dirs"    : [picdir],
            \ "exts"    : base#qw(ext),
            \ "relpath" : 1,
            \ "rmext"   : 1,
            \ }),
        \}
        \ )
  endfor

  let jpgs     = get(pics,'jpg',[])
  let pngs     = get(pics,'png',[])
  let png_only = base#list#minus(pngs,jpgs)

  call extend(pics,{ 'png_only'   : png_only })

  for png in png_only
    let file_png = base#file#catfile([ picdir, png . '.png' ])
    let file_jpg = base#file#catfile([ picdir, png . '.jpg' ])

    call base#image#convert(file_png,file_jpg)
    if filereadable(file_jpg)
      call base#file#delete({ 'file' : file_png })
      let git_add = join(['git add',file_jpg,'-f'],' ')
      call base#sys({ "cmds" : [git_add]})
    endif
  endfor

endfunction

function! projs#action#files_copy_to_project ()
  let exts_s = 'tex'
  let exts_s = input('File extensions:',exts_s)

  let files = projs#proj#files({ "exts" : base#qw(exts_s) })
  let isnew = input('New project? (1/0):',0)

  if isnew
    let proj  = input('New project name:','','custom,projs#complete')
  else
    let proj = input('Project where to copy:','','custom,projs#complete')
  endif

  for f in files
    let fpath=projs#path([f])
    echo fpath
    " code
  endfor

endfunction

function! projs#action#prjfiles_add_file_tag (...)
  let files = projs#proj#files({ "exts" : base#qw('tex') })
endfunction

function! projs#action#info (...) 
	let lines = []

	call add(lines,'PROJS INFO')

	let root = projs#root()

	call add(lines,'ROOT:')
	call add(lines,"\t" . root)

	let dbfile = projs#db#file()
	call add(lines,'DBFILE:')
	call add(lines,"\t" . dbfile)

	call base#buf#open_split({ 'lines' : lines })

endfunction


function! projs#action#append_label (...) 
  let sec = projs#proj#secname()
  let lines = []

  call add(lines,printf('\label{sec:%s}',sec))
  call append(line('.'),lines)
endfunction

function! projs#action#append_section (...) 
  let sec = projs#proj#secname()
  call append(line('.'),[sec])

endfunction

function! projs#action#pdf_view (...) 
  call projs#pdf#view()

endfunction

function! projs#action#pdf_delete (...) 
  call projs#pdf#delete()

endfunction

function! projs#action#help (...) 
  call projs#help()
endfunction

function! projs#action#append_thisproj (...)  
  let proj = projs#proj#name()
  call append(line('.'),[proj])

endfunction

function! projs#action#gui_select_project (...) 
  
endfunction

if 0
  call tree
    called by
      projs#action#async_build
endif

function! projs#action#async_build_Fc (self,temp_file) 
  let self      = a:self
  let temp_file = a:temp_file

  let code    = self.return_code
  let root    = self.root
  let proj    = self.proj
  let start   = self.start
  let mode    = self.mode

  let end      = localtime()
  let duration = end - start
  let s_dur    = ' ' . string(duration) . ' (secs)'
  
  if filereadable(a:temp_file)
    call tex#efm#latex()
    exe 'cd ' . root
    exe 'cgetfile ' . a:temp_file
    
    let err = getqflist()
    
    redraw!
    if len(err)
      let msg = printf('BUILD FAIL: %s %s, mode: %s',proj,s_dur,mode)
      call base#rdwe(msg)
      BaseAct copen
    else
      let msg = printf('BUILD OK: %s %s, mode: %s',proj,s_dur,mode)
      call base#rdw(msg)
      BaseAct cclose
    endif
    echohl None
  endif
endfunction

function! projs#action#excel_import (...) 
  let ref = get(a:000,0,{})

  let proj     = get(ref,'proj',projs#proj#name())
  let file_sht = get(ref,'file','')

  let xdir = projs#path([ 'data' , proj, 'sht' ])

  if !strlen(file_sht)
    let files = base#find({ 
      \  "dirs"        : [xdir],
      \  "exts"        : ['xls'],
      \  "cwd"         : 1,
      \  "relpath"     : 0,
      \  "subdirs"     : 1,
      \  "fnamemodify" : '',
      \  })
  
    for file in files
      call projs#action#excel_import({ 'file' : file })
    endfor

    return 
  endif

  let file_base = fnamemodify(file_sht,':r')

python3 << eof
import vim

import os
import sqlite3
import win32com

ROW_SPAN = (14, 21)
COL_SPAN = (2, 7)

file_sht = vim.eval('file_sht')

from win32com.client import constants, Dispatch
app = Dispatch("Excel.Application")
app.Visible = True
ws = app.Workbooks.Open(file_sht).Sheets(0)

exceldata = [[ ws.Cells(row, col).Value 
              for col in xrange(COL_SPAN[0], COL_SPAN[1])] 
             for row in xrange(ROW_SPAN[0], ROW_SPAN[1])]
  
eof
endfunction

function! projs#action#xls_render (...) 
  let ref = get(a:000,0,{})

  let proj = get(ref,'proj',projs#proj#name())
  let file = get(ref,'file','')

  let xdir   = projs#path([ 'data' , proj, 'xls' ])

  if !strlen(file)
    let files = base#find({ 
      \  "dirs"    : [xdir],
      \  "exts"    : ['xls'],
      \  "relpath" : 0,
      \  "subdirs" : 1,
      \  "fnamemodify" : '',
      \  })
  
    for file in files
      call projs#action#xls_render({ 'file' : file })
    endfor

    return 
  endif

  if !filereadable(file)
    return 
  endif

  let file_base = fnamemodify(file,':r')
  let file_db   = file_base . '.db'

python3 << eof
import vim
import sqlite3
import pandas as pd

file_base = vim.eval('file_base')

file_xls  = vim.eval('file')
file_db   = vim.eval('file_db')

print(file_xls)
print(file_db)

con = sqlite3.connect(file_db)
wb  = pd.ExcelFile(file_xls)

for sheet in wb.sheet_names:
  df = pd.read_excel(file_xls,sheet_name = sheet)
  print(sheet)
  print(df)
  #df.to_sql(sheet, con, index=False, if_exists="replace" )

con.commit()
con.close()
eof
endfunction

if 0
  Usage
    projs#action#async_build()
    projs#action#async_build({ 'sec_bat' : '_build_htlatex_' })
    projs#action#async_build({ 'sec_bat' : '_build_pdflatex_' })
  Call tree
    calls
      projs#proj#name
      projs#root
      projs#sec#file
      projs#sec#new
endif

function! projs#action#async_build (...) 
  let ref = get(a:000,0,{})

  let root = projs#root()

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let sec_bat = '_build_pdflatex_'
  let sec_bat = get(ref,'sec_bat',sec_bat)

  let bat     = projs#sec#file(sec_bat)

  let o = { 'prompt' : 0 }
  call projs#sec#new(sec_bat,o)

  let start = localtime()
  
  let env = {
    \ 'proj'  : proj,
    \ 'root'  : root,
    \ 'start' : start,
    \ 'mode'  : sec_bat,
    \ }
  let cmd = bat

  function env.get(temp_file) dict
    call projs#action#async_build_Fc(self,a:temp_file)
  endfunction

  echo printf('async_build: %s, mode: %s',proj,sec_bat)

  call asc#run({ 
    \ 'cmd' : cmd, 
    \ 'Fn'  : asc#tab_restore(env) 
    \ })
  return 1

endfunction

function! projs#action#async_build_htlatex () 
  call projs#action#async_build({ 'sec_bat' : '_build_htlatex_' })
endfunction

function! projs#action#create_sec_tab (...)
  let sec = input('Table file:','fig_')

  let lines = []

  call projs#sec#new(sec,{ 
    \ "prompt" : 0, 
    \ 'seccmd' : '',
    \ 'add_lines_after' : lines,
    \ })

endfunction

function! projs#action#create_sec_fig (...)
  let sec = input('Figure file:','fig_')

  let lines = []

  call projs#sec#new(sec,{ 
    \ "prompt"          : 0,
    \ 'seccmd'          : '',
    \ 'add_lines_after' : lines,
    \ })

endfunction


function! projs#action#buildmode_set ()
  let buildmode=input('PROJS buildmode:','','custom,projs#complete#buildmodes')
  
  call projs#varset('buildmode',buildmode)
  call projs#echo('Build mode set: ' . buildmode)

endfunction

function! projs#action#joinlines ()
    let jlines =  projs#filejoinlines({ 'write_jfile' : 1 })
    VSEC _join_
endfunction

function! projs#action#html_out_view ()
  call projs#html_out#view ()
endfunction

function! projs#action#add_to_db ()
	let dbfile = projs#db#file()

	let proj = projs#proj#name()
	let sec  = projs#buf#sec()

	let root   = projs#root()
	let rootid = projs#rootid()

	let pid = projs#db#pid()

	let fid_last = projs#db#fid_last()
	let fid      = fid_last + 1

	let t = "projs"
	let h = {
		\	"proj"   : proj,
		\	"sec"    : sec,
		\	"root"   : root,
		\	"rootid" : rootid,
		\	"file"   : b:basename,
		\	"pid"    : pid,
		\	"fid"    : fid,
		\	}
	
	let ref = {
		\ "dbfile" : projs#db#file(),
		\ "i"      : "INSERT",
		\ "t"      : t,
		\ "h"      : h,
		\ }
		
	call pymy#sqlite#insert_hash(ref)
	
	let [ rows_h, cols ] = pymy#sqlite#query({
		\	'dbfile' : dbfile,
		\	'p'      : p,
		\	'q'      : q,
		\	})

endfunction

if 0
  see also:
endif

function! projs#action#_plg_tex_view ()
  let dir = base#qw#catpath('plg projs data tex')

  let ln = ['dir:',"  " . dir]

  call base#find#open_split({
      \ 'opts_find' : { 
            \ "dirs"    : [dir],
            \ "dirids"  : [],
            \ "exts"    : base#qw('tex sty'),
            \ "relpath" : 1,
            \ "cwd"     : 0,
            \ "subdirs" : 1,
            \ "fnamemodify" : '',
            \ },
      \ 'opts_split' : {
          \ 'title'              : 'List of TeX template files',
          \ 'table_headers'      : ['file'],
          \ 'lines_before_table' : ln,
          \ }
      \ })

    return
endfunction

function! projs#action#tex4ht_mk_dirs ()
	let dirs = [ '', 'js' , 'css' ]

	for dir in dirs
		let dir = projs#proj#dir_tex4ht(dir)
		call base#mkdir(dir)
	endfor
	
endfunction

function! projs#action#tex4ht_css_view ()
	let dir = projs#proj#dir_tex4ht('css')

endfunction

function! projs#action#tex4ht_js_view ()
	let dir = projs#proj#dir_tex4ht('js')
endfunction

function! projs#action#_xmlfile_view()
	let xmlfile = projs#xmlfile()
	call base#fileopen({ 
		\	'files'    : [xmlfile] ,
		\	'load_buf' : 1,
		\	})
	
endfunction

function! projs#action#_xml_update_col()
	let xmlfile = projs#xmlfile()

	let proj = projs#selectproject()
	let r = {
		\	'q'      : 'SELECT sec FROM projs WHERE proj = ?',
		\	'p'      : [proj],
		\	'dbfile' : projs#db#file(),
		\	}
	let secs = pymy#sqlite#query_as_list(r)
	call base#varset('this',secs)

	let msg_a = [
		\	printf("[proj=%s]select section:",proj),	
		\	]
	let msg = join(msg_a,"\n")
	let sec = base#input_we(msg,'',{ 'complete' : 'custom,base#complete#this' })

	let col = 'tags'

	let val = input(printf('[proj=%s,sec=%s,col=%s] new value:',proj,sec,col),'')

	let r = {
			\	'proj' : proj,
			\	'sec' : sec,
			\	'val' : val,
			\	'col' : col,
			\	'xmlfile' : xmlfile,
			\	}
	call projs#xml#update_col(r)

endfunction


function! projs#action#view_db_fill_tags_py3()
	let file = base#qw#catpath('plg projs scripts db_fill_tags.py3')
	call base#fileopen({ 
		\	'files'    : [file] ,
		\	'load_buf' : 1,
		\	})

endfunction
