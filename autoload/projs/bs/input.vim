

if 0
  call projs#bs#input#url()

  call projs#bs#input#url({ 'zfile' : zfile })
  call projs#bs#input#url({ 'zfile' : zfile, 'prefix' : prefix })
endif

function! projs#bs#input#url (...)
  let ref = get(a:000,0,{})

  let rootid   = projs#rootid()
  let proj     = projs#proj#name()

  let zfile = projs#sec#file('_zlan_')
  let zfile = get(ref,'zfile',zfile)

  let prefix = printf('[ rootid: %s, proj: %s ]',rootid, proj)
  let prefix = get(ref,'prefix',prefix)

  let keep = 1
  let msg = printf('%s %s: ',prefix,'url')

  let msg_head = ''
  let url = ''

  while keep
    let cnt = 0

    let cmpl = ''
    call base#varset('this',[])

    let url = input(msg_head . msg,'','custom,base#complete#this')

    let cnt = 1

    " Base.Util url_parse()
    let u = base#url#parse(url,{ 
        \ 'rm_query' : 1 
        \ })
    let url = get(u,'url','')

    if !len(url)
       let msg_head = "\nNon-zero URL required\n"

    elseif projs#zlan#has({
        \ 'url'   : url,
        \ 'zfile' : zfile
        \ })

       let msg_head = printf("\nURL in ZLAN: %s\n",fnamemodify(zfile,':t'))

    else
       let cnt = 0
    endif

    if cnt 
      continue
    endif

    break
  endw

  return url
endf

function! projs#bs#input#author_id (...)
  let ref = get(a:000,0,{})

  let rootid   = projs#rootid()
  let proj     = projs#proj#name()

  let prefix = printf('[ rootid: %s, proj: %s ]',rootid, proj)
  let prefix = get(ref,'prefix',prefix)

  let msg = printf('%s %s: ',prefix,'author_id')

endfunction

function! projs#bs#input#tags (...)
  let ref = get(a:000,0,{})

  let rootid   = projs#rootid()
  let proj     = projs#proj#name()

  let prefix = printf('[ rootid: %s, proj: %s ]',rootid, proj)
  let prefix = get(ref,'prefix',prefix)

  let tag_list = projs#bs#tags#list()

  let msg = printf('%s %s: ',prefix,'tags')

  let msg_tags_del = 'delete: '

  let msg_head = ''

  let msg_head_base_a = [
      \ '',
      \ 'Commands:',
      \ '   ; - skip',
      \ '   . - finish',
      \ '   , - delete selected',
      \ ]

  let msg_head_base = join(msg_head_base_a, "\n")

  " final string with tags chosen, comma-separated list
  let tgs = ''

  let tags_selected = []

  let keep = 1
  while keep
    let cnt = 0

    let cmpl = ''
    call base#varset('this',tag_list)

    let tgs = input(msg_head . msg,'','custom,base#complete#this')

    let tags_s = tgs

    " finish
    if tags_s =~ '\.\s*$'
       let tgs = join(tags_selected, ',')
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

    if cnt 
      continue
    endif

    break
  endw

  return tgs

endf
