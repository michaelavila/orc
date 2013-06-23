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

    executeNext: ->
        @functions.shift()()

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
        executor = new ExecutionContext functions
        if @currentStack?
            @currentStack.push executor
        else
            @contexts.push [executor]
        @execute()
        executor

    canExecute: ->
        for executorStack in @contexts
            return true unless executorStack.isEmpty() or executorStack.last().waiting()

    execute: =>
        while @canExecute()
            for executorStack in @contexts
                @currentStack = executorStack
                context = @currentStack.last()

                context.executeNext @execute if context.hasFunctions()
                context.readyCallback = @execute if context.waiting()
                executorStack.pop() unless context.waiting() or context.hasFunctions()

                if executorStack.isEmpty()
                    @contexts.remove executorStack
                    break
        @currentStack = null

module.exports.Orchestrator = Orchestrator
module.exports.ExecutionContext = ExecutionContext
module.exports.orc = new Orchestrator()
