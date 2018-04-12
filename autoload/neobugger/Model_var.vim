if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})

    let s:srcfile = 'variables'
    let s:lines = []
    let s:indent = -1
    let s:_Prototype = {
          \ 'frame': '',
          \ 'vars': {},
          \ 'vars_last': {},
          \}
endif


" Constructor
function! neobugger#Model_var#New()
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let model = NbRuntimeGet(s:name)
    if !empty(model)
        return model
    endif
    let model = s:prototype.New(deepcopy(s:_Prototype))
    let abstract = neobugger#Model#New(s:name)
    call model.Inherit(abstract)

    call NbRuntimeSet(s:name, model)
    return model
endfunction


" Get variable under cursor
function! s:prototype.get_selected() dict
  let line = getline(".")
  " Get its id - it is last in the string
  let match = matchlist(line, '.*\t\(\d\+\)$')
  let id = get(match, 1)
  if id
    let variable = g:RubyDebugger.variables.find_variable({'id' : id})
    return variable
  else
    return {}
  endif
endfunction


" @todo wilson: Forward the changed item
" Output format for Breakpoints Window
function! s:prototype.Render(...) dict
    let __func__ = 'Render'

    let s:indent = -1
    let output = ["Variables:"]
    "call self._render(self.vars, output)
    call extend(output, s:lines)
    return join(output, "\n")
endfunction


function! s:prototype.Update(dir) dict
    let __func__ = 'Update'
    let fname = a:dir. s:srcfile
    silent! call s:log.info(__func__, ' file='. fname)
    if !filereadable(fname)
        return -1
    endif
    let s:lines = readfile(fname)

    " view2window
    "silent! call s:log.info(__func__, ' vars=', string(self.vars))
    call self.UpdateView()
    return 0
endfunction


" Open breakpoint in existed/new window
function! s:prototype.open() dict
  call s:jump_to_file(self.file, self.line)
endfunction


function! s:prototype._set_sign() dict
  if has("signs")
    exe ":sign place " . self.id . " line=" . self.line . " name=breakpoint file=" . self.file
  endif
endfunction


function! s:prototype._unset_sign() dict
  if has("signs")
    exe ":sign unplace " . self.id
  endif
endfunction


" Send deleting breakpoint message to debugger, if it is run
" (e.g.: 'delete 5')
function! s:prototype._send_delete_to_debugger() dict
    let __func__ = "Model_Var._send_delete_to_debugger"

    silent! call s:log.info(__func__)
endfunction


