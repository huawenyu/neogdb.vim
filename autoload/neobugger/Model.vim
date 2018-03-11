if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})

    " Normally this should be list.
    " So far we have no observer use same name,
    " Use dictionary make the remove easier
    let s:observers = {}
endif


" Constructor
function! neobugger#Model#New()
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let l:model = s:prototype.New(a:0 >= 1 ? a:1 : {})
    return l:model
endfunction


function! s:prototype.ObserverPurge(...) dict
    let l:__func__ = 'ObserverPurge'
    silent! call s:log.info(l:__func__, '()')

    let s:observers = {}
endfunction

function! s:prototype.ObserverAppend(name, obs)
    let l:__func__ = 'ObserverAppend'
    silent! call s:log.info(l:__func__, '('.a:name.')')

    let s:observers[a:name] = a:obs
endfunction

function! s:prototype.ObserverRemove(name)
    let l:__func__ = 'ObserverRemove'
    silent! call s:log.info(l:__func__, '('.a:name.')')

    unlet s:observers[a:name]
endfunction

function! s:prototype.ObserverExist(name)
    let l:__func__ = 'ObserverExist'
    silent! call s:log.info(l:__func__, '('.a:name.')')

    return has_key(s:observers, a:name)
endfunction


function! s:prototype.ObserverUpdateAll(type)
    let l:__func__ = 'ObserverUpdateAll'
    silent! call s:log.info(l:__func__, '('.a:name.')')

    for [next_name, next_obj] in items(s:observers)
        try
            call next_obj.Update(a:type, self)
        catch
            echohl ErrorMsg
            echom v:exception
            echohl NONE
        endtry
    endfor
endfunction


function! s:prototype.get_selected(...)
    throw s:script. ': Virtual function get_selected() must be implement.'
endfunction

function! s:prototype.Render(...)
    throw s:script. ': Virtual function Render() must be implement.'
endfunction

function! s:prototype.open(...)
    throw s:script. ': Virtual function open() must be implement.'
endfunction

function! s:prototype._set_sign(...)
    throw s:script. ': Virtual function _set_sign() must be implement.'
endfunction

function! s:prototype._unset_sign(...)
    throw s:script. ': Virtual function _unset_sign() must be implement.'
endfunction

function! s:prototype._send_delete_to_debugger(...)
    throw s:script. ': Virtual function _send_delete_to_debugger() must be implement.'
endfunction

