
if 0
	usage
		let ids = projs#bs#author#ids ()
endif

function! projs#bs#author#ids (...)

  let ids = pymy#sqlite#query_as_list({
      \ 'dbfile' : projs#bs#db_file(),
      \ 'q' : 'SELECT DISTINCT id FROM authors ORDER BY id',
      \ 'p' : [],
      \ })

  return ids
endf
