if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})

    " https://technotales.wordpress.com/2010/04/29/vim-splits-a-guide-to-doing-exactly-what-you-want/
    let s:_Prototype = {
                \ 'next_buffer_number': 1,
                \ 'size': 10,
                \ 'tabnr': -1,
                \ 'wid': -1,
                \ 'position': ['botright'],
                \ 'is_job': 0,
                \}
endif


" Constructor
function! neobugger#View#New(name, title, options)
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')
    silent! call s:log.info(__func__, '(', a:name, ')')

    let view = s:prototype.New(deepcopy(s:_Prototype))

    let view.name = a:name
    let view.title = a:title
    let view['position'] = NbConfGet(a:name, 'layout')

    if has_key(a:options, 'is_job')
        let view.is_job = a:options.is_job
    endif

    return view
endfunction


function! neobugger#View#Toggle(name)
    let __func__ = 'neobugger#View#Toggle'
    silent! call s:log.info(__func__, '(', a:name, ')')

    let this = NbConfGet(a:name, 'this', {})
    if !empty(this) && this.is_open()
        call this.close()
        call NbConfSet(a:name, 'this', {})
        return {}
    else
        let Fview_new = function('neobugger#'. a:name. '#New')
        let this = Fview_new()
        call this.open()
        let l:bufnum = NbConfGet(a:name, 'bufnr')
        if l:bufnum >=0
            silent! call s:log.info(__func__, 'backto buffer ', l:bufnum)
            execute 'b '. l:bufnum
        endif
        call NbConfSet(a:name, 'this', this)
        return this
    endif
endfunction


function! neobugger#View#IsOpen(name)
    let __func__ = 'neobugger#View#IsOpen'
    silent! call s:log.info(__func__, '(', a:name, ')')

    let this = NbConfGet(a:name, 'this', {})
    if !empty(this) && this.is_open()
        return 1
    endif
    return 0
endfunction


" Clear all data from window
function! s:prototype.clear() dict
    silent 1,$delete _
endfunction


" Close window
function! s:prototype.close() dict
    let __func__ = 'close'
    silent! call s:log.info(__func__, '(', self.name, ')')

    if !self.is_open()
        throw s:script. ": Window " . self.name . " is not open"
    endif

    let obs = NbConfGet('View_main', 'observe')
    for nameObs in obs
        let obs = NbRuntimeGet(nameObs)
        if !empty(obs)
            call obs.ObserverRemove(self.name)
        endif
    endfor

    if winnr("$") != 1
        call self.focus()
        close
        exe "wincmd p"
        stopinsert
        let self.wid = -1
    else
        " If this is only one window, just quit
        :q
    endif
    call s:log.info("Closed window with name: " . self.name)
endfunction


" Display data to the window
function! s:prototype.display(data) dict
    let __func__ = 'display'
    "silent! call s:log.info(__func__, '(', self.name, ')')
    call self.focus()
    setlocal modifiable

    let current_line = line(".")
    let current_column = col(".")
    let top_line = line("w0")

    call self.clear()

    call self._insert_data(a:data)
    call self._restore_view(top_line, current_line, current_column)

    setlocal nomodifiable
    "call s:log.info("Complete displaying data in window with name: " . self.name)
endfunction


function! s:prototype.focus() dict
    let __func__ = 'focus'
    "silent! call s:log.info(__func__, '(', self.name, ')')
    call win_gotoid(self.wid)
endfunction


function! s:prototype.is_open() dict
    return win_id2win(self.wid) != 0
endfunction

" Open window and display data (stolen from NERDTree)
function! s:prototype.open() dict
    let __func__ = 'open'
    silent! call s:log.info(__func__, '(', self.name, ')')

    let main_wid = NbConfGet('View_main', 'wid')
    if self.is_open()
        return
    endif

    " create the window
    call s:log.info(s:script. ':'. __func__. '('. self.name.') :'. string(self.position))
    if type(self.position) == type([])
        if win_gotoid(main_wid) == 1
            for cmd in self.position
                silent exec cmd
            endfor
            let self.wid = win_getid()
            let self.tabnr = tabpagenr()
            call NbConfSet(self.name, 'wid', self.wid)
            call NbConfSet(self.name, 'tabnr', self.tabnr)

            let obs = NbConfGet(self.name, 'observe')
            for nameObs in obs
                let ob = NbRuntimeGet(nameObs)
                if !empty(ob)
                    call ob.ObserverAppend(self.name, self)
                endif
            endfor
        else
            call s:log.info(s:script. ':'. __func__. '('. self.name.')  goto View_main.wid='. string(main_wid). ' fail.')
        endif
    else
        silent exec self.position . ' ' . self.size . ' new'
        let self.wid = win_getid()
    endif

    if !self._exist_for_tab()
        call self._set_buf_name(self._next_buffer_name())
        silent! exec "edit " . self._buf_name()

        if has_key(self, 'bind_mappings')
            call self.bind_mappings()
        endif
    else
        " Or just jump to opened buffer
        silent! exec "buffer " . self._buf_name()
    endif

    " set buffer options
    if !self.is_job
        setlocal winfixheight
        setlocal noswapfile
        setlocal buftype=nofile
        setlocal nowrap
        setlocal foldcolumn=0
        setlocal nobuflisted
        setlocal nospell
        setlocal nolist
        iabc <buffer>
        setlocal cursorline
        "setfiletype viewer_window
        setfiletype c
        call s:log.info("Opened buffer with name: " . self.name)

        if has_key(self, 'setup_syntax_highlighting') && has("syntax") && exists("g:syntax_on") && !has("syntax_items")
            call self.setup_syntax_highlighting()
        endif

        call self.display("[Empty]\n")
        if win_gotoid(main_wid) == 1
            stopinsert
        endif
    endif
endfunction


" Open/close window
function! s:prototype.toggle() dict
    call s:log.info("Toggling window with name: " . self.name)
    if self._exist_for_tab() && self.is_open()
        call self.close()
    else
        call self.open()
    end
endfunction


function! s:prototype.Update(type, model) dict
    let __func__ = 'Update'
    silent! call s:log.info(__func__, '(type='.a:type.' name='.a:model.name.')')

    if a:type ==# 'break'
        call self.UpdateBreak(a:model)
    elseif a:type ==# 'step'
        call self.UpdateStep(a:model)
    elseif a:type ==# 'var'
        call self.UpdateVar(a:model)
    elseif a:type ==# 'frame'
        call self.UpdateFrame(a:model)
    elseif a:type ==# 'current'
        call self.UpdateCurrent(a:model)
    endif
endfunction


function! s:prototype.UpdateBreak(model) dict
    let __func__ = 'UpdateBreak'
    silent! call s:log.warn(__func__, ' view='. string(self))
    throw s:script. ': '. self.name .' must implement '. __func__
endfunction


function! s:prototype.UpdateStep(model) dict
    let __func__ = 'UpdateStep'
    silent! call s:log.warn(__func__, ' view='. string(self))
    throw s:script. ': '. self.name .' must implement '. __func__
endfunction


function! s:prototype.UpdateCurrent(model) dict
    let __func__ = 'UpdateCurrent'
    silent! call s:log.warn(__func__, ' view='. string(self))
    throw s:script. ': '. self.name .' must implement '. __func__
endfunction


function! s:prototype.UpdateVar(model) dict
    let __func__ = 'UpdateVar'
    silent! call s:log.warn(__func__, ' view='. string(self))
    throw s:script. ': '. self.name .' must implement '. __func__
endfunction


function! s:prototype.UpdateFrame(model) dict
    let __func__ = 'UpdateFrame'
    silent! call s:log.warn(__func__, ' view='. string(self))
    throw s:script. ': '. self.name .' must implement '. __func__
endfunction


" Return buffer name, that is stored in tab variable
function! s:prototype._buf_name() dict
    return t:window_{self.name}_buf_name
endfunction


" Return 1 if the window exists in current tab
function! s:prototype._exist_for_tab() dict
    return exists("t:window_" . self.name . "_buf_name")
endfunction


" Insert data to the window
function! s:prototype._insert_data(data) dict
    let old_p = @p
    " Put data to the register and then show it by 'put' command
    let @p = a:data
    silent exe "normal \"pP"
    let @p = old_p
    "call s:log.info("Inserted data to window with name: " . self.name)
endfunction


" Calculate correct name for the window
function! s:prototype._next_buffer_name() dict
    let name = self.name . self.next_buffer_number
    let self.next_buffer_number += 1
    return name
endfunction


" Restore the view
function! s:prototype._restore_view(top_line, current_line, current_column) dict
    let old_scrolloff=&scrolloff
    let &scrolloff=0
    call cursor(a:top_line, 1)
    normal! zt
    call cursor(a:current_line, a:current_column)
    let &scrolloff = old_scrolloff
    "call s:log.info("Restored view of window with name: " . self.name)
endfunction


function! s:prototype._set_buf_name(name) dict
    let t:window_{self.name}_buf_name = a:name
endfunction

