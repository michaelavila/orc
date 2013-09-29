orc = require('orc').orc
ExecutionContext = require('orc').ExecutionContext
OrcError = require('orc').OrcError

describe 'ExecutionContext', ->
  beforeEach ->
    @context = new ExecutionContext()
    sinon.stub @context, 'readyCallback'

  it 'should be waiting initially', ->
    expect(@context.waiting()).to.be.false

  describe '#waiting', ->
    it 'should be false when there are no holds', ->
      @context.holds = 0

      expect(@context.waiting()).to.be.false

    it 'should be true when there are holds', ->
      @context.holds = 1

      expect(@context.waiting()).to.be.true

  describe '#wait', ->
    it 'should cause context to be waiting', ->
      @context.wait()

      expect(@context.waiting()).to.be.true

  describe '#done', ->
    context 'when not waiting', ->
      it 'should not do anything', ->
        @context.done()

        expect(@context.waiting()).to.be.false

      it 'should not call readyCallback', ->
        @context.done()

        expect(@context.readyCallback).to.not.have.been.called

    context 'when waiting', ->
      beforeEach ->
        @context.wait()

      it 'should cause context to no longer be waiting', ->
        @context.done()

        expect(@context.waiting()).to.be.false

      it 'should call readyCallback', ->
        @context.done()

        expect(@context.readyCallback).to.have.been.called

      context 'for many things', ->
        beforeEach ->
          @context.wait()
          
        it 'should require multiple dones', ->
          @context.done()
          expect(@context.waiting()).to.be.true

          @context.done()
          expect(@context.waiting()).to.be.false

        it 'should not call readyCallback', ->
          @context.done()
          expect(@context.readyCallback).to.not.have.been.called

  describe '#canExecute', ->
    it 'should be false when empty', ->
      sinon.stub(@context.functions, 'isEmpty').returns true

      expect(@context.canExecute()).to.be.false

    it 'should be true when not empty', ->
      sinon.stub(@context.functions, 'isEmpty').returns false

      expect(@context.canExecute()).to.be.true

  describe '#executeNext', ->
    beforeEach ->
      @step = sinon.stub()
      @context.functions = [@step]

    it 'should execute the next function', ->
      @context.executeNext()

      expect(@step).to.have.been.called

    context 'when not waiting', ->
      it 'should not set the readyCallback', ->
        sinon.stub(@context, 'waiting').returns false

        @context.executeNext @step

        expect(@context.readyCallback).to.not.equal @step

    context 'when waiting', ->
      it 'should set the readyCallback', ->
        sinon.stub(@context, 'waiting').returns true

        @context.executeNext @step

        expect(@context.readyCallback).to.equal @step

  describe '#fail', ->
    it 'should throw an OrcError', ->
      expect(@context.fail).to.throw OrcError

  describe '#handleError', ->
    it 'should call fail', ->
      sinon.stub @context, 'fail'

      @context.handleError()

      expect(@context.fail).to.have.been.called

describe 'Orc', ->
  describe 'errorOn', ->
    it 'returns a callback that throws an OrcError', ->
      orc.sequence ->
        expect(orc.errorOn()).to.throw OrcError

    it 'causes sequence to error', ->
      log = ''

      expect(
        orc.sequence.bind(null, orc.errorOn(), -> log += 'second function')
      ).to.throw OrcError
      expect(log).to.equal ''

    it 'asynchronously calls handleError on the correct context', ->
      callback = null
      context = orc.sequence ->
        callback = orc.waitFor orc.errorOn()

      log = ''
      context.handleError = -> log += 'handleError'

      callback()
      expect(log).to.equal 'handleError'

    it 'gives handleError the error on the context', ->
      callback = null
      context = orc.sequence ->
        callback = orc.waitFor orc.errorOn()

      log = ''
      context.handleError = (errorArg, contextArg) ->
        expect(errorArg).not.to.equal null
        expect(contextArg).to.equal context

      callback()

  describe 'waitFor', ->
    it 'does not require a callback argument', ->
      callback = null

      orc.sequence ->
        callback = orc.waitFor()

      expect(callback).not.to.throw()

    it 'waits for callback to be called', ->
      log = ''
      orcCallback = null

      orc.sequence (->
        orcCallback = orc.waitFor(-> log += 'callback ')
      ), (->
        log += 'end of sequence'
      )
      expect(log).to.equal ''

      orcCallback()
      expect(log).to.equal 'callback end of sequence'

    it 'passes on the arguments it receives', ->
      log = ''
      orcCallback = null

      orc.sequence (->
        orcCallback = orc.waitFor((arg) -> log += "callback #{arg} ")
      ), (->
        log += 'end of sequence'
      )
      expect(log).to.equal ''

      orcCallback('testarg')
      expect(log).to.equal 'callback testarg end of sequence'

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
      expect(log).to.equal ''

      orcOuterCallback()
      expect(log).to.equal 'callback '

      orcInnerCallback()
      expect(log).to.equal 'callback inner callback end of sequence'

  describe 'sequence', ->
    it 'works with non-async functions', ->
      log = ''
      a = -> log += 'a'
      b = -> log += 'b'

      orc.sequence a, b

      expect(log).to.equal 'ab'

    it 'works with async functions', ->
      log = ''
      a = -> log += 'a'; orc.waitFor()
      b = -> log += 'b'
           
      context = orc.sequence a, b
      expect(log).to.equal 'a'
          
      context.done()
      expect(log).to.equal 'ab'

    it 'can run several simulatenously', ->
      log1 = ''
      a = -> log1 += 'a'; orc.waitFor()
      b = -> log1 += 'b'

      log2 = ''
      c = -> log2 += 'c'; orc.waitFor()
      d = -> log2 += 'd'
           
      context1 = orc.sequence a, b
      expect(log1).to.equal 'a'
      context2 = orc.sequence c, d
      expect(log2).to.equal 'c'

      context2.done()
      expect(log2).to.equal 'cd'

      context1.done()
      expect(log1).to.equal 'ab'

    it 'can nest non-async', ->
      log = ''
      a = -> log += 'a'
      b = -> orc.sequence (-> log += 'b'), (-> log += 'b')
      c = -> log += 'c'

      orc.sequence a, b, c
          
      expect(log).to.equal 'abbc'

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
      expect(log).to.equal 'a'
          
      context.done()
      expect(log).to.equal 'ab'

      inner_context.done()
      expect(log).to.equal 'abbc'

    it 'properly handles a sequence that ends waiting without functions', ->
      log = ''

      inner_context = null
      orc.sequence (->
        inner_context = orc.sequence (-> log += 'a'), (-> orc.waitFor())
      ), (->
        log += 'b'
      )

      expect(log).to.equal 'a'

      inner_context.done()
      expect(log).to.equal 'ab'
