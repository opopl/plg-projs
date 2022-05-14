
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

if 0
  call tree
    called by
      projs#util#ii_data_from_url
    cals
endif

function! projs#url#site#get (...)
  let ref = get(a:000,0,{})

  let url = get(ref,'url','')
  let u = base#url#parse(url)
  let host = get(u,'host','')

  if !len(host) | return '' | endif

  let data = projs#url#site#hosts_data ()
  let site = ''
  let prefii = ''

  for [ host_pats_s, host_struct ] in items(data)
    let host_pats = base#string#split_trim(host_pats_s,{ 'sep' : ',' })
    for host_pat in host_pats

      if matchstr(host, host_pat) != ''
        let site = get(host_struct,'site','')
        let site_pref = get(host_struct,'prefii','')
        let prefii = len(site_pref) ? site_pref : 'stz.' . site
        break
      endif

      if site | break | endif
    endfor
  endfor

  return [ site, prefii ]

endfunction

