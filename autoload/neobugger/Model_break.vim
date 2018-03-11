if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})

    sign define GdbBreakpointEn text=● texthl=Search
    sign define GdbBreakpointDis text=● texthl=Function
    sign define GdbBreakpointDel text=● texthl=Comment

    let s:breakpoint_signid_start = 5000
    let s:breakpoint_signid_max = 0

    let s:breakpoints = {}

    let s:toggle_all = 0
    let s:save_break = './.gdb.break'
endif


" Constructor
function! neobugger#Model_break#New()
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let l:model = s:prototype.New(a:0 >= 1 ? a:1 : {})
    let l:abstract = neobugger#Model#New()
    call l:model.Inherit(l:abstract)

    return l:model
endfunction


function! s:prototype.LoadFromFile(fBreakpoints) dict
    let l:__func__ = "LoadFromFile"
    silent! call s:log.info(l:__func__, "()")

    if !empty(a:fBreakpoints) && filereadable(a:fBreakpoints)
        let s:save_break = a:fBreakpoints
    endif

    if filereadable(s:save_break)
        call nelib#util#read_variable('g:neobugger_tmp', s:save_break)
        let s:breakpoints = g:neobugger_tmp
    else
        silent! call s:log.warn(l:__func__, "('". s:save_break. "'): file not exits.")
        return
    endif

    silent! call s:log.info("Set and sign breaks ...")
    if !empty(s:breakpoints)
        call self.UpdateSign(0)
        call self.Render()
        call neobugger#Handle('current', 'UpdateBreaks', 0, s:breakpoints)
    endif
endfunction


" Key: file:line, <or> file:function
" Value: empty, <or> if condition
" @state 0 disable 1 enable, Toggle: none -> enable -> disable
" @type 0 line-break, 1 function-break
function! s:prototype.ToggleBreak() dict
    let l:__func__ = "ToggleBreak"
    silent! call s:log.info(l:__func__, "()")

    let newItem = neobugger#break_item#New('toggle', '')
    if empty(newItem)
        silent! call s:log.info(l:__func__, "() create a break_item fail")
        return
    endif

    let mode = 0
    let oldItem = get(s:breakpoints, newItem.name, {})
    if empty(oldItem) || !newItem.equal(oldItem)
        let s:breakpoints[newItem.name] = newItem
        let newItem['update'] = 1
    else
        let oldItem['state'] += 1
        let newItem['update'] = 1
    endif
    call nelib#util#save_variable(s:breakpoints, s:save_break)
    call self.ObserverUpdateAll("break")

    " Remove state=2 item
    for [next_key, next_val] in items(s:breakpoints)
        let state = next_val['state'] % 3
        if state == 2
            silent! call s:log.info("Remove breakpoint " . next_key)
            unlet s:breakpoints[next_key]
        endif
    endfor

    "call self.Breaks2Qf()
    "call self.UpdateSign(mode)
    "call neobugger#Handle('current', 'UpdateBreaks', mode, s:gdb_break)
endfunction


function! s:prototype.ToggleBreakAll() dict
    let s:toggle_all = ! s:toggle_all
    let mode = 0
    for v in values(s:breakpoints)
        if s:toggle_all
            let v['state'] = 0
        else
            let v['state'] = 1
        endif
    endfor
    call self.UpdateSign(0)
    call neobugger#Handle('current', 'UpdateBreaks', 0, s:gdb_break)
endfunction


function! s:prototype.ClearBreak() dict
    let s:breakpoints = {}
    call self.Breaks2Qf()
    call self.UpdateSign(0)
    call neobugger#Handle('current', 'UpdateBreaks', 2, s:gdb_break)
endfunction







" *** Breakpoint class (start)

let s:Breakpoint = { 'id': 0 }

" ** Public methods

" Constructor of new brekpoint. Create new breakpoint and set sign.
function! s:Breakpoint.new(file, line)
  let var = copy(self)
  let var.file = a:file
  let var.line = a:line
  let s:Breakpoint.id += 1
  let var.id = s:Breakpoint.id

  call var._set_sign()
  silent call s:log.info("Set breakpoint to: " . var.file . ":" . var.line)
  return var
endfunction


" Destroyer of the breakpoint. It just sends commands to debugger and destroys
" sign, but you should manually remove it from breakpoints array
function! s:Breakpoint.delete() dict
  call self._unset_sign()
  call self._send_delete_to_debugger()
endfunction


" Add condition to breakpoint. If server is not running, just store it, it
" will be evaluated after starting the server
function! s:Breakpoint.add_condition(condition) dict
  let self.condition = a:condition
  if has_key(g:RubyDebugger, 'server') && g:RubyDebugger.server.is_running() && has_key(self, 'debugger_id')
    call g:RubyDebugger.queue.add(self.condition_command())
  endif
endfunction



" Send adding breakpoint message to debugger, if it is run
function! s:Breakpoint.send_to_debugger() dict
  if has_key(g:RubyDebugger, 'server') && g:RubyDebugger.server.is_running()
    call s:log.info("Server is running, so add command to Queue")
    call g:RubyDebugger.queue.add(self.command())
  endif
endfunction


" Command for setting breakpoint (e.g.: 'break /path/to/file:23')
function! s:Breakpoint.command() dict
  return 'break ' . self.file . ':' . self.line
endfunction


" Command for adding condition to breakpoin (e.g.: 'condition 1 x>5')
function! s:Breakpoint.condition_command() dict
  return 'condition ' . self.debugger_id . ' ' . self.condition
endfunction


" Find and return breakpoint under cursor
function! s:Breakpoint.get_selected() dict
  let line = getline(".")
  let match = matchlist(line, '^\(\d\+\)')
  let id = get(match, 1)
  let breakpoints = filter(copy(g:RubyDebugger.breakpoints), "v:val.id == " . id)
  if !empty(breakpoints)
    return breakpoints[0]
  else
    return {}
  endif
endfunction


" Output format for Breakpoints Window
function! s:prototype.Render(mode, options) dict
    if a:mode ==# 'break'
        let a:options['mode'] = 'gdb'
        return self._render2gdb(a:options)
    elseif a:mode ==# 'sign'
        return self._render2sign(a:options)
    elseif a:mode ==# 'view'
        let a:options['mode'] = 'view'
        return self._render2gdb(a:options)
    endif
endfunction


function! s:prototype._render2gdb(options) dict
    let l:__func__ = "_render2gdb"
    silent! call s:log.info(l:__func__, "() options=". string(a:options))

    if has_key(a:options, 'mode')
        let mode = a:options['mode']
    else
        silent! call s:log.info(l:__func__, "(". a:options['file'] .")")
        return
    endif

    if mode ==# 'gdb'
        let modeType = 0
    elseif mode ==# 'view'
        let modeType = 1
    endif

    let breakCmds = []
    let cnt = 0

    for [next_key, next_val] in items(s:breakpoints)
        let state = next_val['state'] % 3
        if state == 0
            let cnt += 1
            if empty(next_val['command'])
                call add(breakCmds, 'break '. next_key)
            else
                cmds = split(next_val['command'], ';')
                cmd1st = substitute(cmds[0], '^ *', '', 'g')
                if cmd1st ==? 'if'
                    call add(breakCmds, 'break '. next_key.' '.cmd1st)
                    extend(breakCmds, cmds[1:])
                elseif cmd1st ==? 'com'
                    cmdEnd = substitute(cmds[-1], '^ *', '', 'g')
                    if cmdEnd ==? 'end'
                        call add(breakCmds, 'break '. next_key)
                        extend(breakCmds, cmds[0:])
                    else
                        silent! call s:log.warn(l:__func__, "(".next_key.") no end: ".next_val)
                    endif
                endif
            endif
        endif
    endfor

    if modeType == 0
        call insert(breakCmds, 'delete')
    else
        call insert(breakCmds, 'Breakpoints: ['. cnt. ']')
    endif

    if has_key(a:options, 'file')
        call writefile(breakCmds, a:options['file'])
    endif
    return breakCmds
endfunction


function! s:prototype._render2sign(options) dict
    let l:__func__ = "_render2sign"
    silent! call s:log.info(l:__func__, "()")

    let i = s:breakpoint_signid_start
    while i <= s:breakpoint_signid_max
        exe 'sign unplace '.i
        let i += 1
    endwhile

    let s:breakpoint_signid_max = 0
    let id = s:breakpoint_signid_start
    for [next_key, next_val] in items(s:breakpoints)
        try
            let buf = bufnr(next_val['file'])
            let linenr = next_val['line']
            let next_val['sign_id'] = 0

            let state = next_val['state'] % 3
            if state == 0
                exe 'sign place '.id.' name=GdbBreakpointEn line='.linenr.' buffer='.buf
            elseif state == 1
                exe 'sign place '.id.' name=GdbBreakpointDis line='.linenr.' buffer='.buf
            else
                continue
            endif

            let next_val['sign_id'] = id
            let s:breakpoint_signid_max = id
            let id += 1
        catch /.*/
            echo v:exception
        endtry
    endfor
    return {}
endfunction


" Open breakpoint in existed/new window
function! s:Breakpoint.open() dict
  call s:jump_to_file(self.file, self.line)
endfunction


function! s:Breakpoint._set_sign() dict
  if has("signs")
    exe ":sign place " . self.id . " line=" . self.line . " name=breakpoint file=" . self.file
  endif
endfunction


function! s:Breakpoint._unset_sign() dict
  if has("signs")
    exe ":sign unplace " . self.id
  endif
endfunction


" Send deleting breakpoint message to debugger, if it is run
" (e.g.: 'delete 5')
function! s:Breakpoint._send_delete_to_debugger() dict
  if has_key(g:RubyDebugger, 'server') && g:RubyDebugger.server.is_running() && has_key(self, 'debugger_id')
    let message = 'delete ' . self.debugger_id
    call g:RubyDebugger.queue.add(message)
  endif
endfunction

