if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
endif


"Returns the visually selected text
function! nelib#util#get_visual_selection()
    "Shamefully stolen from http://stackoverflow.com/a/6271254/794380
    " Why is this not a built-in Vim script function?!
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]
    let lines = getline(lnum1, lnum2)
    let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][col1 - 1:]
    return join(lines, "\n")
endfunction


function! nelib#util#save_variable(var, file)
    call writefile([string(a:var)], a:file)
endfunction


" Serialize back a obj type({}) from file
" varname should be name of a global variable
function! nelib#util#read_variable(varname, file)
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')
    try
        let str_var = "let g:neobugger_tmp = " . readfile(a:file)[0]
        silent! call s:log.info(__func__, "() execute=", str_var)
        execute str_var
    catch /.*/
        echomsg string(g:neobugger_tmp)
        silent! call s:log.info(__func__, "() var=". string(g:neobugger_tmp))
    endtry
endfunction

