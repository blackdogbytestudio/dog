## DogPDA — pushdown automaton component.
## Expects DogPDAState instances so pause and resume are available.
##
## push() — suspends current via pause(), activates new via enter().
## pop()  — exits top via exit(), resumes below via resume().
## send() — replaces top of stack, not a push.
##
## Usage in actor:
##   @onready var pda: DogPDA = $DogPDA
##   var state_gameplay = StateGameplay.new() # extends DogPDAState
##   var state_pause    = StatePause.new()    # extends DogPDAState
##
##   func _ready():
##       pda.init(state_gameplay, self)
##
##   func _process(delta):
##       pda.update(delta)
##
##   func _on_pause_pressed():
##       pda.push(state_pause)
##
##   func _on_resume_pressed():
##       pda.pop()
class_name DogPDA
extends DogMachine


var _stack: Array[DogPDAState] = []


## Init: push the initial state as the first stack entry.
func init(initial: DogState, host: Node) -> void:
	_host = host
	push(initial as DogPDAState)


## Push a new state on top.
## Current state is paused (not exited) — it stays on the stack.
func push(state: DogPDAState) -> void:
	if _current != null:
		(_current as DogPDAState).pause(_host)
	_stack.push_back(state)
	_current = state
	_current.enter(_host)


## Pop the top state.
## Top is fully exited, the state below resumes.
func pop() -> void:
	if _stack.size() <= 1:
		push_warning("DogPDA: cannot pop the last state.")
		return
	_current.exit(_host)
	_stack.pop_back()
	_current = _stack.back()
	(_current as DogPDAState).resume(_host)


## Peek at the state below the top without popping.
func peek() -> DogPDAState:
	if _stack.size() < 2:
		return null
	return _stack[_stack.size() - 2]


## Stack depth — useful for debug.
func depth() -> int:
	return _stack.size()


## send() replaces the top of the stack — not a push.
## Goes through exit → enter, not pause → resume.
func _transition(next: DogState) -> void:
	_current.exit(_host)
	_stack[_stack.size() - 1] = next as DogPDAState
	_current = next
	_current.enter(_host)
