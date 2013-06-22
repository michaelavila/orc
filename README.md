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

So orc will, hopefully, help you:

1. clearly and concisely express asynchronous flow control
2. do so without interfering with the API of your module

## How does it work?

The design of orc is simple.

Orc orchestrates the execution of a list of functions. Executing this list of
functions one after the other is called a sequence. Orc, before proceeding from
one function to the next, checks to see if it is waiting.  If orc is waiting
then it stops and only proceeds to execute the sequence once it is done waiting.

At any point during the execution of your sequence functions orc can be told to
wait until a callback is executed. Orc can be instructed to wait for no, one,
or many things. Orc can run sequences in parallel and nested in one another.

Orc achieves this by creating an executor for each sequence. This executor acts
as an execution context in which we keep track of which functions belong to the
sequence and whether we are waiting on anything from them. If wait is called during
a sequence then it is routed to the current executor. If sequence is called
during a sequence then an executor is placed on the execution stack and executed
before completing the original sequence. When calling sequence in parallel with
another sequence orc creates an execution stack and places it next to the current
sequence execution stack.
