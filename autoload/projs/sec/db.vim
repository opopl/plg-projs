
"{
function! projs#sec#db#add_children (...)
  let ref = get(a:000,0,{})

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let sec = projs#buf#sec()
  let sec = get(ref,'sec',sec)

  let children = get(ref,'children',[])

"  for child in children
"perl << eof
  
"eof
  "endfor

endfunction
"} end:
"
function! projs#sec#db#data (...)
  let ref = get(a:000,0,{})

  let root = projs#root()
  let rootid = projs#rootid()

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let sec = projs#buf#sec()
  let sec = get(ref,'sec',sec)

  call projs#init#prj_perl()

perl << eof
  use Plg::Projs::Prj;
  use Vim::Perl qw(VimVar VimLet);

  my ($proj, $sec) = map { VimVar($_) } qw(proj sec);
  return unless $proj && $sec;

  my $sd = $prj->_sec_data({
     sec  => $sec,
     proj => $proj,
  });

  VimLet('sd',$sd);
eof
  return sd

endfunction
