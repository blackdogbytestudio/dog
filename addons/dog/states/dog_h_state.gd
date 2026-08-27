@abstract
class_name DogHState
extends DogFSMState
## DogHState — base for hierarchical states.
## The hierarchy is GDScript inheritance, not a data structure.
## Parents are pure guards — no movement, no animation.
##
## Convention: call super() on the FIRST line of update().
## If super() returns non-null a guard intercepted — return it.
## Then run your own logic.
##
## [codeblock]
##
## StateAlive   (extends DogHState)  — guard: if dead return die
## StateGrounded(extends StateAlive) — guard: if airborne return airborne
## StateIdle    (extends StateGrounded) — leaf: movement logic
##
## StateIdle.update():
##   var next = super(owner, delta)  # runs Grounded → Alive guards
##   if next: return next            # a guard intercepted
##   # idle logic here
##   return null
## [/codeblock]
