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

Using orc should result in programs that avoid two common problems. The first
is created when using the javascript event mechanism directly to express the
asynchronous parts of your program. In this situation the problem is that the
flow of the program jumps from event handler to event handler. This makes the
program difficult to understand and work with. The second situation involves
using something like caolan's [async](https://github.com/caolan/async).
Unfortunately, implementations like this require you to introduce implementation
details about how asynchrony is managed into the signature of the asynchronous
methods.

So orc will, hopefully, help you:

1. clearly and concisely express asynchronous flow control
2. do so without interfering with the API of your module
