
"{
function! projs#url#site#hosts_data (...)
  let ref = get(a:000,0,{})

  let hosts_file = projs#url#site#hosts_file ()
  let hosts_file = get(ref, 'hosts_file', hosts_file)

  if ! filereadable(hosts_file) | return | endif

  let data = base#yaml#parse_fs({ 'file' : hosts_file })
  return data
  
endfunction
"} end: 
"
function! projs#url#site#hosts_file ()
  let hosts_file = base#qw#catpath('p_sr', 'scrape bs in hosts.yaml')
  return hosts_file
endfunction

function! projs#url#site#get (...)
  let ref = get(a:000,0,{})

  let url = get(ref,'url','')

endfunction
