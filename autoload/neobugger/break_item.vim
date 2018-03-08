if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})

    "
    " break_item {
    "   .name*      masterkey: relative-path-file:[line-text|function]
    "   .file       relative-path-filename
    "   .linetext   the breakpoint's line-text or function-name
    "   .line       the breakpoint's lineno
    "   .type       0 break at line, 1 at function
    "   .state      0 disable, 1 enable, 2 delete
    "   .update     0 noting, 1 need fresh gdb & view
    "   .offset     auto-load's offset if supported
    "   .sign_id
    "   .break
    "   .condition  get from user input, split by ';'
    "   .command    get from user input, split by ';'
    " }
    "

    let s:_Prototype = {
                \ 'name': '',
                \ 'file': '',
                \ 'text': '',
                \ 'line': 0,
                \ 'type': 0,
                \ 'state': 0,
                \ 'update': 0,
                \ 'offset': 0,
                \ 'sign_id': 0,
                \ 'break': '',
                \ 'condition': '',
                \ 'command': [],
                \}
endif


" Constructor
function! neobugger#break_item#New(options)
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let newBreak = s:prototype.New(deepcopy(s:_Prototype))
    if empty(a:options)
        call newBreak.add_break()
    else
    endif

    let newMenuItem.text = a:options['text']
    let newMenuItem.shortcut = a:options['shortcut']
    let newMenuItem.children = []

    let newMenuItem.isActiveCallback = -1
    if has_key(a:options, 'isActiveCallback')
        let newMenuItem.isActiveCallback = a:options['isActiveCallback']
    endif

    let newMenuItem.callback = -1
    if has_key(a:options, 'callback')
        let newMenuItem.callback = a:options['callback']
    endif

    return newMenuItem
endfunction


function! s:prototype.add_break(command) dict
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
endfunction


function! neobugger#menu_item#NewSubmenu(options)
    let standard_options = { 'callback': -1 }
    let options = extend(a:options, standard_options, "force")

    return neobugger#menu_item#New(options)
endfunction


function! s:prototype.addMenuItem(menuItem) dict
    call add(self.children, a:newMenuItem)
endfunction


"return 1 if this menu item should be displayed
"
"delegates off to the isActiveCallback, and defaults to 1 if no callback was
"specified
function! s:prototype.enabled()
    if self.isActiveCallback != -1
        return {self.isActiveCallback}()
    endif
    return 1
endfunction


"perform the action behind this menu item, if this menuitem has children then
"display a new menu for them, otherwise deletegate off to the menuitem's
"callback
function! s:prototype.execute()
    if len(self.children)
        let mc = g:NERDTreeMenuController.New(self.children)
        call mc.showMenu()
    else
        if self.callback != -1
            call {self.callback}()
        endif
    endif
endfunction


"return 1 if this menuitem is a separator
function! s:prototype.isSeparator()
    return self.callback == -1 && self.children == []
endfunction


"return 1 if this menuitem is a submenu
function! s:prototype.isSubmenu()
    return self.callback == -1 && !empty(self.children)
endfunction

