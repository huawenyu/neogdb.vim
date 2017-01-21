function! s:__init__()
    "{
    if exists("s:init")
        return
    endif
    let s:init = 1

    sign define GdbBreakpoint text=●
    sign define GdbCurrentLine text=⇒


    let s:gdb_port = 7778
    let s:run_gdb = "gdb -q -f a.out"
    let s:max_breakpoint_sign_id = 0
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


function! gdb#gdb_pause_match_new() abort
    "{
    let this = vimexpect#State([
                \ ['Continuing.', 'continue'],
                \ ['\v[\o32]{2}([^:]+):(\d+):\d+', 'jump'],
                \ ['Remote communication error.  Target disconnected.:', 'retry'],
                \ ])


    function this.continue(...)
        call self._parser.switch(s:gdb_running_matcher)
        call self.update_current_line_sign(0)
    endfunction


    function this.jump(file, line, ...)
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


    function this.retry(...)
        if self._server_exited
            return
        endif
        sleep 1
        call self.attach()
        call self.send('continue')
    endfunction

    return this
    "}
endfunction


function! gdb#gdb_running_match_new() abort
    "{
    let this = vimexpect#State([
                \ ['\v^Breakpoint \d+', 'pause'],
                \ ['\v\[Inferior\ +.{-}\ +exited\ +normally', 'disconnected'],
                \ ['(gdb)', 'pause'],
                \ ])

    function this.pause(...)
        call self._parser.switch(s:gdb_pause_matcher)
        if !self._initialized
            call self.send('set confirm off')
            call self.send('set pagination off')
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


    function this.disconnected(...)
        if !self._server_exited && self._reconnect
            " Refresh to force a delete of all watchpoints
            call s:RefreshBreakpoints()
            sleep 1
            call self.attach()
            call self.send('continue')
        endif
    endfunction

    return this
    "}
endfunction


function! gdb#gdb_new() abort
    "{
    let this = {}

    function! this.kill()
        call gdb#Map(0)
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
    let gdb = vimexpect#Parser(s:gdb_running_matcher, copy(s:gdb))
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
    " Create new tab for the debugging view
    tabnew
    let gdb._tab = tabpagenr()
    " create horizontal split to display the current file and maybe gdbserver
    sp
    let gdb._server_buf = -1
    if type(a:server_cmd) == type('')
        " spawn gdbserver in a vertical split
        let server = gdb#gdbserver_new(gdb)
        vsp | enew | let gdb._server_id = termopen(a:server_cmd, server)
        let gdb._jump_window = 2
        let gdb._server_buf = bufnr('%')
    endif
    " go to the bottom window and spawn gdb client
    wincmd j
    enew | let gdb._client_id = termopen(a:client_cmd, gdb)
    let gdb._client_buf = bufnr('%')
    call gdb#Map(1)
    " go to the window that displays the current file
    exe gdb._jump_window 'wincmd w'
    let g:gdb = gdb
    "}
endfunction


function! gdb#Test(bang, filter)
    "{
    let cmd = "GDB=1 make test"
    if a:bang == '!'
        let server_addr = '| vgdb'
        let cmd = printf('VALGRIND=1 %s', cmd)
    else
        let server_addr = printf('localhost:%d', s:gdb_port)
        let cmd = printf('GDBSERVER_PORT=%d %s', s:gdb_port, cmd)
    endif
    if a:filter != ''
        let cmd = printf('TEST_SCREEN_TIMEOUT=1000000 TEST_FILTER="%s" %s', a:filter, cmd)
    endif
    call s:Spawn(cmd, s:run_gdb, server_addr, 1)
    "}
endfunction


function! gdb#RefreshBreakpointSigns(breakpoints)
    "{
    let buf = bufnr('%')
    let i = 5000
    while i <= s:max_breakpoint_sign_id
        exe 'sign unplace '.i
        let i += 1
    endwhile
    let s:max_breakpoint_sign_id = 0
    let id = 5000
    for linenr in keys(get(a:breakpoints, bufname('%'), {}))
        exe 'sign place '.id.' name=GdbBreakpoint line='.linenr.' buffer='.buf
        let s:max_breakpoint_sign_id = id
        let id += 1
    endfor
    "}
endfunction


function! gdb#RefreshBreakpoints(breakpoints)
    "{
    if !exists('g:gdb')
        return
    endif
    if g:gdb._parser.state() == s:gdb_running_matcher
        " pause first
        call jobsend(g:gdb._client_id, "\<c-c>")
    endif
    if g:gdb._has_breakpoints
        call g:gdb.send('delete')
    endif
    let g:gdb._has_breakpoints = 0
    for [file, breakpoints] in items(a:breakpoints)
        for linenr in keys(a:breakpoints)
            let g:gdb._has_breakpoints = 1
            call g:gdb.send('break '.file.':'.linenr)
        endfor
    endfor
    "}
endfunction


function! gdb#Send(data)
    if !exists('g:gdb')
        throw 'Gdb is not running'
    endif
    call g:gdb.send(a:data)
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
    if a:type == 0
        tunmap <f4>
        tunmap <f5>
        tunmap <f6>
        tunmap <f7>
    elseif a:type == 1
        tnoremap <silent> <f4> <c-\><c-n>:GdbContinue<cr>i
        tnoremap <silent> <f5> <c-\><c-n>:GdbNext<cr>i
        tnoremap <silent> <f6> <c-\><c-n>:GdbStep<cr>i
        tnoremap <silent> <f7> <c-\><c-n>:GdbFinish<cr>i
    elseif a:type == 2
        nnoremap <silent> <f4> :GdbContinue<cr>
        nnoremap <silent> <f5> :GdbNext<cr>
        nnoremap <silent> <f6> :GdbStep<cr>
        nnoremap <silent> <f7> :GdbFinish<cr>
    endif
    "}
endfunction


let s:gdb_pause_matcher = gdb#gdb_pause_match_new()
let s:gdb_running_matcher = gdb#gdb_running_match_new()
let s:gdb = gdb#gdb_new()

