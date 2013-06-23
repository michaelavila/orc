Array::isEmpty = ->
    @length == 0

Array::last = ->
    @[@length-1]

Array::remove = (object) ->
    @splice @indexOf(object), 1

class ExecutionContext
    constructor: (@functions) ->
        @holds = 0

    waiting: ->
        @holds > 0

    wait: ->
        @holds++

    done: ->
        return unless @waiting()
        @holds--
        @readyCallback() unless @waiting()

    hasFunctions: ->
        not @functions.isEmpty()

    executeNext: (readyCallback) ->
        @functions.shift()()
        @readyCallback = readyCallback if @waiting()

class Orchestrator
    constructor: ->
        @contexts = []
        @currentStack = null

    wait: ->
        @currentStack.last().wait()

    waitFor: (callback) ->
        @wait()
        executionStack = @currentStack
        =>
            @currentStack = executionStack
            callback arguments...
            executionStack.last().done()
            @currentStack = null

    sequence: (functions...) ->
        context = new ExecutionContext functions
        if @currentStack? then @currentStack.push context else @contexts.push [context]
        @execute()
        context

    canExecute: ->
        for contextStack in @contexts
            return true unless contextStack.isEmpty() or contextStack.last().waiting()

    execute: =>
        while @canExecute()
            for contextStack in @contexts
                @currentStack = contextStack
                context = @currentStack.last()
                context.executeNext @execute if context.hasFunctions()
                contextStack.pop() unless context.waiting() or context.hasFunctions()
                if contextStack.isEmpty()
                    @contexts.remove contextStack
                    break
        @currentStack = null

module.exports.Orchestrator = Orchestrator
module.exports.ExecutionContext = ExecutionContext
module.exports.orc = new Orchestrator()
