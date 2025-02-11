
"""
throttled(f::Function, timeout::Real)

Return a function that when invoked, will only be triggered at most once
during `timeout` seconds.
The throttled function will run as much as it can, without ever
going more than once per `wait` duration.

This throttle is 'leading' and has some other properties that are specifically designed for our use in Pluto, see the tests.

Inspired by FluxML
See: https://github.com/FluxML/Flux.jl/blob/8afedcd6723112ff611555e350a8c84f4e1ad686/src/utils.jl#L662
"""
function throttled(f::Function, timeout::Real)
    tlock = ReentrantLock()
    iscoolnow = Ref(false)
    run_later = Ref(false)

    function flush()
        lock(tlock) do
            run_later[] = false
            f()
        end
    end

    function schedule()
        @async begin
            sleep(timeout)
            if run_later[]
                flush()
            end
            iscoolnow[] = true
        end
    end
    schedule()

    function throttled_f()
        if iscoolnow[]
            iscoolnow[] = false
            flush()
            schedule()
        else
            run_later[] = true
        end
    end

    return throttled_f, flush
end
