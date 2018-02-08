if !exists("s:init")
    let s:init = 1
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))
endif


let Job = {}

function Job.on_stdout(job_id, data) dict
    call append(line('$'), self.get_name().' stdout: '.join(a:data))
endfunction

function Job.on_stderr(job_id, data) dict
    call append(line('$'), self.get_name().' stderr: '.join(a:data))
endfunction

function Job.on_exit(job_id, data) dict
    call append(line('$'), self.get_name().' exited')
endfunction

function Job.get_name() dict
    return 'shell '.self.name
endfunction

function Job.new(name, ...) dict
    let instance = extend(copy(g:Job), {'name': a:name})
    let argv = ['bash']
    if a:0 > 0
        let argv += ['-c', a:1]
    endif
    let instance.id = jobstart(argv, instance)
    return instance
endfunction

"let job1 = Job.new('1')
"let job2 = Job.new('2', 'for i in {1..10}; do echo hello $i!; sleep 1; done')
"
"
"To send data to the job's stdin, one can use the |jobsend()| function, like
"this:
">
"    :call jobsend(job1, "ls\n")
"    :call jobsend(job1, "invalid-command\n")
"    :call jobsend(job1, "exit\n")
"<
"A job may be killed at any time with the |jobstop()| function:
">
"    :call jobstop(job1)
"
