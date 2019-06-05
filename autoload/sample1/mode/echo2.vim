if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))

    let s:symbols = {}
endif


function! sampele1#mode#echo2#Conf() abort
    " user special config
    let this = {
        \ "module" : "gdb",
        \ "Scheme" : 'neobugger#gdb#basic#Conf',
        \
        \ "autorun" : 0,
        \ "reconnect" : 0,
        \ "showbreakpoint" : 1,
        \ "showbacktrace" : 1,
        \ "conf_gdb_layout" : ["vsp"],
        \ "conf_gdb_cmd" : ["gdb -ex 'echo neobugger_starting\n' -q -f", 'sysinit/init'],
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


    function this.on_remote_debugging(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    return this
endfunc
