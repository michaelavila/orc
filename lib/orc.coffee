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

class Orc
    constructor: ->
        @stacks = []
        @currentStack = null

    wait: ->
        @currentStack.last().wait()

    waitFor: (callback) ->
        @wait()
        contextStack = @currentStack
        =>
            @currentStack = contextStack
            callback arguments...
            contextStack.last().done()
            @currentStack = null

    sequence: (functions...) ->
        context = new ExecutionContext functions
        if @currentStack? then @currentStack.push context else @stacks.push [context]
        @execute()
        context

    canExecute: ->
        for contextStack in @stacks
            return true unless contextStack.isEmpty() or contextStack.last().waiting()

    execute: =>
        while @canExecute()
            for contextStack in @stacks
                @currentStack = contextStack
                context = @currentStack.last()
                context.executeNext @execute if context.hasFunctions()
                contextStack.pop() unless context.waiting() or context.hasFunctions()
                if contextStack.isEmpty()
                    @stacks.remove contextStack
                    break
        @currentStack = null

module.exports.Orc = Orc
module.exports.ExecutionContext = ExecutionContext
module.exports.orc = new Orc()
