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


command! -nargs=+ -complete=file Nbgdb call neobugger#gdb#start('local', [<f-args>][0], {'args' : [<f-args>][1:]})
function! s:attachGDB(binaryFile, args)
    if len(a:args.args) >= 1
        if a:args.args[0] =~ '\v^\d+$'
            call neobugger#gdb#start('pid', a:binaryFile, {'pid': str2nr(a:args.args[0])})
        else
            call neobugger#gdb#start('server', a:binaryFile, {'args': a:args.args})
        endif
    else
        throw "Can't call Nbgdbattach with ".a:0." arguments"
    endif
endfunction
command! -nargs=+ -complete=file Nbgdbattach call s:attachGDB([<f-args>][0], {'args' : [<f-args>][1:]})






"
"command! GdbDebugNvim call gdb_expect#spawn(printf('make && gdbserver localhost:%d a.out', s:gdb_port), s:run_gdb, printf('localhost:%d', s:gdb_port), 0, 0)
"command! -nargs=1 GdbDebugServer call gdb_expect#spawn(0, s:run_gdb, 'localhost:'.<q-args>, 0, 0)
"command! -nargs=1 GdbDebug1 call gdb_python#spawn(0, <q-args>, 0, 0, 1)
"command! -nargs=1 -complete=file GdbInspectCore call gdb_expect#spawn(0, printf('gdb -q -f -c %s a.out', <q-args>), 0, 0, 0)
command! GdbDebugStop call neobugger#gdb#Kill()
command! GdbToggleBreak call neobugger#gdb#ToggleBreak()
command! GdbToggleBreakAll call neobugger#gdb#ToggleBreakAll()
command! GdbClearBreak call neobugger#gdb#ClearBreak()
command! GdbContinue call neobugger#gdb#Send("c")
command! GdbNext call neobugger#gdb#Next()
command! GdbStep call neobugger#gdb#Step()
command! GdbFinish call neobugger#gdb#Send("finish")
"command! GdbUntil call neobugger#gdb#Send("until " . line('.'))
command! GdbUntil call neobugger#gdb#TBreak()
command! GdbFrameUp call neobugger#gdb#FrameUp()
command! GdbFrameDown call neobugger#gdb#FrameDown()
command! GdbInterrupt call neobugger#gdb#Interrupt()
command! GdbRefresh call neobugger#gdb#Send("info line")
command! GdbInfoLocal call neobugger#gdb#Send("info local")
command! GdbInfoBreak call neobugger#gdb#Send("info break")
command! GdbEvalWord call neobugger#gdb#Eval(expand('<cword>'))
command! -range GdbEvalRange call neobugger#gdb#Eval(neobugger#gdb#GetExpression(<f-args>))
command! GdbWatchWord call neobugger#gdb#Watch(expand('<cword>')
command! -range GdbWatchRange call neobugger#gdb#Watch(neobugger#gdb#GetExpression(<f-args>))


function! GdbLocalRemoteStr()
    if s:gdb_local_remote
        let s:gdb_local_remote = 0
        return 'Nbgdbattach sysinit/init 10.1.1.125:444'
    else
        let s:gdb_local_remote = 1
        return 'Nbgdb t1'
    endif
endfunction

nnoremap <F2> :<c-u><C-\>e GdbLocalRemoteStr()<cr>
cnoremap <F2> :<c-u><C-\>e GdbLocalRemoteStr()<cr>

"nnoremap <silent> <m-pageup> :GdbFrameUp<cr>
"nnoremap <silent> <m-pagedown> :GdbFrameDown<cr>
"nnoremap <silent> <m-f9> :GdbWatchWord<cr>
"vnoremap <silent> <m-f9> :GdbWatchRange<cr>

