""Creates an enum object from {names}.
" The resulting object will be a dict with a member for each name.
"
" An enumeration object. It has fields for each name in the enumeration:
"   - Each name is attached to a unique value (0, 1, etc.).
"   - Names are better in all caps.
"   - Names and values must be unique.
"
" For example:
" >
"   let g:animals = nelib#enum#Create(['DUCK', 'PIG', 'COW'])
"   echomsg g:animals.PIG      " This will echo 1.
"   echomsg g:animals.COW      " This will echo 2
"   #echomsg g:animals.Name(0)  " This will echo DUCK.
"   #echomsg g:animals.Names()  " This will echo ['DUCK', 'PIG', 'COW'].
" <
"
" @param {names} must be a list of names
function! nelib#enum#Create(names) abort
    if empty(a:names)
        throw 'Enum must have at least one name.'
    endif
    if type(a:names) == type([])
        let l:enum = {}
        let l:counter = 0
        for l:name in a:names
            if has_key(l:enum, l:name)
                throw l:name.' appears in enum twice.'
            endif
            let l:enum[l:name] = l:counter
            let l:counter += 1
        endfor
    else
        throw 'Enum must be created from list [].'
    endif
    return l:enum
endfunction

