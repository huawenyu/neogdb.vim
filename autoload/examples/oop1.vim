let s:prototype = tlib#Object#New({
            \ '_class': ['FooBar'],
            \ 'foo': 1, 
            \ 'bar': 2, 
            \ })
" Constructor
function! FooBar(...)
    let object = s:prototype.New(a:0 >= 1 ? a:1 : {})
    return object
endf


function! s:prototype.babble()
  echo "I think, therefore I am ". (self.foo * self.bar) ." months old."
endfunction


let foobar = FooBar({'bar': 24})

echo foobar.IsA('FooBar')
echo foobar.IsA('object')
echo foobar.IsA('Foo')
if foobar.RespondTo('babble')
  call foobar.babble()
  call foobar.Call('babble')
endif
if foobar.RespondTo('speak')
  foobar.Call('speak')
endif

