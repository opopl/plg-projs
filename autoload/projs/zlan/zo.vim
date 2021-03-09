
function! projs#zlan#zo#view ()
  let zfile = projs#sec#file('_zlan_')

  call base#fileopen({ 
    \ 'files'    : [ zfile ],
    \ 'load_buf' : 1,
    \ })
  
endfunction

function! projs#zlan#zo#fetch ()
  
endfunction

function! projs#zlan#zo#add (...)
  let ref = get(a:000,0,{})

  let rootid   = projs#rootid()
  let rootid_i = get(ref,'rootid','')

  let proj   = projs#proj#name()
  let proj_i = get(ref,'proj','')

  let zfile = projs#sec#file('_zlan_')

  let zdata      = projs#zlan#data()

  let zorder     = get(zdata,'order',{})
  let zorder_on  = get(zorder,'on',[])
  let zorder_all = get(zorder,'all',[])

  let l = keys(zdata)

  let prefix = printf('[ rootid: %s, proj: %s ]',rootid, proj)

  let keys = base#varget('projs_zlan_keys',[])
  
  let tag_list = projs#bs#tag_list()

  let d = {}

  let tags_selected = []
  for k in keys

    let keep = 1
    let msg = printf('%s %s: ',prefix,k)
    let msg_head = ''

    while keep
      let cnt = 0

      let cmpl = ''
      call base#varset('this',[])
      if k == 'tags'
        call base#varset('this',tag_list)
      endif

      let d[k] = input(msg_head . msg,'','custom,base#complete#this')

      if k == 'tags'
        let tags_s = get(d,k,'')

        " finish
        if tags_s =~ '\.\s*$'
          let d[k] = join(tags_selected, ',')
          break

        " skip and continue
        elseif tags_s =~ ';\s*$'
          let cnt = 1

        " add and continue
        else
          call extend(tags_selected,split(tags_s,','))
          let msg_head = "\n" . join(tags_selected, ',') . "\n"
          let cnt = 1
        endif

      elseif k == 'url'
        let url = get(d,k,'')
        let cnt = 1

        if !len(url)
          let msg_head = "\nNon-zero URL required\n"

        elseif projs#zlan#has({ 'url' : url })
          let msg_head = "\nURL in ZLAN\n"

        else
          let cnt = 0
        endif

      endif

      if cnt 
        continue
      endif

      break
    endw
  endfor

  "unlet d.url
  let url = get(copy(d),'url','')
  
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
