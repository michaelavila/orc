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
