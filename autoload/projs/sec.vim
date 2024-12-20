
"---------------------------------
"
" Section-related functions:
"
"   projs#sec#new(sec)
"
"   projs#sec#rename(new, old)
"
"   projs#sec#open(sec)
"   projs#sec#append({ sec : sec, lines : lines })
"
"---------------------------------
"
function! projs#sec#append (...)
  let ref = get(a:000,0,{})

  let sec   = get(ref,'sec','')
  let lines = get(ref,'lines',[])
  let text  = get(ref,'text','')

  call extend(lines, split(text,"\n") )

  let file = projs#sec#file(sec)

  let r = {
      \ 'lines' : lines,
      \ 'file'  : file,
      \ 'mode'  : 'append',
      \ }
  call base#file#write_lines(r)

endf

"Usage:
"   call projs#sec#rename_mv (old, new)

function! projs#sec#rename_mv (...)
  let new = get(a:000,0,'')
  let old = get(a:000,1,old)
endf

function! projs#sec#rename_adjust (...)
  let old = get(a:000,0,'')
  let new = get(a:000,1,'')

  let newf = projs#sec#file(new)

  let oldf_base = projs#sec#file_base(old)
  let newf_base = projs#sec#file_base(new)

  let lines = readfile(newf)

  let nlines = []
  let pats = {}
  call extend(pats,{ '^\(%%file\s\+\)\(\w\+\)\s*$' : '\1'.new  })
  call extend(pats,{ '^\(\\label{sec:\)'.old.'\(}\s*\)$' : '\1'.new.'\2' })

  for line in lines
    for [ pat, subpat ] in items(pats)
      if line =~ pat
        let line = substitute(line,pat,subpat,'g')
      endif
    endfor

    call add(nlines,line)
  endfor

  call writefile(nlines,newf)

  let pfiles = projs#proj#files()
  let ex = {}
  for pfile in pfiles
    call extend(ex,{ pfile : 1 })
  endfor
  call extend(ex,{ newf_base : 1, oldf_base : 0 })

  let pfiles = []
  for [ file, infile ] in items(ex)
    if infile
      call add(pfiles,file)
    endif
  endfor

  let f_listfiles = projs#sec#file('_dat_files_')

  call base#file#write_lines({
      \ 'lines' : pfiles,
      \ 'file'  : f_listfiles,
      \})

endf

"Usage:
"   call projs#sec#rename (old, new)
"   call projs#sec#rename (new)

function! projs#sec#rename (...)

  let old = projs#proj#secname()
  let new = ''

  if a:0 == 2
    let old = get(a:000,0,old)
    let new = get(a:000,1,new)

  elseif a:0 == 1
    let new = get(a:000,0,new)
  endif

  while !strlen(new)
    let msg = printf('[ sec=%s ] New section name: ',old)
    let new = input(msg,'','custom,projs#complete#secnames')
  endw

  let oldf = projs#sec#file(old)
  let newf = projs#sec#file(new)

  let oldf_base = projs#sec#file_base(old)
  let newf_base = projs#sec#file_base(new)

  let msg_a = [
    \ " ",
    \ "Old: " . oldf,
    \ "New: " . newf,
    \ " ",
    \ "This will rename sections, old => new",
    \ " ",
    \ "Are you sure? (1/0): ",
    \ ]
  let msg = join(msg_a,"\n")
  let do_rename = base#input_we(msg,0,{ })
  if !do_rename
    redraw!
    echohl MoreMsg
    echo 'Rename aborted'
    echohl None
    return
  endif

  call rename(oldf,newf)

  call projs#sec#rename_adjust(old, new)

  call projs#proj#secnames()
  call base#fileopen({ 'files' : [newf]})

endfunction

function! projs#sec#delete_prompt (...)
  let sec = projs#proj#secname()
  let sec = get(a:000,0,sec)
  call projs#sec#delete(sec,{ 'prompt' : 1})
endfunction

function! projs#sec#date (...)
  let ref = get(a:000,0,{})
  let sec = get(ref,'sec','')

  let lang = get(ref,'lang','en')
  let repr = get(ref,'repr','short')

  let lst = matchlist(sec, '^\zs\(\d\+\)_\(\d\+\)_\(\d\+\)\ze')

  " no match for dates
  if !len(lst) | return {} | endif

  let [ date, day, month, year ] = lst[0:3]

  let day = substitute(day,'^0','','g')
  let month = substitute(month,'^0','','g')

  let yfile = base#qw#catpath('plg','projs data yaml months.yaml')
  let map_months = base#yaml#parse_fs({ 'file' : yfile })

  let path = join([lang, repr, month], '.')
  let month_str = base#x#getpath(map_months, path, '')

  let r = {
      \ 'date'  : date,
      \ 'day'   : day,
      \ 'month' : month_str,
      \ 'year'  : year,
      \ }

  return r

endfunction

"Usage:
"  call projs#sec#delete (sec)
"
"Call tree:
"  Calls:
"    projs#proj#secname
"    projs#sec#file

function! projs#sec#delete (...)

  let sec = projs#proj#secname()
  let sec = get(a:000,0,sec)

  let opts = {}
  let opts = get(a:000,1,opts)

  let prompt = get(opts,'prompt',0)

  if prompt
    let do_del = input(printf('[ %s ] Delete section? (1/0): ',sec),0)
    if !do_del
      call base#rdwe('deletion aborted')
      return
    endif
  endif

  let ok = 1
  let ok = ok && projs#sec#delete_from_vcs(sec)
  let ok = ok && projs#sec#delete_from_db(sec)
  let ok = ok && projs#sec#delete_from_fs(sec)

  if ok
    call projs#echo('Section has been deleted: ' . sec)
  endif

endfunction

function! projs#sec#delete_from_vcs (sec,...)
  let sec = a:sec

  let secfile   = projs#sec#file(sec)

  if filereadable(secfile)
    let dirname = fnamemodify(secfile,':p:h')
    let bname   = fnamemodify(secfile,':p:t')
    call base#cd(dirname)
    let cmd = 'git rm ' . bname . ' --cached '
    let ok = base#sys({
      \ "cmds"         : [cmd],
      \ "split_output" : 0,
      \ "skip_errors"  : 1,
      \ })
  else
    call projs#warn('Section file does not exist for: '.sec)
    return
  endif

endfunction


function! projs#sec#delete_from_fs (sec,...)
  let sec = a:sec

  let secfile   = projs#sec#file(sec)

  let ok = base#file#delete({ 'file' : secfile })
  return ok
endfunction

function! projs#sec#delete_from_db (sec,...)
  let sec = a:sec

  let ref = get(a:000,0,{})

  let dbfile  = projs#db#file()

  let proj = projs#proj#name()

  let r = {
      \  'q' : 'DELETE FROM projs WHERE proj = ? AND sec = ?',
      \  'p' : [ proj, sec ],
      \  }
  call pymy#sqlite#query(r)
  let ok = 1

  return ok
endfunction

function! projs#sec#onload (sec)
  let sec = a:sec

  let prf = { 'prf' : 'projs#sec#onload' }
  call base#log([
    \ 'sec => ' . sec,
    \ ],prf)
  call projs#sec#add(sec)

  return
endfunction

function! projs#sec#parent ()
  let parent = projs#varget('parent_sec','')
  return parent
endfunction

if 0
  call tree
    calls
      projs#sec#file_base_a
endif

function! projs#sec#file (...)
  let proj = projs#proj#name()

  let sec = projs#proj#secname()
  let sec = get(a:000,0,sec)

  if !len(sec)
    return ''
  endif

  let secfile = projs#path( projs#sec#file_base_a(sec) )
  return secfile
endf

function! projs#sec#filecheck (...)
    let sec = a:1
    let sfile = projs#sec#file(sec)

    if !filereadable(sfile)
        call projs#sec#new(sec)
    endif

    return 1
endf


function! projs#sec#file_base (...)
  let sec = projs#proj#secname()
  let sec = get(a:000,0,sec)

  let sfile_a = projs#sec#file_base_a(sec)

  let sfile = base#file#catfile(sfile_a)
  return sfile
endf

if 0
  called by
    projs#sec#file
endif

function! projs#sec#file_base_a (...)

    let sec = projs#proj#secname()
    let sec = get(a:000,0,sec)

    let dot = '.'

    let proj = projs#proj#name()

    let root_id = projs#rootid()

    let sfile_a = []

    let runext = (has('win32')) ? 'bat' : 'sh'

    if sec == '_main_'
        let sfile_a = [ proj.'.tex']

    elseif sec == '_vim_'
        let sfile_a = [ proj.'.vim']

    elseif sec =~ '^_bld\.'
        let target = substitute(copy(sec),'^_bld\.\(.*\)$','\1','g')
        let sfile_a = [ printf('%s.bld.%s.yml',proj,target) ]

    elseif sec =~ '^_perl\.'
        let sec = substitute(sec,'^_perl\.\(.*\)$','\1','g')
        let sfile_a = [ printf('%s.%s.pl',proj,sec)]

    elseif sec =~ '_pm.'
        let sec = substitute(sec,'^_pm\.\(.*\)$','\1','g')
        let sfile_a = [ 'perl', 'lib', 'projs', root_id, proj, printf('%s.pm',sec)]

    elseif sec == '_pl_'
        let sfile_a = [ proj.'.pl']

    elseif sec == '_zlan_'
        let sfile_a = [ printf('%s.zlan',proj) ]

    elseif sec == '_sql_'
        let sfile_a = [ proj.'.sql']

    elseif sec == '_yml_'
        let sfile_a = [ proj.'.yml' ]

    elseif sec == '_osecs_'
        let sfile_a = [ proj.'.secorder.i.dat']

    elseif sec == '_dat_'
        let sfile_a = [ proj . '.secs.i.dat' ]

    elseif sec == '_ii_include_'
      let sfile_a = [ proj . '.ii_include.i.dat' ]

    elseif sec == '_ii_exclude_'
      let sfile_a = [ proj . '.ii_exclude.i.dat' ]

    elseif sec == '_dat_defs_'
      let sfile_a = [ proj . '.defs.i.dat' ]

    elseif sec == '_dat_files_'
      let sfile_a = [ proj . '.files.i.dat' ]

    elseif sec == '_dat_files_ext_'
      let sfile_a = [ proj . '.files_ext.i.dat' ]

    elseif sec == '_dat_citn_'
        let sfile_a = [ proj.'.citn.i.dat']

    elseif sec == '_bib_'
        let sfile_a = [ proj.'.refs.bib']

    elseif sec == '_tex_jnd_'
        let sfile_a = [ 'builds', proj, 'src', 'jnd.tex' ]

    elseif sec == '_join_'
        let sfile_a = [ 'joins', proj . '.tex' ]

    elseif sec == '_build_pdflatex_'
        let sfile_a = [ 'b_' . proj . '_pdflatex.'.runext ]

    elseif sec == '_build_perltex_'
        let sfile_a = [ 'b_' . proj . '_perltex.'.runext ]

    elseif sec == '_build_htlatex_'
        let sfile_a = [ 'b_' . proj . '_htlatex.'.runext ]

    elseif sec == '_main_htlatex_'
        let sfile_a = [ proj . '.main_htlatex.tex' ]

    else
        let sfile_a = [proj.dot.sec.'.tex']

    endif

    return sfile_a

endfunction

"call tree
"  called by
"    projs#sec#add

function! projs#sec#add_to_secnames (sec)
  let sec = a:sec

  if ! projs#sec#exists(sec)
    let secnames    = base#varref('projs_secnames',[])
    let secnamesall = base#varref('projs_secnamesall',[])

    call add(secnames,sec)
    call add(secnamesall,sec)

    let secnamesall = base#uniq(secnamesall)
    let secnames    = base#uniq(secnames)
  endif
endfunction

function! projs#sec#add_to_dat (sec,...)
  let ref = get(a:000,0,{})

  let sec = a:sec

  let sfile = projs#sec#file(sec)
  let sfile = fnamemodify(sfile,':p:t')

  let pfiles =  projs#proj#files()
  if !base#inlist(sfile, pfiles)
    call add(pfiles,sfile)

    let f_listfiles = projs#sec#file('_dat_files_')
    call base#file#write_lines({
      \ 'lines' : pfiles,
      \ 'file'  : f_listfiles,
      \})
  endif
endfunction


function! projs#sec#add_to_xml (sec,...)
  let ref=get(a:000,0,{})

  let sec = a:sec
  let proj = get(ref,'proj','')
  let xmlfile = projs#xmlfile()
  let cols = projs#xml#cols()

python3 << eof
import vim
import xml.etree.ElementTree as ET
import xml.dom.minidom as minidom
from xml.etree.ElementTree import Element, SubElement, Comment, tostring

def prettify(elem):
    """Return a pretty-printed XML string for the Element.
    """
    rough_string = ET.tostring(elem, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ")

sec     = vim.eval('sec')
xmlfile = vim.eval('xmlfile')
proj    = vim.eval('proj')

cols = vim.eval('cols')

tree = ET.ElementTree(file=xmlfile)
root = tree.getroot()

e_sec = Element('sec')
for col in cols:
  e_col = Element(col)

for e in root.findall('.//proj[@name={}]'.format(proj))
  e.append(e_sec)

xml = prettify(root)
eof
  let xml = py3eval('xml')
  let r = {
        \   'lines'  : split(xml,"\n"),
        \   'file'   : xmlfile,
        \ }
  call base#file#write_lines(r)

endfunction

if 0
  usage
    projs#sec#add_to_db(sec)
    projs#sec#add_to_db(sec,{ 'db_data' : db_data })
  call tree
    called by
      projs#sec#new
endif

function! projs#sec#add_to_db (sec,...)
  let ref = get(a:000,0,{})

  let tags   = get(ref,'tags','')

  let db_data = get(ref,'db_data',{})

  let sec    = a:sec

  let dbfile  = projs#db#file()

  let sfile = projs#sec#file(sec)
  let sfile = fnamemodify(sfile,':p:t')

  let root   = projs#root()
  let rootid = projs#rootid()

  let proj = projs#proj#name()

  let t = "projs"
  let h = {
    \ "rootid" : rootid,
    \ "proj"   : proj,
    \ "sec"    : sec,
    \ "file"   : sfile,
    \ "tags"   : tags,
    \ }
  call extend(h, db_data)
python3 << eof
import vim
from plg.projs.Prj.Prj import Prj
from plg.projs.Prj.Section import Section

h = vim.eval('h')

root    = vim.eval('root')
rootid  = vim.eval('rootid')

db_file = vim.eval('dbfile')
proj    = vim.eval('proj')
sec     = vim.eval('sec')

section = Section(h)

prj = Prj({
  'db_file' : db_file,
  'proj'    : proj,
  'root'    : root,
  'rootid'  : rootid,
})

prj.add(h)

eof

endfunction

if 0
  call tree
    called by
      projs#insert#ii_url

endif

if 0
  call tree
    calls
      pymy#sqlite#query
        base#sql#split
endif

function! projs#sec#ii_max (...)
  let ref = get(a:000,0,{})

  let ii_prefix = get(ref,'ii_prefix','')
  let iipe      = escape(ii_prefix,'.')

  let qs = printf("MAX( CAST(RGX_SUB('^%s(\\d+)\\..*', '\\1', sec) AS INTEGER) )", iipe)
  let q  = printf("SELECT %s as s FROM projs WHERE RGX('^%s(\\d+)',sec)", qs, iipe)

  let ref = {
    \ 'q'      : q,
    \ 'dbfile' : projs#db#file(),
    \ }

  let [rows,cols] = pymy#sqlite#query(ref)

  let rwh  = get(rows,0,{})
  let vals = values(rwh)
  let max  = get(vals,0,0)
  let max  = ( max == v:none || max == '') ? 0 : max

  return max

endf

function! projs#sec#count_ii (...)
  let ref = get(a:000,0,{})

  let ii_prefix = get(ref,'ii_prefix','')
  let iipe = escape(ii_prefix,'.')

  "let q = printf("SELECT COUNT(*) FROM projs WHERE sec LIKE '%s%%'",ii_prefix)
  "let q = printf("SELECT sec FROM projs WHERE sec LIKE '%s%%'",ii_prefix)
  let qs = printf("MAX( CAST(RGX_SUB('^%s(\\d+)\\..*', '\\1', sec) AS INTEGER) )", iipe)
  let q = printf("SELECT %s as s FROM projs WHERE RGX('^%s',sec)", qs, iipe)

"def rgx_sub(pattern, replacement, string):

  let ref = {
    \ 'q'      : q,
    \ 'dbfile' : projs#db#file(),
    \ }

  let [rows,cols] = pymy#sqlite#query(ref)
  let nums = []
  "for rw in rows
    ""let sec = get(rw,'sec','')
    ""let num =
  "endfor

  debug let rwh  = get(rows,0,{})
  let vals = values(rwh)
  let cnt  = vals[0]

  return cnt

endfunction


if 0
  projs#sec#add

  Purpose:
    - add sec to the list of sections in dat-file: _dat_files_
    - add sec to var: projs_secnames
    - add sec to var: projs_secnamesall
    - add sec to db

  Usage:
    call projs#sec#add (sec)

    call projs#sec#add (sec, { 'db_data' : db_data })
  Returns:
    1
  Call tree:
    calls:
      projs#sec#add_to_secnames
      projs#sec#add_to_dat
      projs#sec#add_to_db
        projs#db#file
        projs#sec#file
        pymy#sqlite#insert_hash
    called by:
      projs#sec#new
endif

if 0
  Usage
    projs#sec#add(sec, { ... })
  Call tree
    calls
      projs#sec#add_to_secnames
      projs#sec#add_to_dat
      projs#sec#add_to_db
        from plg.projs.Prj.Prj import Prj
        from plg.projs.Prj.Section import Section

        s = Section({ ..., db_data })
        Prj.add(s)
endif

function! projs#sec#add (sec,...)
  let ref = get(a:000,0,{})

  let sec   = a:sec

  call projs#sec#add_to_secnames(sec)
  call projs#sec#add_to_dat(sec)
  call projs#sec#add_to_db(sec,ref)
  "call projs#sec#add_to_xml(sec)

  return 1
endfunction

function! projs#sec#record (sec)
  let sec    = a:sec

  let proj   = projs#proj#name()
  let dbfile = projs#db#file()
python3 << eof
import vim
from plg.projs.Prj.Prj import Prj

sec     = vim.eval('sec') or ''
proj    = vim.eval('proj') or ''
db_file = vim.eval('dbfile') or ''

prj = Prj({ 'proj' : proj, 'db_file' : db_file })
section = prj._section({ 'sec' : sec })
record = section._record()
eof
  let record = py3eval('record')
  return record

endfunction

function! projs#sec#is_date_my (sec)
  let sec = a:sec

  let list  = matchlist(sec,'^\(\w\+\)_\(\d\+\)$')

  let month = get(list,1,'')
  let year  = get(list,2,'')

  let is_date = len(month) && len(year) && base#inlist(month,base#varget('projs_months_3',[])) ? 1 : 0
  return is_date

endfunction

function! projs#sec#select (...)
  let ref = get(a:000,0,{})

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let db_file = projs#db#file()

  let pat  = get(ref,'pat','')
  let ext  = get(ref,'ext','')

  let header = [ 'projs section selection dialog' ]
  let header = get(ref,'header',header)

  let secs = projs#db#secnames(ref)

  let r = {
    \ 'list'   : secs,
    \ 'thing'  : 'section',
    \ 'prefix' : 'select',
    \ 'header' : header,
    \ }
  let sec = base#inpx#ctl(r)

  return sec

endfunction

function! projs#sec#insert_url (...)
  let ref = get(a:000,0,{})

  let sec = projs#buf#sec()
  let sec = get(ref,'sec',sec)

  let proj = projs#proj#name()

  let url = get(ref,'url','')

  let pylib   = projs#pylib()
  call pymy#py3#add_lib( pylib . '/plg/projs' )

  let file = projs#sec#file(sec)
python3 << eof
import vim,in_place,re
import Base.DBW as dbw

file      = vim.eval('file')
url       = vim.eval('url')
db_file   = vim.eval('projs#db#file()')

proj      = vim.eval('proj')
sec       = vim.eval('sec')

is_head = 0

url_cmt_done = 0
url_tex_done = 0

url_cmt = '%%url ' + url

url_tex = [ r'\Purl{%s}' % url ]
#url_tex = [
#  r'{ \small'          ,
#  r'\vspace{0.5cm}'    ,
#  r'\url{' + url + '}' ,
#  r'\vspace{0.5cm}'    ,
#  r'}'                 ,
#]

lines_w = []
f     = open(file,'rb')

lines = f.read().splitlines()

try:
  for ln in lines:
      line = ln.decode('utf-8')
      end_head = 0
      after_head = 0
      if re.match(r'^%%url\s+', line):
        url_cmt_done = 1
        line         = url_cmt
      if re.match(r'^\s*\\url\{.*\}\s*$', line):
        url_tex_done = 1
      if re.match(r'^%%beginhead', line):
        is_head = 1
      if re.match(r'^%%endhead', line):
        is_head = 0
        end_head = 1
        if url_cmt_done == 0:
          lines_w.append(url_cmt)
      lines_w.append(line)

  if url_tex_done == 0:
     lines_w.extend(url_tex)
finally:
  f.close()

b    = vim.current.buffer
b[:] = []
b[:] = lines_w

dbw.update_dict({
  'db_file' : db_file,
  'table'   : 'projs',
  'update'  : {
    'url' : url
  },
  'where' : {
    'sec'  : sec,
    'proj' : proj,
  },
  'db_close' : 1,
})

eof
  let b:url = url
  call base#rdw('Updated URL: ', url)

endfunction

function! projs#sec#buf (sec)
  let sec = a:sec

  let sfile = projs#sec#file(sec)
  let w = {
      \ 'root'      : projs#root(),
      \ 'file_full' : sfile,
      \ }
  let bufs = base#buffers#get().with(w).bufs
  return get(bufs,0,{})
endfunction

function! projs#sec#exists (...)
  let sec = get(a:000,0,'')

  let ok = 1
  let ok = ok && projs#sec#exists_db({ 'sec' : sec })
  let ok = ok && projs#sec#exists_fs(sec)

  return ok

endfunction

function! projs#sec#exists_db (...)
  let ref = get(a:000,0,{})

  let dbfile = projs#db#file()

  let [ rows_h, cols ] = pymy#sqlite#select({
    \  'dbfile' : dbfile,
    \  't'      : 'projs',
    \  'f'      : 'sec',
    \  'w'      : ref,
    \  })
  return len(rows_h) ? 1 : 0

endfunction

function! projs#sec#exists_fs (...)
  let sec = get(a:000,0,'')

  let sec_file = projs#sec#file(sec)

  let ok = 1
  let ok = ok && filereadable(sec_file)

  return ok

endfunction

if 0
  called by
    projs#visual#cut_to_verb
endif

function! projs#sec#verb_new()
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
  return sec
endfunction


if 0
  Usage
     call projs#sec#new(sec,{...})

     projs#sec#new(sec)
     projs#sec#new(sec,{ "git_add" : 1 })
     projs#sec#new(sec,{ "view" : 1 })
     projs#sec#new(sec,{ "prompt" : 0 })
     projs#sec#new(sec,{ "rewrite" : 1 })


  Call tree
    Calls
      projs#buf#sec
      projs#proj#name
      projs#sec#header
      projs#sec#lines_seccmd
      projs#sec#parent


endif

"""end_help_projs_sec_new

if 0
  call tree
    called by
      projs#insert#ii
      projs#insert#ii_url
      projs#new
    calls
      projs#sec#header
      projs#sec#add ( sec_new_sec_add )
        projs#sec#add_to_secnames
        projs#sec#add_to_dat
        projs#sec#add_to_db
          from plg.projs.Prj.Prj import Prj
          from plg.projs.Prj.Section import Section

          s = Section({ ..., db_data })
          Prj.add(s)
endif

"""sec_new_start {

function! projs#sec#new(sec,...)
    let sec = a:sec

    let ref = get(a:000,0,{})

    let proj   = projs#proj#name()

    let rootid = projs#rootid()

    let rw = get(ref, 'rewrite', 0)
    if projs#sec#exists(sec) && !rw
      return
    endif

    let parent_sec = get(ref,'parent_sec','')

    " e.g. section, subsection
    let sec_type   = get(ref,'sec_type','')

    let git_add    = get(ref,'git_add',0)

    let url        = get(ref,'url','')

    let author_id  = get(ref,'author_id','')

    let title      = get(ref,'title','')
    let tags       = get(ref,'tags','')
    let date       = get(ref,'date','')

    let o = base#varget('projs_opts_PrjSecNew',{})

    let prompt = get(o,'prompt',1)
    let prompt = get(ref,'prompt',prompt)

    call projs#echo("Creating file:\n\t" . sec )

    let lines = []
    call extend(lines, get(ref, 'add_lines_before', [] ) )

    let sec_file = projs#sec#file(sec)

    let sec_ext  = fnamemodify(sec_file,':p:e')

"""head_newsec
    let rh = {
      \ 'sec'        : sec,
      \ 'ext'        : sec_ext,
      \ 'parent_sec' : parent_sec,
      \ 'url'        : url,
      \ 'author_id'  : author_id,
      \ 'tags'       : tags,
      \ 'date'       : date,
      \ 'title'      : title,
      \ }

    if sec_ext == 'tex'
      let keymap = projs#select#keymap({ 'prompt' : prompt })
      if strlen(keymap)
        call extend(rh,{ 'keymap' : keymap })
      endif
    endif
    call extend(lines, projs#sec#header(rh) )

"""newsec_sec_type
"
    if sec_ext == 'tex'
        if len(sec_type)
          if len(title)
            let l_title = [
              \ ' ',
              \ printf('\%s{%s}' , sec_type, title),
              \ printf('\label{sec:%s}' , sec),
              \ ' ',
              \ ]
            call extend(lines, l_title)
          endif

          let bw = base#word('insert_plus')
        endif
    endif

    if len(url)
      call extend(lines, [ printf('\Purl{%s}',url) ])
    endif
    if len(author_id)
      call extend(lines, [
          \ '\ifcmt',
          \ ' author_begin',
          \ '   ' . printf('author_id %s',author_id),
          \ ' author_end',
          \ '\fi',
          \ ])
    endif

    let projtype = projs#varget('projtype','regular')
    let sub = printf('projs#newseclines#%s#%s', projtype, sec)

    let r = {
       \ 'proj'  : proj,
       \ 'sec'   : sec,
       \ 'title' : title,
       \ }

    try
      exe printf('call extend(lines,%s(r))',sub)
    catch
      call projs#warn('Problems while executing:'."\n\t".sub)
    endtry

    let inref = { 'prompt' : prompt }

    if sec =~ '^fig_'
      call extend(lines,projs#newseclines#fig_num(sec))

    elseif sec =~ '^fig\.'
      let fig = substitute(copy(sec),'^fig\.\(.*\)','\1','g')

      let tex_file = base#qw#catpath('plg','projs data tex fig.tex')
      call extend(lines,readfile(tex_file))

      let nlines=[]
      for line in lines
        let line = substitute(line,'_sec_',sec,'g')
        call add(nlines,line)
      endfor
      let lines = nlines

"""newsec__yml_
    elseif sec =~ '_yml_'
      let yml_file = base#qw#catpath('plg','projs templates yml proj.yml')
      if filereadable(yml_file)
        call extend(lines,readfile(yml_file))

        let nlines = []
        for line in lines
          let line = substitute(line,'_proj_',proj,'g')
          call add(nlines,line)
        endfor
        let lines = nlines
      endif

"""newsec__bld.
    elseif sec =~ '_bld\.'
      let target = substitute(copy(sec),'^_bld\.\(.*\)$','\1','g')

      let yml_file = base#qw#catpath('plg',printf('projs templates yml proj.bld.%s.yml',target))
      if filereadable(yml_file)
        call extend(lines,readfile(yml_file))

        let nlines = []
        for line in lines
          let line = substitute(line,'_proj_',proj,'g')
          call add(nlines,line)
        endfor
        let lines = nlines
      endif

"""newsec__perl.fig.
    elseif sec =~ '_perl\.fig\.'
      let fig_name = substitute(copy(sec),'^_perl\.fig\.\(.*\)','\1','g')

      let pl_file = base#qw#catpath('plg','projs data perl fig.pl')
      call extend(lines,readfile(pl_file))

      let nlines=[]
      for line in lines
        let line = substitute(line,'_sec_',fig_name,'g')
        call add(nlines,line)
      endfor
      let lines = nlines

"""newsec__perl
    elseif sec =~ '_perl\.'
      let sec_name = substitute(copy(sec),'^_perl\.\(.*\)','\1','g')

      let pl_file = base#qw#catpath('plg','projs data perl %s.pl')
      let pl_file = printf(pl_file,sec_name)

      if filereadable(pl_file)
        call extend(lines,readfile(pl_file))

        let nlines=[]
        for line in lines
          let line = substitute(line,'_proj_',proj,'g')
          let line = substitute(line,'_rootid_',rootid,'g')
          call add(nlines,line)
        endfor

        let lines = nlines
      endif

"""newsec__pm.
    " _pm.bld _pm.edt
    elseif sec =~ '_pm\.'
      let sec_name = substitute(copy(sec),'^_pm.\(.*\)','\1','g')

      let pm_file = base#qw#catpath('plg','projs data pm %s.pm')
      let pm_file = printf(pm_file,sec_name)

      call extend(lines,readfile(pm_file))

      let nlines=[]
      for line in lines
        let line = substitute(line,'_proj_',proj,'g')
        let line = substitute(line,'_rootid_',rootid,'g')
        call add(nlines,line)
      endfor
      let lines = nlines

      let sec_file = projs#sec#file(sec)
      let sec_dir  = fnamemodify(sec_file,':p:r')

      call base#mkdir(sec_dir)

"""newsec__vim_
    elseif sec == '_vim_'
      let r = {
          \ 'proj'     : proj,
          \ 'projtype' : projtype,
          \ }
      call extend(lines,projs#newseclines#_vim_(r))

    elseif base#inlist(sec,base#qw('_build_perltex_ _build_pdflatex_'))
      let r = {
          \ 'proj' : proj,
          \ 'sec'  : sec,
          \ }
      call extend(lines, projs#newseclines#_build_tex_(r))

    else
      if prompt
        call extend(lines, projs#sec#lines_prompt(r))
      endif

    endif

    call extend(lines,get(ref,'add_lines_after',[]))

    call writefile(lines, sec_file)

    let db_data = {
      \ 'url'        : url,
      \ 'tags'       : tags,
      \ 'date'       : date,
      \ 'title'      : title,
      \ 'author_id'  : author_id,
      \ 'parent'     : parent_sec,
      \ }
"""sec_new_sec_add
    call projs#sec#add(sec,{ 'db_data' : db_data })

    let rx = (sec =~ '^_perl\.')
    if rx
      call system(printf("chmod +rx %s",shellescape(sec_file)))
    endif

    if git_add
      let dir   = fnamemodify(sec_file,':p:h')
      let bname = fnamemodify(sec_file,':p:t')

      exe 'cd ' . dir
      call base#sys("git add " . bname)
    endif

    let vv = get(ref,'view')
    if vv
       if base#type(vv) == 'Number'
         exe 'split ' . sec_file

       elseif base#type(vv) == 'String'
         if base#inlist(vv,base#qw('edit split'))
           exe printf('%s %s', vv, sec_file)
         endif
       endif
    endif

    return 1
endfunction
"""sec_new_end }

function! projs#sec#perl_open (sec,...)
  let sec = a:sec

  let root = projs#root()
  let proj = projs#proj#name()

  let file = base#file#catfile([ root, printf('%s.%s.pl',proj,sec) ])
  call base#fileopen({
    \ 'files'    : [file],
    \ 'load_buf' : 1,
    \ })
endfunction

if 0
  calls
    projs#sec#open
endif

function! projs#sec#open_load_buf (sec,...)
  let sec = a:sec
  call projs#sec#open(sec,{ 'load_buf' : 1 })
endfunction

if 0
  usage
    call projs#sec#open(sec)

    let opts = { 'load_buf' : 1, 'load_maps' : 1 }
    call projs#sec#open(sec,opts)
  call tree
    called by
      VSEC
endif

function! projs#sec#open (...)
 let proj = projs#proj#name()

 let parent_sec = projs#proj#secname()

 let sec      = get(a:000,0,'')
 let opts     = get(a:000,1,{})

 let load_buf  = get(opts,'load_buf',0)
 let load_maps = get(opts,'load_maps',1)

 if !strlen(sec)
    let sec = projs#select#sec()
 endif

 if !projs#sec#exists(sec)
    let cnt = input('Section does not exist, continue? (1/0):',1)
    if !cnt | return | endif

    call projs#sec#add(sec)
 endif

  call projs#varset("secname",sec)

  let vfile             = ''
  let vfiles            = []

  if projs#varget('secdirexists',0)
    let vfile = projs#path([ proj, sec . '.tex' ])
  else
    let vfile = projs#sec#file(sec)
  endif

  if sec == '_main_'
        for ext in projs#varget('extensions_tex',[])
            let vfile = projs#path([ proj . '.' . ext ])
                if filereadable(vfile)
                    call add(vfiles, vfile)
                endif
        endfor

  elseif sec == '_dat_'
    call projs#gensecdat()

    return
  elseif sec == '_osecs_'
    call projs#opensecorder()

    return

  elseif sec == '_join_'

    call projs#filejoinlines()

  elseif sec == '_pl_all_'
    call extend(vfiles,base#splitglob('projs',proj . '.*.pl'))
    call extend(vfiles,base#splitglob('projs',proj . '.pl'))
    let vfile=''

  else

    let vfile = projs#sec#file(sec)
  endif

  if strlen(vfile)
    call add(vfiles,vfile)
  endif

  call projs#varset('curfile',vfile)

  let vfiles = base#uniq(vfiles)

  call projs#varset("parent_sec",parent_sec)

  for vfile in vfiles
    if !filereadable(vfile)
      call projs#sec#new(sec)
    endif

    let ext = fnamemodify(vfile,':e')

    let s:obj = {
      \ 'sec'  : sec ,
      \ 'proj' : proj ,
      \ }
    function! s:obj.init (...) dict
      let b:sec  = self.sec
      let b:proj = self.proj
    endfunction

    let Fc = s:obj.init
    let res = base#fileopen({
      \ 'files'    : [ vfile ],
      \ 'load_buf' : load_buf,
      \ 'Fc'       : Fc,
      \ })

    if load_maps
      call projs#maps({ 'exts' : [ext] })
    endif

    let buf_nums = get(res,'buf_nums',[])
    let bufnr    = get(buf_nums,0,'')

    call projs#sec#bufnr({
      \ 'sec'    : sec,
      \ 'proj'   : proj,
      \ 'bufnr'  : bufnr
      \ })

  endfor

  call base#stl#set('projs')
  "KEYMAP russian-jcukenwin
  "
  if b:ext == 'tex'
    KEYMAP ukrainian-jcuken
  elseif b:ext == 'xml'
    setlocal keymap=
  endif

  return
endf

function! projs#sec#bufnr (...)
  let ref = get(a:000,0,{})

  let proj  = projs#proj#name()
  let bufnr = ''
  let sec   = projs#proj#secname()

  if base#type(ref) == 'String'
    let sec  = get(a:000,0,sec)
    let proj = get(a:000,1,proj)

  elseif base#type(ref) == 'Dictionary'
    let bufnr = get(ref,'bufnr','')
    let sec   = get(ref,'sec',sec)
    let proj  = get(ref,'proj',proj)
  endif

  let bfs = base#varref('projs_sec_bufs',{})
  let bs  = get(bfs,proj,{})

  if !len(bufnr)
    let bufnr = get(bs,sec,'')
    return bufnr
  else
    call extend(bs,{ sec : bufnr })
    call extend(bfs,{ proj : bs })
  endif
endf

if 0
  call tree
    called by:
      projs#sec#new
endif


function! projs#sec#header (...)
  let ref = get(a:000,0,{})

  let sec        = get(ref,'sec','')
  let ext        = get(ref,'ext','')
  let keymap     = get(ref,'keymap','')
  let parent_sec = get(ref,'parent_sec','')

  let url        = get(ref,'url','')
  let title      = get(ref,'title','')
  let tags       = get(ref,'tags','')

  let date       = get(ref,'date','')

  let author_id  = get(ref,'author_id','')

  let title      = get(ref,'title','')

  let header = []

  if ext == 'tex'
    if strlen(keymap)
      call add(header,'% vim: keymap=' . keymap )
    endif

    call extend(header,[ '%%beginhead '])
    call extend(header,[ ' ' ])
    call extend(header,[ '%%file '   . sec])
    call extend(header,[ '%%parent ' . parent_sec ])
    call extend(header,[ ' ' ])
    call extend(header,[ '%%url '    . url    ] )
    call extend(header,[ ' ' ])
    call extend(header,[ '%%author_id ' . author_id ] )
    call extend(header,[ '%%date ' . date ] )
    call extend(header,[ ' ' ])
    call extend(header,[ '%%tags '   . tags   ] )
    call extend(header,[ '%%title '  . title  ] )
    call extend(header,[ ' ' ])
    call extend(header,[ '%%endhead '])

  elseif ext == 'bat'
    call extend(header,[ 'rem file ' . sec])

  elseif ext == 'vim'

    call extend(header,[ '"""file ' . sec])
    call extend(header,[ '"""parent ' . parent_sec ])
  endif

  return header
endf

if 0
  called by
    projs#sec#new
endif

function! projs#sec#lines_seccmd (...)
  let ref = get(a:000,0,{})

  let sec    = get(ref,'sec','')
  let seccmd = get(ref,'seccmd','')

  let lines = []

  if strlen(seccmd)
    let title = sec
    let label = 'sec:'.sec

    call add(lines,'\' . seccmd . '{'.title.'}')
    call add(lines,'\label{'.label.'}')
    call add(lines,' ')
  endif

  return lines
endf

function! projs#sec#lines_prompt (...)
  let ref = get(a:000,0,{})

  let sec = get(ref,'sec','')

  let cnt = input('Continue adding? (1/0):',1)

  let lines = []

  if cnt
    let addsec = input('Add sectioning? (1/0):',1)
    if addsec
      let seccmd = input('Sectioning command: ','section','custom,tex#complete#seccmds')

      let title = input('Title: ',sec)
      let label = input('Label: ','sec:' . sec)

      call add(lines,'\' . seccmd . '{'.title.'}')
      call add(lines,'\label{'.label.'}')
      call add(lines,' ')
    endif
  endif

  return lines
endf
