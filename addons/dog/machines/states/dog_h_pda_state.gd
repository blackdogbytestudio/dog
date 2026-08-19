@abstract
class_name DogHPDAState
extends DogPDAState
## DogHPDAState — base for states that live on a DogHPDA stack.
## Extends DogPDAState adding the super() guard convention.
## Use this instead of DogPDAState when the state will be
## pushed onto a DogHPDA and uses a guard hierarchy.
##
## Full lifecycle:
##   enter  → fresh start, connect signals
##   pause  → freeze, keep signals alive
##   resume → unfreeze, pick up where you left off
##   exit   → fully done, disconnect signals and timers
##
## Convention: call super() on the FIRST line of update().
## If super() returns non-null a guard intercepted — return it.
##
## Example hierarchy:
##   class StateAlive    extends DogHPDAState — guard: if dead return die
##   class StateGrounded extends StateAlive   — guard: if airborne return airborne
##   class StateIdle     extends StateGrounded — leaf: movement logic
