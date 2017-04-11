if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))

    let s:symbols = {}
endif


function! confos#me() abort
    " user special config
    let this = {
        \ "Scheme" : 'gdb#SchemeCreate',
        \ "ServerInit" : 'confos#InitSvr',
        \ "Symbol" : 'confos#Symbol',
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
        \       {   "match":   ['\v^--More-- ', '\v^--more-- '],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_gdbserver_more",
        \       },
        \       {   "match":   ['\v^System time: ','Release Version Information: '],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_getsystemstatus_end",
        \       },
        \       {   "match":   ['\VVirtual domain configuration: disable'],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_vdom_disable",
        \       },
        \       {   "match":   ['\VVirtual domain configuration: enable'],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_vdom_enable",
        \       },
        \
        \       {   "match":   ['\vProcess \[1\]: type\=wanopt\(2\) index\=0 pid\=(\d+) state\=running',
        \                       '\v^(\d+).*/bin/wad 7 0'],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_worker_pid",
        \       },
        \       {   "match":   ['\VSet watchdog enable.'],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_watchdog_enable",
        \       },
        \       {   "match":   ['\VSet watchdog disable.'],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_watchdog_disable",
        \       },
        \       {   "match":   ['\v^wad debug level is (\d+) \(0x'],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_wad_debug_level",
        \       },
        \       {   "match":   ['\v^Remote debugging from host '],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_remote_debugging",
        \       },
        \   ]
        \ }
        \ }


    function this.on_gdbserver_more(...)
        if g:gdb._remote_debugging
            return
        endif
        call gdb#SendSvr('')
    endfunction

    function this.on_getsystemstatus_end(...)
        if g:gdb._remote_debugging
            return
        endif
        if g:gdb._vdom
        else
            call gdb#SendSvr('diag debug app wad 0')
            call gdb#SendSvr('diag debug enable')
            call gdb#SendSvr('diag test app wad 1000')
        endif
    endfunction

    function this.on_vdom_disable(...)
        let g:gdb._vdom = 0
    endfunction

    function this.on_vdom_enable(...)
        let g:gdb._vdom = 1
    endfunction

    function this.on_worker_pid(pid, ...)
        let g:gdb._worker_pid = a:pid
        if g:gdb._remote_debugging
            return
        endif
        call gdb#SendSvr('diag test app wad 2200')
        call gdb#SendSvr('diag test app wad 7')
    endfunction

    function this.on_watchdog_enable(...)
        if g:gdb._remote_debugging
            return
        endif
        call gdb#SendSvr('diag test app wad 7')
    endfunction

    function this.on_watchdog_disable(...)
        if g:gdb._remote_debugging
            return
        endif
        call gdb#SendSvr('diag test app wad 2200')
        call gdb#SendSvr('diag debug app wad '. g:gdb._debug_level)
        call gdb#SendSvr('diag debug disable')

        if g:gdb._worker_pid
            call gdb#SendSvr('sys sh')
            call gdb#SendSvr('gdbserver :444 --attach '. g:gdb._worker_pid)
        endif
    endfunction

    function this.on_wad_debug_level(level, ...)
        if g:gdb._remote_debugging
            return
        endif
        let g:gdb._debug_level = a:level
    endfunction

    function this.on_remote_debugging(...)
        let g:gdb._remote_debugging = 1
    endfunction


    return this
endfunc


function! confos#InitSvr() abort
    if !has_key(g:gdb, "_server_id") || empty(g:gdb._server_addr)
        echoerr "GdbServer window not exist or address is empty"
        return
    endif

    let g:gdb._vdom = 0
    let g:gdb._worker_pid = 0
    let g:gdb._debug_level = 0
    let g:gdb._remote_debugging = 0

    echomsg printf("GdbserverInit(%s-%s) starting ..."
                \, string(g:gdb._server_addr), string(g:gdb._server_id))
    call gdb#SendSvr('telnet '. g:gdb._server_addr[0])
    sleep 1
    call gdb#SendSvr('admin')
    sleep 1
    call gdb#SendSvr('')
    sleep 1
    call gdb#SendSvr('get system status')
endfunc


function! confos#Symbol(type, expr) abort
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
