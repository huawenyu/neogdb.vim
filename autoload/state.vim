
function! s:__init__()
    if exists("s:init")
        return
    endif
    let s:path = expand('<sfile>:p')

endfunc
call s:__init__()

function! s:Debug(msg)
    if &verbose
        echomsg s:path. ": ". msg
    endif
endfunc


function! state#Open(config) abort
    let conf = a:config
    if type(conf) != type({})
       \ || ! has_key(conf, "scheme")
        throw "neogdb.state#Open: config not dict or have no 'scheme'."
    endif

    let creator = function(conf.scheme)
    if ! creater
        throw "neogdb.state#Open: no creator '". conf['scheme'] ."'."
    endif
    let scheme = creator()
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
        for [k,v] in keys(conf.state)
            if has_key(scheme.state, k)
                call extend(scheme.state[k], v)
            else
                let scheme.state[k] = v
            endif
        endfor
    endif
    unlet conf['state']

    " Merge conf.window into scheme.window
    if has_key(conf, 'window')
        call extend(scheme.window, conf.window)
    endif
    unlet conf['window']

    " Load state
    for [k,v] in items(scheme.state)
        let expect = []
        for i in v
            call add(expect, [ i.match, 'on_call', i ])
        endfor

        let state = expect#State(expect)
        let state.ctx = ctx
        let ctx.state[k] = state

        function! state.on_call(matched, ...)
            call this.ctx.on_call(a:matched, a:000)
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
        let window.name = conf_win.name
        if !has_key(ctx.state, conf_win.state)
            throw printf("neogdb.state#CreateRuntime: window ''%s' initstate '%s' not exist",
                        \ conf_win.name, conf_win.state)
        endif
        let state0 = ctx.state[conf_win.state]
        let window._state = state0
        let state0._window = window

        let target = expect#Parser(state0, window)
        let window._target = target

        if has_key(conf, conf_win.layout[0])
            exec conf[conf_win.layout[0]]
        else
            exec conf[conf_win.layout[1]]
        endif
        let window._wid = win_getid()
        if has_key(conf, conf_win.cmd[0])
            enew | let window._client_id = termopen(conf[conf_win.cmd[0]], target)
        else
            enew | let window._client_id = termopen(conf[conf_win.cmd[1]], target)
        endif
        let window._bufnr = bufnr('%')
    endfor

    " Backto main windows
    if win_gotoid(ctx._win_main) == 1
        let ctx._jump_window = win_id2win(ctx._win_main)
        stopinsert
    endif


    function! ctx.on_call(matched, ...)
        let matched = a:matched
        call s:Debug(string(matched))

        if !has_key(matched, 'action') || !has_key(matched, 'arg0')
            throw "neogdb.state#CreateRuntime: have no 'action','arg0' with " . string(matched)
        endif

        let window = matched._window
        if has_key(matched, 'window')
           \ && ! empty(matched.window)
           \ && has_key(ctx.window, matched.window)
            let window = ctx.window[matched.window]
        endif

        try
            if matched.action ==# 'call'
                if has_key(scheme, matched.arg0)
                    call call(scheme[matched.arg0], a:000)
                else
                    call s:Debug(printf("Scheme '%s' call function '%s' not exist",
                                \ scheme.name, matched.arg0))
                endif
            elseif matched.action ==# 'send'
                let str = call("printf", [matched.arg0] + a:000)
                call jobsend(window._client_id, str."\<cr>")
            elseif matched.action ==# 'switch'
                if has_key(ctx.state, matched.arg0)
                    call window._target._parser.switch(ctx.state[matched.arg0])
                else
                    call s:Debug(printf("Window '%s' switch State '%s' not exist",
                                \ window.name, matched.arg0))
                endif
            elseif matched.action ==# 'push'
                if has_key(ctx.state, matched.arg0)
                    call window._target._parser.push(ctx.state[matched.arg0])
                else
                    call s:Debug(printf("Window '%s' push State '%s' not exist",
                                \ window.name, matched.arg0))
                endif
            elseif matched.action ==# 'pop'
                if has_key(ctx.state, matched.arg0)
                    call window._target._parser.pop(ctx.state[matched.arg0])
                else
                    call s:Debug(printf("Window '%s' pop State '%s' not exist",
                                \ window.name, matched.arg0))
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

