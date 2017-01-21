if exists("g:loaded_neovim_gdb") || &cp
    finish
endif
let g:loaded_neovim_gdb = 1


if has("nvim")
else
    finish
endif


let s:gdb_port = 7778
let s:run_gdb = "gdb -q -f a.out"
let s:run_gdb_cmd = "gdb -q -f "
let s:breakpoints = {}


function! s:ToggleBreak()
    let file_name = bufname('%')
    let file_breakpoints = get(s:breakpoints, file_name, {})
    let linenr = line('.')
    if has_key(file_breakpoints, linenr)
        call remove(file_breakpoints, linenr)
    else
        let file_breakpoints[linenr] = 1
    endif
    let s:breakpoints[file_name] = file_breakpoints
    call gdb#RefreshBreakpointSigns(s:breakpoints)
    call gdb#RefreshBreakpoints(s:breakpoints)
endfunction


function! s:ClearBreak()
    let s:breakpoints = {}
    call gdb#RefreshBreakpointSigns(s:breakpoints)
    call gdb#RefreshBreakpoints(s:breakpoints)
endfunction


function! s:GetExpression(...) range
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]
    let lines = getline(lnum1, lnum2)
    let lines[-1] = lines[-1][:col2 - 1]
    let lines[0] = lines[0][col1 - 1:]
    return join(lines, "\n")
endfunction


function! s:Eval(expr)
    call gdb#Send(printf('print %s', a:expr))
endfunction


function! s:Watch(expr)
    let expr = a:expr
    if expr[0] != '&'
        let expr = '&' . expr
    endif

    call s:Eval(expr)
    call gdb#Send('watch *$')
endfunction


"command! GdbDebugNvim call gdb#spawn(printf('make && gdbserver localhost:%d a.out', s:gdb_port), s:run_gdb, printf('localhost:%d', s:gdb_port), 0, 0)
"command! -nargs=1 GdbDebugServer call gdb#spawn(0, s:run_gdb, 'localhost:'.<q-args>, 0, 0)
command! -nargs=1 GdbDebug call gdb#spawn(0, s:run_gdb_cmd.<q-args>, 0, 0, 0)
command! -nargs=1 GdbDebug1 call gdb#spawn(0, s:run_gdb_cmd.<q-args>, 0, 0, 1)
"command! -bang -nargs=? GdbDebugTest call gdb#Test(<q-bang>, <q-args>)
"command! -nargs=1 -complete=file GdbInspectCore call gdb#spawn(0, printf('gdb -q -f -c %s a.out', <q-args>), 0, 0, 0)
command! GdbDebugStop call gdb#Kill()
command! GdbToggleBreakpoint call s:ToggleBreak()
command! GdbClearBreakpoints call s:ClearBreak()
command! GdbContinue call gdb#Send("c")
command! GdbNext call gdb#Send("n")
command! GdbStep call gdb#Send("s")
command! GdbFinish call gdb#Send("finish")
command! GdbFrameUp call gdb#Send("up")
command! GdbFrameDown call gdb#Send("down")
command! GdbInterrupt call gdb#Interrupt()
command! GdbEvalWord call s:Eval(expand('<cword>'))
command! -range GdbEvalRange call s:Eval(s:GetExpression(<f-args>))
command! GdbWatchWord call s:Watch(expand('<cword>')
command! -range GdbWatchRange call s:Watch(s:GetExpression(<f-args>))


call gdb#Map(2)
nnoremap <silent> <c-b> :GdbToggleBreakpoint<cr>
nnoremap <silent> <m-pageup> :GdbFrameUp<cr>
nnoremap <silent> <m-pagedown> :GdbFrameDown<cr>
nnoremap <silent> <f9> :GdbEvalWord<cr>
vnoremap <silent> <f9> :GdbEvalRange<cr>
nnoremap <silent> <m-f9> :GdbWatchWord<cr>
vnoremap <silent> <m-f9> :GdbWatchRange<cr>

