
function! confos#Conf() abort
    " user special config
    let this = {
        \ "scheme" : "gdb#SchemeCreate",
        \ "symbol" : "confos#Symbol",
        \ "autorun" : 0,
        \ "reconnect" : 0,
        \ "conf_gdb_cmd" : ["gdb -q -f", "sysinit/init"],
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
            let g:gdb._server_addr[1] = string(a:port)
            call gdb#Attach()
        endif
    endfunction


    return this
endfunc


function! confos#Symbol(expr) abort
    return a:expr
endfunc
