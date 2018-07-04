if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})

    "sign define GdbBreakpointEn text=● texthl=Search
    "sign define GdbBreakpointDis text=● texthl=Function
    "sign define GdbBreakpointDel text=● texthl=Comment

    "sign define GdbCurrentLine text=☛ texthl=Error
    ""sign define GdbCurrentLine text=☛ texthl=Keyword
    ""sign define GdbCurrentLine text=⇒ texthl=String

    "set errorformat+=#%c\ \ %.%#\ in\ %m\ \(%.%#\)\ at\ %f:%l
    "set errorformat+=#%c\ \ %.%#\ in\ \ \ \ %m\ \ \ \ at\ %f:%l
    "set errorformat+=#%c\ \ %m\ \(%.%#\)\ at\ %f:%l
endif


" Constructor
" @param conf='local|pid|server'
"        type 'local', 'bin-exe', {'args': [list]}
"        type 'pid', 'bin-exe', {'pid': 3245}
"        type 'server', 'bin-exe', {'args': [list]}
function! neobugger#Debugger#New()
    "{
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let l:std = s:prototype.New(a:0 >= 1 ? a:1 : {})
    return l:std
    "}
endfunction

