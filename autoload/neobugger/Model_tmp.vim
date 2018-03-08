if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})
endif


" Constructor
function! neobugger#model_var#New()
    "{
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let l:model = s:prototype.New(a:0 >= 1 ? a:1 : {})
    let l:abstract = neobugger#Model#New()
    call l:model.Inherit(l:abstract)

    return l:model
    "}
endfunction


" @mode 0 refresh-all, 1 only-change
function! s:prototype.ARefreshBreakpointSigns(mode)
    "{
    "}
endfunction

