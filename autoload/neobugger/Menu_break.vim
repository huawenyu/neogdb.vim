if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})
endif


" Constructor
function! neobugger#Menu_break#New(...)
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let l:menu = s:prototype.New(a:0 >= 1 ? a:1 : {})
    let l:abstract = neobugger#Menu#New('Breakpoints')
    call l:menu.Inherit(l:abstract)

    call l:menu.addMenuItem(neobugger#menu_item#New(
                \{ 'text': '[t] toggle the breakpoint',
                \  'shortcut': 't',
                \  'callback': 'neobugger#Menu_break#_click_toggle'}))
    call l:menu.addMenuItem(neobugger#menu_item#New(
                \{ 'text': '[b] add/enable a breakpoint',
                \  'shortcut': 'b',
                \  'callback': 'neobugger#Menu_break#_click_add'}))
    call l:menu.addMenuItem(neobugger#menu_item#New(
                \{ 'text': '[c] add/enable a breakpoint with condition',
                \  'shortcut': 'c',
                \  'callback': 'neobugger#Menu_break#_click_add'}))
    call l:menu.addMenuItem(neobugger#menu_item#New(
                \{ 'text': '[m] add/enable a breakpoint with command',
                \  'shortcut': 'm',
                \  'callback': 'neobugger#Menu_break#_click_add'}))
    call l:menu.addMenuItem(neobugger#menu_item#New(
                \{ 'text': '[B] disable the current breakpoint',
                \  'shortcut': 'B',
                \  'callback': 'neobugger#Menu_break#_click_move'}))
    call l:menu.addMenuItem(neobugger#menu_item#New(
                \{ 'text': '[d] delete the current breakpoint',
                \  'shortcut': 'd',
                \  'callback': 'neobugger#Menu_break#_click_move'}))
    call l:menu.addMenuItem(neobugger#menu_item#New(
                \{ 'text': '[a] disable all the breakpoints',
                \  'shortcut': 'a',
                \  'callback': 'neobugger#Menu_break#_click_move'}))
    call l:menu.addMenuItem(neobugger#menu_item#New(
                \{ 'text': '[A] delete all the breakpoints',
                \  'shortcut': 'A',
                \  'callback': 'neobugger#Menu_break#_click_move'}))

    return l:menu
endfunction


" Toggle state: enable -> disable -> delete
function! neobugger#Menu_break#_click_toggle()
    let newNodeName = input("Add a childnode\n".
                          \ "==========================================================\n".
                          \ "Enter the dir/file name to be created. Dirs end with a '/'\n" .
                          \ "", neobugger#gdb#curr_info())

    let modelBreak = NbRuntimeGet('Model_break')
    if !empty(modelBreak)
        call modelBreak.ToggleBreak()
    endif
endfunction


function! neobugger#Menu_break#_click_add()
    let newNodeName = input("Add a childnode\n".
                          \ "==========================================================\n".
                          \ "Enter the dir/file name to be created. Dirs end with a '/'\n" .
                          \ "", neobugger#gdb#curr_info())

    if newNodeName ==# ''
        call nerdtree#echo("Node Creation Aborted.")
        return
    endif

    try
        let newPath = g:NERDTreePath.Create(newNodeName)
        let parentNode = b:NERDTree.root.findNode(newPath.getParent())

        let newTreeNode = g:NERDTreeFileNode.New(newPath, b:NERDTree)
        if empty(parentNode)
            call b:NERDTree.root.refresh()
            call b:NERDTree.render()
        elseif parentNode.isOpen || !empty(parentNode.children)
            call parentNode.addChild(newTreeNode, 1)
            call NERDTreeRender()
            call newTreeNode.putCursorHere(1, 0)
        endif
    catch /^NERDTree/
        call nerdtree#echoWarning("Node Not Created.")
    endtry
endfunction


function! neobugger#Menu_break#_click_move()
    let curNode = g:NERDTreeFileNode.GetSelected()
    let newNodePath = input("Rename the current node\n" .
                          \ "==========================================================\n" .
                          \ "Enter the new path for the node:                          \n" .
                          \ "", curNode.path.str(), "file")

    if newNodePath ==# ''
        call nerdtree#echo("Node Renaming Aborted.")
        return
    endif

    try
        let bufnum = bufnr("^".curNode.path.str()."$")

        call curNode.rename(newNodePath)
        call NERDTreeRender()

        "if the node is open in a buffer, ask the user if they want to
        "close that buffer
        if bufnum != -1
            let prompt = "\nNode renamed.\n\nThe old file is open in buffer ". bufnum . (bufwinnr(bufnum) ==# -1 ? " (hidden)" : "") .". Replace this buffer with a new file? (yN)"
            call s:promptToRenameBuffer(bufnum,  prompt, newNodePath)
        endif

        call curNode.putCursorHere(1, 0)

        redraw
    catch /^NERDTree/
        call nerdtree#echoWarning("Node Not Renamed.")
    endtry
endfunction


function! neobugger#Menu_break#_click_delete()
    let currentNode = g:NERDTreeFileNode.GetSelected()
    let confirmed = 0

    if currentNode.path.isDirectory && currentNode.getChildCount() > 0
        let choice =input("Delete the current node\n" .
                         \ "==========================================================\n" .
                         \ "STOP! Directory is not empty! To delete, type 'yes'\n" .
                         \ "" . currentNode.path.str() . ": ")
        let confirmed = choice ==# 'yes'
    else
        echo "Delete the current node\n" .
           \ "==========================================================\n".
           \ "Are you sure you wish to delete the node:\n" .
           \ "" . currentNode.path.str() . " (yN):"
        let choice = nr2char(getchar())
        let confirmed = choice ==# 'y'
    endif


    if confirmed
        try
            call currentNode.delete()
            call NERDTreeRender()

            "if the node is open in a buffer, ask the user if they want to
            "close that buffer
            let bufnum = bufnr("^".currentNode.path.str()."$")
            if buflisted(bufnum)
                let prompt = "\nNode deleted.\n\nThe file is open in buffer ". bufnum . (bufwinnr(bufnum) ==# -1 ? " (hidden)" : "") .". Delete this buffer? (yN)"
                call s:promptToDelBuffer(bufnum, prompt)
            endif

            redraw
        catch /^NERDTree/
            call nerdtree#echoWarning("Could not remove node")
        endtry
    else
        call nerdtree#echo("delete aborted")
    endif
endfunction


function! neobugger#Menu_break#_click_list()
    let treenode = g:NERDTreeFileNode.GetSelected()
    if !empty(treenode)
        if has("osx")
            let stat_cmd = 'stat -f "%z" '
        else
            let stat_cmd = 'stat -c "%s" '
        endif

        let cmd = 'size=$(' . stat_cmd . shellescape(treenode.path.str()) . ') && ' .
        \         'size_with_commas=$(echo $size | sed -e :a -e "s/\(.*[0-9]\)\([0-9]\{3\}\)/\1,\2/;ta") && ' .
        \         'ls -ld ' . shellescape(treenode.path.str()) . ' | sed -e "s/ $size / $size_with_commas /"'

        let metadata = split(system(cmd),'\n')
        call nerdtree#echo(metadata[0])
    else
        call nerdtree#echo("No information available")
    endif
endfunction


function! s:prototype.ParseVar(frame, srcfile, dstfile) dict
    let l:__func__ = "Model_Var.ParseVar"
    silent! call s:log.info(l:__func__, '() frame=', a:frame, ' src=', a:srcfile, ' dst=', a:dstfile)

    return 1
endfunction

