if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))

    let s:symbols = {}
endif


function! neobugger#gdb#local#Conf() abort
    " user special config
    let this = {
        \ "Scheme" : 'neobugger#gdb#default#Conf',
        \ "autorun" : 1,
        \ "reconnect" : 0,
        \ "showbreakpoint" : 0,
        \ "showbacktrace" : 0,
        \ "conf_gdb_layout" : ["sp"],
        \ "conf_gdb_cmd" : ["gdb -ex 'echo neobugger_starting\n' -q -f", 'a.out'],
        \ "window" : [
        \   {   "name":   "gdbserver",
        \       "status":  0,
        \   },
        \ ],
        \ "state" : {
        \ }
        \ }

    function this.Restart(...)
        silent! call s:log.info(self.module.".Restart() args=", string(a:000))
        call jobsend(self._client_id, "\<c-c>info line\<cr>start\<cr>")
    endfunction

    return this
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
