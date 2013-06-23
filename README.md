# orc

Orc is designed with one particular goal in mind: to simplify how event driven
programs are written. The approach orc takes in solving this problem is simpler
and less obtrusive than the [alternatives](https://github.com/caolan/async).
This is the interface to orc:

```coffeescript
# run a list of functions one after another
# waiting between functions that require
# some kind of asynchronous handling
orc.sequence functions...

# and in the functions that the sequence calls
# you wrap the callbacks you want to wait for
# with the orc waitFor decorator
callback = orc.waitFor eventCallback
```

## Why use it?

Using orc should result in programs that avoid two common problems. The first
is created when using the javascript event mechanism directly to express the
asynchronous parts of your program. In this situation the problem is that the
flow of the program jumps from event handler to event handler. This makes the
program difficult to understand and work with. The second situation involves
using something like caolan's [async](https://github.com/caolan/async).
Unfortunately, implementations like this require you to introduce implementation
details about how asynchrony is managed into the signature of the asynchronous
methods.

So orc will help you:

1. clearly and concisely express asynchronous flow control
2. do so without interfering with the API of your module

## How does it work?

Orc is a simple beast. A methodical executor, orc orchestrates the execution of
lists of functions. Orc has two execution strategies: one by one or all at once.
These strategies can be carried out alone, combined, and at the same time. At
any point during the execution orc can be asked to wait so that a more thorough
execution can take place.

Orc achieves all of this through the use of some simple data structures and an
execution context. Execution contexts help orc keep track of what it is
executing, the strategy being used to execute, and whether or not orc should
wait before proceeding with the next execution. Orc uses a set of stacks of
queues to ensure that each execution is carried out at the correct time and in
the correct order.

The condemned functions are placed into queues so that they can be executed in
the correct order. Each execution context keeps track of a single queue. When
a new execution is called for during another execution a new context is created
and stacked on top of the current context. Orc only carries out executions from
the top of the execution context stacks. When orc is asked to carry out multiple
executions at the same time it simply places all of the execution stacks into a
set. That is it: a set of stacks of queues and a context to keep track of extra
information associated with each queue.

## Working Example

The following example loads some content, in this case http://google.com, and
then renders that content in some way.

```coffeescript
orc = require('./lib/orc').orc

loadData = ->
    console.log 'load the data and wait'
    http = require 'http'
    options =
        host: 'google.com'
        port: 80
        path: ''

    handleHTTPGet = (response) ->
        response.setEncoding 'utf8'

        handleData = (chunk) ->
            console.log "data loaded #{chunk}"

        # here we wait as well
        response.on 'data', orc.waitFor(handleData)

    # here we wait
    http.get options, orc.waitFor(handleHTTPGet)

renderPage = ->
    console.log 'now render the page'


# this is where we initiate the sequence
orc.sequence loadData, renderPage
```

Obviously the important thing here is that the content must complete loading
before we proceed to render. I've included some sample code for making an http
request in the `loadData` function and `renderPage` simply reports that it was
called. I imagine you can fill in the details of what `renderPage` might go on
to do.

If you save this example to say `example.coffee` and then run the coffee
interpreter on it you should see the following:

```bash
$ coffee example.coffee
load the data and wait
data loaded <HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>301 Moved</TITLE></HEAD><BODY>
<H1>301 Moved</H1>
The document has moved
<A HREF="http://www.google.com/">here</A>.
</BODY></HTML>

now render the page
```

You can see that everything was executed in the correct order by inspecting the
output. The data is loaded and then at the very end it is "rendered" (even
though we aren't technically rendering it.)
