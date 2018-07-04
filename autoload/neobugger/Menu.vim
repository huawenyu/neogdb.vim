" Code from nerdtree
"
if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})
endif


" Constructor
function! neobugger#Menu#New(title, ...)
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let menu = s:prototype.New(a:0 >= 1 ? a:1 : {})
    let menu.menuItems = []
    let menu.title = a:title

    "if a:menuItems[0].isSeparator()
    "    let menu.menuItems = a:menuItems[1:-1]
    "else
    "    let menu.menuItems = a:menuItems
    "endif
    return menu
endfunction


" @return the new added menuItem
function! s:prototype.addMenuItem(menuItem) dict
    call add(self.menuItems, a:menuItem)
    return a:menuItem
endfunction


"Get all top level menu items that are currently enabled
function! s:prototype.allEnabled()
    let toReturn = []
    for item in self.menuItems
        if item.enabled()
            call add(toReturn, item)
        endif
    endfor
    return toReturn
endfunction


function! s:prototype.showMenu() dict
    call self._saveOptions()

    try
        let self.selection = 0

        let done = 0
        while !done
            redraw!
            call self._echoPrompt()
            let key = nr2char(getchar())
            silent! call s:log.info("menu get input shortcut-key: [". key. ']')
            let done = self._handleKeypress(key)
        endwhile
    finally
        call self._restoreOptions()
    endtry

    if self.selection != -1
        let m = self._current()
        call m.execute()
    endif
endfunction


function! s:prototype._echoPrompt()
    echo self.title . ':'
    for i in range(0, len(self.menuItems)-1)
        if self.selection == i
            echo "> " . self.menuItems[i].text
        else
            echo "  " . self.menuItems[i].text
        endif
      endfor
    echo 'Choice (Keys j/k/<Enter>/<ESC> or shortcut): '
endfunction


function! s:prototype._current()
    return self.menuItems[self.selection]
endfunction


"change the selection (if appropriate) and return 1 if the user has made
"their choice, 0 otherwise
function! s:prototype._handleKeypress(key)
    if a:key == 'j'
        call self._cursorDown()
    elseif a:key == 'k'
        call self._cursorUp()
    elseif a:key == nr2char(27) "escape
        let self.selection = -1
        return 1
    elseif a:key == "\r" || a:key == "\n" "enter and ctrl-j
        return 1
    else
        let index = self._nextIndexFor(a:key)
        if index != -1
            let self.selection = index
            if len(self._allIndexesFor(a:key)) == 1
                return 1
            endif
        endif
    endif

    return 0
endfunction


"get indexes to all menu items with the given shortcut
function! s:prototype._allIndexesFor(shortcut)
    let toReturn = []

    for i in range(0, len(self.menuItems)-1)
        if self.menuItems[i].shortcut ==# a:shortcut
            call add(toReturn, i)
        endif
    endfor

    return toReturn
endfunction


"get the index to the next menu item with the given shortcut, starts from the
"current cursor location and wraps around to the top again if need be
function! s:prototype._nextIndexFor(shortcut)
    for i in range(self.selection+1, len(self.menuItems)-1)
        if self.menuItems[i].shortcut ==# a:shortcut
            return i
        endif
    endfor

    for i in range(0, self.selection)
        if self.menuItems[i].shortcut ==# a:shortcut
            return i
        endif
    endfor

    return -1
endfunction


"sets &cmdheight to whatever is needed to display the menu
function! s:prototype._setCmdheight()
    let &cmdheight = len(self.menuItems) + 3
endfunction


"set any vim options that are required to make the menu work (saving their old
"values)
function! s:prototype._saveOptions()
    let self._oldLazyredraw = &lazyredraw
    let self._oldCmdheight = &cmdheight
    set nolazyredraw
    call self._setCmdheight()
endfunction


"restore the options we saved in _saveOptions()
function! s:prototype._restoreOptions()
    let &cmdheight = self._oldCmdheight
    let &lazyredraw = self._oldLazyredraw
endfunction


"move the cursor to the next menu item, skipping separators
function! s:prototype._cursorDown()
    let done = 0
    while !done
        if self.selection < len(self.menuItems)-1
            let self.selection += 1
        else
            let self.selection = 0
        endif

        if !self._current().isSeparator()
            let done = 1
        endif
    endwhile
endfunction


"move the cursor to the previous menu item, skipping separators
function! s:prototype._cursorUp()
    let done = 0
    while !done
        if self.selection > 0
            let self.selection -= 1
        else
            let self.selection = len(self.menuItems)-1
        endif

        if !self._current().isSeparator()
            let done = 1
        endif
    endwhile
endfunction

