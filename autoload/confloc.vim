if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))

    let s:symbols = {}
endif


function! confloc#me() abort
    " user special config
    let this = {
        \ "Scheme" : 'gdb#SchemeCreate',
        \ "autorun" : 1,
        \ "reconnect" : 0,
        \ "showbreakpoint" : 0,
        \ "showbacktrace" : 0,
        \ "conf_gdb_layout" : ["sp"],
        \ "conf_gdb_cmd" : ['gdb -q -f', 'a.out'],
        \ "window" : [
        \   {   "name":   "gdbserver",
        \       "status":  0,
        \   },
        \ ],
        \ "state" : {
        \ }
        \ }

    return this
endfunc


function! confloc#InitSvr() abort
    if !has_key(g:gdb, "_server_id") || empty(g:gdb._server_addr)
        echoerr "GdbServer window not exist or address is empty."
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


function! confloc#Symbol(type, expr) abort
    let expr = get(s:symbols, a:type, '')
    if !empty(expr)
        let Expr = function(expr)
        let expr = Expr(a:expr)
        return expr
    else
        return printf('p %s', a:expr)
    endif
endfunc


function! s:__fini__()
    if exists("s:init")
        return
    endif
    let s:symbols = {
        \}
endfunction
call s:__fini__()
let s:init = 1
