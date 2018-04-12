if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})

    let s:_Prototype = {
                \ 'dashboard': 'stack',
                \}
endif


" Constructor
function! neobugger#View_frame#New()
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let view = s:prototype.New(deepcopy(s:_Prototype))
    let l:title = NbConfGet(s:name, 'title')
    let abstract = neobugger#View#New(s:name, l:title, {})
    call view.Inherit(abstract)

    call NbConfSet(s:name, 'this', view)
    return view
endfunction


function! s:prototype.bind_mappings()
    nnoremap <buffer> <2-leftmouse> :call <SID>window_variables_activate_node()<cr>
    nnoremap <buffer> o :call <SID>window_variables_activate_node()<cr>"
endfunction


function! s:prototype.Update(model) dict
    let __func__ = 'Update'
    silent! call s:log.info(__func__, '()')

    call self.display(a:model.Render())
endfunction


" TODO: Is there some way to call s:WindowVariables.activate_node from mapping
" command?
" Expand/collapse variable under cursor
function! s:window_variables_activate_node()
    let variable = s:Var.get_selected()
    if variable != {} && variable.type == "VarParent"
        if variable.is_open
            call variable.close()
        else
            call variable.open()
        endif
    endif
    call g:RubyDebugger.queue.execute()
endfunction


" Add syntax highlighting
function! s:prototype.setup_syntax_highlighting()
    execute "syn match rdebugTitle #" . self.title . "#"

    syn match rdebugPart #[| `]\+#
    syn match rdebugPartFile #[| `]\+-# contains=rdebugPart nextgroup=rdebugChild contained
    syn match rdebugChild #.\{-}\t# nextgroup=rdebugType contained

    syn match rdebugClosable #[| `]\+\~# contains=rdebugPart nextgroup=rdebugParent contained
    syn match rdebugOpenable #[| `]\++# contains=rdebugPart nextgroup=rdebugParent contained
    syn match rdebugParent #.\{-}\t# nextgroup=rdebugType contained

    syn match rdebugType #.\{-}\t# nextgroup=rdebugValue contained
    syn match rdebugValue #.*\t#he=e-1 nextgroup=rdebugId contained
    syn match rdebugId #.*# contained

    syn match rdebugParentLine '[| `]\+[+\~].*' contains=rdebugClosable,rdebugOpenable transparent
    syn match rdebugChildLine '[| `]\+-.*' contains=rdebugPartFile transparent

    hi def link rdebugTitle Identifier
    hi def link rdebugClosable Type
    hi def link rdebugOpenable Title
    hi def link rdebugPart Special
    hi def link rdebugPartFile Type
    hi def link rdebugChild Normal
    hi def link rdebugParent Directory
    hi def link rdebugType Type
    hi def link rdebugValue Special
    hi def link rdebugId Ignore
endfunction

