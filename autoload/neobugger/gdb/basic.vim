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
        \       "state":  "init",
        \       "status":  1,
        \       "layout": ["conf_gdb_layout", "vsp"],
        \       "cmd":    ["conf_gdb_cmd", "$SHELL"],
        \   },
        \   {   "name":   "gdbserver",
        \       "state":  "gdbserver",
        \       "status":  1,
        \       "layout": ["conf_server_layout", "sp"],
        \       "cmd":    ["conf_server_cmd", "$SHELL"],
        \   },
        \   {   "name":   "job",
        \       "state":  "job",
        \       "status":  0,
        \       "layout": ["conf_job_layout", "tabnew"],
        \       "cmd":    ["conf_job_cmd", "$SHELL"],
        \   },
        \ ],
        \ "state" : {
        \   "init": [
        \       {   "match":   [ 'neobugger_starting', ],
        \           "hint":    "The 1st time entering gdb",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_init",
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
        \   ],
        \   "pause": [
        \       {   "match":   ["Continuing."],
        \           "hint":    "gdb.Continue",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_continue",
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


