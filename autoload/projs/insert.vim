
function! projs#insert#template_tex ()
  call projs#insert#template ('tex')
endfunction

function! projs#insert#template_vim ()
  call projs#insert#template ('vim')
endfunction

function! projs#insert#projname ()
  let proj = projs#proj#name()
  call append(line('.'),proj)

endfunction

if 0
BaseDatView projs_opts_PrjInsert
endif

function! projs#insert#main ()
  let proj = projs#proj#name()

python3 << eof
import vim,re

proj = vim.eval('proj')

t = '''
%%beginhead

%%file _main_
%%file f_main

%%url

%%endhead

\\def\PROJ{_proj_}
\\def\ii#1{\InputIfFileExists{\PROJ.#1.tex}{}{}}
\\def\iif#1{\input{\PROJ/#1.tex}}
\\def\idef#1{\InputIfFileExists{_def.#1.tex}{}{}}

'''
t = re.sub(r'_proj_',proj,t)

eof
  let t  = py3eval('t')
  let ta = split(t,"\n")
  call append(line('.'),ta)

endfunction

"""pin_pauthor
function! projs#insert#cmt_author ()

  let db_buf_data = projs#db#buf_data()

  let author_id   = get(db_buf_data,'author_id','')

  if !len(author_id)
    let a_data    = projs#author#select()
  
    let author_id = get(a_data,'author_id','')
    let author    = get(a_data,'author','')
  endif

  let lines = projs#cmt#author({ 'author_id' : author_id })
  call append('.',lines)

endfunction

function! projs#insert#uri ()
  let url = input('url: ','')

  call projs#sec#insert_url({
    \ 'url' : url,
    \ })
  let y = input('fetch URL? (1/0): ',1)
  if y
    call projs#action#url_fetch()
  endif

endfunction

"""pin_cmt_pic
function! projs#insert#cmt_pic ()
  let url     = input('[pic] url: ','')
  let caption = input('[pic] caption: ','')

  let lines = []

  let width = '0.5'
  let fig_env = 'wrapfigure'

  call add(lines,'')
  call add(lines,'\ifcmt')
  call add(lines,printf('  pic %s',url))
  if len(caption)
    call add(lines,printf('  caption %s',caption))
  endif

  call add(lines,printf('  width %s',width))
  call add(lines,printf('  fig_env %s',fig_env))
  call add(lines,'\fi')
  call add(lines,'')

  call append('.',lines)

endfunction

function! projs#insert#item_usr ()
  let usr    = input('user: ','')

  let lines = []
  call add(lines,'')
  call add(lines,printf('\iusr{%s}',usr))
  call add(lines,'')
  call add(lines,base#const#pp())

  call append('.',lines)

endfunction

function! projs#insert#cmt_fig_old ()
  let proj   = projs#proj#name()
  let rootid = projs#rootid()
  let sec    = projs#buf#sec()

  let tags = input('tags: ','')

python3 << eof
import vim,re

proj   = vim.eval('proj')
tags   = vim.eval('tags')
sec    = vim.eval('sec')
rootid = vim.eval('rootid')

tags = ','.join([ tags, sec ])

date = ''
m = re.match(r'^(\d+_\d+_\d+)\..*$',sec)
if m:
  date = m.group(1)
 
if len(date):
  tags = ','.join([ tags, date ])

t = '''
\\ifcmt
fig_begin 
  tex \centering
  img_begin 
    tags _tags_
    tags projs,_rootid_,_proj_
    width 0.5
  img_end
fig_end
\\fi
'''

t = re.sub(r'_proj_',proj,t)
t = re.sub(r'_tags_',tags,t)
t = re.sub(r'_rootid_',rootid,t)

eof
  let t  = py3eval('t')
  let ta = split(t,"\n")
  call append(line('.'),ta)

endfunction

function! projs#insert#t_file ()
  let c = []

  let sec =  projs#buf#sec()

  if !len(sec)
    return 
  endif

  let cmts = {
      \ 'tex'  : '%%',
      \ 'vim'  : '"""',
      \ 'pl'   : '###',
      \ }
  let cmt = get(cmts,b:ext,'%%')

  if sec == '_main_'
    let sec = 'f_main'
  endif

  call add(c, ' ')
  call add(c, cmt . 'file ' . sec)
  call add(c, ' ')

  call append('.',c)

endfunction

"""pin_ii
function! projs#insert#ii ()
  let proj = projs#proj#name()

  let sec  = projs#buf#sec()

  let ii_prefix = printf('%s.', sec)

  let comps = []
  call base#varset('this',comps)
  let ii_sec = input('ii_sec name: ',ii_prefix,'custom,base#complete#this')

  let do_ii = 1
  if projs#buf#ii_has(sec)
    let do_ii = input('Section already here, insert? (1/0):',0)
  endif

  if !do_ii | return | endif

  let lines = []
  call add(lines,printf('\ii{%s}',ii_sec))
  call append('.',lines)

  let r_new = {
      \  }

  " see also:
  "   projs#bld#do#print_ii_tree
  call projs#sec#new(ii_sec,r_new)
  call base#tg#update('projs_this')

endfunction


if 0
  usage
    call projs#insert#ii_url
  call tree
    calls
      projs#buf#sec
      projs#util#ii_data_from_url
      projs#author#get
endif

"""pin_ii_url {
function! projs#insert#ii_url ()
  let proj   = projs#proj#name()

  let rootid = projs#rootid()

  let sec    = projs#buf#sec()

  let ii_prefix = printf('%s.', sec)

  let list  = matchlist(sec,'^\(\w\+\)_\(\d\+\)$')

  let month = get(list,1,'')
  let year  = get(list,2,'')

  let is_date = len(month) && len(year) && base#inlist(month,base#varget('projs_months_3',[])) ? 1 : 0
  if is_date
    let ii_prefix = ''
  endif

  let pat = len(ii_prefix) ? printf('^%s',ii_prefix) : ''
  let r = {}
  if len(pat)
    call extend(r,{ 'pat' : pat })
  endif

  let url = ''
  if !is_date
    let url = input('[PIN ii_url] URL: ','')
  endif

  let html_file = base#qw#catpath('html_root projs ' . rootid . ' pin ii_url 1.htm')

  let data = projs#db#url_data({ 'url' : url })
  let sec  = get(data,'sec','')
  if len(sec)
    call base#rdwe('URL already stored, sec: ' . sec)
    return 
  endif

"""ii_data
  let ii_data = projs#util#ii_data_from_url({ 
    \ 'url'    : url,
    \ 'prompt' : 1,
    \ })

  let pref      = get(ii_data,'pref','')
  let author_id = get(ii_data,'author_id','')
  let author    = projs#author#get({ 'author_id' : author_id })

  let data_pref       = projs#insert#ii_url#get_pref_auth({ 
      \ 'author_id' : author_id,
      \ 'pref'      : pref,
      \ })

  let pref            = get(data_pref,'pref','')
  let author_id_list  = get(data_pref,'author_id_list',[])
  let author_id_first = get(data_pref,'author_id_first','')

  let author_id_str = join(author_id_list, ',')

  if len(pref)
    let ii_prefix .= printf('%s.',pref)
  endif

  let cnt = projs#sec#count_ii({ 'ii_prefix' : ii_prefix })

  let inum = cnt + 1

  let ii_prefix .= printf('%s.',inum)

  let title = ''
  let title = input('ii section title: ','')
  let title = base#rmwh(title)

  let headcmd  = projs#buf#headcmd('chapter')
  let sec_type = projs#util#subsec(headcmd)

  let comps = []
  if is_date
    let mon_num = projs#util#month_number(month)
    let day_nums = base#varget('projs_day_nums',[])
    for dn in day_nums
      call add(comps,printf('%s_%s_%s',dn,mon_num,year))
    endfor
  else

    let secs = projs#db#secnames(r)
    for sec in secs
      call add(comps,sec)
    endfor
  endif

  call base#varset('this',comps)
  let ii_sec = input('ii_sec name: ',ii_prefix,'custom,base#complete#this')

  "let tags   = input('tags: ','')
  let tags = projs#bs#input#tags()

  let do_ii = 1
  if projs#buf#ii_has(sec)
    let do_ii = input('Section already here, insert? (1/0):',0)
  endif

  if do_ii
    let lines = []
    call add(lines,printf('\ii{%s}',ii_sec))

    let msg_a = [
        \ 'Choices for appending:',
        \ ' 1 - append at end', 
        \ ' 2 - append at current line',  
        \ ' ',
        \ 'Choice number:', 
        \ ]
    let msg = join(msg_a, "\n")
    let a_choice = input(msg,'1')

    let map = {
        \ '1' : line('$'),
        \ '2' : line('.'),
        \ }
    let pos = get(map,a_choice,line('$'))

    call append(pos,lines)
  endif

  let r_new = {
      \  'url'       : url,
      \  'title'     : title,
      \  'sec_type'  : sec_type,
      \  'author_id' : author_id_str,
      \  'author'    : author,
      \  'tags'      : tags,
      \  }

  call projs#sec#new(ii_sec,r_new)

  call base#tg#update('projs_this')

endfunction
" } end of: ii_url


function! projs#insert#def_ii ()
  let proj = projs#proj#name()
  let c = []

  call add(c, ' ')
  call add(c, '%%file f_main')
  call add(c, ' ')
  call add(c, printf('\def\PROJ{%s}',proj))
  call add(c, '\def\ii#1{\InputIfFileExists{\PROJ.#1.tex}{}{}}' )
  call add(c, ' ')

  call append('.',c)

endfunction

function! projs#insert#def_jj ()

  let sec = projs#buf#sec()
  let c = printf('\def\jj#1{\InputIfFileExists{\PROJ.%s.#1.tex}{}{}}',sec)

  call append('.',c)

endfunction


function! projs#insert#figure ()

  let lines = []

  let picname  = input('Picture FileName:','','custom,projs#complete#pics')
  let picwidth = input('Picture Width (in terms of \textwidth):','0.5')
  let caption  = input('Caption:','')
  let label    = input('Label:',picname)

  call add(lines,'\begin{figure}[ht]')
  call add(lines,' \centering')
  call add(lines,' \PrjPicW{'.picname.'}{'.picwidth.'}')
  call add(lines,' \caption{'.caption.'}')
  call add(lines,' \label{fig:'.label.'}')
  call add(lines,'\end{figure}')

  call append(line('.'),lines)

endfunction

function! projs#insert#secname ()
  let sec = projs#proj#secname()
  call append(line('.'),sec)

endfunction

function! projs#insert#template (type)
  let type  = a:type
  let t     = projs#varget('templates_'.type,{})
  let tlist = sort(keys(t))

  if !len(tlist)
    call projs#echo('No '.type.' templates found, aborting.')
    return
  endif

  let tname = input(type.' template name:','','custom,projs#complete#templates_'.type)
  let tlines = get(t,tname,[])

  call append(line('.'),tlines)
  
endfunction
