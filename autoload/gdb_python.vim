function! s:__init__()
    "{
    if exists("s:init")
        return
    endif

    "}
endfunction
call s:__init__()


function! gdb_python#spawn(server_cmd, client_cmd, server_addr, reconnect, mode)
    "{
    if exists('g:gdb')
        throw 'Gdb already running'
    endif
    let gdb = gdb#gdb_new()
    call extend(gdb, gdb#spawn(a:server_cmd, a:client_cmd, a:server_addr, a:reconnect, a:mode))

    " link gdb-neovim as .gdbinit
    let gdbinit = glob("`find " . $HOME . " -maxdepth 1 -iname '.gdbinit' -print`")
    Decho "neogdb.vim: find gdbinit=" . gdbinit
    if empty(gdbinit)
        let gdbinit = glob("`find " . $HOME . "/.vim -name 'gdb-neovim' -type f -print`")
        Decho "neogdb.vim: find gdb-neovim=" . gdbinit
        if empty(gdbinit)
            throw "neogdb.vim: Cann't find gdb-neovim which will be .gdbinit"
        else
            Decho "neogdb.vim: ln -s " . shellescape(gdbinit) . " " . shellescape($HOME . "/.gdbinit")
            call system('ln -s ' . shellescape(gdbinit) . shellescape($HOME . "/.gdbinit"))
        endif
    endif
    let gdbinit = glob("`find " . $HOME . " -maxdepth 1 -iname '.gdbinit' -print`")
    Decho("neogdb.vim: find gdbinit=" . gdbinit)
    if empty(gdbinit)
        throw "neogdb.vim: Cann't find .gdbinit"
    endif

    " Create new tab for the debugging view
    tabnew
    let gdb._tab = tabpagenr()
    silent! ball 1
    let gdb._win_main = win_getid()
    silent! vsp
    let gdb._win_term = win_getid()

    if win_gotoid(gdb._win_main) == 1
        silent! lvimgrep set $HOME/.vimrc
        silent! lopen
        let gdb._win_lqf = win_getid()
    endif

    if win_gotoid(gdb._win_main) == 1
        silent! vimgrep set $HOME/.vimrc
        silent! copen
        let gdb._win_qf = win_getid()
    endif

    " Create gdb terminal
    if win_gotoid(gdb._win_term) == 1
        let gdb._server_buf = -1
        enew | let gdb._client_id = termopen(a:client_cmd, gdb)
        let gdb._client_buf = bufnr('%')
        call gdb#Map("tmap")
    endif

    " Backto main windows for display file
    if win_gotoid(gdb._win_main) == 1
        let gdb._jump_window = win_id2win(gdb._win_main)
    endif
    let g:gdb = gdb
    "}
endfunction


function! s:__fini__()
    "{
    if exists("s:init")
        return
    endif
    "}
endfunction
call s:__fini__()
let s:init = 1

