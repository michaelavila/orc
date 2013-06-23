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
