
" ===========================================
"METHODS:
"  projs#visual#ii_to_new_secs (start, end)
"
" ===========================================
"
function! projs#visual#append_to_sec (start, end, ... )
  let start = a:start
  let end   = a:end

  let sec = get(a:000,0,'')
  if !strlen(sec)
    let msg_a = [
      \  "Section: ",  
      \  ]
    let msg = join(msg_a,"\n")
    let r = { 'complete' : 'custom,projs#complete#secnamesall' }
    let sec = base#input_we(msg, '' , r)
  endif

  let lines = base#vim#visual_selection()
  let r = {
      \  'sec'   : sec,
      \  'lines' : lines,
      \  }
  call projs#sec#append(r)

  let r_cut = { 
    \ 'start' : start,
    \ 'end'   : end }
  call base#buf#cut(r_cut)

endf

function! projs#visual#ii_rename (start, end, ... )
  let start = a:start
  let end   = a:end

  let secs = projs#visual#ii#secs(start,end)

  if !len(secs)
    redraw!
    echohl WarningMsg
    echo "No sections selected!"
    echohl None
    return
  endif

  for sec in secs
    let msg_a = [
      \  "II RENAME",  
      \  "",  
      \  "New section: ",  
      \  ]
    let msg = join(msg_a,"\n")
    let new = base#input_we(msg,'',{ 'complete' : 'custom,projs#complete#secnames'})

    call projs#sec#rename(sec, new)
  endfor

endf

function! projs#visual#ii_to_new_secs (start, end, ... )
  let start = a:start
  let end   = a:end

  let secs = projs#visual#ii#secs(start,end)

  for sec in secs
    let r = {
        \  'git_add'    : 1,
        \  'rewrite'    : 0,
        \  'parent_sec' : b:sec,
        \  }
    call projs#sec#new(sec, r)
  endfor

  let s:obj = { 'secs' : secs }
  function! s:obj.init () dict
    let yn = input('Sections have been created, open the sections now? 1/0: ', 0 )

    let secs = self.secs

    if yn
      for sec in secs
        call base#tg#go(sec)
      endfor
    endif
  endfunction
  
  call base#tg#update('projs_this',{ 'Fc_done' : s:obj.init })
  
endfunction

function! projs#visual#help (...)
  call base#bufact_common#help ({ 'map_types' : base#qw('vnoremap') })
endfunction

"" split on subsubsection
function! projs#visual#split_ss2 (start, end, ... )
  let start  = a:start
  let end    = a:end

  call base#CD('texdocs')

  let msg    = 'section prefix: '
  let sec    = exists('b:sec') ? b:sec : ''
  let prefix = base#input_we(msg,sec,{ 'complete' : 'custom,projs#complete#secnames' })

	let msg_a = [
		\	"e.g. subsubsection ",	
		\	"",	
		\	"split_macro:",	
		\	]
	let msg = join(msg_a,"\n")
	let split_macro = base#input_we(msg,'subsubsection',{ })

python3 << eof
import vim,re
from itertools import repeat

start = int(vim.eval('start'))
end   = int(vim.eval('end'))

b = vim.current.buffer

secs = []

data      = {}
sec_lines = []
sec       = ''

prefix      = vim.eval('prefix')
split_macro = vim.eval('split_macro')

for k in range(start, end + 1, 1):
  i = k - 1
  n = k - start + 1
  m = re.search(r'^\\' + split_macro + '{(.*)}\s*$', b[i])
  if m:
    if len(sec):
      data.update({ sec : sec_lines })
    sec_lines = [ b[i] ]
    sec = m.group(1)
    sec = re.sub(r'\s','_',sec)
    sec = prefix + sec
    secs.append(sec)
  else:
    sec_lines.append( b[i] )

if len(sec):
  data.update({ sec : sec_lines })

tex_lines = []
for sec in secs:
  tex_lines.append('\\ii{%s}' % (sec))

eof
  let secs      = py3eval('secs')
  let data      = py3eval('data')
  let tex_lines = py3eval('tex_lines')

  for sec in secs
    let r = {
        \  'git_add'    : 0,
        \  'rewrite'    : 0,
        \  'parent_sec' : b:sec,
        \  }
    call projs#sec#delete(sec)
    call projs#sec#new(sec, r)

    let sec_lines = get(data,sec,[])
    call extend(sec_lines,[ ' ' ],0)

    let ra = { 
      \ 'sec'   : sec, 
      \ 'lines' : sec_lines }
    call projs#sec#append(ra)
  endfor

  call base#buf#cut({ 'start' : start, 'end' : end })
  call append(line('.'),tex_lines)

endfunction
