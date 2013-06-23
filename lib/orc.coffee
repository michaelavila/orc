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
        @functions.length > 0

    executeNext: ->
        @functions.shift()()

class Orchestrator
    constructor: ->
        @executors = []
        @currentExecutionContextStack = null

    currentExecutionContext: ->
        @currentExecutionContextStack[@currentExecutionContextStack.length-1]

    wait: ->
        @currentExecutionContext().wait()

    waitFor: (callback) ->
        @wait()
        executionStack = @currentExecutionContextStack
        executor = @currentExecutionContext()
        =>
            @currentExecutionContextStack = executionStack
            callback arguments...
            executor.done()
            @currentExecutionContextStack = null

    sequence: (functions...) ->
        executor = new ExecutionContext functions
        if @currentExecutionContextStack?
            @currentExecutionContextStack.push executor
        else
            @executors.push [executor]
        @execute()
        executor

    canExecute: ->
        for executorStack in @executors
            if executorStack.length > 0 and not executorStack[executorStack.length-1].waiting()
                return true
        return false

    execute: =>
        while @canExecute()
            for executorStack in @executors
                @currentExecutionContextStack = executorStack
                executor = @currentExecutionContext()

                if executor.hasFunctions()
                    executor.executeNext()

                if executor.waiting()
                    executor.readyCallback = @execute
                if not executor.waiting() and not executor.hasFunctions()
                    executorStack.pop()

                if executorStack.length == 0
                    @executors.splice @executors.indexOf(executorStack), 1
                    break
        @currentExecutionContextStack = null

module.exports.Orchestrator = Orchestrator
module.exports.ExecutionContext = ExecutionContext
module.exports.orc = new Orchestrator()
