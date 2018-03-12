if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})

    " - 'observers'
    "   Normally this should be list.
    "   So far we have no observer use same name,
    "   Use dictionary make the remove easier
    let s:_Prototype = {
                \ 'name': '',
                \ 'observers': {},
                \}
endif


" Constructor
function! neobugger#Model#New(name)
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')
    let model = s:prototype.New(deepcopy(s:_Prototype))
    let model.name = a:name
    return model
endfunction


function! s:prototype.ObserverPurge(...) dict
    let __func__ = 'ObserverPurge'
    silent! call s:log.info(__func__, '() from ', self.name)

    let self.observers = {}
endfunction

function! s:prototype.ObserverAppend(name, obs)
    let __func__ = 'ObserverAppend'
    silent! call s:log.info(__func__, '('.a:name.') to ', self.name)

    let self.observers[a:name] = a:obs
endfunction

function! s:prototype.ObserverRemove(name)
    let __func__ = 'ObserverRemove'
    silent! call s:log.info(__func__, '('.a:name.') from ', self.name)

    if has_key(self.observers, a:name)
        unlet self.observers[a:name]
    endif
endfunction

function! s:prototype.ObserverExist(name)
    let __func__ = 'ObserverExist'
    silent! call s:log.info(__func__, '('.a:name.')')

    return has_key(self.observers, a:name)
endfunction


function! s:prototype.ObserverUpdateAll(type)
    let __func__ = 'ObserverUpdateAll'
    silent! call s:log.info(__func__, '('.a:name.')')

    for [next_name, next_obj] in items(self.observers)
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

