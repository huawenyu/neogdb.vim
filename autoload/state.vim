
function! s:__init__()
    if exists("s:init")
        return
    endif
    let s:path = expand('<sfile>:p')

endfunc
call s:__init__()

function! s:Debug(msg)
    if &verbose
        echomsg s:path. ": ". string(a:msg)
    endif
endfunc


function! state#Open(config) abort
    let conf = a:config
    if type(conf) != type({})
       \ || ! has_key(conf, "scheme")
        throw "neogdb.state#Open: config not dict or have no 'scheme'."
    endif

    let Creator = function(conf.scheme)
    if empty(Creator)
        throw "neogdb.state#Open: no Creator '". conf['scheme'] ."'."
    endif
    let scheme = Creator()
    call s:Debug("Open". conf['scheme'])
    call state#CreateRuntime(scheme, conf)
endfunc


function! state#CreateRuntime(scheme, config) abort
    let scheme = a:scheme
    let conf = a:config

    let ctx = {
        \ "window" : {},
        \ "state" : {},
        \ "func" : {},
        \}
    let ctx.scheme = scheme
    let ctx.conf = conf
    let g:state_ctx = ctx

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
        call extend(scheme.window, conf.window)
        unlet conf['window']
    endif

    " Merge conf into scheme
    call extend(scheme, conf)

    " Load state
    for [k,v] in items(scheme.state)
        let patterns = []
        for i in v
            call add(patterns, [ i.match, 'on_call',
                        \ [i.window, i.action, i.arg0] ])
        endfor

        let state = expect#State(k, patterns)
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
    tabnew
    let ctx._tab = tabpagenr()
    silent! ball 1
    let ctx._win_main = win_getid()

    let windows = scheme.window
    for conf_win in windows
        if has_key(ctx.window, conf_win.name)
            throw printf("neogdb.state#CreateRuntime: window duplicate '%s'",
                        \ conf_win.name)
        endif
        let window = {}
        let ctx.window[conf_win.name] = window
        let window._name = conf_win.name
        if !has_key(ctx.state, conf_win.state)
            throw printf("neogdb.state#CreateRuntime: window ''%s' initstate '%s' not exist",
                        \ conf_win.name, conf_win.state)
        endif
        let state0 = copy(ctx.state[conf_win.state])
        let window._state = state0
        let state0._window = window

        let target = expect#Parser(state0, window)
        let window._target = target
        let window._ctx = ctx

        if has_key(conf, conf_win.layout[0])
            exec conf[conf_win.layout[0]]
        else
            exec conf_win.layout[1]
        endif
        let window._wid = win_getid()

        if has_key(conf, conf_win.cmd[0])
            enew | let window._client_id = termopen(conf[conf_win.cmd[0]], target)
        else
            enew | let window._client_id = termopen(conf_win.cmd[1], target)
        endif
        let window._bufnr = bufnr('%')
    endfor

    " Backto main windows
    if win_gotoid(ctx._win_main) == 1
        let ctx._jump_window = win_id2win(ctx._win_main)
        stopinsert
    endif


    " self is termopen's target, here is the window, not ctx itself
    " @match1: [i.window, i.action, i.arg0]
    function! ctx.on_call(match1, ...)
        let matched = a:match1
        call s:Debug(matched)

        if empty(matched[1]) || empty(matched[2])
            throw "neogdb.state#CreateRuntime: have no 'action','arg0' with " . string(matched)
        endif

        let window = self
        if !empty(matched[0])
           \ && has_key(ctx.window, matched[0])
            let window = ctx.window[matched[0]]
        endif

        try
            if matched[1] ==# 'call'
                let scheme = g:state_ctx.scheme
                if has_key(scheme, matched[2])
                    call call(scheme[matched[2]], a:000, window)
                else
                    call s:Debug(printf("Scheme '%s' call function '%s' not exist",
                                \ scheme.name, matched[2]))
                endif
            elseif matched[1] ==# 'send'
                let str = call("printf", [matched[2]] + a:000)
                call jobsend(window._client_id, str."\<cr>")
            elseif matched[1] ==# 'switch'
                if has_key(ctx.state, matched[2])
                    call window._target._parser.switch(ctx.state[matched[2]])
                else
                    call s:Debug(printf("Window '%s' switch State '%s' not exist",
                                \ window._name, matched[2]))
                endif
            elseif matched[1] ==# 'push'
                if has_key(ctx.state, matched[2])
                    call window._target._parser.push(ctx.state[matched[2]])
                else
                    call s:Debug(printf("Window '%s' push State '%s' not exist",
                                \ window._name, matched[2]))
                endif
            elseif matched[1] ==# 'pop'
                if has_key(ctx.state, matched[2])
                    call window._target._parser.pop(ctx.state[matched[2]])
                else
                    call s:Debug(printf("Window '%s' pop State '%s' not exist",
                                \ window._name, matched[2]))
                endif
            endif
        catch
            call s:Debug(string(matched). " trigger " .string(v:exception))
        endtry
    endfunc


endfunc


function! s:__fini__()
    if exists("s:init")
        return
    endif

endfunc
call s:__fini__()
let s:init = 1

