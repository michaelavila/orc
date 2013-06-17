class Executor
    constructor: (@functions) ->
        @holds = 0

    waiting: ->
        @holds > 0

    wait: ->
        @holds++

    done: ->
        if not @waiting()
            return
        @holds--
        if not @waiting()
            @readyCallback()

    hasFunctions: ->
        @functions.length > 0

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

    waitForCallback: (callback) ->
        @wait()
        executor = @currentExecutor()
        -> callback(); executor.done()

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
            if executorStack.length > 0 and not executorStack[executorStack.length-1].waiting()
                return true
        return false

    execute: =>
        while @canExecute()
            for executorStack in @executors
                @currentExecutorStack = executorStack
                executor = @currentExecutor()

                if executor.hasFunctions()
                    executor.executeNext()

                if executor.waiting()
                    executor.readyCallback = @execute
                if not executor.waiting() and not executor.hasFunctions()
                    executorStack.pop()

                if executorStack.length == 0
                    @executors.splice @executors.indexOf(executorStack), 1
                    break
        @currentExecutorStack = null

module.exports.Orchestrator = Orchestrator
module.exports.Executor = Executor
module.exports.orc = new Orchestrator()
