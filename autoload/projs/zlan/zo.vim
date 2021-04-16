
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

    let msg_tags_del = 'delete: '

    let msg_head = ''
    let msg_head_base = ''

    if k == 'tags'
      let msg_head_base .= "\n" . 'Commands:' 
      let msg_head_base .= "\n" . '  ; - skip'
      let msg_head_base .= "\n" . '  . - finish'
      let msg_head_base .= "\n" . '  , - delete selected'
      let msg_head_base .= "\n" 
    endif

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

        " delete selected and continue
        elseif tags_s =~ ',\s*$'
          call base#varset('this',tags_selected)
          let tags_del = input(msg_head . msg_tags_del,'','custom,base#complete#this')
          let tags_del_a = split(tags_del,',')
          let n = []
          for tag in tags_selected
            if !base#inlist(tag,tags_del_a)
              call add(n,tag)
            endif
          endfor

          let tags_selected = n
					call sort(tags_selected)

          let msg_head = msg_head_base 
             \ . "\n" . 'Tags selected:' 
             \ . "\n" . join(tags_selected, "\n") . "\n"

          let cnt = 1

        " add and continue
        else
          let tags_a = split(tags_s,',')
          for tag in tags_a
            if !base#inlist(tag,tags_selected)
              call add(tags_selected,tag)
            endif
          endfor

					call sort(tags_selected)
					let tags_n = ''
					for tg in tags_selected
						let tags_n .= "  " . tg . "\n"
					endfor

          let msg_head = msg_head_base 
             \ . "\n" . 'Tags selected:' 
             \ . "\n" . tags_n
          let cnt = 1
        endif

      elseif k == 'url'
        let url = get(d,k,'')
        let cnt = 1

				let u = base#url#parse(url,{ 
						\	'rm_query' : 1 
						\	})
				let url = get(u,'url','')

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
