" Gdb log:
"show logging            Show the current values of the logging settings.
"set logging on          Enable logging.
"set logging off         Disable logging.
"set logging file file   Change the name of the current logfile. The default logfile is gdb.txt.
"set logging overwrite [on|off]  By default, gdb will append to the logfile. Set overwrite if you want set logging on to overwrite the logfile instead.
"set logging redirect [on|off]   By default, gdb output will go to both the terminal and the logfile. Set redirect if you want output to go only to the log file.

function! s:__init__()
    "{
    if exists("s:init")
        return
    endif

    sign define GdbBreakpointEn text=● texthl=Number
    sign define GdbBreakpointDis text=● texthl=Function
    "sign define GdbBreakpointDis text=● texthl=Identifier

    sign define GdbCurrentLine text=☛ texthl=Error
    "sign define GdbCurrentLine text=☛ texthl=Keyword
    "sign define GdbCurrentLine text=⇒ texthl=String

    set errorformat+=#0\ \ %m\ \(%.%#\)\ at\ %f:%l
    set errorformat+=#%.%#\ in\ %m\ \(%.%#\)\ at\ %f:%l

    let s:gdb_port = 7778
    let s:max_breakpoint_sign_id = 0
    let s:breakpoints = {}
    let s:gdb_file_bt = '/tmp/gdb.bt'
    "}
endfunction
call s:__init__()

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
        let window = winnr()
        exe self._jump_window 'wincmd w'
        let self._current_buf = bufnr('%')
        let target_buf = bufnr(a:file, 1)
        if bufnr('%') != target_buf
            exe 'buffer ' target_buf
            let self._current_buf = target_buf
        endif
        exe ':' a:line
        let self._current_line = a:line
        exe window 'wincmd w'
        call self.update_current_line_sign(1)
    endfunction

    function this.on_pause()
        if !self._initialized
            call self.send('set confirm off')
            call self.send('set pagination off')

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

            if !empty(self._server_addr)
                call self.send('set remotetimeout 50')
                call self.attach()
                call s:RefreshBreakpoints()
                call self.send('c')
            endif
            if g:gdb._mode == 1
                call self.send('br main')
                call self.send('r')
            endif
            let self._initialized = 1
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
        let file = next_val['file']
        let linenr = next_val['line']
        if next_val['state']
            let g:gdb._has_breakpoints = 1
            call g:gdb.send('break '.file.':'.linenr)
        endif
    endfor
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
    exec "cfile " . s:gdb_file_bt
    call g:gdb.on_jump(a:file, a:line)
endfunction


function! gdb#Breakpoints(file)
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif
    if filereadable(a:file)
        exec "lgetfile " . a:file
    endif
endfunction


function! gdb#Stack(file)
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif
    if filereadable(a:file)
        exec "cgetfile " . a:file
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


function! gdb#Map(type)
    "{
    if a:type ==# "unmap"
        unmap <f4>
        unmap <f5>
        unmap <f6>
        unmap <f7>
        unmap <f8>
        tunmap <f4>
        tunmap <f5>
        tunmap <f6>
        tunmap <f7>
    elseif a:type ==# "tmap"
        tmap <silent> <f4> <c-\><c-n>:GdbContinue<cr>i
        tmap <silent> <f5> <c-\><c-n>:GdbNext<cr>i
        tmap <silent> <f6> <c-\><c-n>:GdbStep<cr>i
        tmap <silent> <f7> <c-\><c-n>:GdbFinish<cr>i
    elseif a:type ==# "nmap"
        nmap <silent> <f4> :GdbContinue<cr>
        nmap <silent> <f5> :GdbNext<cr>
        nmap <silent> <f6> :GdbStep<cr>
        nmap <silent> <f7> :GdbFinish<cr>
        nmap <silent> <f8> :GdbUntil<cr>
        nmap <silent> <C-Up>   :GdbFrameUp<CR>
        nmap <silent> <C-Down> :GdbFrameDown<CR>
    endif
    "}
endfunction


" Key: file:line, <or> file:function
" Value: empty, <or> if condition
" @state 0 disable 1 enable, Toggle: none -> enable -> disable
function! gdb#ToggleBreak()
    let filenm = bufname('%')
    let linenr = line('.')
    let file_breakpoints = filenm .':'.linenr
    let old_value = get(s:breakpoints, file_breakpoints, {})
    if empty(old_value)
        let s:breakpoints[file_breakpoints] = {'file':filenm,
                    \'type':0, 'line':linenr, 'fn' : '',
                    \'state':1, 'cond' : ''}
    elseif old_value['state']
        let old_value['state'] = 0
    else
        call remove(s:breakpoints, file_breakpoints)
    endif
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


function! s:__fini__()
    "{
    if exists("s:init")
        return
    endif
    "}
endfunction
call s:__fini__()
let s:init = 1

