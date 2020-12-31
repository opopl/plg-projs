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

function! projs#action#term_build_dir ()
  let proj   = projs#proj#name()

  let target = projs#bld#target()
  let bdir   = projs#path([ 'builds', proj, 'src', target ])

  call base#cd(bdir)
  if has('terminal')
    terminal
  endif

endfunction

function! projs#action#cd_builds ()
  let proj   = projs#proj#name()

  let target = projs#bld#target()
  let bdir   = projs#path([ 'builds', proj, 'src', target ])

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
  let url_db = projs#db#url()
  let url    = base#value#var('b:url',url_db)

  if !len(url)
    call base#rdwe('zero URL! abort')
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
    \ 'url'  : url,
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

  if !strlen(url) || url == 'v:none'
    let url = base#input_we('url: ','')
  endif

  call projs#sec#insert_url({ 
        \ 'url' : url, 
        \ 'sec' : projs#buf#sec() 
        \ })
  let y = input('fetch URL? (1/0): ',1)
  if y
    call projs#action#url_fetch()
  endif

endfunction

"""pa_url_fetch
function! projs#action#url_fetch ()
  let proj = b:proj 
  let file = b:basename

  "let url = projs#action#url_fetch#url()
  let url = projs#db#url()

  let ofile = projs#buf#url_file()

  call base#rdw(ofile)

  let old_mtime = filereadable(ofile) ? base#file#mtime(ofile) : ''

  let Fc =  projs#action#url_fetch#Fc ()

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



if 0
  Call tree
    called by
      projs#action#async_build_bare
endif


function! projs#action#async_build_bare_Fc (self,temp_file) 
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

if 0
  call tree
    called by
      projs#action#async_build_pwg
endif

function! projs#action#async_build_pwg_Fc (self,temp_file) 
  let self      = a:self
  let temp_file = a:temp_file

  let code    = self.return_code
  let root    = self.root
  let proj    = self.proj
  let start   = self.start
  let mode    = self.mode

  let build_files = self.build_files
  let src_dir     = self.src_dir

  let end      = localtime()
  let duration = end - start
  let s_dur    = ' ' . string(duration) . ' (secs)'
  
  let pdf_file = projs#pdf#path(proj,'pwg')

  let log = get(build_files,'log','')

  if filereadable(temp_file)
    "let log_bn = fnamemodify(log,':p:t')
    "call tex#efm#latex()
    "exe 'cd ' . src_dir
    "exe 'cgetfile ' . log_bn
    
    let err = []

    call tex#efm#latex()
    exe 'cgetfile ' . temp_file
    call extend(err,getqflist())

    redraw!
    if len(err)
      let msg = printf('(PWG) LATEX ERR: %s %s',proj,s_dur)
      call base#rdwe(msg)
      BaseAct copen
      exe 'cd ' . src_dir
    else
      let msg = printf('(PWG) LaTeX OK: %s %s',proj,s_dur)
      call base#rdw(msg,'StatusLine')
      BaseAct cclose
    endif
    echohl None
  endif

  "if filereadable(a:temp_file)
    "let out = readfile(a:temp_file)
    "call base#buf#open_split({ 'lines' : out })
  "endif
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

"""pwg_insert_img
function! projs#action#pwg_insert_img (...) 
  let ref = get(a:000,0,{})

  let root    = projs#root()
  let root_id = projs#rootid()

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  call chdir(root)
  let cmd = join([ 
      \ 'bb_pdflatex.bat', 
      \ proj, root_id,
      \ '-c','insert_pwg' ], ' ' )

  let jnd = projs#sec#file('_tex_jnd_')
  if filereadable(jnd)
    call delete(jnd)
  endif

  let env = {
    \ 'proj'        : proj,
    \ 'root'        : root,
    \ 'jnd'         : jnd,
    \ }

  function env.get(temp_file) dict
    let jnd = get(self,'jnd','')
    "VSEC _tex_jnd_
    if filereadable(a:temp_file)
      let out = readfile(a:temp_file)
      call base#buf#open_split({ 'lines' : out })
    endif
    "call projs#action#pwg_insert_pwg_Fc(self,a:temp_file)
    call base#rdw('OK: pwg_insert_img')
  endfunction

  call asc#run({ 
    \ 'cmd' : cmd, 
    \ 'Fn'  : asc#tab_restore(env) 
    \ })
  return 1
endf


"""prjact_async_build_pwg

function! projs#action#async_build_pwg (...) 
  let ref = get(a:000,0,{})

  let root    = projs#root()
  let root_id = projs#rootid()

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let mode = '_bb_tex_'

  let start = localtime()
  call chdir(root)
  let cmd = join([ 
      \ 'bb_tex.bat', 
      \ proj,
      \ '-c','build_pwg' ], ' ' )

  let src_dir = projs#builddir('src')

  let build_files = {}
  for ext in base#qw('log aux')
    let ff = base#find({ 
        \  "dirs"    : [src_dir],
        \  "exts"    : [ext],
        \  "relpath" : 0,
        \  })
    call extend(build_files,{ 
      \ ext : get(ff,0,'')
      \ })

  endfor
  
  let env = {
    \ 'proj'        : proj,
    \ 'root'        : root,
    \ 'start'       : start,
    \ 'mode'        : mode,
    \ 'build_files' : build_files,
    \ 'src_dir'     : src_dir,
    \ }

  function env.get(temp_file) dict
    call projs#action#async_build_pwg_Fc(self,a:temp_file)
  endfunction

  let msg = printf('async_build_pwg: %s, mode: %s', proj, mode)
  call base#rdw(msg,'WildMenu')

  call asc#run({ 
    \ 'cmd' : cmd, 
    \ 'Fn'  : asc#tab_restore(env) 
    \ })
  return 1
endf

function! projs#action#edt (...) 
  let ref = get(a:000,0,{})

  let root    = projs#root()
  let root_id = projs#rootid()

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let efile = printf('%s.edt.pl',proj)

  let start = localtime()
  call chdir(root)
  let cmd = join([ 'perl', efile ], ' ' )

  let env = {
    \ 'proj'  : proj,
    \ 'root'  : root,
    \ 'start' : start,
    \ }

  function env.get(temp_file) dict
    call projs#action#edt_Fc(self,a:temp_file)
  endfunction

  let msg = printf('edt: %s', proj)
  call base#rdw(msg)

  call asc#run({ 
    \ 'cmd' : cmd, 
    \ 'Fn'  : asc#tab_restore(env) 
    \ })
  return 1

endf

if 0
  call tree
    called by
      projs#action#edt
endif

function! projs#action#edt_Fc (self,temp_file) 
  let self      = a:self
  let temp_file = a:temp_file

  let root    = self.root
  let proj    = self.proj
  let start   = self.start

  let end      = localtime()
  let duration = end - start
  let s_dur    = ' ' . string(duration) . ' (secs)'
  
  let out = []
  if filereadable(a:temp_file)
    call extend(out, readfile(temp_file))
  endif

  call base#buf#open_split({ 'lines' : out })

  call base#rdw('DONE: EDT')
endf

function! projs#action#bld_join (...) 
  let ref = get(a:000,0,{})

  let root    = projs#root()
  let root_id = projs#rootid()

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let target = projs#bld#target()

  let bfile = projs#sec#file('_perl.bld')

  let start = localtime()
  call chdir(root)

  let act = 'join'

  let a = [ 'perl', bfile, act, '-t', target ]
  let cmd = join(a, ' ' )

  call base#varset('projs_bld_last',{ 
    \ 'cmd' : cmd, 
    \ 'act' : act })

  let env = {
    \ 'proj'  : proj,
    \ 'root'  : root,
    \ 'start' : start,
    \ }

  function env.get(temp_file) dict
    call projs#action#bld_join_Fc(self,a:temp_file)
  endfunction

  let msg = printf('bld_join: %s', proj)
  call base#rdw(msg)

  call asc#run({ 
    \ 'cmd' : cmd, 
    \ 'Fn'  : asc#tab_restore(env) 
    \ })
  return 1

endf

"""PA_out_bld
function! projs#action#out_bld (...) 
  let out = base#varget('projs_bld_compile_output',[])
  call base#buf#open_split({ 
    \  'lines' : out,
    \  })

endf

function! projs#action#view_bld_log (...) 
  let proj   = projs#proj#name()
  let bdir   = projs#path([ 'builds', proj, 'src' ])
  
  let log = base#file#catfile([ bdir, 'jnd.log' ])
  call base#fileopen({ 
    \ 'files'    : [log],
    \ 'load_buf' : 1,
    \ })
endf


"if 0
"  Usage
"    projs#action#bld_compile()
"  Call tree
"    calls
"      projs#proj#name
"      projs#root
"      projs#action#bld_compile_Fc
"      projs#bld#make_secs
"        projs#sec#new
"      projs#sec#file
"endif

"""PA_bld_compile
function! projs#action#bld_compile (...) 
  let ref = get(a:000,0,{})

  let root    = projs#root()
  let root_id = projs#rootid()

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let config = get(ref,'config','')

  let target = get(ref,'target','')

  call projs#bld#make_secs()

  if !len(target)
    let target = projs#bld#target()
  endif
  if len(target)
    call base#varset('projs_bld_target',target)
  endif

  let bfile = projs#sec#file('_perl.bld')

  let start = localtime()
  call chdir(root)

  let act = 'compile'
  let a = [ 'perl', bfile, act, '-t', target ]

  if len(config)
    call extend(a,[ '-c' ,config ])
  endif
  let cmd = join(a, ' ' )

  call base#varset('projs_bld_last_compile',{ 
    \ 'cmd'    : cmd,
    \ 'config' : config, })

  let jnd_pdf = projs#bld#jnd_pdf({ 'target' : target }) 
  let jnd_tex = projs#bld#jnd_tex({ 'target' : target }) 

  let env = {
    \ 'proj'    : proj,
    \ 'root'    : root,
    \ 'config'  : config,
    \ 'target'  : target,
    \ 'start'   : start,
    \ 'cmd'     : cmd,
    \ 'jnd_pdf' : jnd_pdf,
    \ 'jnd_tex' : jnd_tex,
    \ }

  function env.get(temp_file) dict
    call projs#action#bld_compile_Fc(self,a:temp_file)
  endfunction

  let msg = printf('bld_compile: %s; target: %s; config: %s', proj, target, config)
  call base#rdw(msg)

  call asc#run({ 
    \ 'cmd' : cmd, 
    \ 'Fn'  : asc#tab_restore(env) 
    \ })
  return 1

endf

function! projs#action#bld_compile_xelatex () 

  let r = {
      \ 'config' : 'xelatex',
      \ }
  call projs#action#bld_compile(r) 

endf

if 0
  called by
    projs#action#bld_compile
endif

function! projs#action#bld_compile_Fc (self,temp_file) 
  let self      = a:self
  let temp_file = a:temp_file

  let root    = self.root
  let proj    = self.proj
  let cmd     = self.cmd

  let start   = self.start

  let config   = self.config
  let target   = self.target

  let jnd_pdf = self.jnd_pdf
  let jnd_tex = self.jnd_tex

  let code    = self.return_code

  let end      = localtime()
  let duration = end - start
  let s_dur    = ' ' . string(duration) . ' (secs)'

  let ok = ( code == 0 ) ? 1 : 0

  let jnd_size = 0
  try
    let jnd_size = base#file#size(jnd_pdf)
  catch 
    "call base#rdwe('base#file#size error: ' . jnd_pdf,'NonText')
  endtry
  
  let err = []
  if filereadable(a:temp_file)
    let lines = readfile(a:temp_file)

    call base#varset('projs_bld_compile_output',lines)

    call tex#efm#latex()
    exe 'cd ' . root
    exe 'cgetfile ' . a:temp_file

    let err = getqflist()
    let jfile = fnamemodify(jnd_tex,':t')
    let jdir  = fnamemodify(jnd_tex,':h')
    for e in err
      unlet e.bufnr
      call extend(e,{ 'filename' : jfile })
    endfor
    exe 'cd ' . jdir
    call setqflist(err)
    if len(err)
      let ok = 0
    endif
  endif

  if !jnd_size
     redraw!
     let msg = printf('[ZERO FILE SIZE] PERL BUILD FAIL: %s %s',proj,s_dur)
     call base#rdwe(msg,'NonText')
     return
  endif


  redraw!
  if ! ok
      let m = 'PERL BUILD FAIL: %s %s; target: %s; config: %s'
      let msg = printf(m,proj,s_dur,target,config)
      call base#rdwe(msg)
      if len(err)
        BaseAct copen
      else
        call base#buf#open_split({ 
          \ 'lines'   : lines,
          \ 'cmds_after' : [],
          \ 'stl_add' : [ 
              \ 'Command: %1*',
              \ cmd ,
              \ '%0*' ,
              \ ],
          \ })
      endif
      

      "\ 'V[ %1* v - view, %2* a - append %0* ]',
  else
      let m = 'PERL BUILD OK: %s %s; target: %s; config: %s'
      let msg = printf(m,proj,s_dur,target,config)
      call base#rdw(msg)
      BaseAct cclose
  endif
  echohl None
endf

if 0
  Usage
    projs#action#bld_join_Fc(self,temp_file)
  Call tree
    called by
      projs#action#bld_join
endif

function! projs#action#bld_join_Fc (self,temp_file) 
  let self      = a:self
  let temp_file = a:temp_file

  let root    = self.root
  let proj    = self.proj
  let start   = self.start

  let end      = localtime()
  let duration = end - start
  let s_dur    = ' ' . string(duration) . ' (secs)'
  
  if filereadable(a:temp_file)
    let out = readfile(temp_file)
    call base#buf#open_split({ 'lines' : out })
  endif

  call base#rdw(printf('OK: bld_join (project: %s)', proj))
endf

function! projs#action#fig_view (...) 
  let r = {
      \ 'ext'    : 'pl',
      \ 'pat'    : 'fig',
      \ 'prompt' : 0,
      \ }
  call projs#db_cmd#list_secs(r)
endf

function! projs#action#fig_create (...) 
  let bsec = projs#buf#sec()

  let fsec  = printf('_perl.fig.%s',bsec)
  let iisec = printf('fig.%s',bsec)

  call append(line('.'),'\def\sectitle{}')
  call append(line('.'),printf('\ii{fig.%s}',bsec))

  call projs#sec#new(fsec)
  call projs#sec#new(iisec)

  call projs#sec#open_load_buf(iisec)
  call projs#sec#open_load_buf(fsec)

endf

"""prjact_async_build_bare
if 0
  Usage
    projs#action#async_build_bare()
  Call tree
    calls
      projs#proj#name
      projs#root
      projs#sec#file
      projs#sec#new
endif


function! projs#action#async_build_bare (...) 
  let ref = get(a:000,0,{})

  let root    = projs#root()
  let root_id = projs#rootid()

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let mode = '_bb_tex_'

  let start = localtime()
  call chdir(root)

  let cmd = ''

  let bat = has('win32') ? 'bb_tex.bat' : 'bb_tex.sh'
  let cmd = join([ bat, proj, '-c bare' ], ' ' )
  
  let env = {
    \ 'proj'  : proj,
    \ 'root'  : root,
    \ 'start' : start,
    \ 'mode'  : mode,
    \ }

  function env.get(temp_file) dict
    call projs#action#async_build_bare_Fc(self,a:temp_file)
  endfunction

  echo printf('async_build_bare: %s, mode: %s', proj, mode)

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
    let jlines = projs#filejoinlines({ 
      \ 'write_jfile' : 1 
      \ })
    VSEC _join_
endfunction

function! projs#action#html_out_view ()
  call projs#html_out#view ()
endfunction

"""pa_get_img
function! projs#action#get_img ()
  let pl   = base#qw#catpath('plg projs scripts bufact tex get_img.pl')

  let pl_e = shellescape(pl)

  let proj = projs#proj#name()
  let cmd  = join([ 'perl', pl_e, '-p', proj ], ' ')

  call base#rdw('Getting images: ' . proj)
  
  let env = { 'proj' : proj }
  function env.get(temp_file) dict
    let temp_file = a:temp_file
    let code      = self.return_code

    if filereadable(a:temp_file) 
      let out  = readfile(a:temp_file)
      let last = get(out,-1,'')

      if last =~ 'SUCCESS:\s\+\(\d\+\)\s\+images' 
        call base#rdw(last)

      elseif last =~ 'NO IMAGES'
        call base#rdw(last,'Conditional')

      else
        call base#rdwe(last)
        call base#buf#open_split({ 'lines' : out })
      endif
    else
    endif
  endfunction
  
  call asc#run({ 
    \ 'path' : projs#root(),
    \ 'cmd'  : cmd,
    \ 'Fn'   : asc#tab_restore(env)
    \ })

endf

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
    \ "proj"   : proj,
    \ "sec"    : sec,
    \ "root"   : root,
    \ "rootid" : rootid,
    \ "file"   : b:basename,
    \ "pid"    : pid,
    \ "fid"    : fid,
    \ }
  
  let ref = {
    \ "dbfile" : projs#db#file(),
    \ "i"      : "INSERT OR REPLACE",
    \ "t"      : t,
    \ "h"      : h,
    \ }
    
  call pymy#sqlite#insert_hash(ref)
  
endfunction

function! projs#action#verb_new ()
  let dir = projs#root()
  let proj = projs#proj#name()

  let files = projs#db#files()

  let files = filter(files,'v:val =~ printf("^%s.verb_",proj)')

  let num = 1
  if len(files)
    let pat = printf("^%s.verb_\\zs\\d\\+\\ze.*$",proj)
    let nums = map(copy(files),'matchstr(v:val,pat)')
    let num = max(nums) + 1
  endif

  let sec = printf('verb_%s',num)
  call projs#sec#new(sec)
  call base#rdw(printf('created new section: %s',sec))

  call append('.',printf('\ii{%s}',sec))
  TgUpdate projs_this

endfunction

function! projs#action#list_projs ()
  let projs = projs#list()

  let proj = projs#proj#name()

  let data = []
  for proj in projs
    call add(data,[proj,''])
  endfor

  let lines = [ 
      \ 'Current project:' , "\t" . proj,
      \ '   List of Projects: ' 
      \ ]

  call extend(lines, pymy#data#tabulate({
      \ 'data'    : data,
      \ 'headers' : [ 'project', 'description' ],
      \ }))

  let s:obj = { 'proj' : proj }
  function! s:obj.init (...) dict
      let proj = self.proj
      let hl = 'WildMenu'
      call matchadd(hl,'\s\+'.proj.'\s\+')
      call matchadd(hl,proj)
  endfunction
    
  let Fc = s:obj.init

  call base#buf#open_split({ 
      \ 'lines'    : lines ,
      \ 'cmds_pre' : ['resize 99'] ,
      \ 'Fc'       : Fc,
      \ })
  return

endfunction

"""prjact_tex_show_command
function! projs#action#tex_show_command ()
  let root = projs#root()
  let proj = projs#proj#name()

  let bat = 'tex_show_command.bat'

  let class   = input('class: ','','custom,projs#complete#tex_documentclasses')
  let macro   = input('TeX macro: ','','custom,projs#complete#tex_macros')

  let cmd_bat = join([ bat, macro, class ], ' ')
  
  let env = {}
  function env.get(temp_file) dict
    let temp_file = a:temp_file
    let code      = self.return_code
  
    if filereadable(a:temp_file)
      let out = readfile(a:temp_file)
      call base#buf#open_split({ 'lines' : out })
    endif
  endfunction
  
  call asc#run({ 
    \ 'cmd' : cmd_bat, 
    \ 'Fn'  : asc#tab_restore(env) 
    \ })

endfunction

"""pa_author_add
function! projs#action#author_add (...)
  let ref = get(a:000,0,{})

  let author_id = get(ref,'author_id','')

  let hash = projs#author#hash()

  let a_data    = projs#author#select({ 'author_id' : author_id })

  let author    = get(a_data,'author','')
  let author_id = get(a_data,'author_id','')

  call projs#author#add({ 
     \  'author_id' : author_id,
     \  'author'    : author })

endfunction

"""pa_author_list
function! projs#action#author_list ()
  let hash = projs#author#hash()

  let data = []
  let head = [ 'author_id', 'author' ]

  let proj = projs#proj#name()

  for author_id in sort(keys(hash))
    let author = get(hash,author_id,'')

    call add(data, [ author_id, author ])
  endfor

  let lines = []
  call extend(lines,[ printf('List of authors for project: %s' , proj) ])

  let l_data = pymy#data#tabulate({
    \ 'data'    : data,
    \ 'headers' : head,
    \ })
  call extend(lines,l_data)

  call base#buf#open_split({ 'lines' : lines })

endfunction

function! projs#action#tree_view ()
  let file = projs#tree#file()

  call base#fileopen({ 
    \ 'files'    : [file] ,
    \ 'load_buf' : 1,
    \ })

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
    \ 'files'    : [xmlfile] ,
    \ 'load_buf' : 1,
    \ })
  
endfunction

function! projs#action#_xml_update_col()
  let xmlfile = projs#xmlfile()

  let proj = projs#selectproject()
  let r = {
    \ 'q'      : 'SELECT sec FROM projs WHERE proj = ?',
    \ 'p'      : [proj],
    \ 'dbfile' : projs#db#file(),
    \ }
  let secs = pymy#sqlite#query_as_list(r)
  call base#varset('this',secs)

  let msg_a = [
    \ printf("[proj=%s]select section:",proj),  
    \ ]
  let msg = join(msg_a,"\n")
  let sec = base#input_we(msg,'',{ 'complete' : 'custom,base#complete#this' })

  let col = 'tags'

  let val = input(printf('[proj=%s,sec=%s,col=%s] new value:',proj,sec,col),'')

  let r = {
      \ 'proj' : proj,
      \ 'sec' : sec,
      \ 'val' : val,
      \ 'col' : col,
      \ 'xmlfile' : xmlfile,
      \ }
  call projs#xml#update_col(r)

endfunction


function! projs#action#view_db_fill_tags_py3()
  let file = base#qw#catpath('plg projs scripts db_fill_tags.py3')
  call base#fileopen({ 
    \ 'files'    : [file] ,
    \ 'load_buf' : 1,
    \ })

endfunction
