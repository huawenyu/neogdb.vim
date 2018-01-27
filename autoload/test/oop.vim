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

    "===============================
    function! this.babble()
        echo "'Bar' babble: therefore I am ". (self.foo * self.bar) ." months old."
    endfunction

    function! this.speak()
        echo "'Bar' speak: therefore I am ". (self.foo * self.bar) ." months old."
    endfunction

    return this.New(a:0 >= 1 ? a:1 : {})
endfunction

let myfoo = Foo({'foo': 12})
let mybar = Bar({'bar': 24})
call mybar.Inherit(myfoo)

call myfoo.babble()
echo myfoo.IsA('FooBar')
echo myfoo.IsA('object')
echo myfoo.IsA('Foo')
echo myfoo.RespondTo('babble')
echo myfoo.RespondTo('speak')

call mybar.babble()
call mybar.speak()
echo mybar.IsA('FooBar')
echo mybar.IsA('object')
echo mybar.IsA('Foo')
echo mybar.RespondTo('babble')
echo mybar.RespondTo('speak')

