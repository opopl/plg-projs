

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
    calls
      projs#data#dict#update
endif

function! projs#url#fb#data (...)
  let ref = get(a:000,0,{})

  let prompt      = get(ref,'prompt',0)
  let prompt_head = get(ref,'prompt_head','')

  let url    = get(ref,'url','')

  let u = base#url#parse(url)
  let query_p = get(u,'query_p',{})

  let path = get(u,'path','')

  let fb_authors = projs#data#dict({ 'id' : 'fb_authors' })

  let fb_groups  = projs#data#dict({ 'id' : 'fb_groups' })
  let fb_group_list = sort(values(fb_groups))

  let path_a     = split(path,'/')
  let path_front = get(path_a,0,'')

  let fb_group = ''

  let author_id = ''
  let author    = ''

  let fb_auth  = path_front

  if path_front == 'permalink.php'
    let fb_auth = ''
    let post_id = get(query_p, 'story_fbid', '')
    if len(post_id)
      let fb_auth = get(query_p, 'id', '')
    endif

  elseif path_front =~ 'groups'
    let fb_auth  = ''
    let fb_group = get(path_a,1,'')

    if len(fb_group)
      let fb_group_id = get(fb_groups,fb_group,'')

      " did not fb group, need to add
      if !len(fb_group_id)
        call base#varset('this',fb_group_list)

        let fb_group_id = base#input_we('New fb_group id:', '', { 'this' : 1 })

        let msg = printf('[%s] fb group name: ',fb_group_id)
        let fb_group_name = base#input_we(msg,'')

        let author = fb_group_name

        let author_id = printf('fb_group.%s',fb_group_id)
        call projs#data#dict#update({
            \ 'id'  : 'fb_groups',
            \ 'upd' : { fb_group : fb_group_id },
            \ })
        call projs#data#dict#update({
            \ 'id'  : 'authors',
            \ 'upd' : { author_id : fb_group_name },
            \ })
      endif

      echo 'Facebook group id: ' . fb_group_id

      if !len(author)
        let author_id = printf('fb_group.%s',fb_group_id)
  
        let author_db = projs#author#get_db({ 'author_id' : author_id })
        let author    = base#x#get(author_db,'name','')
  
        if !len(author)
          let author = projs#author#add_prompt({ 'author_id' : author_id })
        endif
      endif

    endif
  endif

  "debug echo 'fb_auth => ' . fb_auth

  if len(fb_auth)
    let author_id = get(fb_authors, fb_auth, '')

    if !len(author_id) && prompt
      call base#varset('this', projs#author#ids_db())
      let author_id = input(printf('[ facebook auth: %s ] Enter new author_id: ',fb_auth), '', 'custom,base#complete#this')
  
      let author_db = projs#author#get_db({ 'author_id' : author_id })
      let author = get(author_db,'name','')
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
