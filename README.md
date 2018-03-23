# What's new

## UI: Using MVC pattern
  - [o] Support new View: local-variable, backtrace, register
  - [o] Support new Menu: start, breakpoint
    - [ ] Menu support default which come from last time choice
    - [ ] breakpoint support auto locate by text
    - [ ] breakpoint support all function of current file
    - [ ] breakpoint update by 'source gdb.breaks'
    - [O] gdb init also by 'source gdb.start'

## commands
  - [O] Add cmd: skip current line, default bind-to <f3>

## Keymap
  - [O] Add cmd: skip current line, default bind-to <f3>

# Next features
  - [ ] Module may refactor as Abstract-Object, So donn't need Handle
  - [ ] Only support one debugger per same time: If execute two or more vim-debugger, the file will overwrite each others

