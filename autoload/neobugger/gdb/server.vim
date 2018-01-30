if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))

    let s:symbols = {}
endif


function! neobugger#gdb#server#Conf() abort
    " user special config
    let this = {
        \ "module" : "gdb",
        \ "Scheme" : 'neobugger#gdb#basic#Conf',
        \ "Inherit": 'neobugger#gdb#server#New',
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


function! neobugger#gdb#server#New()
    let this = tlib#Object#New({
                \ '_class': ['GdbServer'],
                \ })


    function! this.Init()
        let l:__func__ = "server.Init"
        if !has_key(self, "_server_id")
            echoerr l:__func__. "(): GdbServer window not exist."
            return
        endif
        if empty(self._server_addr)
            echoerr l:__func__. "(): server address is empty."
            return
        endif

        let self._vdom = 0
        let self._worker_pid = 0
        let self._debug_level = 0
        let self._remote_debugging = 0

        silent! call s:log.info(l:__func__, " args=", string(self.args))
        let l:cmdstr = 'login.exp '. self._server_addr[0].' '.join(self.args.args[1:], ' ')
        silent! call s:log.info(l:__func__, " cmdstr=", l:cmdstr)
        call self.SendSvr(l:cmdstr)
    endfunction


    function! this.Symbol(type, expr)
        let l:__func__ = "server.Symbol"
        silent! call s:log.info(l:__func__, " type=", a:type, " expr=", a:expr)

        let expr = get(s:symbols, a:type, '')
        if !empty(expr)
            let Expr = function(expr)
            let expr = Expr(a:expr)
            return expr
        else
            return printf('p %s', a:expr)
        endif
    endfunction


    return this.New(a:0 >= 1 ? a:1 : {})
endfunction


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
