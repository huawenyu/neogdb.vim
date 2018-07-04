if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))
endif


function! nelib#state#Open(config) abort
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')
    silent! call s:log.info(__func__. " args=", string(a:config))

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
    silent! call s:log.info(__func__. " ", conf['Scheme'])
    let g:state_ctx = nelib#state#CreateRuntime(scheme, conf)
    return g:state_ctx
endfunc


function! nelib#state#CreateRuntime(scheme, config) abort
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')
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
                throw printf("%s: state '%s' match '%s' should be list"
                        \ , __func__, k, string(matches))
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


    " @todo wilson: use view
    " Load window
    " Create new tab as FSM's view
    tabnew | silent! b1
    let ctx._tab = tabpagenr()
    silent! ball 1
    let ctx._wid_main = win_getid()
    let viewMain = neobugger#View_main#New()
    let viewMain.wid = ctx._wid_main
    let viewMain.tabnr = ctx._tab
    call NbConfSet('View_main', 'wid', viewMain.wid)

    "let bufnr = winbufnr(0)
    "let viewMain = neobugger#View_main#New()
    "call viewMain.open()
    "exec 'silent! b'. bufnr
    "let ctx._tab = viewMain.tabnr
    "let ctx._wid_main = viewMain.wid

    silent! call s:log.info("Creating the 'main' window.wid=". viewMain.wid)

    let windows = scheme.window
    for conf_win in windows
        if !conf_win.status
            continue
        endif

        if has_key(ctx.window, conf_win.name)
            throw printf("%s: window duplicate '%s'"
                        \ , __func__, conf_win.name)
        endif

        silent! call s:log.info("Creating the window: ". conf_win.name. ' view='.conf_win.view)
        let window = {}
        let ctx.window[conf_win.name] = window
        let window._name = conf_win.name
        if !has_key(ctx.state, conf_win.state)
            throw printf("%s: window ''%s' initstate '%s' not exist"
                        \ , __func__, conf_win.name, conf_win.state)
        endif
        let state0 = copy(ctx.state[conf_win.state])
        let window._state = state0
        let state0._window = window

        let target = nelib#expect#Parser(state0, window)
        let window._target = target
        let window._ctx = ctx

        " cmd
        if has_key(conf, conf_win.cmd[0])
            let cmdstr = join(conf[conf_win.cmd[0]])
        else
            let cmdstr = conf_win.cmd[1]
        endif

        " window as view
        let viewName = conf_win.view
        let view = NbConfGet(viewName, 'this')
        if empty(view)
            let view = neobugger#View#New(viewName, "instanceOf".viewName, {'is_job': 1})
            call NbConfSet(viewName, 'this', view)
        endif
        if !empty(view)
            silent! call s:log.info(__func__, " termopen:", cmdstr)

            call view.open()
            let window._wid = win_getid()
            enew | let window._client_id = termopen(cmdstr, target)
            let window._bufnr = bufnr('%')
            let confStatus = NbConfGet(viewName, 'status')
            if empty(confStatus)
                call view.close()
            else
                " Scroll to the end of terminal output
                normal G
            endif
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
        let __func__ = "ctx.on_call"
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
                let funcname = matched[3]
                if has_key(scheme, funcname)
                    let funcargs = []
                    call add(funcargs, funcname)
                    call extend(funcargs, a:000)
                    silent! call s:log.info(__func__, "func=", funcname,
                                \" args=", string(funcargs))
                    call call(scheme[funcname], funcargs, scheme)
                else
                    silent! call s:log.info("Scheme '", scheme.name,
                                \"' call function '", funcname, "' not exist")
                endif
            elseif matched[2] ==# 'send'
                let str = call("printf", [funcname] + a:000)
                call jobsend(window._client_id, str."\<cr>")
            elseif matched[2] ==# 'switch'
                call state#Switch(window._name, funcname, 0)
            elseif matched[2] ==# 'push'
                call state#Switch(window._name, funcname, 1)
            elseif matched[2] ==# 'pop'
                call state#Switch(window._name, funcname, 2)
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

    if a:mode == 0
        silent! call s:log.debug("State => ", a:state_name)
        call g:state_ctx.window[a:win_name]._target._parser.switch(g:state_ctx.state[a:state_name])
        let g:state_ctx.window[a:win_name]._state = g:state_ctx.window[a:win_name]._target._parser._stack[-1]
    elseif a:mode == 1
        silent! call s:log.debug("State push ", a:state_name)
        call g:state_ctx.window[a:win_name]._target._parser.push(g:state_ctx.state[a:state_name])
        let g:state_ctx.window[a:win_name]._state = g:state_ctx.window[a:win_name]._target._parser._stack[-1]
    elseif a:mode == 2
        silent! call s:log.debug("State pop ", a:state_name)
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

