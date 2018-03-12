if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})
endif


" Constructor
function! neobugger#model_var#New()
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let model = s:prototype.New(a:0 >= 1 ? a:1 : {})
    let abstract = neobugger#Model#New()
    call model.Inherit(abstract)

    call NbRuntimeSet(s:name, model)
    return model
endfunction

