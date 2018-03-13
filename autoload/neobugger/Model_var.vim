if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})

    let s:indent = -1
    let s:_Prototype = {
          \ 'frame': '',
          \ 'vars': {},
          \ 'vars_last': {},
          \}
endif


" Constructor
function! neobugger#Model_var#New()
    let __func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let model = NbRuntimeGet(s:name)
    if !empty(model)
        return model
    endif
    let model = s:prototype.New(deepcopy(s:_Prototype))
    let abstract = neobugger#Model#New(s:name)
    call model.Inherit(abstract)

    call NbRuntimeSet(s:name, model)
    return model
endfunction


" @return -1 file-not-exist
"          0 succ
"          1 wait 'end'
function! s:prototype.ParseVar(frame, srcfile, dstfile) dict
    let __func__ = "ParseVar"
    "silent! call s:log.info(__func__, '() frame=', a:frame, ' src=', a:srcfile, ' dst=', a:dstfile)

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
        "echo matchlist('  str = 0x7fffffffda24 "hello world"', '^\(\S\+\) = \(.*\)')
        let matches = matchlist(l:line, '^\(\S\+\) = \(.*\)')
        "silent! call s:log.info(__func__, '(matches) '. string(matches))
        if len(matches) < 2
            continue
        endif

        let l:key = matches[1]
        let l:val = matches[2]
        "silent! call s:log.info(__func__, '(before) '. l:key . ' = '. l:val)
        if match(l:val, '{') != -1
            continue
        elseif match(l:val, '<optimized out>') != -1
            continue
        elseif match(l:key, '__FUNCTION__') != -1
            continue
        elseif match(l:val, '0x') != -1
              \ && match(l:val, '0x.*".*"') == -1
            let l:check_parse = 1
        endif

        "silent! call s:log.info(__func__, '(after) '. l:key . ' = '. l:val)
        let self.vars[l:key] = l:val
    endfor

    if !l:check_parse
                \ || !exists("g:neogdb_vars")
                \ || empty(g:neogdb_vars)
                \ || type(g:neogdb_vars) != type({})
        call self.ObserverUpdateAll("var")
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
    let __func__ = "ParseVarType"
    "silent! call s:log.info(__func__, '() src=', a:srcfile, ' dst=', a:dstfile)

    if exists("g:neogdb_vars") && type(g:neogdb_vars) == type({})
    else
        return -1
    endif
    if !filereadable(a:srcfile)
        return -1
    endif
    let l:lines = readfile(a:srcfile)

    let next_is_key = 1
    let customVars = []
    for l:line in l:lines
        if next_is_key
            let next_is_key = 0

            let matches = matchlist(l:line, 'whatis \(.*\)')
            "silent! call s:log.info(__func__, ' line=', l:line, ' key=', string(matches))
            if len(matches) > 0 && !empty(matches[1])
                let memberName = matches[1]
            endif
        else
            let next_is_key = 1

            let matches = matchlist(l:line, 'type = \(.*\)')
            "silent! call s:log.info(__func__, ' line=', l:line, ' val=', string(matches))
            if len(matches) > 0 && !empty(matches[1])
                let memberTypeName = matches[1]
                if has_key(self.vars, memberName)
                    let l:cmdstr = ''
                    " Write command backto /tmp/gdb.cmd
                    " Customize var detail
                    let listPrint = []
                    let listInfo = []
                    if has_key(g:neogdb_vars, memberTypeName)
                        let l:attrs = get(g:neogdb_vars, memberTypeName, [])
                        if type(l:attrs) != type([])
                            continue
                        endif

                        for l:attr in l:attrs
                            let l:print = substitute(l:attr, '{}', memberName, "g")
                            let l:info = substitute(l:attr, '{}', '', "g")
                            call add(listPrint, l:print)
                            call add(listInfo, l:info)
                        endfor
                    endif

                    let iMax = len(listPrint)
                    if iMax > 0
                        call add(customVars, printf('echo ValueOf %s\n', memberName))

                        let i = 0
                        while i < iMax
                            call add(customVars, printf('echo MemberIs %s\n', listInfo[i]))
                            call add(customVars, 'p '. listPrint[i])
                            let i += 1
                        endwhile
                    endif
                endif
            endif
        endif
    endfor

    if !empty(customVars)
        call writefile(customVars, a:dstfile)
        return 1
    endif

    " view2window
    "silent! call s:log.info(__func__, ' vars=', string(self.vars))
    call self.ObserverUpdateAll("var")
    return 0
endfunction


function! s:prototype.ParseVarEnd(srcfile) dict
    let __func__ = "ParseVarEnd"
    silent! call s:log.info(__func__, '() src=', a:srcfile)

    if !filereadable(a:srcfile)
        return -1
    endif
    let l:lines = readfile(a:srcfile)

    let next_is_key = 1
    let varName = ''
    let memberName = ''
    let child = {}
    for l:line in l:lines
        let matches = matchlist(l:line, '^ValueOf \(.*\)')
        "silent! call s:log.info(__func__, ' line=', l:line, ' key=', string(matches))
        if len(matches) > 0 && !empty(matches[1])
            if !empty(varName) && !empty(child)
                if has_key(self.vars, varName)
                    let child['s:pointer'] = self.vars[varName]
                    let self.vars[varName] = child
                endif
            endif

            let varName = matches[1]
            let memberName = ''
            let child = {}
            continue
        else
            let matches = matchlist(l:line, '^MemberIs \(.*\)')
            if len(matches) > 0 && !empty(matches[1])
                let memberName = matches[1]
                continue
            else
                " Show error in vars
                "echo matchlist('$15 = 0x5f6775626f656e23 <error: Cannot access', '$\d\+ = \(.*\) <error: \(.*\)')
                "let matches = matchlist(l:line, '^ <error: \(.*\)')
                if len(matches) > 0 && !empty(matches[1])
                    let memberName = ''
                    continue
                else
                    "echo matchlist('$16 = 1600610676', '$\d\+ = \(.*\)')
                    let matches = matchlist(l:line, '$\d\+ = \(.*\)')
                    "silent! call s:log.info(__func__, ' line=', l:line, ' val=', string(matches))
                    if len(matches) > 0 && !empty(matches[1])
                        let memberVal = matches[1]

                        if empty(memberName)
                            continue
                        else
                            let child[memberName] = memberVal
                        endif
                    else
                        let memberName = ''
                        continue
                    endif
                endif
            endif
        endif
    endfor

    if !empty(varName) && !empty(child)
        if has_key(self.vars, varName)
            let child['s:pointer'] = self.vars[varName]
            let self.vars[varName] = child
        endif
    endif

    " view2window
    "silent! call s:log.info(__func__, ' vars=', string(self.vars))
    call self.ObserverUpdateAll("var")
    call nelib#util#active_win_pop()
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


function! s:prototype._render(dir, output) dict
    let s:indent += 1
    for [name, data] in items(a:dir)
        if name ==# 's:pointer'
            continue
        "elseif data =~ '<error: '
        "    continue
        elseif type(data) == type('')
            let got = 0
            if has_key(self.vars_last, name)
                let old = self.vars_last[name]
                if type(old) == type('') && old != data
                    let got = 1
                    call add(a:output,
                                \ printf("%*s%s: {%s} <= {%s}",
                                \ s:indent * 3, ' ',
                                \ name, data,
                                \ self.vars_last[name]))
                endif
            endif

            if !got
                call add(a:output,
                            \ printf("%*s%s: {%s}",
                            \ s:indent * 3, ' ',
                            \ name, data))
            endif
        elseif type(data) == type({})
            if has_key(data, 's:pointer')
                let str_data = data['s:pointer']
                call add(a:output,
                            \ printf("%*s%s: {%s}",
                            \ s:indent * 3, ' ',
                            \ name, str_data))
            endif
            call self._render(data, a:output)
        endif
    endfor
endfunction


" @todo wilson: Forward the changed item
" Output format for Breakpoints Window
function! s:prototype.Render(...) dict
    let s:indent = -1
    let output = ["Variables:"]
    call self._render(self.vars, output)
    return join(output, "\n")
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
    let __func__ = "Model_Var._send_delete_to_debugger"

    silent! call s:log.info(__func__)
endfunction

