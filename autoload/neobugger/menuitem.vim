if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)

    let s:prototype = tlib#Object#New({
                \ '_class': ['menuItem'],
                \ })
endif


" Constructor
function! neobugger#menuitem#New(options)
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let newMenuItem = s:prototype.New(a:0 >= 1 ? a:1 : {})

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


function! neobugger#menuitem#NewSeparator(options)
    let standard_options = { 'text': '--------------------',
                \ 'shortcut': -1,
                \ 'callback': -1 }
    let options = extend(a:options, standard_options, "force")

    return neobugger#menuitem#New(options)
endfunction


function! neobugger#menuitem#NewSubmenu(options)
    let standard_options = { 'callback': -1 }
    let options = extend(a:options, standard_options, "force")

    return neobugger#menuitem#New(options)
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

