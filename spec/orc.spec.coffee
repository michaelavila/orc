orc = require('../lib/orc').orc
ExecutionContext = require('../lib/orc').ExecutionContext
OrcError = require('../lib/orc').OrcError

describe 'ExecutionContext', ->
  it 'can wait for many things', ->
    context = new ExecutionContext()
    context.readyCallback = ->

    context.wait()
    context.wait()
    expect(context.waiting()).toBe true

    context.done()
    expect(context.waiting()).toBe true

    context.done()
    expect(context.waiting()).toBe false

  it 'handles too many dones() gracefully', ->
    context = new ExecutionContext()
    context.readyCallback = ->

    context.done()
    context.done()
    expect(context.waiting()).toBe false

    context.wait()
    expect(context.waiting()).toBe true

  describe 'handleError', ->
    it 'throws OrcError', ->
      context = new ExecutionContext()
      expect(context.handleError).toThrow OrcError

  describe 'fail', ->
    it 'throws OrcError', ->
      context = new ExecutionContext()
      expect(context.fail).toThrow OrcError

describe 'Orc', ->
  describe 'errorOn', ->
    it 'returns a callback that throws an OrcError', ->
      orc.sequence ->
        expect(orc.errorOn()).toThrow OrcError

    it 'causes sequence to error', ->
      log = ''

      expect(
        orc.sequence.bind(null, orc.errorOn(), -> log += 'second function')
      ).toThrow OrcError
      expect(log).toBe ''

    it 'asynchronously calls handleError on the correct context', ->
      callback = null
      context = orc.sequence ->
        callback = orc.waitFor orc.errorOn()

      log = ''
      context.handleError = -> log += 'handleError'

      callback()
      expect(log).toBe 'handleError'

    it 'gives handleError the error on the context', ->
      callback = null
      context = orc.sequence ->
        callback = orc.waitFor orc.errorOn()

      log = ''
      context.handleError = (errorArg, contextArg) ->
        expect(errorArg).not.toBe null
        expect(contextArg).toBe context

      callback()

  describe 'waitFor', ->
    it 'does not require a callback argument', ->
      callback = null

      orc.sequence ->
        callback = orc.waitFor()

      expect(callback).not.toThrow()

    it 'waits for callback to be called', ->
      log = ''
      orcCallback = null

      orc.sequence (->
        orcCallback = orc.waitFor(-> log += 'callback ')
      ), (->
        log += 'end of sequence'
      )
      expect(log).toBe ''

      orcCallback()
      expect(log).toBe 'callback end of sequence'

    it 'passes on the arguments it receives', ->
      log = ''
      orcCallback = null

      orc.sequence (->
        orcCallback = orc.waitFor((arg) -> log += "callback #{arg} ")
      ), (->
        log += 'end of sequence'
      )
      expect(log).toBe ''

      orcCallback('testarg')
      expect(log).toBe 'callback testarg end of sequence'

    it 'can be nested in other waitFor callbacks', ->
      log = ''
      orcOuterCallback = null
      orcInnerCallback = null

      orc.sequence (->
        orcOuterCallback = orc.waitFor(->
          log += 'callback '
          orcInnerCallback = orc.waitFor -> log += 'inner callback '
        )
      ), (->
        log += 'end of sequence'
      )
      expect(log).toBe ''

      orcOuterCallback()
      expect(log).toBe 'callback '

      orcInnerCallback()
      expect(log).toBe 'callback inner callback end of sequence'

  describe 'sequence', ->
    it 'works with non-async functions', ->
      log = ''
      a = -> log += 'a'
      b = -> log += 'b'

      orc.sequence a, b

      expect(log).toBe 'ab'

    it 'works with async functions', ->
      log = ''
      a = -> log += 'a'; orc.waitFor()
      b = -> log += 'b'
           
      context = orc.sequence a, b
      expect(log).toBe 'a'
          
      context.done()
      expect(log).toBe 'ab'

    it 'can run several simulatenously', ->
      log1 = ''
      a = -> log1 += 'a'; orc.waitFor()
      b = -> log1 += 'b'

      log2 = ''
      c = -> log2 += 'c'; orc.waitFor()
      d = -> log2 += 'd'
           
      context1 = orc.sequence a, b
      expect(log1).toBe 'a'
      context2 = orc.sequence c, d
      expect(log2).toBe 'c'

      context2.done()
      expect(log2).toBe 'cd'

      context1.done()
      expect(log1).toBe 'ab'

    it 'can nest non-async', ->
      log = ''
      a = -> log += 'a'
      b = -> orc.sequence (-> log += 'b'), (-> log += 'b')
      c = -> log += 'c'

      orc.sequence a, b, c
          
      expect(log).toBe 'abbc'

    it 'can nest async', ->
      inner_context = null

      log = ''
      a = -> log += 'a'; orc.waitFor()
      b = -> inner_context = orc.sequence (->
        log += 'b'; orc.waitFor()
      ), (->
        log += 'b'
      )
      c = -> log += 'c'

      context = orc.sequence a, b, c
      expect(log).toBe 'a'
          
      context.done()
      expect(log).toBe 'ab'

      inner_context.done()
      expect(log).toBe 'abbc'

    it 'properly handles a sequence that ends waiting without functions', ->
      log = ''

      inner_context = null
      orc.sequence (->
        inner_context = orc.sequence (-> log += 'a'), (-> orc.waitFor())
      ), (->
        log += 'b'
      )

      expect(log).toBe 'a'

      inner_context.done()
      expect(log).toBe 'ab'
