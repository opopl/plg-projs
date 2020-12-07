

if 0
  Purpose
    - parse input facebook url
    - returns {} - data structure which contains:
        author_id
  Usage
    let data = projs#url#fb#data({ 'url' : url })
    echo data

    let data = projs#url#fb#data({ 
      \ 'url'    : url,
      \ 'prompt' : 1,
      })
    let author_id = get(data,'author_id','')
  call tree
    called by
      projs#util#ii_data_from_url
endif

function! projs#url#fb#data (...)
  let ref = get(a:000,0,{})

  let prompt = get(ref,'prompt',0)

  let url    = get(ref,'url','')
  let struct = base#url#struct(url)

  let path = get(struct,'path','')

  let fb_authors = projs#data#dict({ 'id' : 'fb_authors' })
  let fb_groups  = projs#data#dict({ 'id' : 'fb_groups' })

  let path_a     = split(path,'/')
  let path_front = get(path_a,0,'')

  let fb_auth  = path_front
  let fb_group = ''

  let author_id = ''

  if path_front =~ 'permalink.php'
    let fb_auth = ''

  elseif path_front =~ 'groups'
    let fb_auth  = ''
    let fb_group = get(path_a,1,'')

    let fb_group_id = get(fb_groups,fb_group,'')

    if len(fb_group_id)
      let author_id = printf('fb_group.%s',fb_group_id)
      let author    = projs#author#get({ 'author_id' : author_id })
      if !len(author)
        let author = projs#author#add_prompt({ 'author_id' : author_id })
      endif
    endif
  endif

  if len(fb_auth)
    let author_id = get(fb_authors,fb_auth,'')
  
    if !len(author_id) && prompt
      call base#varset('this',projs#author#ids())
      let author_id = input(printf('[ facebook auth: %s ] Enter new author_id: ',fb_auth), '', 'custom,base#complete#this')
  
      let author = projs#author#get({ 'author_id' : author_id })
      if !len(author)
        let author = projs#author#add_prompt({ 'author_id' : author_id })
      endif
  
      call projs#facebook#add_author_id({ 
        \ 'author_id' : author_id ,
        \ 'fb_auth'   : fb_auth ,
        \ })
    endif
  endif

  let data = {
      \ 'author_id' : author_id,
      \ }
  return data
  
endfunction
