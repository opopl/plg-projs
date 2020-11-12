
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
%%file _main_
%%file f_main

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

function! projs#insert#uri ()
  let url = input('url: ','')

  call projs#sec#insert_url({
    \ 'url' : url,
    \ })

endfunction

function! projs#insert#cmt_fig ()
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
