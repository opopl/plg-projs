
function! projs#bs#tags#list (...)

  let tag_list = pymy#sqlite#query_as_list({
      \ 'dbfile' : projs#bs#db_file(),
      \ 'q' : 'SELECT DISTINCT tag FROM page_tags ORDER BY tag',
      \ 'p' : [],
      \ })

  return tag_list
endf

