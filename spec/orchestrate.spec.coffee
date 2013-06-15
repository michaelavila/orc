class Orchestrator
    constructor: ->
        @waiting = false

    sequence: (functions...) ->
        index = 0
        for func in functions
            index++
            func()
            if @waiting
                @waiting_functions = functions.slice(index)
                break

    wait: ->
        @waiting = true

    done: ->
        @waiting = false
        if @waiting_functions
            @sequence @waiting_functions...

describe "orchestrate", ->
    describe "#sequence", ->
        orc = null

        beforeEach ->
            orc = new Orchestrator()

        it "can orchestrate normal functions", ->
            function_log = ''
            a = -> function_log += 'a'
            b = -> function_log += 'b'

            orc.sequence a, b

            expect(function_log).toBe 'ab'

        it "can orchestrate asynchronous functions", ->
            function_log = ''
            a = -> function_log += 'a'; orc.wait()
            b = -> function_log += 'b'

            orc.sequence a, b
            expect(function_log).toBe 'a'

            orc.done()
            expect(function_log).toBe 'ab'
