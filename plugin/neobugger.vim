if exists("g:loaded_neovim_gdb") || &cp
    finish
endif
let g:loaded_neovim_gdb = 1


if has("nvim")
else
    finish
endif


" Gdb
command! -nargs=+ -complete=file Nbgdb call neobugger#New('gdb', 'local', [<f-args>][0], {'args' : [<f-args>][1:]})
function! s:attachGDB(binaryFile, args)
    if len(a:args.args) >= 1
        if a:args.args[0] =~ '\v^\d+$'
            call neobugger#New('gdb', 'pid', a:binaryFile, {'pid': str2nr(a:args.args[0])})
        else
            call neobugger#New('gdb', 'server', a:binaryFile, {'args': a:args.args})
        endif
    else
        throw "Can't call Nbgdbattach with ".a:0." arguments"
    endif
endfunction
command! -nargs=+ -complete=file Nbgdbattach call s:attachGDB([<f-args>][0], {'args' : [<f-args>][1:]})


command! GdbDebugStop call neobugger#Handle('gdb', 'Kill')
command! GdbToggleBreak call neobugger#Handle('gdb', 'ToggleBreak')
command! GdbToggleBreakAll call neobugger#Handle('gdb', 'ToggleBreakAll')
command! GdbClearBreak call neobugger#Handle('gdb', 'ClearBreak')
command! GdbContinue call neobugger#Handle('gdb', 'Send', 'c')
command! GdbNext call neobugger#Handle('gdb', 'Next')
command! GdbStep call neobugger#Handle('gdb', 'Step')
command! GdbFinish call neobugger#Handle('gdb', 'Send', "finish")
"command! GdbUntil call neobugger#Handle('gdb', 'Send', "until ". line('.'))
command! GdbUntil call neobugger#Handle('gdb', 'TBreak')
command! GdbFrameUp call neobugger#Handle('gdb', 'FrameUp')
command! GdbFrameDown call neobugger#Handle('gdb', 'FrameDown')
command! GdbInterrupt call neobugger#Handle('gdb', 'Interrupt')
command! GdbRefresh call neobugger#Handle('gdb', 'Send', "info line")
command! GdbInfoLocal call neobugger#Handle('gdb', 'Send', "info local")
command! GdbInfoBreak call neobugger#Handle('gdb', 'Send', "info break")
command! GdbEvalWord call neobugger#Handle('gdb', 'Eval', expand('<cword>'))
command! -range GdbEvalRange call neobugger#Handle('gdb', 'Eval', util#get_visual_selection())
command! GdbWatchWord call neobugger#Handle('gdb', 'Watch', expand('<cword>')
command! -range GdbWatchRange call neobugger#Handle('gdb', 'Watch', util#get_visual_selection())


let s:gdb_local_remote = 0
function! GdbLocalRemoteStr()
    if s:gdb_local_remote
        let s:gdb_local_remote = 0
        return 'Nbgdbattach sysinit/init 192.168.0.180:444'
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

