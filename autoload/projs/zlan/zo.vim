
function! projs#zlan#zo#view ()
  let zfile = projs#sec#file('_zlan_')

  call base#fileopen({ 
    \ 'files'    : [ zfile ],
    \ 'load_buf' : 1,
    \ })
  
endfunction

function! projs#zlan#zo#fetch ()
  
endfunction

function! projs#zlan#zo#add_fb_post (...)
  let ref = get(a:000,0,{})

  let zfile = base#qw#catpath('p_sr','fb posts.zlan')

  call projs#zlan#zo#add({
    \ 'zfile'  : zfile,
    \ 'fields' : base#qw('url tags title date ii author_id'),
    \ 'prefix' : '[posts.zlan]',
    \ })

endfunction

if 0
  usage
    call projs#zlan#zo#add()
    call projs#zlan#zo#add({ 'zfile' : zfile })
    call projs#zlan#zo#add({ 'zfile' : zfile, 'fields' : 'url tags caption' })
endif

"""zlan_add
function! projs#zlan#zo#add (...)
  let ref = get(a:000,0,{})

  let rootid   = projs#rootid()
  let proj     = projs#proj#name()

  let zfile = projs#sec#file('_zlan_')
  let zfile = get(ref,'zfile',zfile)

  let prefix = printf('[ rootid: %s, proj: %s ]',rootid, proj)
  let prefix = get(ref,'prefix',prefix)

  " either string or array
  let fields   = get(ref,'fields','url tags')

  let fields_a = base#type(fields) == 'String' ? base#qw(fields) : fields

  let zdata = projs#zlan#data({ 'zfile' : zfile })

  let keys = base#varget('projs_zlan_keys',[])

  let d = {}
  for field in fields_a
    let value = ''

    if field == 'url'
      let value = projs#bs#input#url({ 'zfile' : zfile, 'prefix' : prefix })
    elseif field == 'tags'
      let value = projs#bs#input#tags({ 'prefix' : prefix })
    elseif field == 'author_id'
      let value = projs#bs#input#author_id({ 'prefix' : prefix })
    else
      let value = input(printf('Input %s: ',field),'')
    endif

    let d[field] = value
  endfor

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
