
fun! DC_NewProjs(...)
 RFUN SubNameStart DC_NewProjs

 LFUN F_VarCheckExist
 LFUN F_VarUpdate
 LFUN F_FileOpen
 LFUN F_echo_redraw
 LFUN DC_Proj_GenPerl
 LFUN F_sub_warn
 LFUN F_sys

 LCOM MenuReset
 LCOM VSECBASE

 let g:DC_ProjsDir=$PROJSDIR

 let vars=[
       \  'DC_Proj_SecNamesBase',
       \  'DC_ProjsDir',
       \  'projs',
       \  'DC_ProjTypes',
       \ ]

 call F_VarCheckExist(vars)

 call F_uniq('projs')

 echo ""
 echo "This will create a new TeX project skeleton "
 echo "		in projects' directory: " . g:DC_ProjsDir
 echo ""

 let yn=input('Continue? (y/n): ','y')
 if yn != 'y'
   RFUN SubNameEnd
   return 0
 endif
  
 if a:0
 	 let proj=a:1
	 let projtype='regular'

 else
	 LFUN F_GetFromChooseDialog
	 LFUN DC_CompleteProjs

	 let projtype=F_GetFromChooseDialog({ 
		 	\ 'list'        : g:DC_ProjTypes,
		 	\ 'startopt'    : '',
		 	\ 'header'      : "Available project types are: ",
		 	\ 'numcols'     : 1,
		 	\ 'bottom'      : "Choose a project type by number: ",
		 	\ })

 endif

 let projstruct=F_GetFromChooseDialog({ 
		 	\ 'list'        : g:DC_ProjStructures,
		 	\ 'startopt'    : 'in_root',
		 	\ 'header'      : "Available project structures are: ",
		 	\ 'numcols'     : 1,
		 	\ 'bottom'      : "Choose a project structure by number: ",
		 	\ })

 CD projs

"""projtype_regular
 if projtype == 'regular'

	 if ! exists('proj') || ! strlen(proj) 
	 	let proj=input('Project name:','','custom,DC_CompleteProjs')
	 endif

	 if ! strlen(proj)
		 call F_sub_warn('no project name provided')
		 RFUN SubNameEnd 
		 return 0 
	 endif
	
	 if index(g:projs,proj) >= 0
		  let rw = input('Project already exists, rewrite (y/n)?: ','n')

			if rw != 'y'
		    RFUN SubNameEnd
				return 0
			endif
	 endif
	
	 let texfiles={}
	 let texfileids=g:DC_Proj_SecNamesBase
	 
	 for id in texfileids
	      let texfiles[id]=id
	 endfor
	
	 call map(texfiles, "proj . '.' . v:key . '.tex' ")
	 call extend(texfiles, { '_main_' : proj . '.tex' } )
	
	 """ fill in base sections: 
	 """   preamble, packages, begin etc. 
	 for [id,file] in items(texfiles)
		 		let cmd = ' tex_create_proj.pl ' 
	          \ . ' --dir  ' . g:DC_ProjsDir 
	          \ . ' --proj ' . proj
	          \ . ' --sec  ' . id
	          \ . ' --struct  ' . projstruct
	          \ . ' --force  '
				if ! F_sys(cmd)
			    	RFUN SubNameEnd 
						return 0
				endif
	 endfor
	
	 """ append the name of the project being created to 
	 """   PROJS.i.dat
	 if ! F_sys(' tex_create_proj.pl ' 
	        \ . ' --proj ' . proj
	        \ . ' --appenddat '
	        \ . ' --force '
	       	\ ) 
		  RFUN SubNameEnd 
			return 0
	 endif
	
	 for file in values(texfiles)
		 if filereadable(file)
	     	if ! F_sys("git add " . file )
		  		RFUN SubNameEnd 
					return 0
				endif
		 endif
	 endfor

	 if index(g:projs,proj) < 0
	 		call add(g:projs,proj)
	 endif
	
	 let g:proj=proj
	
	 call DC_Proj_GenPerl()
	
	 call F_echo_redraw('Created new project: ' . proj)
	
	 let menuprojs=input('Load projs menu? (y/n): ', 'n')
	 if menuprojs == 'y'
	 		MenuReset projs
	 endif
	 let loadmain=input('Load the main project file? (y/n): ', 'n')
	 if loadmain == 'y'
	 		VSECBASE _main_
	 endif
	
"""projtype_receipt
 elseif projtype == 'receipt'

	 let recnumber=input('Receipt number:','')

	 let proj='receipt_REC_' . recnumber

perl << EOF
#!/usr/bin/env perl
 
 use strict;
 use warnings;
 use feature qw(switch);
  
# use Vim::Perl qw( VimVars VimLet VimMsg );
# Vim::Perl::init;
#
# use Text::Generate::TeX;
# use Data::Dumper;
#
# my $vars=VimVars(  qw( recnumber )  );
# my $tex=Text::Generate::TeX->new;
# my $file=Text::Generate::TeX->new;
#
# VimMsg(Dumper($vars));
 	
EOF

"""projtype_address
 elseif projtype == 'address'

perl << EOF
#!/usr/bin/env perl
 
 use strict;
 use warnings;
  
# use Vim::Perl qw( VimVars VimLet VimMsg );
#
# use Text::Generate::TeX;
# use Data::Dumper;
#
# my $vars=VimVars(  qw( recnumber )  );
# my $tex=Text::Generate::TeX->new;
# my $file=Text::Generate::TeX->new;
#
# VimMsg(Dumper($vars));
 	
EOF
	 
 endif

 RFUN SubNameEnd
 return 1

endf


