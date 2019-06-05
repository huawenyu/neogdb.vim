if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))

    let s:module = 'sample1'
    let s:prototype = tlib#Object#New({
                \ '_class': [s:module],
                \ })
endif


" Constructor
function! sample1#echo#New(conf, binaryFile, args)
    "{
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let l:f_conf = 'sample1#mode#'.a:conf.'#Conf'
    let Conf = function(l:f_conf)
    if empty(Conf)
        throw l:__func__. " error: no Conf '". a:conf ."' from ".l:f_conf
    endif
    let conf = Conf()
    if type(conf) != type({})
        throw l:__func__. " error: Conf '". a:conf ."' should return a dict not ". type(conf). "."
    endif

    let l:parent = s:prototype.New(a:0 >= 1 ? a:1 : {})

    call nelib#state#Open(conf)
    if !exists('g:state_ctx') || !has_key(g:state_ctx, 'window')
        return
    endif

    if has_key(g:state_ctx.window, 'gdb')
        let win_gdb = g:state_ctx.window['gdb']
        let gdb._win_gdb = win_gdb
        let gdb._client_id = win_gdb._client_id
    else
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
    endif
    "}
endfunction


function! s:prototype._Send(data)
    let l:__func__ = "gdb._Send"
    silent! call s:log.trace(l:__func__. "() args=". string(a:data))
    call jobsend(self._client_id, a:data)
endfunction


function! s:prototype.on_continue(...)
    call state#Switch('gdb', 'running', 0)
    call self.Update_current_line_sign(0)
endfunction
