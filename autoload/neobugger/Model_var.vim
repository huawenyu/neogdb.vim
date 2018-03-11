if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})
endif


" Constructor
function! neobugger#Model_var#New(viewer)
    "{
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let l:model = s:prototype.New(a:0 >= 1 ? a:1 : {})
    let l:model.frame = ""
    let l:model.vars = {}
    let l:model.vars_last = {}
    let l:model.viewer = a:viewer
    let l:abstract = neobugger#Model#New()
    call l:model.Inherit(l:abstract)

    return l:model
    "}
endfunction


" @return -1 file-not-exist
"          0 succ
"          1 wait 'end'
function! s:prototype.ParseVar(frame, srcfile, dstfile) dict
    let l:__func__ = "Model_Var.ParseVar"
    silent! call s:log.info(l:__func__, '() frame=', a:frame, ' src=', a:srcfile, ' dst=', a:dstfile)

    if self.frame == a:frame
        let self.vars_last = deepcopy(self.vars)
    else
        let self.frame = a:frame
        let self.vars = {}
        let self.vars_last = {}
    endif

    if !filereadable(a:srcfile)
        return -1
    endif
    let l:check_parse = 0
    let l:lines = readfile(a:srcfile)
    for l:line in l:lines
        let matches = matchlist(l:line, '\(.*\) = \(.*\)')
        if len(matches) < 2
            continue
        endif

        let l:key = matches[1]
        let l:val = matches[2]
        if match(l:val, '0x') != -1
            let l:check_parse = 1
        endif

        if match(l:key, '__FUNCTION__') != -1
            continue
        endif

        if match(l:val, '<optimized out>') != -1
            continue
        endif

        "echomsg 'ParseVar '. l:key . ' = '. l:val
        let self.vars[l:key] = l:val
    endfor

    if !l:check_parse
        return 0
    endif

    " Write command backto /tmp/gdb.cmd
    let l:lines = []
    let l:cmdstr = ""
    for [key, val] in items(self.vars)
        if match(val, '^0x') != -1
            let l:cmdstr = printf('whatis %s', key)
            call add(l:lines, "echo ". l:cmdstr. '\n')
            call add(l:lines, l:cmdstr)
        endif
    endfor
    call writefile(l:lines, a:dstfile)
    return 1
endfunction


" Read Sample:
"
"> (gdb) whatis clt
"> type = struct wad_http_client *
"
" @return -1 file-not-exist
"          0 succ
"          1 wait 'end'
function! s:prototype.ParseVarType(srcfile, dstfile) dict
    let l:__func__ = "Model_Var.ParseVarEnd"

    if !filereadable(a:srcfile)
        return -1
    endif
    let l:lines = readfile(a:srcfile)

    let next_is_key = 1
    let l:ParseVarValue = []
    for l:line in l:lines
        if next_is_key
            let next_is_key = 0

            let matches = matchlist(l:line, 'whatis \(.*\)')
            "silent! call s:log.info(l:__func__, ' line=', l:line, ' key=', string(matches))
            if len(matches) > 0 && !empty(matches[1])
                let l:key = matches[1]
            endif
        else
            let next_is_key = 1

            let matches = matchlist(l:line, 'type = \(.*\)')
            "silent! call s:log.info(l:__func__, ' line=', l:line, ' val=', string(matches))
            if len(matches) > 0 && !empty(matches[1])
                let l:val = matches[1]
                if has_key(self.vars, l:key)
                    let l:cmdstr = ''
                    " Write command backto /tmp/gdb.cmd
                    if exists("*NeogdbvimVarCallback")
                        let l:plist = NeogdbvimVarCallback(l:key, l:val)
                        if !empty(l:plist)
                            let l:varname = printf('ValueOf %s', l:key)
                            call add(l:ParseVarValue, "echo ". l:varname. '\n')

                            for l:print in l:plist
                                call add(l:ParseVarValue, l:print)
                            endfor
                        endif
                    endif
                endif
            endif
        endif
    endfor

    if !empty(l:ParseVarValue)
        call writefile(l:ParseVarValue, a:dstfile)
        return 1
    endif

    " view2window
    silent! call s:log.info(l:__func__, ' vars=', string(self.vars))
    call self.viewer.display(self.Render())
    return 0
endfunction


function! s:prototype.ParseVarEnd(srcfile) dict
    let l:__func__ = "Model_Var.ParseVarEnd"

    if !filereadable(a:srcfile)
        return -1
    endif

    " view2window
    silent! call s:log.info(l:__func__, ' vars=', string(self.vars))
    call self.viewer.display(self.Render())
    return 0
endfunction


" Get variable under cursor
function! s:prototype.get_selected() dict
  let line = getline(".")
  " Get its id - it is last in the string
  let match = matchlist(line, '.*\t\(\d\+\)$')
  let id = get(match, 1)
  if id
    let variable = g:RubyDebugger.variables.find_variable({'id' : id})
    return variable
  else
    return {}
  endif
endfunction


" @todo wilson: Forward the changed item
" Output format for Breakpoints Window
function! s:prototype.Render() dict
    let output = "Variables:\n"
    for [name, data] in items(self.vars)
        if has_key(self.vars_last, name)
                    \ && self.vars_last[name] != data
            let output .= name. ': {'. data. "} <- {". self.vars_last[name]. "}\n"
        else
            let output .= name. ': {'. data. "}\n"
        endif
    endfor
    return output
endfunction


" Open breakpoint in existed/new window
function! s:prototype.open() dict
  call s:jump_to_file(self.file, self.line)
endfunction


function! s:prototype._set_sign() dict
  if has("signs")
    exe ":sign place " . self.id . " line=" . self.line . " name=breakpoint file=" . self.file
  endif
endfunction


function! s:prototype._unset_sign() dict
  if has("signs")
    exe ":sign unplace " . self.id
  endif
endfunction


" Send deleting breakpoint message to debugger, if it is run
" (e.g.: 'delete 5')
function! s:prototype._send_delete_to_debugger() dict
    let l:__func__ = "Model_Var._send_delete_to_debugger"

    silent! call s:log.info(l:__func__)
endfunction

