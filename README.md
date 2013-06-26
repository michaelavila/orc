# orc

Orc orchestrates the execution of lists of functions. This library will help you:

1. clearly and concisely express asynchronous flow
2. do so without interfering with your API

Get it from npm:

    npm install orc

## Example

The following example is typical: make an HTTP request for some content and
render that content in some way once we receive it. Here we tell orc to
sequence the two functions loadData and renderPage. In the loadData function we
tell orc to waitFor a response and then to wait for the data to finish loading.
The renderPage function just logs "now render the page" to the console.

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

        response.on 'data', handleData

        # here we wait as well
        response.on 'end', orc.waitFor()

    # here we wait
    http.get options, orc.waitFor(handleHTTPGet)

renderPage = ->
    console.log 'now render the page'


# this is where we initiate the sequence
orc.sequence loadData, renderPage
```

If you run the example you will see that everything is called in the correct
order. The renderPage function does not run until we have received all of the
data from the loadData function. I've listed the output below:

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

## How does it work?

Everything begins with you telling orc to sequence some functions. Orc places
these condemned functions into an ExecutionContext. The context lets orc keep
the details of each execution separated. These details are things like the
functions being executed and whether or not the execution is on hold for
anything. At this point orc will begin executing, if it's not already.

Orc can execute both dependent and independent sequences. A sequence is dependent
when it requires another sequence to complete before it completes. Dependent
sequences are called inside of other sequences kinda like this:

```coffeescript
orc.sequence ->
  orc.sequence ...
```

Independent sequences on the other hand look kinda like this:

```coffeescript
orc.sequence ...
orc.sequence ...
```

Whether or not one sequence depends on another sequence determines where orc
puts the execution context. If the sequence is independent orc will add it
alongside whatever other contexts exist. If the sequence is dependent orc
will stack the context on top of whichever context depends on it. Orc then
manages these dependencies by only executing from the context at the top of of
each stack.

## Getting Started

1. Require orc

```coffeescript
orc = require('orc').orc
```

2. Sequence some functions

```coffeescript
loadContent = ->
bar = ->

orc.sequence foo, bar
```

3. Wait for some stuff

```coffeescript
loadContent = ->
  request = loader.get someDataUrl
  request.on 'data', orc.waitFor(parseData)

renderContent = ->
  animator.do animationOptions orc.waitFor()

orc.sequence loadContent, renderContent
```

4. Tell orc how to error

```coffeescript
loadContent = ->
  request = loader.get someDataUrl
  request.on 'data', orc.waitFor(parseData)
  request.on 'error', orc.errorOn()

renderContent = ->
  animator.do animationOptions orc.waitFor()

orc.sequence loadContent, renderContent
```

5. Handle sequence error instead of erroring

```coffeescript
loadContent = ->
  request = loader.get someDataUrl
  request.on 'data', orc.waitFor(parseData)
  request.on 'error', orc.errorOn()

renderContent = ->
  animator.do animationOptions orc.waitFor()

context = orc.sequence loadContent, renderContent
context.handleError = (error, context) -> console.log "#{error} for #{context}"
```

That's it.
