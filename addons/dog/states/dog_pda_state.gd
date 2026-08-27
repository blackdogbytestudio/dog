@abstract
class_name DogPDAState
extends DogState
## DogStatePDA — base for states that live on a DogPDA stack.
## Extends DogState adding pause and resume virtuals.
## Use this instead of DogState when the state will be
## pushed onto a DogPDA and needs to freeze/unfreeze cleanly.
##
## Lifecycle on a DogPDA stack:
##   enter  → state becomes active for the first time
##   pause  → state is suspended, a new state pushed on top
##   resume → state is back on top after the above was popped
##   exit   → state is done, clean up signals and timers
##
## Example:
##   class StateGameplay extends DogStatePDA:
##       func pause(host):
##           host.set_physics_process(false)
##       func resume(host):
##           host.set_physics_process(true)

## Called when a new state is pushed on top of this one.
## Freeze here — do not disconnect signals or clean up.
@abstract
func pause(host: Node) -> void


## Called when the state above this one is popped.
## Unfreeze here — pick up exactly where you left off.
@abstract
func resume(owner: Node) -> void
