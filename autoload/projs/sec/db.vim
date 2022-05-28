
"{
function! projs#sec#db#add_children (...)
  let ref = get(a:000,0,{})

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let sec = projs#buf#sec()
  let sec = get(ref,'sec',sec)

  let children = get(ref,'children',[])

  for child in children
    let sdc = projs#sec#db#data({ 'sec' : sec, 'proj' : proj })
    let file_child = get(sdc,'file','')
  endfor

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

perl << eof
  use Plg::Projs::Prj;
  use Vim::Perl qw(VimVar VimLet);

  my ($proj, $sec, $root, $rootid) = map { VimVar($_) } qw(proj sec root rootid);
  return unless $proj && $root && $rootid;

  my %n = (
     proj   => $proj,
     sec    => $sec,
     root   => $root,
     rootid => $rootid,
  );
  our $prj ||= Plg::Projs::Prj->new(%n);

  my $prev;
  $prev->{rootid} = $prj->{rootid};
  my $force = ($prev->{rootid} && ($prev->{rootid} ne $rootid)) ? 1 : 0;

  $prj->{$_} = $n{$_} for keys %n;
  $prj->init_db({ force => 1 });

  my $sd = $prj->_sec_data({
     sec  => $sec,
     proj => $proj,
  });

  VimLet('sd',$sd);
eof
  return sd

endfunction
