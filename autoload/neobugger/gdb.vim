if !exists("s:script")
    let s:script = expand('<sfile>:t')
    silent! let s:log = logger#getLogger(s:script)

    sign define GdbCurrentLine text=☛ texthl=Error
    "sign define GdbCurrentLine text=☛ texthl=Keyword
    "sign define GdbCurrentLine text=⇒ texthl=String

    set errorformat+=#%c\ \ %.%#\ in\ %m\ \(%.%#\)\ at\ %f:%l
    set errorformat+=#%c\ \ %.%#\ in\ \ \ \ %m\ \ \ \ at\ %f:%l
    set errorformat+=#%c\ \ %m\ \(%.%#\)\ at\ %f:%l

    let s:gdb_port = 7778
    let s:breakpoint_signid_start = 5000
    let s:breakpoint_signid_max = 0

    let s:toggle_all = 0
    let s:qf_gdb_frame = '/tmp/gdb.frame'
    let s:qf_gdb_break = '/tmp/gdb.break'

    let s:currFrame = ""
    let s:module = 'gdb'
    let s:prototype = tlib#Object#New({
                \ '_class': [s:module],
                \ })
endif


" Constructor
" @param conf='local|pid|server'
"        type 'local', 'bin-exe', {'args': [list]}
"        type 'pid', 'bin-exe', {'pid': 3245}
"        type 'server', 'bin-exe', {'args': [list]}
function! neobugger#gdb#New(conf, binaryFile, args)
    "{
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')
    if neobugger#Exists(s:module)
        throw 'neobugger['.s:module.' already running!'
    endif

    if !filereadable(a:binaryFile)
        throw l:__func__. " error: no program '". a:binaryFile ."'."
    endif

    let server_addr = (a:0 >= 2) ? a:2 : ''

    let l:f_conf = 'neobugger#gdb#'.a:conf.'#Conf'
    let Conf = function(l:f_conf)
    if empty(Conf)
        throw l:__func__. " error: no Conf '". a:conf ."' from ".l:f_conf
    endif
    let conf = Conf()
    if type(conf) != type({})
        throw l:__func__. " error: Conf '". a:conf ."' should return a dict not ". type(conf). "."
    endif

    let l:parent = s:prototype.New(a:0 >= 1 ? a:1 : {})
    let l:abstract = neobugger#Debugger#New()
    call l:parent.Inherit(l:abstract)

    if has_key(conf, 'Inherit')
        let l:ChildNew = function(conf.Inherit)
        let l:child = l:ChildNew()
        call l:child.Inherit(l:parent)
        let gdb = l:child
    else
        let gdb = l:parent
    endif

    let gdb.module = s:module
    let gdb._initialized = 0
    let gdb._mode = a:conf
    let gdb._binaryFile = a:binaryFile
    let gdb.args = a:args
    silent! call s:log.info(l:__func__, ": args=", string(a:args))

    let gdb._autorun = 0
    if has_key(conf, 'autorun')
        let gdb._autorun = conf.autorun
    endif

    let gdb._reconnect = 0
    if has_key(conf, 'reconnect')
        let gdb._reconnect = conf.reconnect
    endif

    let gdb._showbreakpoint = 0
    if exists('g:neogdb_window')
        if index(g:neogdb_window, 'breakpoint') >= 0
            let gdb._showbreakpoint = 1
        endif
    else
        if has_key(conf, 'showbreakpoint')
            let gdb._showbreakpoint = conf.showbreakpoint
        endif
    endif

    let gdb._showbacktrace = 0
    if exists('g:neogdb_window')
        if index(g:neogdb_window, 'backtrace') >= 0
            let gdb._showbacktrace = 1
        endif
    else
        if has_key(conf, 'showbacktrace')
            let gdb._showbacktrace = conf.showbacktrace
        endif
    endif

    if len(conf.conf_gdb_cmd) >= 2
        if !empty(a:binaryFile)
            let conf.conf_gdb_cmd[1] = a:binaryFile
        endif
    endif

    let gdb._server_addr = []
    let gdb._attach_pid = "NoAttachedPid"
    if a:conf == "pid"
        if !get(a:args,'pid')
            throw l:__func__. " error: attach pid, but no pid."
        endif
        "let conf.conf_gdb_cmd[1] = a:args.pid
        let gdb._attach_pid = a:args.pid
    elseif a:conf == "server"
        if !has_key(a:args,'args') "Attach to gdbserver
            throw l:__func__. " error: attach pid, but no gdbserver."
        endif
        "call l:debugger.writeLine('target remote '.a:args.con)
        " 10.1.1.125:444 -> ["10.1.1.125", "444"]
        let gdb._server_addr = split(a:args.args[0], ":")
    endif

    " Load all files from backtrace to solve relative-path
    silent! call s:log.trace("Load open files ...")

    "if gdb._showbacktrace && filereadable(s:qf_gdb_frame)
    "    exec "cgetfile " . s:qf_gdb_frame
    "    let list = getqflist()
    "    for i in range(len(list))
    "        if has_key(list[i], 'bufnr')
    "            let list[i].filename = fnamemodify(bufname(list[i].bufnr), ':p:.')
    "            unlet list[i].bufnr
    "        else
    "            let list[i].filename = fnamemodify(list[i].filename, ':p:.')
    "        endif
    "        if filereadable(list[i].filename)
    "            exec "e ". list[i].filename
    "        endif
    "    endfor
    "    "silent! call s:log.trace("old backtrace:<cr>", list)
    "endif

    " window number that will be displaying the current file
    let gdb._jump_window = 1
    let gdb._current_buf = -1
    let gdb._current_line = -1
    let gdb._has_breakpoints = 0
    let gdb._server_exited = 0
    let gdb._gdb_bt_qf = s:qf_gdb_frame
    let gdb._gdb_break_qf = s:qf_gdb_break
    let cword = expand("<cword>")

    call nelib#state#Open(conf)
    if !exists('g:state_ctx')
        silent! call s:log.trace("  nelib#state#Open() fail: 'g:state_ctx' not exist.")
        return
    endif
    if !has_key(g:state_ctx, 'window')
        silent! call s:log.trace("  nelib#state#Open() fail: the dict[window] not exist.")
        return
    endif
    " MustExist: Gdb window
    if has_key(g:state_ctx.window, 'gdb')
        let win_gdb = g:state_ctx.window['gdb']
        let gdb._win_gdb = win_gdb
        let gdb._client_id = win_gdb._client_id
    else
        silent! call s:log.trace("  nelib#state#Open() fail: the window 'gdb' not exist in dict[window].")
        return
    endif


    if has_key(g:state_ctx.window, 'gdbserver')
        let win_gdbserver = g:state_ctx.window['gdbserver']
        let gdb._win_gdbserver = win_gdbserver
        let gdb._server_id = win_gdbserver._client_id
    endif

    if has_key(g:state_ctx.window, 'job')
        let win_job = g:state_ctx.window['job']
        let gdb._win_job = win_job
        let gdb._job_id = win_job._client_id
    endif

    " Create quickfix: lgetfile, cgetfile
    if gdb._showbacktrace && win_gotoid(g:state_ctx._wid_main) == 1
        if !filereadable(gdb._gdb_bt_qf)
            exec "silent! vimgrep " . cword ." ". expand("%")
        else
            "exec "silent cgetfile " . gdb._gdb_bt_qf
        endif
        silent! copen
        let gdb._win_qf = win_getid()
    endif

    if gdb._showbreakpoint && win_gotoid(g:state_ctx._wid_main) == 1
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
        call gdb.Map("tmap")
    endif

    if win_gotoid(g:state_ctx._wid_main) == 1
        stopinsert
        call gdb.Map("nmap")
        return gdb
    else
        silent! call s:log.trace("  nelib#state#Open() fail: Cann't jump back 'main' window.")
    endif
    "}
endfunction


function! s:prototype.Kill() dict
    call self.Map("unmap")
    call self.Update_current_line_sign(0)
    exe 'bd! '. self._client_buf
    if self._server_buf != -1
        exe 'bd! '. self._server_buf
    endif
    exe 'tabnext '. self._tab
    tabclose
    neobugger#Remove(self.module)
endfunction


function! s:prototype.Send(data) dict
    let l:__func__ = "gdb.Send"
    silent! call s:log.trace(l:__func__. "[". string(self._client_id). " at ". self._win_gdb._state.name. "] args=". string(a:data))

    if self._win_gdb._state.name ==# "pause"
                \ || self._win_gdb._state.name ==# "init"
                \ || self._win_gdb._state.name ==# "parsevar"
        call jobsend(self._client_id, a:data."\<cr>")
    else
        silent! call s:log.error(l:__func__, ": Cann't send data when state='". self._win_gdb._state.name. "'")
    endif
endfunction


function! s:prototype._Send(data) dict
    let l:__func__ = "gdb._Send"
    silent! call s:log.trace(l:__func__. "() args=". string(a:data))
    call jobsend(self._client_id, a:data)
endfunction



function! s:prototype.SendSvr(data) dict
    let l:__func__ = "gdb.SendSvr"
    silent! call s:log.trace(l:__func__. "() args=". string(a:data))

    if has_key(self, "_server_id")
        call jobsend(self._server_id, a:data."\<cr>")
    endif
endfunction


function! s:prototype.SendJob(data) dict
    if has_key(self, "_job_id")
        call jobsend(self._job_id, a:data."\<cr>")
    endif
endfunction


function! s:prototype.Attach() dict
    if !empty(self._server_addr)
        call self.Send(printf('target remote %s',
                    \join(self._server_addr, ":")))
        call state#Switch('gdb', 'remoteconn', 0)
    endif
endfunction


function! s:prototype.Update_current_line_sign(add) dict
    " to avoid flicker when removing/adding the sign column(due to the change in
    " line width), we switch ids for the line sign and only remove the old line
    " sign after marking the new one
    let old_line_sign_id = get(self, '_line_sign_id', 4999)
    let self._line_sign_id = old_line_sign_id == 4999 ? 4998 : 4999
    if a:add && self._current_line != -1 && self._current_buf != -1
        exe 'sign place '. self._line_sign_id. ' name=GdbCurrentLine line='
                    \. self._current_line. ' buffer='. self._current_buf
    endif
    exe 'sign unplace '.old_line_sign_id
endfunction


function! s:prototype.Jump(file, line) dict
    if !neobugger#Exists(s:module)
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
        silent! call s:log.error("Jump File not exist: " . file)
    endif


    " Method-1: Using ansync job to parse response
    "if filereadable(s:qf_gdb_frame)
    "    call delete(s:qf_gdb_frame)
    "endif
    "call self.Send('parser_bt')
    "call self.SendJob("for x in {1..15}; do if [ ! -f /tmp/gdb.frame ]; then sleep 0.2; else  echo 'jobDoneLoadBacktrace'; break; fi; done")

    "" Method-2: Using syncronize to parse response
    if self._showbacktrace && filereadable(s:qf_gdb_frame)
        exec "cgetfile " . s:qf_gdb_frame
        call delete(s:qf_gdb_frame)
    endif


    let cwindow = win_getid()
    if cwindow != g:state_ctx._wid_main
        if win_gotoid(g:state_ctx._wid_main) != 1
            return
        endif
    endif
    stopinsert

    let self._current_buf = bufnr('%')
    let target_buf = bufnr(a:file, 1)
    if bufnr('%') != target_buf
        exe 'buffer ' target_buf
        let self._current_buf = target_buf
    endif
    exe ':' a:line | m'

    let self._current_line = a:line
    if cwindow != g:state_ctx._wid_main
        call win_gotoid(cwindow)
    endif
    call self.Update_current_line_sign(1)
endfunction


function! s:prototype.Breakpoints(file) dict
    if !neobugger#Exists(s:module)
        throw 'Gdb is not running'
    endif
    if self._showbreakpoint && filereadable(a:file)
        exec "silent lgetfile " . a:file
    endif
endfunction


function! s:prototype.Stack(file) dict
    if !neobugger#Exists(s:module)
        throw 'Gdb is not running'
    endif
    if self._showbacktrace && filereadable(a:file)
        exec "silent cgetfile " . a:file
    endif
endfunction


function! s:prototype.Interrupt() dict
    if !neobugger#Exists(s:module)
        throw 'Gdb is not running'
    endif
    call jobsend(self._client_id, "\<c-c>info line\<cr>")
endfunction


function! neobugger#gdb#GetCFunLinenr()
  let lnum = line(".")
  let col = col(".")
  let linenr = search("^[^ \t#/]\\{2}.*[^:]\s*$", 'bW')
  call search("\\%" . lnum . "l" . "\\%" . col . "c")
  return linenr
endfunction


function! neobugger#gdb#curr_info()
    let filenm = bufname("%")
    let linenr = line(".")
    let colnr = col(".")
    let cword = expand("<cword>")
    let cfuncline = neobugger#gdb#GetCFunLinenr()

    let fname = fnamemodify(filenm, ':p:.')
    let type = 0
    if linenr == cfuncline
        let type = 1
        let file_breakpoints = fname .':'.cword
    else
        let file_breakpoints = fname .':'.linenr
    endif
    return file_breakpoints
endfunction


function! s:prototype.TBreak() dict
    let file_breakpoints = bufname('%') .':'. line('.')
    call self.Send("tbreak ". file_breakpoints. "\nc")
endfunction


function! s:prototype.FrameUp() dict
    call self.Send("up")
endfunction

function! s:prototype.FrameDown() dict
    call self.Send("down")
endfunction

function! s:prototype.Next() dict
    call self.Send("n")
    if self._mode == "pid"
        call self.Send("where")
    endif
endfunction

function! s:prototype.Step() dict
    call self.Send("s")
endfunction

function! s:prototype.Eval(expr) dict
    if !neobugger#Exists(s:module)
        throw 'Gdb is not running'
    endif

    if self._win_gdb._state.name !=# "pause"
        throw 'Gdb eval only under "pause" but state="'
                \. self._win_gdb._state.name .'"'
    endif

    "call self.Send(printf('print %s', a:expr))
    " Enable smart-eval base-on the special project
    let s:expr = a:expr
    call self.Send(printf('whatis %s', a:expr))
endfunction


" Enable smart-eval base-on the special project
function! s:prototype.Whatis(type) dict
    if !neobugger#Exists(s:module)
        throw 'Gdb is not running'
    endif
    if self._win_gdb._state.name !=# "pause"
        throw 'Gdb eval only under "pause" state'
    endif
    if empty(s:expr)
        throw 'Gdb eval expr is empty'
    endif

    if has_key(self, 'Symbol')
        silent! call s:log.trace("forward to getsymbol")
        let expr = self.Symbol(a:type, s:expr)
        call self.Send(expr)
    else
        call self.Send(printf('p %s', s:expr))
    endif
    let s:expr = ""
endfunction


function! s:prototype.Watch(expr) dict
    let expr = a:expr
    if expr[0] != '&'
        let expr = '&' . expr
    endif

    call self.Eval(expr)
    call self.Send('watch *$')
endfunction


function! s:prototype.ToggleViewGdb() dict
    if neobugger#View#IsOpen('View_gdb')
        call self.View_gdb.close()
        unlet self['View_gdb']
    else
        if !has_key(self, 'View_gdb')
            let self.View_var = neobugger#View_gdb#New(g:state_ctx._wid_main)
        endif

        call self.View_var.open()
    endif
endfunction


function! s:prototype.ToggleViewVar() dict
    if (has_key(self, 'Model_var'))
        unlet self['Model_var']
    endif

    let l:view = neobugger#View#Toggle('View_var')
    if !empty(l:view)
        let self.Model_var = neobugger#Model_var#New(l:view)

        " Get current frame
        if !has_key(self, 'Model_frame')
            if has_key(self, 'View_frame')
                let self.Model_frame = neobugger#Model_frame#New(self.View_frame)
            else
                let self.Model_frame = neobugger#Model_frame#New()
            endif
        endif

        " Trigger parse
        call self.on_parseend()
    endif
endfunction


function! s:prototype.ToggleViewFrame() dict
    let l:view = neobugger#View#Toggle('View_frame')
    if !empty(l:view)
        if !has_key(self, 'Model_frame')
            let self.Model_frame = neobugger#Model_frame#New(self.View_frame)
        endif

        " Trigger parse
        call self.on_parseend()
    endif
endfunction


function! s:prototype.ToggleViewBreak() dict
    if neobugger#View#IsOpen('View_break')
        call self.View_break.close()
        unlet self['View_break']
        unlet self['Model_break']
    else
        let self.View_break = neobugger#View_break#New(g:state_ctx._wid_main)
        let self.Model_break = neobugger#Model_break#New(self.View_var)
        call self.View_break.open()
    endif
endfunction


function! s:prototype.on_load_bt(...) dict
    if self._showbacktrace && filereadable(s:qf_gdb_frame)
        exec "cgetfile " . s:qf_gdb_frame
        "call utilquickfix#RelativePath()
    endif
endfunction

function! s:prototype.on_continue(...) dict
    call state#Switch('gdb', 'running', 0)
    call self.Update_current_line_sign(0)
endfunction

function! s:prototype.on_jump(file, line, ...) dict
    let l:__func__ = "gdb.on_jump"
    silent! call s:log.info(l:__func__, ' open ', a:file, ':', a:line)

    if self._win_gdb._state.name !=# "pause"
        silent! call s:log.info(gdb)
        silent! call s:log.info("State ", self._win_gdb._state.name, " => pause")
        call state#Switch('gdb', 'pause', 0)
        call self.Send('parser_var_bt')
        call self.Send('info line')
    endif
    call self.Jump(a:file, a:line)
endfunction

function! s:prototype.on_whatis(type, ...) dict
    call self.Whatis(a:type)
endfunction

function! s:prototype.on_parseend(...) dict
    let l:__func__ = "on_parseend"

    " parser frame backtrace
    if has_key(self, 'Model_frame')
        let s:currFrame = self.Model_frame.ParseFrame('/tmp/gdb.frame')
        silent! call s:log.info(l:__func__, '(): currentFrame=', s:currFrame)
    endif

    " Start parser the info local variables
    if neobugger#View#IsOpen('View_var')
        call state#Switch('gdb', 'parsevar', 1)
        let l:ret = self.Model_var.ParseVar(s:currFrame, '/tmp/gdb.var', '/tmp/gdb.cmd')
        silent! call s:log.info(l:__func__, '(): ret=', l:ret)
        if l:ret == 0
            " succ, parse-finish
            call state#Switch('gdb', 'parsevar', 2)
            call self.Model_var.ParseVarEnd('/tmp/gdb.var')
        elseif l:ret == -1
            " file-not-exist
            call state#Switch('gdb', 'parsevar', 2)
        else
            " succ & wait end
            call self.Send('neobug_redir_cmd /tmp/gdb.var_type "#neobug_tag_var_type#" source /tmp/gdb.cmd')
        endif
    endif
endfunction

function! s:prototype.on_parse_vartype(...) dict
    let l:ret = self.Model_var.ParseVarType('/tmp/gdb.var_type', '/tmp/gdb.cmd')
    if l:ret == 0
        " succ, parse-finish
        call state#Switch('gdb', 'parsevar', 2)
        call self.Model_var.ParseVarEnd('/tmp/gdb.var')
    elseif l:ret == -1
        " file-not-exist
        call state#Switch('gdb', 'parsevar', 2)
    else
        " succ & wait end
        call self.Send('neobug_redir_cmd /tmp/gdb.vars "#neobug_tag_var_data#" source /tmp/gdb.cmd')
    endif
endfunction

function! s:prototype.on_parse_varend(...) dict
    call state#Switch('gdb', 'parsevar', 2)
    call self.Model_var.ParseVarEnd('/tmp/gdb.vars')

    " Trigger Jump
    call self.Send('info line')
endfunction

function! s:prototype.on_retry(...) dict
    if self._server_exited
        return
    endif
    sleep 1
    call self.Attach()
    call self.Send('continue')
endfunction


function! s:prototype.on_init(...) dict
    let l:__func__ = "gdb.on_init"
    silent! call s:log.info(l:__func__, " args=", string(a:000))

    if self._initialized
      silent! call s:log.warn(l:__func__, "() ignore re-initial!")
      return
    endif

    let self._initialized = 1
    call state#Switch('gdb', 'init', 0)
    " set filename-display absolute
    " set remotetimeout 50
    let cmdstr = "set confirm off\n
                \ set pagination off\n
                \ set width 0\n
                \ set verbose off\n
                \ set logging off\n
                \ handle SIGUSR2 noprint nostop\n
                \ set print elements 2048\n
                \ set print pretty on\n
                \ set print array off\n
                \ set print array-indexes on\n
                \"
    call self.Send(cmdstr)

    " @param logfile, echomsg, commands
    let cmdstr = "define neobug_redir_cmd\n
                \   set logging off\n
                \   set logging file $arg0\n
                \   set logging overwrite on\n
                \   set logging redirect on\n
                \   set logging on\n
                \   if $argc == 3\n
                \       $arg2\n
                \   end\n
                \   if $argc == 4\n
                \       $arg2 $arg3\n
                \   end\n
                \   if $argc == 5\n
                \       $arg2 $arg3 $arg4\n
                \   end\n
                \   set logging off\n
                \   if $arg1 != 0\n
                \     echo $arg1\\n\n
                \   end\n
                \ end\n"
    call self.Send(cmdstr)

    " @param logfile, commands
    " if @param == 0, means NULL
    let cmdstr = "define neobug_redir\n
                \   set logging off\n
                \   set logging file $arg0\n
                \   set logging overwrite on\n
                \   set logging redirect on\n
                \   set logging on\n
                \   if $arg1 != 0\n
                \     $arg1\n
                \   end\n
                \ end\n
                \
                \ define neobug_redirend\n
                \   set logging off\n
                \   if $arg0 != 0\n
                \     echo $arg0\\n\n
                \   end\n
                \ end"
    call self.Send(cmdstr)

    let cmdstr = "define parser_bt\n
                \ set logging off\n
                \ set logging file /tmp/gdb.frame\n
                \ set logging overwrite on\n
                \ set logging redirect on\n
                \ set logging on\n
                \ bt\n
                \ set logging off\n
                \ echo #neobug_tag_parseend#\\n\n
                \ end"
    call self.Send(cmdstr)

    let cmdstr = "define parser_var_bt\n
                \ set logging off\n
                \ set logging file /tmp/gdb.frame\n
                \ set logging overwrite on\n
                \ set logging redirect on\n
                \ set logging on\n
                \ bt\n
                \ set logging off\n
                \ set logging file /tmp/gdb.var\n
                \ set logging overwrite on\n
                \ set logging redirect on\n
                \ set logging on\n
                \ info local\n
                \ set logging off\n
                \ echo #neobug_tag_parseend#\\n\n
                \ end"
    call self.Send(cmdstr)

    let cmdstr = "define silent_on\n
                \ set logging off\n
                \ set logging file /dev/null\n
                \ set logging overwrite off\n
                \ set logging redirect on\n
                \ set logging on\n
                \ end"
    call self.Send(cmdstr)

    let cmdstr = "define silent_off\n
                \ set logging off\n
                \ end"
    call self.Send(cmdstr)

    let cmdstr = "define hook-stop\n
                \ handle SIGALRM nopass\n
                \ parser_var_bt\n
                \ end\n
                \ \n
                \ define hook-run\n
                \ handle SIGALRM pass\n
                \ end\n
                \ \n
                \ define hook-continue\n
                \ handle SIGALRM pass\n
                \ \n
                \ end"
    call self.Send(cmdstr)

    silent! call s:log.info("Load breaks ...")
    let Model_break = neobugger#Model_break#New()
    call Model_break.LoadFromFile('./.gdb.break')
    call NbRuntimeSet('Model_break', Model_break)

    call self.Send('echo #neobug_tag_initend#\n')
endfunction


function! s:prototype.on_initend(...) dict
    let l:__func__ = "gdb.on_initend"
    silent! call s:log.info(l:__func__, " args=", string(a:000))

    if has_key(self, 'Init')
        silent! call s:log.info(l:__func__, " call Init()")
        "call neobugger#Handle(s:module, self.Init)
        call self.Init()
    else
        silent! call s:log.info(l:__func__, " Init() is null.")
    endif

    if self._autorun
        let l:cmdstr = ""
        if self._mode ==# 'local'
            let l:cmdstr = "br main\n
                        \ r"
            call self.Send(l:cmdstr)
        elseif self._mode ==# 'pid'
            let l:cmdstr = "attach ". self._attach_pid
            call self.Send(l:cmdstr)

            let l:cmdstr = "symbol-file ". self._binaryFile
            call self.Send(l:cmdstr)

            " hint backtrace
            call self.Send("bt")
        endif
    endif

    call state#Switch('gdb', 'pause', 0)
endfunction


function! s:prototype.on_accept(port, ...) dict
    if a:port
        let self._server_addr[1] = a:port
        call self.Attach()
    endif
endfunction


function s:prototype.on_remote_debugging(...) dict
    let self._remote_debugging = 1
endfunction


function! s:prototype.on_remoteconn_succ(...) dict
    call state#Switch('gdb', 'pause', 0)
endfunction


function! s:prototype.on_remoteconn_fail(...) dict
    silent! call s:log.error("Remote connect gdbserver fail!")
endfunction


function! s:prototype.on_pause(...) dict
    call state#Switch('gdb', 'pause', 0)
endfunction


function! s:prototype.on_disconnected(...) dict
    if !self._server_exited && self._reconnect
        " Refresh to force a delete of all watchpoints
        "call self.RefreshBreakpoints(2)
        sleep 1
        call self.Attach()
        call self.Send('continue')
    endif
endfunction

function! s:prototype.on_exit(...) dict
    let self._server_exited = 1
endfunction


function! s:prototype.Map(type) dict
    "{
    if a:type ==# "unmap"
        exe 'unmap ' . g:gdb_keymap_refresh
        exe 'unmap ' . g:gdb_keymap_continue
        exe 'unmap ' . g:gdb_keymap_next
        exe 'unmap ' . g:gdb_keymap_step
        exe 'unmap ' . g:gdb_keymap_finish
        exe 'unmap ' . g:gdb_keymap_clear_break
        exe 'unmap ' . g:gdb_keymap_debug_stop
        exe 'unmap ' . g:gdb_keymap_until
        exe 'unmap ' . g:gdb_keymap_toggle_break
        exe 'unmap ' . g:gdb_keymap_toggle_break_all
        exe 'vunmap ' . g:gdb_keymap_toggle_break
        exe 'cunmap ' . g:gdb_keymap_toggle_break
        exe 'unmap ' . g:gdb_keymap_frame_up
        exe 'unmap ' . g:gdb_keymap_frame_down
        exe 'tunmap ' . g:gdb_keymap_refresh
        exe 'tunmap ' . g:gdb_keymap_continue
        exe 'tunmap ' . g:gdb_keymap_next
        exe 'tunmap ' . g:gdb_keymap_step
        exe 'tunmap ' . g:gdb_keymap_finish
        exe 'tunmap ' . g:gdb_keymap_toggle_break_all

        if exists("*NeogdbvimUnmapCallback")
            call NeogdbvimUnmapCallback()
        endif
    elseif a:type ==# "tmap"
        exe 'tnoremap <silent> ' . g:gdb_keymap_refresh . ' <c-\><c-n>:GdbRefresh<cr>i'
        exe 'tnoremap <silent> ' . g:gdb_keymap_continue . ' <c-\><c-n>:GdbContinue<cr>i'
        exe 'tnoremap <silent> ' . g:gdb_keymap_next . ' <c-\><c-n>:GdbNext<cr>i'
        exe 'tnoremap <silent> ' . g:gdb_keymap_step . ' <c-\><c-n>:GdbStep<cr>i'
        exe 'tnoremap <silent> ' . g:gdb_keymap_finish . ' <c-\><c-n>:GdbFinish<cr>i'
        exe 'tnoremap <silent> ' . g:gdb_keymap_toggle_break_all . ' <c-\><c-n>:GdbToggleBreakAll<cr>i'
    elseif a:type ==# "nmap"
        exe 'nnoremap <silent> ' . g:gdb_keymap_refresh . ' :GdbRefresh<cr>'
        exe 'nnoremap <silent> ' . g:gdb_keymap_continue . ' :GdbContinue<cr>'
        exe 'nnoremap <silent> ' . g:gdb_keymap_next . ' :GdbNext<cr>'
        exe 'nnoremap <silent> ' . g:gdb_keymap_step . ' :GdbStep<cr>'
        exe 'nnoremap <silent> ' . g:gdb_keymap_finish . ' :GdbFinish<cr>'
        exe 'nnoremap <silent> ' . g:gdb_keymap_until . ' :GdbUntil<cr>'

        " @todo wilson: If showMenu, consider the default menu choose
        let toggle_break_binding = 'nnoremap <silent> ' . g:gdb_keymap_toggle_break . ' :GdbToggleBreak<cr>'
        if !g:gdb_require_enter_after_toggling_breakpoint
            let toggle_break_binding = toggle_break_binding . '<cr><cr>'
        endif
        exe toggle_break_binding

        exe 'nnoremap <silent> ' . g:gdb_keymap_toggle_break_all . ' :GdbToggleBreakAll<cr>'
        exe 'cnoremap <silent> ' . g:gdb_keymap_toggle_break . ' <cr>'
        exe 'vnoremap <silent> ' . g:gdb_keymap_toggle_break . ' :GdbEvalRange<cr>'
        exe 'nnoremap <silent> ' . g:gdb_keymap_clear_break . ' :GdbClearBreak<cr>'
        exe 'nnoremap <silent> ' . g:gdb_keymap_debug_stop . ' :GdbDebugStop<cr>'
        exe 'nnoremap <silent> ' . g:gdb_keymap_frame_up . ' :GdbFrameUp<cr>'
        exe 'nnoremap <silent> ' . g:gdb_keymap_frame_down . ' :GdbFrameDown<cr>'

        " View
        exe 'nnoremap <silent> ' . g:gdb_keymap_view_var . ' :GdbViewVar<cr>'
        exe 'nnoremap <silent> ' . g:gdb_keymap_view_break . ' :GdbViewBreak<cr>'
        exe 'nnoremap <silent> ' . g:gdb_keymap_view_frame . ' :GdbViewFrame<cr>'

        if exists("*NeogdbvimNmapCallback")
            call NeogdbvimNmapCallback()
        endif
    endif
    "}
endfunction


