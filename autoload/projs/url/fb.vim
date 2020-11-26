

if 0
  Usage
    let data = projs#url#fb#data({ 'url' : url })
    echo data

    let data = projs#url#fb#data({ 
      \ 'url'    : url,
      \ 'prompt' : 1,
      })
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


  let path_a  = split(path,'/')
  let fb_auth = get(path_a,0,'')

  let author_id = get(fb_authors,fb_auth,'')

  if !len(author_id) && prompt
    call base#varset('this',projs#author#ids())
    let author_id = input(printf('[ facebook auth: %s ] Enter new author_id: ',fb_auth), '', 'custom,base#complete#this')

    call projs#facebook#add_author_id({ 
      \ 'author_id' : author_id ,
      \ 'fb_auth'   : fb_auth ,
      \ })
  endif

  let data = {
      \ 'author_id' : author_id,
      \ }
  return data
  
endfunction
