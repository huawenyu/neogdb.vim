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

Add the following line to the plugins regions of ~/.vimrc:

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

## Keys
  - `<F4>` continue
  - `<F5>` next
  - `<F6>` step
  - `<F7>` finish
  - `<F9>` print <var>

# License
Vim license, see LICENSE

# Maintainer
Wilson Huawen Yu <[huawen.yu@gmail.com](mailto:huawen.yu@gmail.com)>
