# neogdb.vim
Vim GDB front-end for neovim: https://github.com/huawenyu/neogdb.vim  
The code reference: https://github.com/neovim/neovim/blob/master/contrib/gdb/neovim_gdb.vim  

## feature
  - gdb commands maps: next, step, finish, continue, etc.
  - breakpoints:
    + auto save/load,
    + populate to local list: lopen
    + side color sign
    + triple state: enable -> disable -> delete
    + toggle current line/toggle-all-breakpoints
    + support condition set
  - backtrace:
    + populate to quickfix: copen

## layout

```
+-------------------------+--------------------------+
|                         |                          |
|                         |                          |
|                         |                          |
|                         |    terminal>             |
|     Code c/c++          |    (gdb)                 |
|                         |                          |
|                         |                          |
|                         |                          |
|                         |                          |
|                         +--------------------------+
|                         |                          |
+-------------------------+  backtrace               |
| breakpoints             |                          |
|                         |                          |
+-------------------------+--------------------------+

```
## Screen Demo

Press <F2> to toggle gdb-local or gdb-remote.

### gdb local

    :GdbLocal confloc#me a.out ""

### gdb remote

    :GdbRemote confos#me sysinit/init 10.1.1.125:444

### gif

[![screen](./screen.gif)](#features)

# Install

## Install if no any plugin manager

The file structure should be clear, just copy the github.vim into ~/.vim/plugin/

## Installing when using [Vundle](https://github.com/VundleVim/Vundle.vim)

Add the following line to the plugins regions of ``~/.vimrc``:

```vim
Plugin 'huawenyu/neogdb.vim'
```

## Installing when using [Pathogen](https://github.com/tpope/vim-pathogen)

```Shell
    cd ~/.vim/bundle
    git clone git@github.com:solars/github-vim.git
```

# Usage

## commands
  - :GdbLocal my_debug_app
  - :GdbDebugStop
  - :GdbToggleBreakpoint
  - :GdbClearBreakpoints
  - :GdbContinue
  - :GdbNext
  - :GdbStep
  - :GdbFinish
  - :GdbFrameUp
  - :GdbFrameDown
  - :GdbInterrupt
  - :GdbEvalWord
  - :GdbWatchWord

## Default keymaps
  - `<F4>` continue
  - `<F5>` next
  - `<F6>` step
  - `<F7>` finish
  - `<F9>` print <var>

# Customization

Put these in your ``~/.vimrc`` to customize the keymaps:

```vim
let g:gdb_keymap_continue = '<f8>'
let g:gdb_keymap_next = '<f10>'
let g:gdb_keymap_step = '<f11>'
" Usually, F23 is just Shift+F11
let g:gdb_keymap_finish = '<f23>'
let g:gdb_keymap_toggle_break = '<f9>'
" Usually, F33 is just Ctrl+F9
let g:gdb_keymap_toggle_break_all = '<f33>'
let g:gdb_keymap_frame_up = '<c-n>'
let g:gdb_keymap_frame_down = '<c-p>'
" Usually, F21 is just Shift+F9
let g:gdb_keymap_clear_break = '<f21>'
" Usually, F17 is just Shift+F5
let g:gdb_keymap_debug_stop = '<f17>'
```

## Miscellaneous

By default, if you run ``GdbLocal`` or ``GdbRemote`` when GDB is already started,  
the plugin will send an interrupt (``<c-c>``) followed by a ``start``.  
This is in order to speed up the edit-compile-test cycle.  
If you instead want an error to be thrown when GDB is already started, change this variable:

```vim
let g:restart_app_if_gdb_running = 0
```

By default, the plugin toggles the breakpoint right after pressing ``g:gdb_keymap_toggle_break``.  
If this flag is set to 1, the plugin will require you to confirm the command with Enter which lets you edit the command before issuing it:

```vim
let g:gdb_require_enter_after_toggling_breakpoint = 0
```

To send your own commands to GDB:

```vim
" Prints the value of the variable under the cursor
nmap <Space>p :call gdb#Send("print " . expand('<cword>'))<CR>
```

### Map and unmap callbacks

You can run your own code when Neogdb sets its keymaps.  
The plugin will call ``NeogdbvimNmapCallback`` on initialization and ``NeogdbvimUnmapCallback`` on exiting, if these functions exist.  

For example, you can put this in your ``~/.vimrc``:

```vim
function! NeogdbvimNmapCallback()
    " Let fzf.vim open files in the current window by default.
    " This is so that, when navigating files,
    " we don't switch to a new tab and thus *always* see the neogdb's splits. 
    let g:fzf_action = { 'enter': 'edit' }
endfunc

function! NeogdbvimUnmapCallback()
    " Quitting to normal editing. Let fzf.vim open files in the new tab,
    " as usual.
    let g:fzf_action = { 'enter': 'tabnew' }
endfunc
```

# License
Vim license, see LICENSE

# Maintainer
Wilson Huawen Yu <[huawen.yu@gmail.com](mailto:huawen.yu@gmail.com)>
