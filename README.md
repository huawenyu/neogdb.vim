# neogdb.vim
Vim GDB front-end for neovim: https://github.com/huawenyu/neogdb.vim  
The code mostly stolen from https://github.com/neovim/neovim/blob/master/contrib/gdb/neovim_gdb.vim


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
  - :GdbDebug my_debug_app
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
  - <F4> continue
  - <F5> next
  - <F6> step
  - <F7> finish
  - <F9> print <var>

# License
Vim license, see LICENSE.

# Maintainer
Wilson Huawen Yu <[huawen.yu@gmail.com](mailto:huawen.yu@gmail.com)>
