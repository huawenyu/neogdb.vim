if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))

    let s:symbols = {}
endif


function! neobugger#gdb#local#Conf() abort
    " user special config
    let this = {
        \ "Scheme" : 'neobugger#gdb#SchemeCreate',
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


function! neobugger#gdb#local#Symbol(type, expr) abort
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
