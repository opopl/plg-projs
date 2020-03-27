


function! projs#xml#cols()
	let cols = base#varget('projs_xml_cols',[])
	return cols
endf

if 0
	Purpose:
		
	Usage:
		call projs#xml#update_col ()
	Call tree:
		calls:
		
		called by:
			projs#db_vis#update
endif

function! projs#xml#update_col(...)
  let ref = get(a:000,0,{})

  let xmlfile = get(ref,'xmlfile',projs#xmlfile())

  let proj = get(ref,'proj','')
  let sec = get(ref,'sec','')
  let col = get(ref,'col','')

  let val = get(ref,'val','')

python3 << eof
import vim
import xml.etree.ElementTree as ET
import xml.dom.minidom as minidom

xmlfile = vim.eval('xmlfile')


def prettify(elem):
    """Return a pretty-printed XML string for the Element.
    """
    rough_string = ET.tostring(elem, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ")

proj = vim.eval('proj')
sec = vim.eval('sec')
col = vim.eval('col')

val = vim.eval('val')

tree = ET.ElementTree(file=xmlfile)
root = tree.getroot()

xpath = './/proj[@name="{}"]/sec[@name="{}"]/{}'.format(proj,sec,col)
for e in root.findall(xpath):
	e.text = val

xml = prettify(root)
eof
	let xml = py3eval('xml')

	" remove empty (spaces-only) lines
	let xmllines = filter(
		\	split(xml,"\n"),
		\	'match(v:val,"^\\zs\\s*\\ze$") == -1')

	let r = {
	      \   'lines'  : xmllines,
	      \   'file'   : projs#xmlfile(),
	      \   }
	call base#file#write_lines(r)	
endf
