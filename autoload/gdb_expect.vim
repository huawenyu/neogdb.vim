function! gdb_expect#gdbserver_new(gdb) abort
    "{
    let this = {}
    let this._gdb = a:gdb


    function this.on_exit()
        let self._gdb._server_exited = 1
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

    let gdb = vimexpect#Parser(s:gdb_running_matcher, copy(s:gdb))
    let gdb_i = gdb#spawn(a:server_cmd, a:client_cmd, a:server_addr, a:reconnect, a:mode)
    call extend(gdb, gdb_i)

    " Create new tab for the debugging view
    tabnew
    let gdb._tab = tabpagenr()
    " create horizontal split to display the current file and maybe gdbserver
    sp
    let gdb._server_buf = -1
    if type(a:server_cmd) == type('')
        " spawn gdbserver in a vertical split
        let server = gdb_expect#gdbserver_new(gdb)
        vsp | enew | let gdb._server_id = termopen(a:server_cmd, server)
        let gdb._jump_window = 2
        let gdb._server_buf = bufnr('%')
    endif
    " go to the bottom window and spawn gdb client
    wincmd j
    enew | let gdb._client_id = termopen(a:client_cmd, gdb)
    let gdb._client_buf = bufnr('%')
    call gdb#Map("tmap")
    " go to the window that displays the current file
    exe gdb._jump_window 'wincmd w'
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

