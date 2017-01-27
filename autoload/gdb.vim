function! s:__init__()
    "{
    if exists("s:init")
        return
    endif

    sign define GdbBreakpointEn text=● texthl=Search
    sign define GdbBreakpointDis text=● texthl=Function
    "sign define GdbBreakpointDis text=● texthl=Identifier

    sign define GdbCurrentLine text=☛ texthl=Error
    "sign define GdbCurrentLine text=☛ texthl=Keyword
    "sign define GdbCurrentLine text=⇒ texthl=String

    set errorformat+=#0\ \ %m\ \(%.%#\)\ at\ %f:%l
    set errorformat+=#%.%#\ \ %.%#\ in\ %m\ \(%.%#\)\ at\ %f:%l
    set errorformat+=#%.%#\ \ %.%#\ in\ \ \ \ %m\ \ \ \ at\ %f:%l

    let s:gdb_port = 7778
    let s:max_breakpoint_sign_id = 0
    let s:breakpoints = {}
    let s:toggle_all = 0
    let s:gdb_bt_qf = '/tmp/gdb.bt'
    let s:gdb_break_qf = '/tmp/gdb.break'
    let s:gdb_source_break = './.gdb.break'
    "}
endfunction
call s:__init__()





function! gdb#SchemeCreate() abort
    " special scheme for some kinds of app
    " @action call, state, send,
    return {
        \ "name" : "SchemeGDB",
        \ "window" : [
        \   {   "name":   "gdb",
        \       "state":  "pause",
        \       "layout": ["conf_gdb_layout", "sp"],
        \       "cmd":    ["conf_gdb_cmd", "$SHELL"],
        \   },
        \   {   "name":   "gdbserver",
        \       "state":  "gdbserver",
        \       "layout": ["conf_server_layout", "sp"],
        \       "cmd":    ["conf_server_cmd", "$SHELL"],
        \       "addr":   ["conf_server_addr", "localhost"],
        \   },
        \ ],
        \ "state" : {
        \   "pause": [
        \       {   "match":   "Continuing.",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":  "on_continue",
        \       },
        \       {   "match":   "\v[\o32]{2}([^:]+):(\d+):\d+",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":  "on_jump",
        \       },
        \       {   "match":   "Remote communication error.  Target disconnected.:",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":  "on_retry",
        \       },
        \   ],
        \   "running": [
        \       {   "match":   "\v^Breakpoint \d+",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":  "on_pause",
        \       },
        \       {   "match":   "\v^Temporary breakpoint \d+",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":  "on_pause",
        \       },
        \       {   "match":   "\v\[Inferior\ +.{-}\ +exited\ +normally",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":  "on_disconnected",
        \       },
        \       {   "match":   "(gdb)",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":  "on_pause",
        \       },
        \   ],
        \   "gdbserver": [
        \       {   "match":   "\vListening on port (\d+)$",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":  "on_listen",
        \       },
        \       {   "match":   "\vDetaching from process \d+",
        \           "window":  "",
        \           "action":  "call",
        \           "arg0":  "on_exit",
        \       },
        \   ],
        \ }
        \}
endfunc



function! gdb#SchemeConfigSample() abort
    " user special config
    return {
        \ "scheme" : "gdb#SchemeCreate",
        \ "conf_gdb_cmd" : "gdb -q -f sysinit/init",
        \ "conf_server_cmd" : "$SHELL",
        \ "conf_server_addr" : "10.1.1.125",
        \ "state" : {
        \   "gdbserver": [
        \       ['\vListening on port (\d+)$', 'on_accept'],
        \       ['\vDetaching from process \d+', 'on_exit'],
        \   ],
        \ }
        \ }
endfunc




function! gdb#gdbserver_new(gdb) abort
    "{
    let this = {}
    let this._gdb = a:gdb


    function this.on_exit()
        let self._gdb._server_exited = 1
    endfunction

    return this
    "}
endfunction


function! gdb#gdb_new() abort
    "{
    let this = {}
    let this.state = "null"

    function! this.kill()
        call gdb#Map("unmap")
        call self.update_current_line_sign(0)
        exe 'bd! '.self._client_buf
        if self._server_buf != -1
            exe 'bd! '.self._server_buf
        endif
        exe 'tabnext '.self._tab
        tabclose
        unlet g:gdb
    endfunction


    function! this.send(data)
        call jobsend(self._client_id, a:data."\<cr>")
    endfunction


    function! this.attach()
        if !empty(self._server_addr)
            call self.send(printf('target remote %s', self._server_addr))
        endif
    endfunction


    function this.retry()
        if self._server_exited
            return
        endif
        sleep 1
        call self.attach()
        call self.send('continue')
    endfunction


    function this.on_jump(file, line)
        if tabpagenr() != self._tab
            " Don't jump if we are not in the debugger tab
            return
        endif

        let cwindow = win_getid()
        if cwindow != self._win_main
            if win_gotoid(self._win_main) != 1
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
        exe ':' a:line
        "normal 
        let self._current_line = a:line

        if cwindow != self._win_main
            call win_gotoid(cwindow)
        endif
        call self.update_current_line_sign(1)
    endfunction

    function this.on_pause()
        if !self._initialized
            "set python print-stack full
            "set filename-display absolute
            let cmdstr_bt = "set confirm off\n
                        \ set pagination off\n
                        \ set verbose off\n
                        \ set print pretty on\n
                        \ set print array off\n
                        \ print array-indexes on\n
                        \"
            call g:gdb.send(cmdstr_bt)

            let cmdstr_bt = "define parser_bt\n
                        \ set logging off\n
                        \ set logging file /tmp/gdb.bt\n
                        \ set logging overwrite on\n
                        \ set logging redirect on\n
                        \ set logging on\n
                        \ bt\n
                        \ set logging off\n
                        \ end"
            call g:gdb.send(cmdstr_bt)

            let cmdstr_bt = "define silent_on\n
                        \ set logging off\n
                        \ set logging file /dev/null\n
                        \ set logging overwrite off\n
                        \ set logging redirect on\n
                        \ set logging on\n
                        \ end"
            call g:gdb.send(cmdstr_bt)

            let cmdstr_bt = "define silent_off\n
                        \ set logging off\n
                        \ end"
            call g:gdb.send(cmdstr_bt)

            if filereadable(s:gdb_source_break)
                call gdb#ReadVariable("s:breakpoints", s:gdb_source_break)
            endif

            "if !empty(self._server_addr)
            "    call self.send('set remotetimeout 50')
            "    call self.attach()
            "    call s:RefreshBreakpoints()
            "    call self.send('c')
            "endif

            let self._initialized = 1
            if !empty(s:breakpoints)
                call gdb#Breaks2Qf()
                call gdb#RefreshBreakpointSigns()
                call gdb#RefreshBreakpoints()
            endif

            if g:gdb._mode == 1
                call self.send('br main')
                call self.send('r')
            endif
        endif
    endfunction


    function this.on_disconnected()
        if !self._server_exited && self._reconnect
            " Refresh to force a delete of all watchpoints
            call s:RefreshBreakpoints()
            sleep 1
            call self.attach()
            call self.send('continue')
        endif
    endfunction


    function! this.update_current_line_sign(add)
        " to avoid flicker when removing/adding the sign column(due to the change in
        " line width), we switch ids for the line sign and only remove the old line
        " sign after marking the new one
        let old_line_sign_id = get(self, '_line_sign_id', 4999)
        let self._line_sign_id = old_line_sign_id == 4999 ? 4998 : 4999
        if a:add && self._current_line != -1 && self._current_buf != -1
            exe 'sign place '.self._line_sign_id.' name=GdbCurrentLine line='
                        \.self._current_line.' buffer='.self._current_buf
        endif
        exe 'sign unplace '.old_line_sign_id
    endfunction

    return this
    "}
endfunction


function! gdb#spawn(server_cmd, client_cmd, server_addr, reconnect, mode)
    "{
    if exists('g:gdb')
        throw 'Gdb already running'
    endif
    let gdb = {}
    " gdbserver port
    let gdb._mode = a:mode
    let gdb._server_addr = a:server_addr
    let gdb._reconnect = a:reconnect
    let gdb._initialized = 0
    " window number that will be displaying the current file
    let gdb._jump_window = 1
    let gdb._current_buf = -1
    let gdb._current_line = -1
    let gdb._has_breakpoints = 0
    let gdb._server_exited = 0
    let gdb._gdb_bt_qf = s:gdb_bt_qf
    let gdb._gdb_break_qf = s:gdb_break_qf
    let gdb._gdb_source_break = s:gdb_source_break

    return gdb
    "}
endfunction


function! gdb#RefreshBreakpointSigns()
    "{
    let i = 5000
    while i <= s:max_breakpoint_sign_id
        exe 'sign unplace '.i
        let i += 1
    endwhile

    let s:max_breakpoint_sign_id = 0
    let id = 5000
    for [next_key, next_val] in items(s:breakpoints)
        let buf = bufnr(next_val['file'])
        let linenr = next_val['line']
        if next_val['state']
            exe 'sign place '.id.' name=GdbBreakpointEn line='.linenr.' buffer='.buf
        else
            exe 'sign place '.id.' name=GdbBreakpointDis line='.linenr.' buffer='.buf
        endif
        let s:max_breakpoint_sign_id = id
        let id += 1
    endfor
    "}
endfunction


" Firstly delete all breakpoints for Gdb delete breakpoints only by ref-no
" Then add breakpoints backto gdb
function! gdb#RefreshBreakpoints()
    "{
    if !exists('g:gdb')
        return
    endif
    if g:gdb.state ==# "running"
        " pause first
        call jobsend(g:gdb._client_id, "\<c-c>")
    endif

    if g:gdb._has_breakpoints
        call g:gdb.send('delete')
    endif

    let g:gdb._has_breakpoints = 0
    for [next_key, next_val] in items(s:breakpoints)
        if next_val['state'] && !empty(next_val['cmd'])
            if ! g:gdb._has_breakpoints
                let g:gdb._has_breakpoints = 1
                call g:gdb.send('silent_on')
            endif
            call g:gdb.send('break '.next_val['cmd'])
        endif
    endfor
    if g:gdb._has_breakpoints
        call g:gdb.send('silent_off')
    endif
    "}
endfunction


function! gdb#Send(data)
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif
    call g:gdb.send(a:data)
endfunction


function! gdb#Jump(file, line)
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif
    call g:gdb.send('parser_bt')
    if filereadable(s:gdb_bt_qf)
        exec "cgetfile " . s:gdb_bt_qf
    endif
    call g:gdb.on_jump(a:file, a:line)
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


function! gdb#OnContinue()
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif
    echo "gdb#OnContinue"
endfunction


function! gdb#OnExit()
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif
    echo "gdb#OnExit"
endfunction


function! gdb#Interrupt()
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif
    call jobsend(g:gdb._client_id, "\<c-c>info line\<cr>")
endfunction


function! gdb#Kill()
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif
    call g:gdb.kill()
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

    Decho "FunctionLinenr=" . cfuncline
    let type = 0
    if linenr == cfuncline
        let type = 1
        let file_breakpoints = filenm .':'.cword
    else
        let file_breakpoints = filenm .':'.linenr
    endif

    let old_value = get(s:breakpoints, file_breakpoints, {})
    if empty(old_value)
        let break_new = input("[break] ", file_breakpoints)
        if !empty(break_new)
            let s:breakpoints[file_breakpoints] = {'file':filenm,
                        \'type':type, 'line':linenr, 'col':colnr,
                        \'fn' : '', 'state':1, 'cmd' : break_new}
            Decho break_new
        endif
    elseif old_value['state']
        let break_new = input("[disable break] ", file_breakpoints)
        if !empty(break_new)
            let old_value['state'] = 0
            Decho break_new
        endif
    else
        let break_new = input("(delete break) ", file_breakpoints)
        if !empty(break_new)
            call remove(s:breakpoints, file_breakpoints)
            Decho break_new
        endif
    endif
    call gdb#SaveVariable(s:breakpoints, s:gdb_source_break)
    call gdb#Breaks2Qf()
    call gdb#RefreshBreakpointSigns()
    call gdb#RefreshBreakpoints()
endfunction


function! gdb#ToggleBreakAll()
    let s:toggle_all = ! s:toggle_all
    for v in values(s:breakpoints)
        if s:toggle_all
            let v['state'] = 0
        else
            let v['state'] = 1
        endif
    endfor
    call gdb#RefreshBreakpointSigns()
    call gdb#RefreshBreakpoints()
endfunction


function! gdb#TBreak()
    let file_breakpoints = bufname('%') .':'. line('.')
    call g:gdb.send("tbreak ". file_breakpoints. "\nc")
endfunction


function! gdb#ClearBreak()
    let s:breakpoints = {}
    call gdb#RefreshBreakpointSigns()
    call gdb#RefreshBreakpoints()
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
    call gdb#Send(printf('print %s', a:expr))
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
        unmap <f4>
        unmap <f5>
        unmap <f6>
        unmap <f7>
        unmap <f8>
        unmap <f9>
        unmap <f10>
        vunmap <f9>
        cunmap <silent> <f9> <cr>
        tunmap <f4>
        tunmap <f5>
        tunmap <f6>
        tunmap <f7>
        tunmap <f10>
    elseif a:type ==# "tmap"
        tmap <silent> <f4> <c-\><c-n>:GdbContinue<cr>i
        tmap <silent> <f5> <c-\><c-n>:GdbNext<cr>i
        tmap <silent> <f6> <c-\><c-n>:GdbStep<cr>i
        tmap <silent> <f7> <c-\><c-n>:GdbFinish<cr>i
        tmap <silent> <f10> <c-\><c-n>:GdbToggleBreakAll<cr>i
    elseif a:type ==# "nmap"
        nmap <silent> <f4> :GdbContinue<cr>
        nmap <silent> <f5> :GdbNext<cr>
        nmap <silent> <f6> :GdbStep<cr>
        nmap <silent> <f7> :GdbFinish<cr>
        nmap <silent> <f8> :GdbUntil<cr>
        nmap <silent> <f9> :GdbToggleBreak<cr>
        nmap <silent> <f10> :GdbToggleBreakAll<cr>
        cnoremap <silent> <f9> <cr>
        vnoremap <silent> <f9> :GdbEvalRange<cr>
        nmap <silent> <C-Up>   :GdbFrameUp<CR>
        nmap <silent> <C-Down> :GdbFrameDown<CR>
    endif
    "}
endfunction


function! s:__fini__()
    "{
    if exists("s:init")
        return
    endif
    call gdb#Map("nmap")
    "}
endfunction
call s:__fini__()
let s:init = 1

