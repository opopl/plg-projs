
function! projs#zlan#zo#view ()
  let zfile = projs#sec#file('_zlan_')

  call base#fileopen({ 
    \ 'files'    : [ zfile ],
    \ 'load_buf' : 1,
    \ })
  
endfunction

function! projs#zlan#zo#fetch ()
  
endfunction

"""zlan_add
function! projs#zlan#zo#add (...)
  let ref = get(a:000,0,{})

  let rootid   = projs#rootid()
  let proj     = projs#proj#name()

  let zfile = projs#sec#file('_zlan_')
  let zdata = projs#zlan#data()

  let keys = base#varget('projs_zlan_keys',[])

  let url  = projs#bs#input#url()
  let tags = projs#bs#input#tags()

  let d = {
    \ 'url'  : url,
    \ 'tags' : tags,
    \ }
  
  call projs#zlan#save({ 
    \ 'zdata' : zdata,
    \ 'zfile' : zfile,
    \ 'd_i'   : d,
    \ })

  let cnt = projs#zlan#count()

  call base#rdw_printf([
    \ '[rootid: %s, proj: %s] added ZLAN entry; on: %s, all: %s ', 
    \ rootid, proj, cnt.on, cnt.all ],'MoreMsg')
  
endfunction
