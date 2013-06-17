orc_module = require('../lib/orc')
orc = orc_module.orc

describe 'Executor', ->
    it 'can wait for many things', ->
        executor = new orc_module.Executor()
        executor.readyCallback = ->

        executor.wait()
        executor.wait()
        expect(executor.waiting()).toBe true

        executor.done()
        expect(executor.waiting()).toBe true

        executor.done()
        expect(executor.waiting()).toBe false

    it 'handles too many dones() gracefully', ->
        executor = new orc_module.Executor()
        executor.readyCallback = ->

        executor.done()
        executor.done()
        expect(executor.waiting()).toBe false

        executor.wait()
        expect(executor.waiting()).toBe true

describe 'Orchestrator', ->
    describe 'sequence', ->
        it 'works with non-async functions', ->
            log = ''
            a = -> log += 'a'
            b = -> log += 'b'

            orc.sequence a, b

            expect(log).toBe 'ab'

        it 'works with async functions', ->
            log = ''
            a = -> log += 'a'; orc.wait()
            b = -> log += 'b'
             
            executor = orc.sequence a, b
            expect(log).toBe 'a'
            
            executor.done()
            expect(log).toBe 'ab'

        it 'can run several simulatenously', ->
            log1 = ''
            a = -> log1 += 'a'; orc.wait()
            b = -> log1 += 'b'

            log2 = ''
            c = -> log2 += 'c'; orc.wait()
            d = -> log2 += 'd'
             
            executor1 = orc.sequence a, b
            expect(log1).toBe 'a'
            executor2 = orc.sequence c, d
            expect(log2).toBe 'c'

            executor2.done()
            expect(log2).toBe 'cd'

            executor1.done()
            expect(log1).toBe 'ab'

        it 'can nest non-async', ->
            log = ''
            a = -> log += 'a'
            b = -> orc.sequence (-> log += 'b'), (-> log += 'b')
            c = -> log += 'c'

            orc.sequence a, b, c
            
            expect(log).toBe 'abbc'

        it 'can nest async', ->
            inner_executor = null

            log = ''
            a = -> log += 'a'; orc.wait()
            b = -> inner_executor = orc.sequence (-> log += 'b'; orc.wait()), (-> log += 'b')
            c = -> log += 'c'

            executor = orc.sequence a, b, c
            expect(log).toBe 'a'
            
            executor.done()
            expect(log).toBe 'ab'

            inner_executor.done()
            expect(log).toBe 'abbc'
