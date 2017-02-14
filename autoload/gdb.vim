if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))

    sign define GdbBreakpointEn text=● texthl=Search
    sign define GdbBreakpointDis text=● texthl=Function
    sign define GdbBreakpointDel text=● texthl=Comment

    sign define GdbCurrentLine text=☛ texthl=Error
    "sign define GdbCurrentLine text=☛ texthl=Keyword
    "sign define GdbCurrentLine text=⇒ texthl=String

    set errorformat+=#0\ \ %m\ \(%.%#\)\ at\ %f:%l
    set errorformat+=#%.%#\ \ %.%#\ in\ %m\ \(%.%#\)\ at\ %f:%l
    set errorformat+=#%.%#\ \ %.%#\ in\ \ \ \ %m\ \ \ \ at\ %f:%l

    let s:gdb_port = 7778
    let s:breakpoint_signid_start = 5000
    let s:breakpoint_signid_max = 0

    let s:breakpoints = {}
    let s:toggle_all = 0
    let s:gdb_bt_qf = '/tmp/gdb.bt'
    let s:gdb_break_qf = '/tmp/gdb.break'
    let s:brk_file = './.gdb.break'
    let s:fl_file = './.gdb.file'
    let s:file_list = {}

    call gdb#Map("nmap")
endif


function! gdb#SchemeCreate() abort
    let this = {
        \ "name" : "SchemeGDB",
        \ "window" : [
        \   {   "name":   "gdb",
        \       "state":  "init",
        \       "layout": ["conf_gdb_layout", "vsp"],
        \       "cmd":    ["conf_gdb_cmd", "$SHELL"],
        \   },
        \   {   "name":   "gdbserver",
        \       "state":  "gdbserver",
        \       "layout": ["conf_server_layout", "sp"],
        \       "cmd":    ["conf_server_cmd", "$SHELL"],
        \   },
        \   {   "name":   "job",
        \       "state":  "job",
        \       "layout": ["conf_job_layout", "tabnew"],
        \       "cmd":    ["conf_job_cmd", "$SHELL"],
        \   },
        \ ],
        \ "state" : {
        \   "init": [
        \       {   "match":   [ '(gdb)', ],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_init",
        \       },
        \   ],
        \   "remoteconn": [
        \       {   "match":   [ '\v^Remote debugging using \d+\.\d+\.\d+\.\d+:\d+', ],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_remoteconn_succ",
        \       },
        \       {   "match":   [ '\v^\d+\.\d+\.\d+\.\d+:\d+: Connection timed out.', ],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_remoteconn_fail",
        \       },
        \   ],
        \   "pause": [
        \       {   "match":   ["Continuing."],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_continue",
        \       },
        \       {   "match":   ['\v[\o32]{2}([^:]+):(\d+):\d+',
        \                       '\v/([\h\d/]+):(\d+):\d+',
        \                       '\v at /([\h\d/]+):(\d+)',
        \                      ],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_jump",
        \       },
        \       {   "match":   ['The program is not being run.'],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_unexpect",
        \       },
        \       {   "match":   ['\v^type \= (\p+)',],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_whatis",
        \       },
        \       {   "match":   ["Remote communication error.  Target disconnected.:"],
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
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_pause",
        \       },
        \       {   "match":   ['\v\[Inferior\ +.{-}\ +exited\ +normally'],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_disconnected",
        \       },
        \   ],
        \   "gdbserver": [
        \       {   "match":   ['\vListening on port (\d+)'],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_accept",
        \       },
        \       {   "match":   ['\vDetaching from process \d+'],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_exit",
        \       },
        \   ],
        \   "job": [
        \       {   "match":   ['call_jobfunc1'],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_jobfunc1",
        \       },
        \       {   "match":   ['\v^jobDoneLoadBacktrace'],
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":    "on_load_bt",
        \       },
        \   ],
        \ }
        \}

    function this.on_load_bt(...)
        if filereadable(s:gdb_bt_qf)
            exec "cgetfile " . s:gdb_bt_qf
            "call utilquickfix#RelativePath()
        endif
    endfunction

    function this.on_continue(...)
        call state#Switch('gdb', 'running', 0)
        call gdb#Update_current_line_sign(0)
    endfunction

    function this.on_jump(file, line, ...)
        if g:gdb._win_gdb._state.name !=# "pause"
    silent! call s:log.info(gdb)
            silent! call s:log.info("State ", g:gdb._win_gdb._state.name, " => pause")
            call state#Switch('gdb', 'pause', 0)
            call gdb#Send('parser_bt')
            call gdb#Send('info line')
        endif
        call gdb#Jump(a:file, a:line)
    endfunction

    function this.on_whatis(type, ...)
        call gdb#Whatis(a:type)
    endfunction

    function this.on_retry(...)
        if g:gdb._server_exited
            return
        endif
        sleep 1
        call gdb#Attach()
        call gdb#Send('continue')
    endfunction


    function this.on_init(...)
        if !g:gdb._initialized
            " set filename-display absolute
            " set remotetimeout 50
            let cmdstr = "set confirm off\n
                        \ set pagination off\n
                        \ set verbose off\n
                        \ set logging off\n
                        \ set print elements 2048\n
                        \ set print pretty on\n
                        \ set print array off\n
                        \ set print array-indexes on\n
                        \"
            call gdb#Send(cmdstr)

            let cmdstr = "define parser_bt\n
                        \ set logging off\n
                        \ set logging file /tmp/gdb.bt\n
                        \ set logging overwrite on\n
                        \ set logging redirect on\n
                        \ set logging on\n
                        \ bt\n
                        \ set logging off\n
                        \ end"
            call gdb#Send(cmdstr)

            let cmdstr = "define silent_on\n
                        \ set logging off\n
                        \ set logging file /dev/null\n
                        \ set logging overwrite off\n
                        \ set logging redirect on\n
                        \ set logging on\n
                        \ end"
            call gdb#Send(cmdstr)

            let cmdstr = "define silent_off\n
                        \ set logging off\n
                        \ end"
            call gdb#Send(cmdstr)

            silent! call s:log.info("Load breaks ...")
            if filereadable(s:brk_file)
                call gdb#ReadVariable("s:breakpoints", s:brk_file)
            endif

            let g:gdb._initialized = 1
            silent! call s:log.info("Load set breaks ...")
            if !empty(s:breakpoints)
                call gdb#Breaks2Qf()
                call gdb#RefreshBreakpointSigns(0)
                call gdb#RefreshBreakpoints(0)
            endif

            if !empty(g:gdb.ServerInit)
                silent! call s:log.info("Gdbserver call Init()=", g:gdb.ServerInit)
                call g:gdb.ServerInit()
            else
                silent! call s:log.info("Gdbserver Init() is null")
            endif

            if g:gdb._autorun
                let cmdstr = "br main\n
                            \ r"
                call gdb#Send(cmdstr)
            endif
        endif

        call state#Switch('gdb', 'pause', 0)
    endfunction


    function this.on_accept(port, ...)
        if a:port
            let g:gdb._server_addr[1] = a:port
            call gdb#Attach()
        endif
    endfunction


    function this.on_remoteconn_succ(...)
        call state#Switch('gdb', 'pause', 0)
    endfunction


    function this.on_remoteconn_fail(...)
        silent! call s:log.error("Remote connect gdbserver fail!")
    endfunction


    function this.on_pause(...)
        call state#Switch('gdb', 'pause', 0)
    endfunction

    function this.on_disconnected(...)
        if !g:gdb._server_exited && g:gdb._reconnect
            " Refresh to force a delete of all watchpoints
            "call gdb#RefreshBreakpoints(2)
            sleep 1
            call gdb#Attach()
            call gdb#Send('continue')
        endif
    endfunction

    function! this.on_exit(...)
        let g:gdb._server_exited = 1
    endfunction

    return this
endfunc



function! gdb#Kill()
    call gdb#Map("unmap")
    call gdb#Update_current_line_sign(0)
    exe 'bd! '. g:gdb._client_buf
    if g:gdb._server_buf != -1
        exe 'bd! '. g:gdb._server_buf
    endif
    exe 'tabnext '. g:gdb._tab
    tabclose
    unlet g:gdb
endfunction


function! gdb#Send(data)
    if g:gdb._win_gdb._state.name ==# "running"
        \|| g:gdb._win_gdb._state.name ==# "remoteconn"
        echomsg "Disable send data when state='". g:gdb._win_gdb._state.name. "'"
    else
        call jobsend(g:gdb._client_id, a:data."\<cr>")
    endif
endfunction


function! gdb#SendSvr(data)
    call jobsend(g:gdb._server_id, a:data."\<cr>")
endfunction


function! gdb#SendJob(data)
    call jobsend(g:gdb._job_id, a:data."\<cr>")
endfunction


function! gdb#Attach()
    if !empty(g:gdb._server_addr)
        call gdb#Send(printf('target remote %s',
                    \join(g:gdb._server_addr, ":")))
        call state#Switch('gdb', 'remoteconn', 0)
    endif
endfunction


function! gdb#Update_current_line_sign(add)
    " to avoid flicker when removing/adding the sign column(due to the change in
    " line width), we switch ids for the line sign and only remove the old line
    " sign after marking the new one
    let old_line_sign_id = get(g:gdb, '_line_sign_id', 4999)
    let g:gdb._line_sign_id = old_line_sign_id == 4999 ? 4998 : 4999
    if a:add && g:gdb._current_line != -1 && g:gdb._current_buf != -1
        exe 'sign place '. g:gdb._line_sign_id. ' name=GdbCurrentLine line='
                    \. g:gdb._current_line. ' buffer='. g:gdb._current_buf
    endif
    exe 'sign unplace '.old_line_sign_id
endfunction


function! gdb#Spawn(conf, client_cmd, server_addr)
    if exists('g:gdb')
        throw 'Gdb already running'
    endif

    let gdb = {}
    let gdb._initialized = 0
    let Conf = function(a:conf)
    if empty(Conf)
        throw "gdb#Spawn: no Conf '". a:conf ."'."
    endif
    "let Conf = function('confos#Conf')
    let conf = Conf()
    if type(conf) != type({})
        throw "gdb#Spawn: Conf '". a:conf ."' should return a dictionary not ". type(conf). "."
    endif

    let gdb.ServerInit = 0
    if has_key(conf, 'ServerInit')
        let gdb.ServerInit = function(conf.ServerInit)
    endif

    let gdb.Symbol = 0
    if has_key(conf, 'Symbol')
        let gdb.Symbol = function(conf.Symbol)
    endif

    let gdb._autorun = 0
    if has_key(conf, 'autorun')
        let gdb._autorun = conf.autorun
    endif

    let gdb._reconnect = 0
    if has_key(conf, 'reconnect')
        let gdb._reconnect = conf.reconnect
    endif

    if !empty(a:client_cmd)
        let conf.conf_gdb_cmd[1] = a:client_cmd
    endif

    let gdb._server_addr = []
    " 10.1.1.125:444 -> ["10.1.1.125", "444"]
    if !empty(a:server_addr)
        let gdb._server_addr = split(a:server_addr, ":")
    endif

    " Load all files from backtrace to solve relative-path
    " echomsg "Load open files ..."
    "if filereadable(s:gdb_bt_qf)
    "    exec "cgetfile " . s:gdb_bt_qf
    "    let list = getqflist()
    "    echomsg "wilson: ". string(list)
    "    for i in range(len(list))
    "        if has_key(list[i], 'bufnr')
    "            let list[i].filename = fnamemodify(bufname(list[i].bufnr), ':p:.')
    "            unlet list[i].bufnr
    "        else
    "            let list[i].filename = fnamemodify(list[i].filename, ':p:.')
    "        endif
    "        exec "e ". list[i].filename
    "    endfor
    "endif

    if filereadable(s:fl_file)
        call gdb#ReadVariable("s:file_list", s:fl_file)
        for [next_key, next_val] in items(s:file_list)
            if filereadable(next_key)
                exec "e ". fnamemodify(next_key, ':p:.')
            endif
        endfor
    endif

    " window number that will be displaying the current file
    let gdb._jump_window = 1
    let gdb._current_buf = -1
    let gdb._current_line = -1
    let gdb._has_breakpoints = 0
    let gdb._server_exited = 0
    let gdb._gdb_bt_qf = s:gdb_bt_qf
    let gdb._gdb_break_qf = s:gdb_break_qf
    let cword = expand("<cword>")

    call state#Open(conf)
    if !exists('g:state_ctx') || !has_key(g:state_ctx, 'window')
        return
    endif
    if !has_key(g:state_ctx.window, 'gdb')
        return
    endif
    let win_gdb = g:state_ctx.window['gdb']
    let win_gdbserver = g:state_ctx.window['gdbserver']
    let win_job = g:state_ctx.window['job']
    let gdb._win_gdb = win_gdb
    let gdb._win_gdbserver = win_gdbserver
    let gdb._win_job = win_job
    let gdb._client_id = win_gdb._client_id
    let gdb._server_id = win_gdbserver._client_id
    let gdb._job_id = win_job._client_id

    " Create quickfix: lgetfile, cgetfile
    if win_gotoid(g:state_ctx._wid_main) == 1
        if !filereadable(gdb._gdb_bt_qf)
            exec "silent! vimgrep " . cword ." ". expand("%")
        else
            "exec "silent cgetfile " . gdb._gdb_bt_qf
        endif
        silent! copen
        let gdb._win_qf = win_getid()
    endif

    if win_gotoid(g:state_ctx._wid_main) == 1
        if !filereadable(gdb._gdb_break_qf)
            exec "silent! lvimgrep " . cword ." ". expand("%")
        else
            exec "silent lgetfile " . gdb._gdb_break_qf
        endif
        silent! lopen
        let gdb._win_lqf = win_getid()
    endif

    " Create gdb terminal
    if win_gotoid(gdb._win_gdb._wid) == 1
        let gdb._server_buf = -1
        let gdb._client_buf = bufnr('%')
        call gdb#Map("tmap")
    endif

    if win_gotoid(g:state_ctx._wid_main) == 1
        stopinsert
        let g:gdb = gdb
    endif
endfunction


" @mode 0 refresh-all, 1 only-change
function! gdb#RefreshBreakpointSigns(mode)
    "{
    if a:mode == 0
        let i = s:breakpoint_signid_start
        while i <= s:breakpoint_signid_max
            exe 'sign unplace '.i
            let i += 1
        endwhile
    endif

    let s:breakpoint_signid_max = 0
    let id = s:breakpoint_signid_start
    for [next_key, next_val] in items(s:breakpoints)
        let buf = bufnr(next_val['file'])
        let linenr = next_val['line']

        if a:mode == 1 && next_val['change']
           \ && has_key(next_val, 'sign_id')
            exe 'sign unplace '. next_val['sign_id']
        endif

        if a:mode == 0 || (a:mode == 1 && next_val['change'])
            if next_val['state']
                exe 'sign place '.id.' name=GdbBreakpointEn line='.linenr.' buffer='.buf
            else
                exe 'sign place '.id.' name=GdbBreakpointDis line='.linenr.' buffer='.buf
            endif
            let next_val['sign_id'] = id
            let s:breakpoint_signid_max = id
            let id += 1
        endif
    endfor
    "}
endfunction


" Firstly delete all breakpoints for Gdb delete breakpoints only by ref-no
" Then add breakpoints backto gdb
" @mode 0 reset-all, 1 enable-only-change, 2 delete-all
function! gdb#RefreshBreakpoints(mode)
    "{
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif

    let is_running = 0
    if g:gdb._win_gdb._state.name ==# "running"
        " pause first
        let is_running = 1
        call jobsend(g:gdb._client_id, "\<c-c>")
        call state#Switch('gdb', 'pause', 0)
    endif

    if a:mode == 0 || a:mode == 2
        if g:gdb._has_breakpoints
            call gdb#Send('delete')
            let g:gdb._has_breakpoints = 0
        endif
    endif

    if a:mode == 0 || a:mode == 1
        let is_silent = 1
        if a:mode == 1
            let is_silent = 0
        endif

        for [next_key, next_val] in items(s:breakpoints)
            if next_val['state'] && !empty(next_val['cmd'])
                if is_silent == 1
                    let is_silent = 2
                    call gdb#Send('silent_on')
                endif

                if a:mode == 0 || (a:mode == 1 && next_val['change'])
                    let g:gdb._has_breakpoints = 1
                    call gdb#Send('break '. next_val['cmd'])
                endif
            endif
        endfor
        if is_silent == 2
            call gdb#Send('silent_off')
        endif
    endif

    if is_running
        call gdb#Send('c')
    endif
    "}
endfunction


function! gdb#Jump(file, line)
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif
    if tabpagenr() != g:state_ctx._tab
        " Don't jump if we are not in the debugger tab
        return
    endif

    let file = a:file
    if !filereadable(file) && file[0] != '/'
        let file = '/' . file
    endif
    if !filereadable(file)
        echomsg "File not exist: " . file
    endif

    if filereadable(s:gdb_bt_qf)
        call delete(s:gdb_bt_qf)
    endif
    call gdb#Send('parser_bt')
    call gdb#SendJob("for x in {1..15}; do if [ ! -f /tmp/gdb.bt ]; then sleep 0.2; else  echo 'jobDoneLoadBacktrace'; break; fi; done")
    if filereadable(s:gdb_bt_qf)
        exec "cgetfile " . s:gdb_bt_qf
        "call utilquickfix#RelativePath()
    endif

    let cwindow = win_getid()
    if cwindow != g:state_ctx._wid_main
        if win_gotoid(g:state_ctx._wid_main) != 1
            return
        endif
    endif
    stopinsert

    let g:gdb._current_buf = bufnr('%')
    let target_buf = bufnr(a:file, 1)
    if bufnr('%') != target_buf
        exe 'buffer ' target_buf
        let g:gdb._current_buf = target_buf
    endif
    exe ':' a:line | m'

    let fname = fnamemodify(a:file, ':p:.')
    if !has_key(s:file_list, fname)
        let s:file_list[fname] = 1
        call gdb#SaveVariable(s:file_list, s:fl_file)
    endif

    "let fname = fnamemodify(a:file, ':p:.')
    "exec "e ". fname
    "exec ':' a:line | m'

    let g:gdb._current_line = a:line
    if cwindow != g:state_ctx._wid_main
        call win_gotoid(cwindow)
    endif
    call gdb#Update_current_line_sign(1)
endfunction


function! gdb#Breakpoints(file)
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif
    if filereadable(a:file)
        exec "silent lgetfile " . a:file
    endif
endfunction


function! gdb#Stack(file)
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif
    if filereadable(a:file)
        exec "silent cgetfile " . a:file
    endif
endfunction


function! gdb#Interrupt()
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif
    call jobsend(g:gdb._client_id, "\<c-c>info line\<cr>")
endfunction


function! gdb#SaveVariable(var, file)
    call writefile([string(a:var)], a:file)
endfunction

function! gdb#ReadVariable(varname, file)
    let recover = readfile(a:file)[0]
    execute "let ".a:varname." = " . recover
endfunction

function! gdb#Breaks2Qf()
    let list2 = []
    let i = 0
    for [next_key, next_val] in items(s:breakpoints)
        if !empty(next_val['cmd'])
            let i += 1
            call add(list2, printf('#%d  %d in    %s    at %s:%d',
                        \ i, next_val['state'], next_val['cmd'],
                        \ next_val['file'], next_val['line']))
        endif
    endfor

    call writefile(split(join(list2, "\n"), "\n"), s:gdb_break_qf)
    if filereadable(s:gdb_break_qf)
        exec "silent lgetfile " . s:gdb_break_qf
    endif
endfunction


function! gdb#GetCFunLinenr()
  let lnum = line(".")
  let col = col(".")
  let linenr = search("^[^ \t#/]\\{2}.*[^:]\s*$", 'bW')
  call search("\\%" . lnum . "l" . "\\%" . col . "c")
  return linenr
endfunction


" Key: file:line, <or> file:function
" Value: empty, <or> if condition
" @state 0 disable 1 enable, Toggle: none -> enable -> disable
" @type 0 line-break, 1 function-break
function! gdb#ToggleBreak()
    let filenm = bufname("%")
    let linenr = line(".")
    let colnr = col(".")
    let cword = expand("<cword>")
    let cfuncline = gdb#GetCFunLinenr()

    let type = 0
    if linenr == cfuncline
        let type = 1
        let file_breakpoints = filenm .':'.cword
    else
        let file_breakpoints = filenm .':'.linenr
    endif

    let mode = 0
    let old_value = get(s:breakpoints, file_breakpoints, {})
    if empty(old_value)
        let break_new = input("[break] ", file_breakpoints)
        if !empty(break_new)
            let old_value = {
                        \'file':filenm,
                        \'type':type,
                        \'line':linenr, 'col':colnr,
                        \'fn' : '',
                        \'state' : 1,
                        \'cmd' : break_new,
                        \'change' : 1,
                        \}
            "Decho break_new
            let mode = 1
            let s:breakpoints[file_breakpoints] = old_value
        endif
    elseif old_value['state']
        let break_new = input("[disable break] ", old_value['cmd'])
        if !empty(break_new)
            let old_value['state'] = 0
            let old_value['change'] = 1
            "Decho break_new
        endif
    else
        let break_new = input("(delete break) ", old_value['cmd'])
        if !empty(break_new)
            call remove(s:breakpoints, file_breakpoints)
            "Decho break_new
        endif
        let old_value = {}
    endif
    call gdb#SaveVariable(s:breakpoints, s:brk_file)
    call gdb#Breaks2Qf()
    call gdb#RefreshBreakpointSigns(mode)
    call gdb#RefreshBreakpoints(mode)
    if !empty(old_value)
        let old_value['change'] = 0
    endif
endfunction


function! gdb#ToggleBreakAll()
    let s:toggle_all = ! s:toggle_all
    let mode = 0
    for v in values(s:breakpoints)
        if s:toggle_all
            let v['state'] = 0
        else
            let v['state'] = 1
        endif
    endfor
    call gdb#RefreshBreakpointSigns(0)
    call gdb#RefreshBreakpoints(0)
endfunction


function! gdb#TBreak()
    let file_breakpoints = bufname('%') .':'. line('.')
    call gdb#Send("tbreak ". file_breakpoints. "\nc")
endfunction


function! gdb#ClearBreak()
    let s:breakpoints = {}
    call gdb#RefreshBreakpointSigns(0)
    call gdb#RefreshBreakpoints(2)
endfunction


function! gdb#GetExpression(...) range
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]
    let lines = getline(lnum1, lnum2)
    let lines[-1] = lines[-1][:col2 - 1]
    let lines[0] = lines[0][col1 - 1:]
    return join(lines, "\n")
endfunction


function! gdb#Eval(expr)
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif

    if g:gdb._win_gdb._state.name !=# "pause"
        throw 'Gdb eval only under "pause" but state="'
                \. g:gdb._win_gdb._state.name .'"'
    endif

    "call gdb#Send(printf('print %s', a:expr))
    " Enable smart-eval base-on the special project
    let s:expr = a:expr
    call gdb#Send(printf('whatis %s', a:expr))
endfunction


" Enable smart-eval base-on the special project
function! gdb#Whatis(type)
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif
    if g:gdb._win_gdb._state.name !=# "pause"
        throw 'Gdb eval only under "pause" state'
    endif
    if empty(s:expr)
        throw 'Gdb eval expr is empty'
    endif

    if !empty(g:gdb.Symbol)
        silent! call s:log.trace("forward to getsymbol")
        let expr = g:gdb.Symbol(a:type, s:expr)
        call gdb#Send(expr)
    else
        call gdb#Send(printf('p %s', s:expr))
    endif
    let s:expr = ""
endfunction


function! gdb#Watch(expr)
    let expr = a:expr
    if expr[0] != '&'
        let expr = '&' . expr
    endif

    call gdb#Eval(expr)
    call gdb#Send('watch *$')
endfunction


function! gdb#Map(type)
    "{
    if a:type ==# "unmap"
        unmap <f3>
        unmap <f4>
        unmap <f5>
        unmap <f6>
        unmap <f7>
        unmap <f8>
        unmap <f9>
        unmap <f10>
        vunmap <f9>
        cunmap <f9>
        unmap <c-n>
        unmap <c-p>
        tunmap <f3>
        tunmap <f4>
        tunmap <f5>
        tunmap <f6>
        tunmap <f7>
        tunmap <f10>
    elseif a:type ==# "tmap"
        tnoremap <silent> <f3> <c-\><c-n>:GdbRefresh<cr>i
        tnoremap <silent> <f4> <c-\><c-n>:GdbContinue<cr>i
        tnoremap <silent> <f5> <c-\><c-n>:GdbNext<cr>i
        tnoremap <silent> <f6> <c-\><c-n>:GdbStep<cr>i
        tnoremap <silent> <f7> <c-\><c-n>:GdbFinish<cr>i
        tnoremap <silent> <f10> <c-\><c-n>:GdbToggleBreakAll<cr>i
    elseif a:type ==# "nmap"
        nnoremap <silent> <f3> :GdbRefresh<cr>
        nnoremap <silent> <f4> :GdbContinue<cr>
        nnoremap <silent> <f5> :GdbNext<cr>
        nnoremap <silent> <f6> :GdbStep<cr>
        nnoremap <silent> <f7> :GdbFinish<cr>
        nnoremap <silent> <f8> :GdbUntil<cr>
        nnoremap <silent> <f9> :GdbToggleBreak<cr>
        nnoremap <silent> <f10> :GdbToggleBreakAll<cr>
        cnoremap <silent> <f9> <cr>
        vnoremap <silent> <f9> :GdbEvalRange<cr>
        nnoremap <silent> <c-n> :GdbFrameUp<cr>
        nnoremap <silent> <c-p> :GdbFrameDown<cr>
    endif
    "}
endfunction
