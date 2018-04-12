if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})

    " @observers
    "   Normally this should be list.
    "   So far we have no observer use same name,
    "   Use dictionary make the remove easier
    let s:_Prototype = {
                \ 'name': '',
                \ 'observers': {},
                \}
    " @dashboard
    "   Control gdb-python dashboard which generate file
    "let s:_all_dashboard = ['source', 'assembly', 'stack', 'history', 'memory', 'registers', 'breakpoints', 'variables', 'threads', 'expressions']
    let s:_all_dashboard = ['assembly', 'stack', 'history', 'memory', 'registers', 'breakpoints', 'variables', 'threads', 'expressions']
    let s:dashboard = {}
endif


" Constructor
function! neobugger#Model#New(name)
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')
    let model = s:prototype.New(deepcopy(s:_Prototype))
    let model.name = a:name
    return model
endfunction


function! neobugger#Model#Resolve(name)
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let model = NbRuntimeGet(a:name)
    if !empty(model)
        return model
    endif

    let Fmodel_new = function('neobugger#'. a:name. '#New')
    return Fmodel_new()
endfunction


" dashboard -layout source !assembly stack
"   Source,Assembly,Stack,History,Memory,Registers,Breakpoints,Variables,Threads,Expressions,
function! neobugger#Model#Dashboard()
    let __func__ = 'neobugger#Model#Dashboard'

    " Always enable 'source': get current running line
    let dashboard = 'dashboard -layout source '
    for dash in s:_all_dashboard
        if has_key(s:dashboard, dash)
            let dashboard .= dash. ' '
        else
            let dashboard .= '!'. dash. ' '
        endif
    endfor

    silent! call s:log.info(__func__, ': '. dashboard)
    call neobugger#Handle('current', 'Send', dashboard)
endfunction


function! neobugger#Model#DashboardUpdate(dir)
    let __func__ = 'DashboardUpdate'
    silent! call s:log.info(__func__, '('.a:dir.')')

    for dash in s:_all_dashboard
        if has_key(s:dashboard, dash)
            let model = s:dashboard[dash]
            call model.Update(a:dir)
        endif
    endfor
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
    if has_key(a:obs, 'dashboard') && !empty(a:obs['dashboard'])
        let s:dashboard[ a:obs['dashboard'] ] = self

        call neobugger#Model#Dashboard()
    endif
endfunction

function! s:prototype.ObserverRemove(name)
    let __func__ = 'ObserverRemove'
    silent! call s:log.info(__func__, '('.a:name.') from ', self.name)

    if has_key(self.observers, a:name)
        let obs = self.observers[a:name]
        if has_key(obs, 'dashboard') && !empty(obs['dashboard'])
            if has_key(s:dashboard, obs['dashboard'])
                unlet s:dashboard[ obs['dashboard'] ]

                call neobugger#Model#Dashboard()
            endif
        endif

        unlet self.observers[a:name]
    endif
endfunction

function! s:prototype.ObserverExist(name)
    let __func__ = 'ObserverExist'
    silent! call s:log.info(__func__, '('.a:name.')')

    return has_key(self.observers, a:name)
endfunction


" Load data from gdb.python's file
function! s:prototype.Update(dir) dict
    let __func__ = 'Update'
    silent! call s:log.warn(__func__, ' model='. string(self))
    throw s:script. ': '. self.name .' must implement '. __func__
endfunction


function! s:prototype.UpdateView()
    let __func__ = 'UpdateView'
    silent! call s:log.info(__func__, '()')

    for [next_name, next_obj] in items(self.observers)
        try
            call next_obj.Update(self)
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


