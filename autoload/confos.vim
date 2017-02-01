function! s:__init__()
    if exists("s:init")
        return
    endif
    let s:symbols = {}
endfunction
call s:__init__()


function! confos#me() abort
    " user special config
    let this = {
        \ "scheme" : 'gdb#SchemeCreate',
        \ "symbol" : 'confos#Symbol',
        \ "server_init" : 'confos#InitSvr',
        \ "autorun" : 0,
        \ "reconnect" : 0,
        \ "conf_gdb_cmd" : ['gdb -q -f', 'sysinit/init'],
        \ "conf_server_cmd" : ["$SHELL",],
        \ "conf_server_addr" : ["",],
        \ "state" : {
        \   "gdbserver": [
        \       {   "match":   ['\vListening on port (\d+)'],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_accept",
        \       },
        \   ]
        \ }
        \ }


    function this.on_accept(port, ...)
        if a:port
            let g:gdb._server_addr[1] = a:port
            call gdb#Attach()
        endif
    endfunction


    return this
endfunc


function! confos#InitSvr() abort
    "call gdb#SendSvr('gdbserver :444 --attach <pid>')
endfunc


function! confos#Symbol(type, expr) abort
    let expr = get(s:symbols, a:type, '')
    if !empty(expr)
        echomsg "wilson call getsymbol"
        let Expr = function(expr)
        let expr = Expr(a:expr)
        return expr
    else
        echomsg "wilson getsymbol not find ". a:type
        return printf('p %s', a:expr)
    endif
endfunc


function! s:cstr(pchar, len)
    return printf(
        \'p *((char*)(%s))@(%s)'
        \, a:pchar, a:len)
endfunction


function! s:region(expr)
    return s:cstr(
        \printf('&(%s)->buff->data[(%s)->start]', a:expr, a:expr),
        \printf('(%s)->end - (%s)->start', a:expr, a:expr))
endfunction


function! s:string(expr)
    return s:cstr(
        \printf('(%s)->data', a:expr),
        \printf('(%s)->len', a:expr))
endfunction


function! s:http_line(expr)
    let expr = s:region(a:expr. '->br')
    return expr
endfunction


function! s:__fini__()
    if exists("s:init")
        return
    endif
    let s:symbols = {
        \'struct wad_buff_region *': '<SID>region',
        \'struct wad_str *': '<SID>string',
        \'struct wad_http_line *': '<SID>http_line',
        \}
endfunction
call s:__fini__()
let s:init = 1
