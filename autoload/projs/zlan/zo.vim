
function! projs#zlan#zo#view ()
  let zfile = projs#sec#file('_zlan_')

  call base#fileopen({ 
    \ 'files'    : [ zfile ],
    \ 'load_buf' : 1,
    \ })
  
endfunction

function! projs#zlan#zo#fetch ()
  
endfunction

function! projs#zlan#zo#add ()
  let rootid = projs#rootid()
  let proj   = projs#proj#name()

  let zdata      = projs#zlan#data()

  let zorder     = get(zdata,'order',{})
  let zorder_on  = get(zorder,'on',[])
  let zorder_all = get(zorder,'all',[])

  let l = keys(zdata)

  let prefix = printf('[ rootid: %s, proj: %s ]',rootid, proj)

  let keys = base#varget('projs_zlan_keys',[])

  let d = {}
  for k in keys

    let keep = 1
    let msg = printf('%s %s: ',prefix,k)
    let msg_head = ''

    while keep
      let d[k] = input(msg_head . msg,'')
      let msg_head = ''

      if k == 'url'
        let url = get(d,k,'')
        echo url
        let cnt = 1

        if !len(url)
          let msg_head = "Non-zero URL required\n"

        elseif projs#zlan#has({ 'url' : url })
          let msg_head = "URL in ZLAN\n"

        else
          let cnt = 0
        endif

        if cnt 
          continue
        endif
      endif

      break
    endw
  endfor

  let url = get(copy(d),'url','')
  unlet d.url

"  let struct = base#url#struct(url)
  "let host   = get(struct,'host','')

  "call extend(d,{ 'host' : host })

  "call extend(zdata,{ url : d })
  "let zorder = get(zdata,'order',[])
  "call add(zorder,url)

  "call projs#zlan#save({ 'zdata' : zdata })
  "call base#rdw_printf(['added ZLAN entry ' ],'MoreMsg')
  
endfunction
