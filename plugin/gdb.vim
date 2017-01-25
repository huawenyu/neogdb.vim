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


"command! GdbDebugNvim call gdb_expect#spawn(printf('make && gdbserver localhost:%d a.out', s:gdb_port), s:run_gdb, printf('localhost:%d', s:gdb_port), 0, 0)
"command! -nargs=1 GdbDebugServer call gdb_expect#spawn(0, s:run_gdb, 'localhost:'.<q-args>, 0, 0)
command! -nargs=1 GdbLocal  call gdb_expect#spawn(0, <q-args>, 0, 0, 1)
command! -nargs=1 GdbRemote call gdb_expect#spawn("$SHELL", <q-args>, 0, 0, 0)
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
command! GdbFrameUp call gdb#Send("up")
command! GdbFrameDown call gdb#Send("down")
command! GdbInterrupt call gdb#Interrupt()
command! GdbEvalWord call gdb#Eval(expand('<cword>'))
command! -range GdbEvalRange call gdb#Eval(gdb#GetExpression(<f-args>))
command! GdbWatchWord call gdb#Watch(expand('<cword>')
command! -range GdbWatchRange call gdb#Watch(gdb#GetExpression(<f-args>))


call gdb#Map("nmap")
nnoremap <F2> :GdbRemote sysinit/init
nnoremap <silent> <m-pageup> :GdbFrameUp<cr>
nnoremap <silent> <m-pagedown> :GdbFrameDown<cr>
vnoremap <silent> <f9> :GdbEvalRange<cr>
nnoremap <silent> <m-f9> :GdbWatchWord<cr>
vnoremap <silent> <m-f9> :GdbWatchRange<cr>

