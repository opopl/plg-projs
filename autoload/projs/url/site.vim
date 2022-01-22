
"{
function! projs#url#site#data (...)
  let ref = get(a:000,0,{})

  let sites_file = base#qw#catpath('p_sr','scrape bs in hosts.yaml')
  let sites_file = get(ref, 'sites_file', sites_file)

  if ! filereadable(sites_file) | return | endif

  let data = base#yaml#parse_fs({ 'file' : sites_file })
  return data
  
endfunction
"} end: 
"
function! projs#url#site#get (...)
  let ref = get(a:000,0,{})

  let url = get(ref,'url','')

endfunction
