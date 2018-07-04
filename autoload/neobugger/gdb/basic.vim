if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))
endif

function! neobugger#gdb#basic#Conf() abort
    let this = {
        \ "module" : "gdb",
        \ "name" : "SchemeGDB",
        \ "window" : [
        \   {   "name":   "gdb",
        \       "view":   "View_gdb",
        \       "state":  "init",
        \       "status":  1,
        \       "cmd":    ["conf_gdb_cmd", "$SHELL"],
        \   },
        \   {   "name":   "gdbserver",
        \       "view":   "View_server",
        \       "state":  "gdbserver",
        \       "status":  1,
        \       "cmd":    ["conf_server_cmd", "$SHELL"],
        \   },
        \ ],
        \ "state" : {
        \   "init": [
        \       {   "match":   [ '#neobug_tag_init#', ],
        \           "hint":    "The 1st time entering gdb",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_init",
        \       },
        \       {   "match":   [ '#neobug_tag_initend#', ],
        \           "hint":    "gdb Init End",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_initend",
        \       },
        \   ],
        \   "remoteconn": [
        \       {   "match":   [ '\v^Remote debugging using \d+\.\d+\.\d+\.\d+:\d+', ],
        \           "hint":    "gdb.RemoteConnectSucc",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_remoteconn_succ",
        \       },
        \       {   "match":   [ '\v^\d+\.\d+\.\d+\.\d+:\d+: Connection timed out.', ],
        \           "hint":    "gdb.RemoteConnectFail",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_remoteconn_fail",
        \       },
        \       {   "match":   ['\v[\o32]{2}([^:]+):(\d+):\d+',
        \                       '\v/([\h\d/]+):(\d+):\d+',
        \                       '\v^#\d+ .{-} \(\) at (.+):(\d+)',
        \                       '\v at /([\h\d/]+):(\d+)',
        \                      ],
        \           "hint":    "gdb.Jump",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_jump",
        \       },
        \   ],
        \   "pause": [
        \       {   "match":   ["Continuing."],
        \           "hint":    "gdb.Continue",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_continue",
        \       },
        \       {   "match":   ['#neobug_tag_parseend#'],
        \           "hint":    "gdb.ParseEnd",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_parseend",
        \       },
        \       {   "match":   ['\v[\o32]{2}([^:]+):(\d+):\d+',
        \                       '\v/([\h\d/]+):(\d+):\d+',
        \                       '\v^#\d+ .{-} \(\) at (.+):(\d+)',
        \                       '\v at /([\h\d/]+):(\d+)',
        \                      ],
        \           "hint":    "gdb.Jump",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_jump",
        \       },
        \       {   "match":   ['The program is not being run.'],
        \           "hint":    "gdb.Unexpect",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_unexpect",
        \       },
        \       {   "match":   ['\v^type \= (\p+)',],
        \           "hint":    "gdb.Whatis",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_whatis",
        \       },
        \       {   "match":   ["Remote communication error.  Target disconnected.:"],
        \           "hint":    "gdb.Retry",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_retry",
        \       },
        \   ],
        \   "running": [
        \       {   "match":   ['#neobug_tag_parseend#'],
        \           "hint":    "gdb.ParseEnd",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_parseend",
        \       },
        \       {   "match":   ['\v^Breakpoint \d+',
        \                       '\v^Temporary breakpoint \d+',
        \                       '\v^\(gdb\) ',
        \                      ],
        \           "hint":    "gdb.Pause",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_pause",
        \       },
        \       {   "match":   ['\v\[Inferior\ +.{-}\ +exited\ +normally'],
        \           "hint":    "gdb.Disconnected",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_disconnected",
        \       },
        \   ],
        \   "parsevar": [
        \       {   "match":   ['#neobug_tag_var_type#', ],
        \           "hint":    "Parse var type end",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_parse_vartype",
        \       },
        \       {   "match":   ['#neobug_tag_var_data#', ],
        \           "hint":    "Parse var data end",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_parse_varend",
        \       },
        \       {   "match":   ['Error in sourced command file', ],
        \           "hint":    "Parse var data error",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_parse_error",
        \       },
        \   ],
        \   "gdbserver": [
        \       {   "match":   ['\vListening on port (\d+)'],
        \           "hint":    "gdb.Accept",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_accept",
        \       },
        \       {   "match":   ['\vDetaching from process \d+'],
        \           "hint":    "gdb.Exit",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_exit",
        \       },
        \   ],
        \   "job": [
        \       {   "match":   ['call_jobfunc1'],
        \           "hint":    "gdb.JobFunction1",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_jobfunc1",
        \       },
        \       {   "match":   ['\v^jobDoneLoadBacktrace'],
        \           "hint":    "gdb.LoadBackTrace",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_load_bt",
        \       },
        \   ],
        \ }
        \}


    function this.on_load_bt(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_continue(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_jump(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_parseend(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_parse_vartype(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_parse_varend(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_parse_error(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_whatis(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_retry(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_init(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_initend(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_accept(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_remoteconn_succ(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_remoteconn_fail(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_pause(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function this.on_disconnected(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    function! this.on_exit(funcname, ...)
        silent! call s:log.info(self.module.".Scheme.".a:funcname." args=", string(a:000))
        call neobugger#Handle(self.module, a:funcname, a:000)
    endfunction

    return this
endfunction


