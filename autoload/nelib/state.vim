if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))
endif


function! nelib#state#Open(config) abort
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')
    silent! call s:log.info(l:__func__. " args=", string(a:config))

    let conf = a:config
    if type(conf) != type({})
       \ || ! has_key(conf, "Scheme")
        throw "neogdb.nelib#state#Open: config not dict or have no 'Scheme'."
    endif

    let Creator = function(conf.Scheme)
    if empty(Creator)
        throw "neogdb.nelib#state#Open: no Creator '". conf['Scheme'] ."'."
    endif
    let scheme = Creator()
    silent! call s:log.info(l:__func__. " ", conf['Scheme'])
    let g:state_ctx = nelib#state#CreateRuntime(scheme, conf)
    return g:state_ctx
endfunc


function! nelib#state#CreateRuntime(scheme, config) abort
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')
    let scheme = a:scheme
    let conf = a:config

    let ctx = {
        \ "window" : {},
        \ "state" : {},
        \ "func" : {},
        \}
    let ctx.scheme = scheme
    let ctx.conf = conf

    " Merge conf.state into scheme.state
    if has_key(conf, 'state')
        for [k,v] in items(conf.state)
            if has_key(scheme.state, k)
                call extend(scheme.state[k], v)
            else
                let scheme.state[k] = v
            endif
        endfor
        unlet conf['state']
    endif

    " Merge conf.window into scheme.window
    if has_key(conf, 'window')
        for conf_win in conf.window
            let found = 0
            for sch_win in scheme.window
                if conf_win.name ==# sch_win.name
                    let found = 1
                    for [k,v] in items(conf_win)
                        let sch_win[k] = v
                    endfor
                endif
            endfor
            if !found
                call add(scheme.window, conf_win)
            endif
        endfor
        unlet conf['window']
    endif

    " Merge conf into scheme
    call extend(scheme, conf)

    " Load state
    for [k,v] in items(scheme.state)
        let patterns = []
        for i in v
            let matches = i.match
            if type(matches) != type([])
                throw printf("neogdb.nelib#state#CreateRuntime: state '%s' match '%s' should be list"
                        \ ,k, string(matches))
            endif
            for match in matches
                call add(patterns, [ match, 'on_call'
                            \ , [i.hint, i.window, i.action, i.arg0] ])
            endfor
        endfor

        let state = nelib#expect#State(k, patterns)
        let ctx.state[k] = state

        " self is termopen's target, here is the window, not state itself
        " @match1: [i.window, i.action, i.arg0]
        function! state.on_call(...)
            call call(self._ctx['on_call'], a:000, self)
        endfunc

        unlet k v
    endfor


    " Load window
    " Create new tab as FSM's view
    silent! call s:log.info("Creating the 'main' window ...")
    tabnew | silent! b2
    let ctx._tab = tabpagenr()
    silent! ball 1
    let ctx._wid_main = win_getid()
    silent! call s:log.info("The 'main' window-id=", ctx._wid_main)

    let windows = scheme.window
    for conf_win in windows
        if !conf_win.status
            continue
        endif

        if has_key(ctx.window, conf_win.name)
            throw printf("neogdb.nelib#state#CreateRuntime: window duplicate '%s'"
                        \ , conf_win.name)
        endif
        let window = {}
        let ctx.window[conf_win.name] = window
        let window._name = conf_win.name
        if !has_key(ctx.state, conf_win.state)
            throw printf("neogdb.nelib#state#CreateRuntime: window ''%s' initstate '%s' not exist"
                        \ , conf_win.name, conf_win.state)
        endif
        let state0 = copy(ctx.state[conf_win.state])
        let window._state = state0
        let state0._window = window

        let target = nelib#expect#Parser(state0, window)
        let window._target = target
        let window._ctx = ctx

        " layout
        let layout_list = []
        if has_key(conf, conf_win.layout[0])
            let layout_list = conf[conf_win.layout[0]]
        else
            let layout_list = conf_win.layout[1:100]
        endif

        " cmd
        if has_key(conf, conf_win.cmd[0])
            let cmdstr = join(conf[conf_win.cmd[0]])
        else
            let cmdstr = conf_win.cmd[1]
        endif

        " if no layout, only start job, no window
        if empty(layout_list)
            let window._wid = 0
            let window._bufnr = 0
            let argv = ['bash']
            if !empty(cmdstr)
                let argv += ['-c', cmdstr]
            endif

            let window._client_id = jobstart(cmdstr, target)
            silent! call s:log.info(l:__func__, " jobstart[". string(window._client_id). "]: ", cmdstr)
        else
            for layout in layout_list
                exec layout
            endfor
            let window._wid = win_getid()

            enew | let window._client_id = termopen(cmdstr, target)
            let window._bufnr = bufnr('%')
            " Scroll to the end of terminal output
            normal G
            silent! call s:log.info(l:__func__, " termopen:", cmdstr)
        endif
    endfor

    " Backto main windows
    if win_gotoid(ctx._wid_main) == 1
        let ctx._jump_window = win_id2win(ctx._wid_main)
        stopinsert
    else
        silent! call s:log.info("Backto 'main' window fail with window-id=", ctx._wid_main)
    endif


    " self is termopen's target, here is the window, not ctx itself
    " @match1: [i.window, i.action, i.arg0]
    function! ctx.on_call(match1, ...)
        let l:__func__ = "ctx.on_call"
        let matched = a:match1
        silent! call s:log.info("matched: ", matched)
        "silent! call s:log.trace("self=", string(self))

        if empty(matched[2]) || empty(matched[3])
            throw "neogdb.nelib#state#CreateRuntime: have no 'action','arg0' with " . string(matched)
        endif

        let window = self
        if !empty(matched[1])
           \ && has_key(ctx.window, matched[1])
            let window = ctx.window[matched[1]]
        endif

        try
            if matched[2] ==# 'call'
                let scheme = g:state_ctx.scheme
                let l:funcname = matched[3]
                if has_key(scheme, l:funcname)
                    let l:funcargs = []
                    call add(l:funcargs, l:funcname)
                    call extend(l:funcargs, a:000)
                    silent! call s:log.info(l:__func__, "func=", l:funcname,
                                \" args=", string(l:funcargs))
                    call call(scheme[l:funcname], l:funcargs, scheme)
                else
                    silent! call s:log.info("Scheme '", scheme.name,
                                \"' call function '", l:funcname, "' not exist")
                endif
            elseif matched[2] ==# 'send'
                let str = call("printf", [l:funcname] + a:000)
                call jobsend(window._client_id, str."\<cr>")
            elseif matched[2] ==# 'switch'
                call state#Switch(window._name, l:funcname, 0)
            elseif matched[2] ==# 'push'
                call state#Switch(window._name, l:funcname, 1)
            elseif matched[2] ==# 'pop'
                call state#Switch(window._name, l:funcname, 2)
            endif
        catch
            silent! call s:log.info(matched, " trigger ", v:exception)
        endtry
    endfunc


    return ctx
endfunc


" @mode 0 switch, 1 push, 2 pop
function! state#Switch(win_name, state_name, mode) abort
    if !exists('g:state_ctx')
        throw 'stateRuntime is not running'
    endif
    if !has_key(g:state_ctx, 'window') || !has_key(g:state_ctx, 'state')
        throw 'stateRuntime have no windows or states'
    endif
    if !has_key(g:state_ctx.window, a:win_name)
        throw 'stateRuntime have no window=' . a:win_name
    endif
    if !has_key(g:state_ctx.state, a:state_name)
        throw 'stateRuntime have no state=' . a:state_name
    endif

    silent! call s:log.debug("State => ", a:state_name)
    if a:mode == 0
        call g:state_ctx.window[a:win_name]._target._parser.switch(g:state_ctx.state[a:state_name])
        let g:state_ctx.window[a:win_name]._state = g:state_ctx.window[a:win_name]._target._parser._stack[-1]
    elseif a:mode == 1
        call g:state_ctx.window[a:win_name]._target._parser.push(g:state_ctx.state[a:state_name])
        let g:state_ctx.window[a:win_name]._state = g:state_ctx.window[a:win_name]._target._parser._stack[-1]
    elseif a:mode == 2
        call g:state_ctx.window[a:win_name]._target._parser.pop()
        let g:state_ctx.window[a:win_name]._state = g:state_ctx.window[a:win_name]._target._parser._stack[-1]
    endif
endfunc


function! s:__fini__()
    if exists("s:init")
        return
    endif

endfunc
call s:__fini__()
let s:init = 1

