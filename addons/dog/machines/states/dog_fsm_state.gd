@abstract
class_name DogFSMState
extends DogState

## Blocks update() from progressing to the next state.
## Set to true in enter() when the state needs to wait
## for a timer, animation, or signal before moving on.
var locked: bool = false
