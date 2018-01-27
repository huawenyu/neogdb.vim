" Constructor
function! Foo(...)
    let this = tlib#Object#New({
                \ '_class': ['Foo'],
                \ 'foo': 1,
                \ 'bar': 2,
                \ })

    function! this.babble()
        echo "'Foo' babble: therefore I am ". (self.foo * self.bar) ." months old."
    endfunction

    return this.New(a:0 >= 1 ? a:1 : {})
endfunction


function! Bar(...)
    let this = tlib#Object#New({
                \ '_class': ['Bar'],
                \ 'foo': 3,
                \ 'bar': 4,
                \ })

    function! this.babble()
        echo "'Bar' babble: therefore I am ". (self.foo * self.bar) ." months old."
    endfunction

    function! this.speak()
        echo "'Bar' speak: therefore I am ". (self.foo * self.bar) ." months old."
    endfunction

    return this.New(a:0 >= 1 ? a:1 : {})
endfunction

function! Varg2(foo, ...)
  echom a:foo
  echom a:0
  echom a:1
  echo a:000
endfunction

call Varg2("a", "b", "c")

let mybar = Bar({'bar': 24})
call mybar.Inherit(Foo({'foo': 12}))

call mybar.babble()
call mybar.speak()
call mybar.Super('babble')
echo mybar.IsA('FooBar')
echo mybar.IsA('object')
echo mybar.IsA('Foo')
echo mybar.RespondTo('babble')
echo mybar.RespondTo('speak')

