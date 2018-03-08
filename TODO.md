# Code style
- abstract class: Menu.vim
- class: menu_item.vim
- inherit class: Menu_break.vim
- instance of class: instanceOfClass
- class static method: path#file#static_method
- class virtual method: path#file#VirtualMethod
- class public method: path#file#public_method
- class private method: path#file#_private_method
- template class: s:_TemplateClass

# Feature

## Idea
  - [ ] Module may refactor as Abstract-Object, So donn't need Handle
  - [ ] Only support one debugger per same time: If execute two or more vim-debugger, the file will overwrite each others

## Support view & menu

  - [ ] View: local-variable, backtrace, register
  - [ ] Menu: start, breakpoint
    - [ ] Menu support default which come from last time choice
    - [ ] breakpoint support auto locate by text
    - [ ] breakpoint support all function of current file
    - [ ] breakpoint update by 'source gdb.breaks'
    - [ ] gdb init also by 'source gdb.start'

