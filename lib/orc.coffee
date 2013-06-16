class Executor
    constructor: (@functions) ->
        @waiting = false

    wait: ->
        @waiting = true

    done: ->
        @waiting = false
        @readyCallback()

    hasFunctions: ->
        @functions.length > 0

    canExecute: ->
        @hasFunctions() and not @waiting

    executeNext: ->
        @functions.shift()()

class Orchestrator
    constructor: ->
        @executors = []
        @currentExecutorStack = null

    currentExecutor: ->
        @currentExecutorStack[@currentExecutorStack.length-1]

    wait: ->
        @currentExecutor().wait()

    sequence: (functions...) ->
        executor = new Executor functions
        if @currentExecutorStack?
            @currentExecutorStack.push executor
        else
            @executors.push [executor]
        @execute()
        executor

    canExecute: ->
        for executorStack in @executors
            if executorStack.length > 0 and executorStack[executorStack.length-1].canExecute()
                return true
        return false

    execute: =>
        while @canExecute()
            for executorStack in @executors
                @currentExecutorStack = executorStack
                executor = @currentExecutor()
                executor.executeNext()

                if executor.waiting and executor.hasFunctions()
                    executor.readyCallback = @execute
                else if not executor.hasFunctions()
                    executorStack.pop()

                if executorStack.length == 0
                    @executors.splice @executors.indexOf(executorStack), 1
                    break
        @currentExecutorStack = null

module.exports.orc = new Orchestrator()
