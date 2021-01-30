
"if exists("b:projs_current_syntax")
  "finish
"endif

"syn keyword	confTodo	contained TODO FIXME XXX
"" Avoid matching "text#text", used in /etc/disktab and /etc/gettytab
"syn match	confComment	"^#.*" contains=confTodo
"syn match	confComment	"\s#.*"ms=s+1 contains=confTodo
"syn region	confString	start=+"+ skip=+\\\\\|\\"+ end=+"+ oneline
"syn region	confString	start=+'+ skip=+\\\\\|\\'+ end=+'+ oneline

"" Define the default highlighting.
"" Only used when an item doesn't have highlighting yet
"hi def link confComment	Comment
"hi def link confTodo	Todo
"hi def link confString	String
"
syntax region IfOff start=/^off\s*$/ end=/^on\s*$/
highlight link IfOff Comment

syntax keyword zlanKey page global
syntax keyword zlanOp set unset setlist setdict
syntax keyword zlanKeyword url title in ii tags date
"syntax keyword zlanKeyword on off
syntax keyword zlanFlag redo fail
syntax keyword zlanKeyword acts

syn match	zlanComment	"^\s*#.*$"

highlight link zlanKeyword Keyword
highlight link zlanFlag MoreMsg
highlight link zlanKey WarningMsg
highlight link zlanOp Pmenu

highlight def link zlanComment	Comment

let b:projs_current_syntax = "zlan"
