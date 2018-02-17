if !exists("s:script")
    let s:script = expand('<sfile>:t')
    silent! let s:log = logger#getLogger(s:script)

    let s:breakpoints = {}
    let s:prototype = tlib#Object#New({
                \ '_class': ['_Model'],
                \ })
endif


" Constructor
function! neobugger#model#New()
    "{
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let l:model = s:prototype.New(a:0 >= 1 ? a:1 : {})
    return l:model
    "}
endfunction


function! s:prototype.Purge(...)
    throw s:script. ': Abtract function Purge() must be implement.'
endfunction

function! s:prototype.Append(...)
    throw s:script. ': Abtract function Append() must be implement.'
endfunction

function! s:prototype.Remove(...)
    throw s:script. ': Abtract function Remove() must be implement.'
endfunction

function! s:prototype.add_condition(...)
    throw s:script. ': Abtract function add_condition() must be implement.'
endfunction

function! s:prototype.send_to_debugger(...)
    throw s:script. ': Abtract function send_to_debugger() must be implement.'
endfunction

function! s:prototype.command(...)
    throw s:script. ': Abtract function command() must be implement.'
endfunction

function! s:prototype.condition_command(...)
    throw s:script. ': Abtract function condition_command() must be implement.'
endfunction

function! s:prototype.get_selected(...)
    throw s:script. ': Abtract function get_selected() must be implement.'
endfunction

function! s:prototype.render(...)
    throw s:script. ': Abtract function render() must be implement.'
endfunction

function! s:prototype.open(...)
    throw s:script. ': Abtract function open() must be implement.'
endfunction

function! s:prototype._set_sign(...)
    throw s:script. ': Abtract function _set_sign() must be implement.'
endfunction

function! s:prototype._unset_sign(...)
    throw s:script. ': Abtract function _unset_sign() must be implement.'
endfunction

function! s:prototype._send_delete_to_debugger(...)
    throw s:script. ': Abtract function _send_delete_to_debugger() must be implement.'
endfunction

