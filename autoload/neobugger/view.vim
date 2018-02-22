if !exists("s:script")
    let s:script = expand('<sfile>:t')
    silent! let s:log = logger#getLogger(s:script)

    let s:breakpoints = {}
    let s:prototype = tlib#Object#New({
                \ '_class': ['_View'],
                \ })
endif


" Constructor
function! neobugger#view#New(name, title)
    "{
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let l:view = s:prototype.New(a:0 >= 1 ? a:1 : {})

    let l:view.name = a:name
    let l:view.title = a:title

    let l:view['next_buffer_number'] = 1
    let l:view['position'] = 'botright'
    let l:view['size'] = 10
    return l:view
    "}
endfunction


" Clear all data from window
function! s:prototype.clear() dict
  silent 1,$delete _
endfunction


" Close window
function! s:prototype.close() dict
  if !self.is_open()
    throw s:script. ": Window " . self.name . " is not open"
  endif

  if winnr("$") != 1
    call self.focus()
    close
    exe "wincmd p"
  else
    " If this is only one window, just quit
    :q
  endif
  call s:log.info("Closed window with name: " . self.name)
endfunction


" Get window number
function! s:prototype.get_number() dict
  if self._exist_for_tab()
    return bufwinnr(self._buf_name())
  else
    return -1
  endif
endfunction


" Display data to the window
function! s:prototype.display(data) dict
  call s:log.info("Start displaying data in window with name: " . self.name)
  call self.focus()
  setlocal modifiable

  let current_line = line(".")
  let current_column = col(".")
  let top_line = line("w0")

  call self.clear()

  call self._insert_data(a:data)
  call self._restore_view(top_line, current_line, current_column)

  setlocal nomodifiable
  call s:log.info("Complete displaying data in window with name: " . self.name)
endfunction


" Put cursor to the window
function! s:prototype.focus() dict
  exe self.get_number() . " wincmd w"
  call s:log.info("Set focus to window with name: " . self.name)
endfunction


" Return 1 if window is opened
function! s:prototype.is_open() dict
    return self.get_number() != -1
endfunction


" Open window and display data (stolen from NERDTree)
function! s:prototype.open() dict
    if !self.is_open()
      " create the window
      silent exec self.position . ' ' . self.size . ' new'

      if !self._exist_for_tab()
        " If the window is not opened/exists, create new
        call self._set_buf_name(self._next_buffer_name())
        silent! exec "edit " . self._buf_name()
        " This function does not exist in Window class and should be declared in
        " descendants
        call self.bind_mappings()
      else
        " Or just jump to opened buffer
        silent! exec "buffer " . self._buf_name()
      endif

      " set buffer options
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
      setfiletype viewer_window
      call s:log.info("Opened window with name: " . self.name)
    endif

    if has("syntax") && exists("g:syntax_on") && !has("syntax_items")
      call self.setup_syntax_highlighting()
    endif

    call self.display("[Empty]\n")
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


" ** Private methods


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
  call s:log.info("Inserted data to window with name: " . self.name)
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
  call s:log.info("Restored view of window with name: " . self.name)
endfunction


function! s:prototype._set_buf_name(name) dict
  let t:window_{self.name}_buf_name = a:name
endfunction


" *** Window class (end)
