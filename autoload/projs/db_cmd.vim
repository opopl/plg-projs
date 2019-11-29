

function! projs#db_cmd#create_tables ()
  call projs#db#create_tables ()
endf

function! projs#db_cmd#fill_from_files (...)
  call projs#db#fill_from_files ()
endf

function! projs#db_cmd#query_split (...)
  call projs#db#query_split ()
endf

function! projs#db_cmd#drop_tables ()
  call projs#db#drop_tables ()
endf

function! projs#db_cmd#buf_tags_append (...)
  let ref = get(a:000,0,{})

  let proj = b:proj
  let proj = get(ref,'proj',proj)

  let file = b:file
  let file = get(ref,'file',file)
  let file = fnamemodify(file,':t')

  let r = { 
    \ 'file' : file, 
    \ 'proj' : proj 
    \ }
  let tags_a = projs#db#tags_get(r)

  call base#varset('this',tags_a)

  let tags_i = input('tags: ','','custom,base#complete#this')
  call extend(tags_a,split(tags_i,','))
  
  let tags_a = base#uniq(tags_a)
  let tags = join(tags_a, ',')

  call pymy#sqlite#update_hash({
    \ 'dbfile' : projs#db#file(),
    \ 'h' : { 'tags' : tags },
    \ 't' : 'projs',
    \ 'u' : 'UPDATE',
    \ 'w' : { 'proj' : proj, 'file' : file },
    \ })

endfunction

function! projs#db_cmd#search (...)
  let proj = projs#proj#name()

  let tags_a = projs#db#tags_get()

  call base#varset('this',tags_a)
  let tag = input('tags: ','','custom,base#complete#this')

  let q = 'SELECT fid FROM tags WHERE tag = ?'
endfunction

function! projs#db_cmd#thisproj_data (...)
  let proj = projs#proj#name()
  
  let q = 'SELECT sec, tags, file FROM projs WHERE proj = ?'
  let p = [ proj ]
  let [ rows_h, cols ] = pymy#sqlite#query({
    \ 'dbfile' : projs#db#file(),
    \ 'p'      : p,
    \ 'q'      : q,
    \ })

  let lines = pymy#data#tabulate({
    \ 'data_h'  : rows_h,
    \ 'headers' : cols,
    \ })

  call base#buf#open_split({ 'lines' : lines })
endfunction
