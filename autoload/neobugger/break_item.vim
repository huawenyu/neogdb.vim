if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)

    "let s:prototype = tlib#Object#New({'_class': [s:name]})
    " For serialize: this class must be plain-struct-like layout
    "
    " break_item {
    "   .name*      masterkey: relative-path-file:[line-text|function]
    "   .file       relative-path-filename
    "   .linetext   the breakpoint's line-text or function-name
    "   .line       the breakpoint's lineno
    "   .type       0 break at line, 1 at function
    "   .state      0 enable(default), 1 disable, 2 delete
    "   .update     0 do-nothing, 1 need fresh gdb & view
    "   .offset     auto-load's offset if supported
    "   .sign_id
    "   .break
    "   .condition  get from user input, split by ';'
    "   .command    get from user input, split by ';'
    " }
    "

    let s:prototype = {
                \ 'name': '',
                \ 'file': '',
                \ 'text': '',
                \ 'line': 0,
                \ 'col': 0,
                \ 'fn': '',
                \ 'type': 0,
                \ 'state': 0,
                \ 'update': 0,
                \ 'offset': 0,
                \ 'sign_id': 0,
                \ 'break': '',
                \ 'condition': '',
                \ 'command': '',
                \}

endif


" Constructor
function! neobugger#break_item#New(type, cmdtext)
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let newBreak = deepcopy(s:prototype)
    call neobugger#break_item#_fill_detail(newBreak, a:type, a:cmdtext)

    return newBreak
endfunction


function! neobugger#break_item#_fill_detail(item, type, cmdtext)
    let __func__ = "fill_detail"

    let filenm = bufname("%")
    let linenr = line(".")
    let colnr = col(".")
    let cword = expand("<cword>")
    let cfuncline = neobugger#gdb#GetCFunLinenr()

    let fname = fnamemodify(filenm, ':p:.')
    let type = 0
    if linenr == cfuncline
        let type = 1
        let file_breakpoints = fname .':'.cword
    else
        let file_breakpoints = fname .':'.linenr
    endif

    let a:item['name'] = file_breakpoints
    let a:item['file'] = fname
    let a:item['type'] = type
    let a:item['line'] = linenr
    let a:item['col'] = colnr
    let a:item['command'] = a:cmdtext
    silent! call s:log.info(__func__, '() item=', string(a:item))
endfunction


function! s:prototype.equal(item) dict
    let __func__ = "equal"

    let that = a:item
    if !(self.name ==# that.name)
                \ || !(self.file ==# that.file)
                \ || !(self.type ==# that.type)
                \ || !(self.line ==# that.line)
                \ || !(self.command ==# that.command)
        silent! call s:log.info(__func__, '('. that.name. ') not equal')
        return 0
    endif
    silent! call s:log.info(__func__, '('. that.name. ') equal')
    return 1
endfunction

