class Orc
    constructor: ->
        @stacks = []
        @currentStack = null

    sequence: (functions...) ->
        # take note of whether or not orc is currently executing anything
        currentlyExecuting = @currentStack?
        # each sequence needs an execution context so that orc can keep the
        # information about each sequence isolated from the rest 
        context = new ExecutionContext functions
        # orc either adds this context to the current stack or creates a new
        # stack, @currentStack is only set when orc is already in the process
        # of executing a sequence
        if currentlyExecuting
            @currentStack.push context
        else
            @stacks.push [context]
            @execute()
        # return the context just in case it is needed for anything
        context

    waitFor: (callback) ->
        # first wait, then save the context and contextStack in this scope so
        # that they can be used to execute the decorated callback later
        context = @wait()
        contextStack = @currentStack
        =>
            # set the current contextStack so that calls to orc.waitFor made by
            # the callback will be routed to the correct context
            @currentStack = contextStack
            callback arguments...
            # this done is required because of the @wait line at the beginning
            # of the decorator function
            context.done()
            # we don't need @currentStack for the time being
            @currentStack = null

    execute: =>
        while @canExecute()
            for @currentStack in @stacks
                context = @currentStack.last()
                context.executeNext @execute if context.canExecute()
                @currentStack.pop() unless context.waiting() or context.canExecute()
                if @currentStack.isEmpty()
                    @stacks.remove @currentStack
                    break

        @currentStack = null

    wait: ->
        @currentStack.last().wait()

    canExecute: ->
        for contextStack in @stacks
            return true unless contextStack.isEmpty() or contextStack.last().waiting()

class ExecutionContext
    constructor: (@functions) ->
        @holds = 0

    waiting: ->
        @holds > 0

    wait: ->
        @holds++
        @

    done: ->
        return unless @waiting()
        @holds--
        @readyCallback() unless @waiting()

    canExecute: ->
        not @functions.isEmpty()

    executeNext: (readyCallback) ->
        @functions.shift()()
        @readyCallback = readyCallback if @waiting()

Array::isEmpty = ->
    @length == 0

Array::last = ->
    @[@length-1]

Array::remove = (object) ->
    @splice @indexOf(object), 1

module.exports.Orc = Orc
module.exports.ExecutionContext = ExecutionContext
module.exports.orc = new Orc()
