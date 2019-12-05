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

endfunction

"""prjact_csv_query
function! projs#action#csv_query ()
  let proj   = projs#proj#name()
  let csvdir = projs#path([ 'csv' , proj ])

perl << eof
  use DBI;

  my $warn=sub { VimWarn(@_); };

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
  let projs = projs#list()

  let r = {
      \ 'data'   : { 'projs' : projs },
      \ 'dir'    : base#qw#catpath('plg projs scripts'),
      \ 'script' : 'gui_select_project',
      \ 'args'   : [ '-r' ],
      \ }
  call base#script#run(r) 

endfunction

function! projs#action#async_build_Fc (self,temp_file) 
  let self      = a:self
  let temp_file = a:temp_file

  let code  = self.return_code
  let root  = self.root
  let proj  = self.proj
  let start = self.start

  let end = localtime()
  let duration =  end - start
  let s_dur = ' ' . string(duration) . ' (secs)'
  
    if filereadable(a:temp_file)
      call tex#efm#latex()
      exe 'cd ' . root
      exe 'cgetfile ' . a:temp_file
      
      let err = getqflist()
      
      redraw!
      if len(err)
        echohl WarningMsg
        echo 'BUILD FAIL: ' . proj . s_dur
        BaseAct copen
      else
        echohl MoreMsg
        echo 'BUILD OK: ' . proj . s_dur
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

function! projs#action#async_build () 
  let proj = projs#proj#name()
  let root = projs#root()

  "let cmd = 'pdflatex '
  let sec_bat = '_build_pdflatex_'
  let bat     = projs#sec#file(sec_bat)
  "if !filereadable(bat)
  "endif

  let o = { 'prompt' : 0 }
  call projs#sec#new(sec_bat,o)

  let start = localtime()
  
  let env = {
    \ 'proj'  : proj,
    \ 'root'  : root,
    \ 'start' : start,
    \ }
  let cmd = bat

  function env.get(temp_file) dict
    call projs#action#async_build_Fc(self,a:temp_file)
  endfunction

  echo 'async_build: ' . proj

  call asc#run({ 
    \ 'cmd' : cmd, 
    \ 'Fn'  : asc#tab_restore(env) 
    \ })

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

