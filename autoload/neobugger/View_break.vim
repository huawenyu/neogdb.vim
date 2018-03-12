if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})
endif


" Constructor
function! neobugger#View_break#New()
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let view = s:prototype.New(a:0 >= 1 ? a:1 : {})
    let l:title = NbConfGet(s:name, 'title')
    let abstract = neobugger#View#New(s:name, l:title, {})
    call view.Inherit(abstract)

    call NbConfSet(s:name, 'this', view)
    return view
endfunction


function! s:prototype.UpdateBreak(model) dict
    let items = a:model.Render('view', {})
    call self.display(join(items,"\n"))
endfunction


function! s:prototype.UpdateStep(breaks) dict
endfunction


function! s:prototype.UpdateCurrent(breaks) dict
endfunction


function! s:prototype.bind_mappings()
endfunction
