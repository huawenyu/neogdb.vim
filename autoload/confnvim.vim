
function! confnvim#Conf() abort
    " user special config
    let this = {
        \ "scheme" : "gdb#SchemeCreate",
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
        call gdb#Send(printf("target remote %s:%d\nc",
                    \ g:gdb._server_addr, a:port))
    endfunction


    return this
endfunc

