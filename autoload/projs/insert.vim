
function! projs#insert#template_tex ()
	call projs#insert#template ('tex')
endfunction

function! projs#insert#template_vim ()
	call projs#insert#template ('vim')
endfunction

function! projs#insert#projname ()
	let proj = projs#proj#name()
	call append(line('.'),proj)

endfunction

""" BaseDatView projs_opts_PrjInsert
function! projs#insert#main ()
	let proj = projs#proj#name()

python3 << eof
import vim,re

proj = vim.eval('proj')

t = '''
%%file _main_
%%file f_main\n
\\def\PROJ{_PROJ_}\n
\\def\ii#1{\InputIfFileExists{\PROJ.#1.tex}{}{}}\n
\\def\iif#1{\input{\PROJ/#1.tex}}\n
\\def\idef#1{\InputIfFileExists{_def.#1.tex}{}{}}\n
'''
t = re.sub(r'_PROJ_',proj,t)

eof
	let t  = py3eval('t')
	let ta = split(t,"\n")
	call append(line('.'),ta)

endfunction

function! projs#insert#figure ()

	let lines = []

	let picname  = input('Picture FileName:','','custom,projs#complete#pics')
	let picwidth = input('Picture Width (in terms of \textwidth):','0.5')
	let caption  = input('Caption:','')
	let label    = input('Label:',picname)

	call add(lines,'\begin{figure}[ht]')
	call add(lines,' \centering')
	call add(lines,' \PrjPicW{'.picname.'}{'.picwidth.'}')
	call add(lines,' \caption{'.caption.'}')
	call add(lines,' \label{fig:'.label.'}')
	call add(lines,'\end{figure}')

	call append(line('.'),lines)

endfunction

function! projs#insert#secname ()
	let sec = projs#proj#secname()
	call append(line('.'),sec)

endfunction

function! projs#insert#template (type)
	let type  = a:type
	let t     = projs#varget('templates_'.type,{})
	let tlist = sort(keys(t))

	if !len(tlist)
		call projs#echo('No '.type.' templates found, aborting.')
		return
	endif

	let tname = input(type.' template name:','','custom,projs#complete#templates_'.type)
	let tlines = get(t,tname,[])

	call append(line('.'),tlines)
	
endfunction
