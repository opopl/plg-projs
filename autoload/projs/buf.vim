
function! projs#buf#onload_vim ()
  TgSet projs_this
endfunction

function! projs#buf#url (...)
  let ref = get(a:000,0,{})

  let file = get(ref,'file',b:file)

  let lines = readfile(file)

  let url = ''
  for line in lines
    let url = matchstr(line,'^%%url\s\+\zs.*\ze\s*$')
    if strlen(url)
      let url = base#trim(url)
      break
    endif
  endfor

  let b:url = url
  return url

endfunction

if 0
  Used in:
    projs_ftplugin_idat
    ftplugin/idat.vim
endif

function! projs#buf#onload_idat ()

  if !exists("b:proj")
    if !len(b:relpath_projs)
      let b:proj = substitute(b:basename,'^\(\w\+\)\..*','\1','g')

      let sc = matchstr(b:basename,'^\w\+\.\zs.*\ze\.i\.dat')

      if sc == 'ii_include'
        let b:sec  = '_ii_include_'
      elseif sc == 'ii_exclude'
        let b:sec  = '_ii_exclude_'
      endif

    else
      let rp = base#file#ossplit(b:relpath_projs)
      if (get(rp,0,'') == 'builds') && (get(rp,2,'') == 'src')
        let b:proj = get(rp,1,'')
      endif
      
    endif
  endif

  call projs#onload()

endfunction

if 0
  Used in:
    projs_ftplugin_tex
    ftplugin/tex.vim
endif

function! projs#buf#onload_tex_tex ()
  let msg = [ 'basename: ' . b:basename ]
  let prf = { 'plugin' : 'projs', 'func' : 'projs#buf#onload_tex_tex' }
  call base#log(msg, prf)

  if !exists("b:proj")
    if !len(b:relpath_projs)
      let b:proj = substitute(b:basename,'^\(\w\+\)\..*','\1','g')
    else
      let rp = base#file#ossplit(b:relpath_projs)
      if (get(rp,0,'') == 'builds') && (get(rp,2,'') == 'src')
        let b:proj = get(rp,1,'')
        let b:sec  = '_tex_jnd_'
      endif
      
    endif
  endif

  call projs#onload()

  if base#inlist(b:proj,base#qw('inc jnames defs'))
    return
  endif

  if (b:proj =~ '^'.'_def')
    return
  endif

  if !exists('b:sec')
    let b:sec = projs#secfromfile({ 
        \ "file" : b:basename ,
        \ "type" : "basename" ,
        \ "proj" : b:proj     ,
        \ })
  endif

  call projs#sec#bufnr({ 
     \ 'sec'   : b:sec,
     \ 'proj'  : b:proj,
     \ 'bufnr' : b:bufnr 
     \  })

  let [ rows_h, cols ] = projs#db#data_get({ 
    \ 'proj' : b:proj,
    \ 'sec ' : b:sec,
    \ })
  let b:db_data = get(rows_h,0,{})
  let url       = get(b:db_data,'url','')
  if strlen(url)
    let b:url = url
  endif

  "call projs

  let  mprg = 'projs_latexmk'

  let aucmds = [ 
      \ 'call projs#root("'.escape(b:root,'\').'")'           ,
      \ 'call projs#proj#name("' . b:proj .'")'   ,
      \ 'call projs#proj#secname("' . b:sec .'")' ,
      \ 'call projs#onload()'                     ,
      \ ] 

  let fr = '  autocmd BufWinEnter,BufRead,BufEnter,BufWritePost,BufNewFile '
  
  let b:ufile = base#file#win2unix(b:file)
  
  exe 'augroup projs_p_' . b:proj . '_' . b:sec
  exe '  au!'
  for cmd in aucmds
    exe join([ fr, b:ufile, cmd ],' ')
  endfor
  exe 'augroup end'
  
endfunction

function! projs#buf#sec ()
  return exists('b:sec') ? b:sec : ''

endfunction

function! projs#buf#onload_tex_sty ()

endfunction

if 0
  called by:
    projs#action#url_fetch
endif

function! projs#buf#url_file ()

  let sec = ( b:sec != '_main_' ) ? b:sec : ''
  let bname = join(filter([ b:proj, sec, 'html' ],'strlen(v:val) > 0' ), '.')

  let ofile = join([ projs#url_dir(), bname ], '/')
  call base#mkdir(projs#url_dir())

  return ofile
endfunction

function! projs#buf#update ()
  call base#buf#start()

  if !exists("b:sec") 
    call base#rdwe('not a TeX project file! abort')
    return
  endif
python3 << eof
import vim

file = vim.eval('b:file')
sec  = vim.eval('b:sec')

f = open(file,'r')
url = ''
for line in f:
  m = re.match(r'%%url\s+(.*)$',line)
  if m:
    url = m.group(1)
eof
  let url = py3eval('url')
  if strlen(strlen(url))
    let b:url = url
  endif

  call base#rdw('OK: buf_update')

endfunction
