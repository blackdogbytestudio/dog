@tool
class_name DogMachine
extends DogComponent
## Base for all state machine components.

var host: Node:
	get: return host_type()

## The currently active state.
var _current: DogState

## Initialise the machine with a starting state reference.
## [codeblock]
## func _
##   fsm.init(state_idle)
func init(state: DogState) -> void:
	owner = host
	_current = state
	_current.enter(host)


## Drive the active state. Call from the actor's _process:
##   fsm.update(delta)
func update(delta: float) -> void:
	if _current == null:
		return
	var next: DogState = _current.update(host, delta)
	if next != null:
		_transition(next)


## Exit current, enter next. Override in subclasses if needed.
func _transition(next: DogState) -> void:
	if next == null:
		return
	if _current != null:
		if _current.get_class() == next.get_class():
			return
		_current.exit(host)
	_current = next
	_current.enter(host)
