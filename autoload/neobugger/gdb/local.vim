if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))

    let s:symbols = {}
endif


function! neobugger#gdb#local#Conf() abort
    " user special config
    let this = {
        \ "module" : "gdb",
        \ "Scheme" : 'neobugger#gdb#basic#Conf',
        \ "Inherit": 'neobugger#gdb#local#New',
        \
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

    return this
endfunc


function! neobugger#gdb#local#New()
    let this = tlib#Object#New({
                \ '_class': ['GdbLocal'],
                \ })


    function this.Restart(...)
        silent! call s:log.info(self.module.".Restart() args=", string(a:000))
        call self._Send("\<c-c>info line\<cr>start\<cr>")
    endfunction


    return this.New(a:0 >= 1 ? a:1 : {})
endfunction


function! s:__fini__()
    if exists("s:init")
        return
    endif
    let s:symbols = {
        \}
endfunction
call s:__fini__()
let s:init = 1
