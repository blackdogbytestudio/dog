@abstract
class_name DogState
extends RefCounted
## DogState — base class for all states.
## Extends RefCounted: pure script, never enters the scene tree.
## host is passed explicitly on every call so states
## treat the actor as a typed API.
##
## locked: when true update() stops natural progression.
## send() on the machine always bypasses locked.

## Called when this state becomes active.
@abstract
func enter(host: Node) -> void


## Called when this state is leaving.
## Disconnect signals, stop timers, clean up here.
@abstract
func exit(host: Node) -> void


## Called every frame by the host via machine.update(delta).
## Return a DogState to request a transition, null to stay.
## Always check locked first — call super() at the top.
@abstract
func update(host: Node, delta: float) -> DogState
