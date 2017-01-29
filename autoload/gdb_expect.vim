function! s:__init__()
    "{
    if exists("s:init")
        return
    endif
    let s:run_gdb_cmd = "gdb -q -f "
    "}
endfunction
call s:__init__()

function! gdb_expect#sample(server) abort
    let @W= printf("call gdb_expect#spawn(\"bash -c 'ping -c 1 %s; bash'\", 'sysinit/init', '%s', 0, 1)",
                \ a:server, a:server)
endfunction


function! gdb_expect#gdbserver_new(gdb) abort
    "{
    let this = vimexpect#State([
                \ ['\vListening on port (\d+)$', 'on_accept'],
                \ ['\vDetaching from process \d+', 'on_exit'],
                \ ['test_func$', 'on_func'],
                \ ['window.vim', 'on_win'],
                \ ['\vtest_func1 (\d+)', 'on_func1'],
                \ ])
    let this._gdb = a:gdb

    function this.on_func(...)
        echomsg "call test_func"
    endfunction

    function this.on_win(...)
        echomsg "call on_win"
    endfunction

    function this.on_func1(num, ...)
        echomsg "call test_func1 num=" . a:num
    endfunction

    return this
    "}
endfunction


function! gdb_expect#gdb_pause_match_new() abort
    "{
    let this = vimexpect#State([
                \ ['Continuing.', 'continue'],
                \ ['\v[\o32]{2}([^:]+):(\d+):\d+', 'jump'],
                \ ['Remote communication error.  Target disconnected.:', 'retry'],
                \ ])


    function this.continue(...)
        call self._parser.switch(s:gdb_running_matcher)
        let self.state = "running"
        call self.update_current_line_sign(0)
    endfunction


    function this.jump(file, line, ...)
        call gdb#Jump(a:file, a:line)
    endfunction


    function this.retry(...)
        call self.retry()
    endfunction

    return this
    "}
endfunction


function! gdb_expect#gdb_running_match_new() abort
    "{
    let this = vimexpect#State([
                \ ['\v^Breakpoint \d+', 'pause'],
                \ ['\v^Temporary breakpoint \d+', 'pause'],
                \ ['\v\[Inferior\ +.{-}\ +exited\ +normally', 'disconnected'],
                \ ['(gdb)', 'pause'],
                \ ])

    function this.pause(...)
        call self._parser.switch(s:gdb_pause_matcher)
        let self.state = "pause"
        call self.on_pause()
    endfunction


    function this.disconnected(...)
        call self.on_disconnected()
    endfunction

    return this
    "}
endfunction


function! gdb_expect#spawn(server_cmd, client_cmd, server_addr, reconnect, mode)
    "{
    if exists('g:gdb')
        throw 'Gdb already running'
    endif

    let cword = expand("<cword>")
    let gdb = vimexpect#Parser(s:gdb_running_matcher, copy(s:gdb))
    let gdb_i = gdb#spawn(a:server_cmd, a:client_cmd, a:server_addr, a:reconnect, a:mode)
    call extend(gdb, gdb_i)

    " Create new tab for the debugging view
    tabnew
    let gdb._tab = tabpagenr()
    silent! ball 1
    let gdb._win_main = win_getid()

    " Create term
    let gdb._server_buf = -1
    if type(a:server_cmd) == type('') && !empty(a:server_cmd)
        " spawn gdbserver in a vertical split
        let server = gdb_expect#gdbserver_new(gdb)
        let server_parser = vimexpect#Parser(server, server)

        silent! vsp
        let gdb._win_gdbclient = win_getid()

        silent! sp
        let gdb._win_server = win_getid()
        enew | let gdb._server_id = termopen(a:server_cmd, server_parser)
        let gdb._server_buf = bufnr('%')

    else
        silent! vsp
        let gdb._win_gdbclient = win_getid()
    endif

    " Create quickfix: lgetfile, cgetfile
    if win_gotoid(gdb._win_main) == 1
        if !filereadable(gdb._gdb_bt_qf)
            exec "silent! vimgrep " . cword ." ". expand("%")
        else
            exec "silent cgetfile " . gdb._gdb_bt_qf
        endif
        silent! copen
        let gdb._win_qf = win_getid()
    endif

    if win_gotoid(gdb._win_main) == 1
        if !filereadable(gdb._gdb_break_qf)
            exec "silent! lvimgrep " . cword ." ". expand("%")
        else
            exec "silent lgetfile " . gdb._gdb_break_qf
        endif
        silent! lopen
        let gdb._win_lqf = win_getid()
    endif

    " Create gdb terminal
    if win_gotoid(gdb._win_gdbclient) == 1
        let gdb._server_buf = -1
        enew | let gdb._client_id = termopen(s:run_gdb_cmd . a:client_cmd, gdb)
        let gdb._client_buf = bufnr('%')
        call gdb#Map("tmap")
    endif

    " Backto main windows for display file
    if win_gotoid(gdb._win_main) == 1
        let gdb._jump_window = win_id2win(gdb._win_main)
        "normal 
        stopinsert
    endif
    let g:gdb = gdb
    "}
endfunction


function! s:__fini__()
    "{
    if exists("s:init")
        return
    endif

    let s:gdb_pause_matcher = gdb_expect#gdb_pause_match_new()
    let s:gdb_running_matcher = gdb_expect#gdb_running_match_new()
    let s:gdb = gdb#gdb_new()
    "}
endfunction
call s:__fini__()
let s:init = 1

