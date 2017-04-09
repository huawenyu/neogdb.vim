if exists("g:loaded_neovim_gdb") || &cp
    finish
endif
let g:loaded_neovim_gdb = 1


if has("nvim")
else
    finish
endif


"let s:gdb_port = 7778
"let s:run_gdb = "gdb -q -f a.out"
let s:gdb_local_remote = 0


command! -nargs=* GdbLocal  call gdb#Spawn(<f-args>)
command! -nargs=* GdbRemote call gdb#Spawn(<f-args>)
"
"command! GdbDebugNvim call gdb_expect#spawn(printf('make && gdbserver localhost:%d a.out', s:gdb_port), s:run_gdb, printf('localhost:%d', s:gdb_port), 0, 0)
"command! -nargs=1 GdbDebugServer call gdb_expect#spawn(0, s:run_gdb, 'localhost:'.<q-args>, 0, 0)
"command! -nargs=1 GdbDebug1 call gdb_python#spawn(0, <q-args>, 0, 0, 1)
"command! -nargs=1 -complete=file GdbInspectCore call gdb_expect#spawn(0, printf('gdb -q -f -c %s a.out', <q-args>), 0, 0, 0)
command! GdbDebugStop call gdb#Kill()
command! GdbToggleBreak call gdb#ToggleBreak()
command! GdbToggleBreakAll call gdb#ToggleBreakAll()
command! GdbClearBreak call gdb#ClearBreak()
command! GdbContinue call gdb#Send("c")
command! GdbNext call gdb#Send("n")
command! GdbStep call gdb#Send("s")
command! GdbFinish call gdb#Send("finish")
"command! GdbUntil call gdb#Send("until " . line('.'))
command! GdbUntil call gdb#TBreak()
command! GdbFrameUp call gdb#FrameUp()
command! GdbFrameDown call gdb#FrameDown()
command! GdbInterrupt call gdb#Interrupt()
command! GdbRefresh call gdb#Send("info line")
command! GdbInfoLocal call gdb#Send("info local")
command! GdbInfoBreak call gdb#Send("info break")
command! GdbEvalWord call gdb#Eval(expand('<cword>'))
command! -range GdbEvalRange call gdb#Eval(gdb#GetExpression(<f-args>))
command! GdbWatchWord call gdb#Watch(expand('<cword>')
command! -range GdbWatchRange call gdb#Watch(gdb#GetExpression(<f-args>))


function! GdbLocalRemoteStr()
    if s:gdb_local_remote
        let s:gdb_local_remote = 0
        return 'GdbRemote confos#me sysinit/init 10.1.1.125:444'
    else
        let s:gdb_local_remote = 1
        return 'GdbLocal confloc#me t1'
    endif
endfunction

nnoremap <F2> :<c-u><C-\>e GdbLocalRemoteStr()<cr>
cnoremap <F2> :<c-u><C-\>e GdbLocalRemoteStr()<cr>

"nnoremap <silent> <m-pageup> :GdbFrameUp<cr>
"nnoremap <silent> <m-pagedown> :GdbFrameDown<cr>
"nnoremap <silent> <m-f9> :GdbWatchWord<cr>
"vnoremap <silent> <m-f9> :GdbWatchRange<cr>

