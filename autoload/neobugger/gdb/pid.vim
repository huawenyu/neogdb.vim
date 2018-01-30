if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))
endif

function! neobugger#gdb#pid#Conf() abort
    " user special config
    let this = {
        \ "Scheme" : 'neobugger#gdb#basic#Conf',
        \ "autorun" : 1,
        \ "reconnect" : 0,
        \ "showbreakpoint" : 0,
        \ "showbacktrace" : 0,
        \ "conf_gdb_layout" : ["sp"],
        \ "conf_gdb_cmd" : ["sudo gdb -ex 'echo neobugger_starting\n' -q"],
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

