if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))

    let s:symbols = {}
endif


function! neobugger#gdb#server#Conf() abort
    " user special config
    let this = {
        \ "Scheme" : 'neobugger#gdb#SchemeCreate',
        \ "ServerInit" : 'neobugger#gdb#server#InitSvr',
        \ "Symbol" : 'neobugger#gdb#server#Symbol',
        \ "autorun" : 0,
        \ "reconnect" : 0,
        \ "showbreakpoint" : 1,
        \ "showbacktrace" : 1,
        \ "conf_gdb_layout" : ["vsp"],
        \ "conf_gdb_cmd" : ['gdb -q -f', 'sysinit/init'],
        \ "conf_server_cmd" : ["$SHELL",],
        \ "conf_server_addr" : ["",],
        \ "state" : {
        \   "gdbserver": [
        \       {   "match":   ['\v^Remote debugging from host '],
        \           "hint":    "server.GdbClientConnected",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_remote_debugging",
        \       },
        \   ]
        \ }
        \ }


    function this.on_remote_debugging(...)
        let g:gdb._remote_debugging = 1
    endfunction

    return this
endfunc


function! neobugger#gdb#server#InitSvr() abort
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')
    if !has_key(g:gdb, "_server_id")
        echoerr "server#InitSvr(): GdbServer window not exist"
        return
    endif
    if empty(g:gdb._server_addr)
        echoerr "server#InitSvr(): server address is empty"
        return
    endif

    let g:gdb._vdom = 0
    let g:gdb._worker_pid = 0
    let g:gdb._debug_level = 0
    let g:gdb._remote_debugging = 0

    silent! call s:log.info(l:__func__, " args=", string(g:gdb.args))
    let l:cmdstr = 'login.exp '. g:gdb._server_addr[0].' '.join(g:gdb.args.args[1:], ' ')
    silent! call s:log.info(l:__func__, " cmdstr=", l:cmdstr)
    call neobugger#gdb#SendSvr(l:cmdstr)
endfunc


function! neobugger#gdb#server#Symbol(type, expr) abort
    let expr = get(s:symbols, a:type, '')
    if !empty(expr)
        let Expr = function(expr)
        let expr = Expr(a:expr)
        return expr
    else
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
