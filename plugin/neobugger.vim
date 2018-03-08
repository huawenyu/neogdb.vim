if exists("g:loaded_neovim_gdb") || &cp
    finish
endif
let g:loaded_neovim_gdb = 1


if has("nvim")
else
    finish
endif


" InstanceGdb {{{1
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


command! -nargs=0 GdbDebugStop call neobugger#Handle('current', 'Kill')
"command! -nargs=0 GdbToggleBreak call neobugger#Handle('current', 'ToggleBreak')
command! -nargs=0 GdbToggleBreak call neobugger#menu_break#New().showMenu()
command! -nargs=0 GdbToggleBreakAll call neobugger#Handle('current', 'ToggleBreakAll')
command! -nargs=0 GdbClearBreak call neobugger#Handle('current', 'ClearBreak')
command! -nargs=0 GdbContinue call neobugger#Handle('current', 'Send', 'c')
command! -nargs=0 GdbNext call neobugger#Handle('current', 'Next')
command! -nargs=0 GdbStep call neobugger#Handle('current', 'Step')
command! -nargs=0 GdbFinish call neobugger#Handle('current', 'Send', "finish")
"command! -nargs=0 GdbUntil call neobugger#Handle('current', 'Send', "until ". line('.'))
command! -nargs=0 GdbUntil call neobugger#Handle('current', 'TBreak')
command! -nargs=0 GdbFrameUp call neobugger#Handle('current', 'FrameUp')
command! -nargs=0 GdbFrameDown call neobugger#Handle('current', 'FrameDown')
command! -nargs=0 GdbInterrupt call neobugger#Handle('current', 'Interrupt')
command! -nargs=0 GdbRefresh call neobugger#Handle('current', 'Send', "info line")
command! -nargs=0 GdbInfoLocal call neobugger#Handle('current', 'Send', "info local")
command! -nargs=0 GdbInfoBreak call neobugger#Handle('current', 'Send', "info break")
command! -nargs=0 GdbEvalWord call neobugger#Handle('current', 'Eval', expand('<cword>'))
command! -range -nargs=0 GdbEvalRange call neobugger#Handle('current', 'Eval', nelib#util#get_visual_selection())
command! -nargs=0 GdbWatchWord call neobugger#Handle('current', 'Watch', expand('<cword>')
command! -range -nargs=0 GdbWatchRange call neobugger#Handle('current', 'Watch', nelib#util#get_visual_selection())

command! -nargs=0 GdbViewVar call neobugger#Handle('current', 'ToggleViewVar')
command! -nargs=0 GdbViewFrame call neobugger#Handle('current', 'ToggleViewFrame')
command! -nargs=0 GdbViewBreak call neobugger#Handle('current', 'ToggleViewBreak')
" }}}


" Keymap options {{{1
"
if exists('g:neobugger_leader') && !empty(g:neobugger_leader)
        let g:gdb_keymap_refresh = g:neobugger_leader.'r'
        let g:gdb_keymap_continue = g:neobugger_leader.'c'
        let g:gdb_keymap_next = g:neobugger_leader.'n'
        let g:gdb_keymap_step = g:neobugger_leader.'i'
        let g:gdb_keymap_finish = g:neobugger_leader.'N'
        let g:gdb_keymap_until = g:neobugger_leader.'t'
        let g:gdb_keymap_toggle_break = g:neobugger_leader.'b'
        let g:gdb_keymap_toggle_break_all = g:neobugger_leader.'a'
        let g:gdb_keymap_clear_break = g:neobugger_leader.'C'
        let g:gdb_keymap_debug_stop = g:neobugger_leader.'x'
        let g:gdb_keymap_frame_up = g:neobugger_leader.'k'
        let g:gdb_keymap_frame_down = g:neobugger_leader.'j'

        " View
        let g:gdb_keymap_view_var = g:neobugger_leader.'vv'
        let g:gdb_keymap_view_break = g:neobugger_leader.'vb'
        let g:gdb_keymap_view_frame = g:neobugger_leader.'vf'
else
    if !exists("g:gdb_keymap_refresh")
        let g:gdb_keymap_refresh = '<f3>'
    endif
    if !exists("g:gdb_keymap_continue")
        let g:gdb_keymap_continue = '<f4>'
    endif
    if !exists("g:gdb_keymap_next")
        let g:gdb_keymap_next = '<f5>'
    endif
    if !exists("g:gdb_keymap_step")
        let g:gdb_keymap_step = '<f6>'
    endif
    if !exists("g:gdb_keymap_finish")
        let g:gdb_keymap_finish = '<f7>'
    endif
    if !exists("g:gdb_keymap_until")
        let g:gdb_keymap_until = '<f8>'
    endif
    if !exists("g:gdb_keymap_toggle_break")
        let g:gdb_keymap_toggle_break = '<f9>'
    endif
    if !exists("g:gdb_keymap_toggle_break_all")
        let g:gdb_keymap_toggle_break_all = '<f10>'
    endif
    if !exists("g:gdb_keymap_clear_break")
        let g:gdb_keymap_clear_break = '<f21>'
    endif
    if !exists("g:gdb_keymap_debug_stop")
        let g:gdb_keymap_debug_stop = '<f17>'
    endif

    if !exists("g:gdb_keymap_frame_up")
        let g:gdb_keymap_frame_up = '<c-n>'
    endif

    if !exists("g:gdb_keymap_frame_down")
        let g:gdb_keymap_frame_down = '<c-p>'
    endif

    if !exists("g:gdb_keymap_view_var")
        let g:gdb_keymap_view_var = '<a-v>'
    endif
    if !exists("g:gdb_keymap_view_break")
        let g:gdb_keymap_view_break = '<a-b>'
    endif
    if !exists("g:gdb_keymap_view_frame")
        let g:gdb_keymap_view_frame = '<a-f>'
    endif

endif
" }}}


" Customization options {{{1
"   - The 'bufnr', 'wid' is runtime value
let s:neobugger_conf = {
            \'view_main': {
            \       'bufnr': -1,
            \       'wid': -1,
            \       'this': {},
            \       },
            \'view_gdb': {'status': 1, 'title': "Gdb",
            \       'layout': ['vsp new'],
            \       'bufnr': -1,
            \       'wid': -1,
            \       'this': {},
            \       },
            \'gdbserver': {'status': 1, 'title': "GdbServer",
            \       'layout': ['wincmd l', 'wincmd j', 'wincmd j', 'wincmd j', 'rightbelow new'],
            \       'bufnr': -1,
            \       'wid': -1,
            \       'this': {},
            \       },
            \'view_var': {'status': 1, 'title': "Variable",
            \       'layout': ['wincmd l', 'wincmd j', 'wincmd j', 'wincmd j', 'rightbelow new'],
            \       'bufnr': -1,
            \       'wid': -1,
            \       'this': {},
            \       },
            \'view_frame': {'status': 1, 'title': "Frame",
            \       'layout': ['wincmd l', 'wincmd j', 'wincmd j', 'wincmd j', 'rightbelow new'],
            \       'bufnr': -1,
            \       'wid': -1,
            \       'this': {},
            \       },
            \'view_break': {'status': 1, 'title': "Breakpoint",
            \       'layout': ['wincmd l', 'wincmd j', 'wincmd j', 'wincmd j', 'rightbelow new'],
            \       'bufnr': -1,
            \       'wid': -1,
            \       'this': {},
            \       },
            \}

" Read from customer defined 'g:neobugger_user' first
" <or> customer directly redefine 'g:neobugger_conf'.
"
if !exists("g:neobugger_conf")
    let g:neobugger_conf = s:neobugger_conf
endif

if !exists("g:gdb_require_enter_after_toggling_breakpoint")
    let g:gdb_require_enter_after_toggling_breakpoint = 1
endif

if !exists("g:restart_app_if_gdb_running")
    let g:restart_app_if_gdb_running = 1
endif

if !exists("g:neobugger_other")
    let g:neobugger_other = 1
endif

" }}}


" Set option, type must same as default config
function! NbConfSet(view, option, value)
    let s:neobugger_conf[a:view][a:option] = a:value
endfunction


" Return value of option
"   - if 3nd parameter exists for the default when not existed or type not correct.
"   - If the option is not found, get from default config.
function! NbConfGet(view, option, ...)
    if has_key(s:neobugger_conf, a:view)
        let l:conf_default = s:neobugger_conf[a:view]
    else
        throw "NbConfGet(view=". a:view. ' option='. a:option. ' a:0='. a:000. '): No default view.'
    endif

    if has_key(g:neobugger_conf, a:view)
        let l:conf = g:neobugger_conf[a:view]
    elseif has_key(s:neobugger_conf, a:view)
        let l:conf = s:neobugger_conf[a:view]
    endif

    if has_key(l:conf_default, a:option)
        let val_default = l:conf_default[a:option]
    else
        throw "NbConfGet(view=". a:view. ' option='. a:option. ' a:0='. a:000. '): The default view no option.'
    endif

    if has_key(l:conf, a:option)
        let val = l:conf[a:option]
    elseif has_key(l:conf_default, a:option)
        let val = l:conf_default[a:option]
    else
        throw "NbConfGet(view=". a:view. ' option='. a:option. ' a:0='. a:000. '): The view no option.'
    endif

    " No type check
    if a:0 == 0
        return val
    endif

    if type(val) == type(a:1)
        return val
    elseif type(val_default) == type(a:1)
        return val_default
    else
        throw "NbConfGet(view=". a:view. ' option='. a:option. ' a:0='. a:000. '): Type check fail.'
    endif
endfunction



" Helper options {{{1
let s:gdb_local_remote = 0
function! NeobuggerCommandStr()
    if s:gdb_local_remote
        let s:gdb_local_remote = 0
        if exists("g:neogdb_attach_remote_str")
            return 'Nbgdbattach '. g:neogdb_attach_remote_str
        else
            return 'Nbgdbattach sysinit/init 192.168.0.180:444'
        endif
    else
        let s:gdb_local_remote = 1
        return 'Nbgdb t1'
    endif
endfunction

nnoremap <F2> :<c-u><C-\>e NeobuggerCommandStr()<cr>
cnoremap <F2> :<c-u><C-\>e NeobuggerCommandStr()<cr>
" }}}

