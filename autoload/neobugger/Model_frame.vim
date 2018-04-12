if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})

    let s:srcfile = 'stack'
    let s:enumFrame = nelib#enum#Create(['RAWLINE', 'FRAME', 'FUNC', 'PARAM', 'FILE', 'LINE'])
endif


" Constructor
function! neobugger#Model_frame#New(...)
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let model = NbRuntimeGet(s:name)
    if !empty(model)
        return model
    endif
    let model = s:prototype.New()
    let model.frames = []
    let abstract = neobugger#Model#New(s:name)
    call model.Inherit(abstract)

    call NbRuntimeSet(s:name, model)
    return model
endfunction


" Output format for Breakpoints Window
function! s:prototype.Render() dict
    let output = "Frames:\n"
    for frame in self.frames
        let output .= '#'. frame['id']. ' '. frame['fn']. ' at '. frame['locate']. "\n"
    endfor
    return output
endfunction


function! s:prototype.Update(dir) dict
    let __func__ = 'Update'
    let fname = a:dir. s:srcfile
    silent! call s:log.info(__func__, ' file='. fname)
    if !filereadable(fname)
        return -1
    endif

    let self.frames = []
    let lines = readfile(fname)
    for line in lines
        let frame = nelib#util#str2dict('{'.line.'}')
        call add(self.frames, frame)
    endfor

    " view2window
    "silent! call s:log.info(__func__, ' vars=', string(self.vars))
    call self.UpdateView()
    call nelib#util#active_win_pop()
    return 0
endfunction

