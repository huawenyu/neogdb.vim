if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})

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


" Input Sample:
"
" > #0  foo (e=0x7fc9333516a0, ev=<optimized out>) at /full/path/of/foo.c:65
" > #1  0x00000000004348d0 in bar (argc=3, argv=0x7fff6c42b768) at /full/path/of/bar.c:24
"
" @return current frame name
function! s:prototype.ParseFrame(framefile) dict
    let __func__ = "ParseFrame"
    silent! call s:log.info(__func__, '()')

    let self.frames = []
    if !filereadable(a:framefile)
        return "Error"
    endif

    let frame0 = "Null"
    let matches = []
    let l:lines = readfile(a:framefile)
    for l:line in l:lines
        "" RunScript
        "echomsg string(matchlist('#0  foo (e=0x7fc9333516a0, ev=<optimized out>) at /full/path/of/foo.c:65'
        "      \, '\v^#(\d+)  (.*) \((.*)\) at (.*):(\d+)$'))
        "echomsg string(matchlist('#2  0x00000000004348d0 in bar (argc=3, argv=0x7fff6c42b768) at /full/path/of/bar.c:24'
        "      \, '\v^#(\d+)  (.*) in (.*) \((.*)\) at (.*):(\d+)$'))
        if frame0 == "Null"
            let matches = matchlist(l:line, '\v^#(\d+)  (.*) \((.*)\) at (.*):(\d+)$')
            if len(matches) > 5
                let frame0 = matches[2]
                call add(self.frames, {
                            \ 'id': matches[1],
                            \ 'func': matches[2],
                            \ 'param': matches[3],
                            \ 'file': matches[4],
                            \ 'line': matches[5],
                            \})
            endif
        else
            let matches = matchlist(l:line, '\v^#(\d+)  (.*) in (.*) \((.*)\) at (.*):(\d+)$')
            if len(matches) > 6
                call add(self.frames, {
                            \ 'id': matches[1],
                            \ 'func': matches[3],
                            \ 'param': matches[4],
                            \ 'file': matches[5],
                            \ 'line': matches[6],
                            \})
            endif
        endif
        "silent! call s:log.info(__func__, ' line=', l:line, ' matches=', string(matches))
    endfor

    " view2window
    "silent! call s:log.info(__func__, ' frames=', string(self.frames))
    call self.ObserverUpdateAll("frame")
    return frame0
endfunction


" Output format for Breakpoints Window
function! s:prototype.Render() dict
    let output = "Frames:\n"
    for frame in self.frames
        let l:file = tlib#file#Relative(frame.file, getcwd())
        let output .= '#'. frame.id. ' '. frame.func. '('. frame.param. ')  at '. l:file. ':'.frame.line. "\n"
    endfor
    return output
endfunction

