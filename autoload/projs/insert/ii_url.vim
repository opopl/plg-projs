
function! projs#insert#ii_url#get_pref_auth (...)
  let ref = get(a:000,0,{})

  let author_id      = get(ref,'author_id','')
  let pref           = get(ref,'pref','')

  let author_id_list = []

  if !len(author_id)
    let author_ids = projs#author#ids() 
    call base#varset('this',author_ids)

    let i_au = 1
    let m_added = []
    while(1)
      let author_id_input = input( join(m_added, "\n") . "\n" . 'author_id: ','','custom,base#complete#this')
      let author_id = substitute(copy(author_id_input),'[,]*$','','g')
      call add(author_id_list,author_id)

      call add(m_added,printf('[%s] Added: %s', i_au, author_id))

      let i_au += 1
      if author_id_input =~ '^\(\w\+\),$'
        continue
      else
        break
      endif
    endw

    let author_id_first = get(author_id_list,0,'')
    if len(author_id_first)
      let author    = projs#author#get({ 'author_id' : author_id_first })
  
      if len(author)
        echo printf("\n" . 'Found author: %s' . "\n",author)
      else
        let author = projs#author#add_prompt({ 'author_id' : author_id_first })
      endif
    endif

    let pref     .=  len(author_id_first) ? printf('.%s',author_id_first) : ''
  else
    call extend(author_id_list,split(author_id,","))
  endif

  let d_pref = {
      \  'author_id_list'  : author_id_list,
      \  'author_id_first' : author_id_first,
      \  'pref'            : pref,
      \  }
  return d_pref
endf
