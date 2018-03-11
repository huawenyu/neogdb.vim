if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})
endif


" Constructor
function! neobugger#View_main#New()
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let l:view = s:prototype.New(a:0 >= 1 ? a:1 : {})
    let l:title = NbConfGet(s:name, 'title')
    let l:abstract = neobugger#View#New(s:name, l:title, {})
    call l:view.Inherit(l:abstract)

    call NbConfSet(s:name, 'this', l:view)
    return l:view
endfunction


function! s:prototype.UpdateBreak(model) dict
    call a:model.Render('sign', {})
endfunction


function! s:prototype.UpdateStep(model) dict
endfunction


function! s:prototype.UpdateCurrent(model) dict
endfunction


function! s:prototype.bind_mappings() dict
endfunction

