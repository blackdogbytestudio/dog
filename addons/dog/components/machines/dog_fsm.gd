@tool
class_name DogFSM
extends DogMachine
## DogFSM — flat finite state machine.
## States return the next DogState from update() to transition.
## send() forces a transition from outside at any time.
##
## Usage in actor:
##   @onready var fsm: DogFSM = $DogFSM
##   var state_idle  = StateIdle.new()
##   var state_walk  = StateWalk.new()
##   var state_hurt  = StateHurt.new()
##
##   func _ready():
##       fsm.init(state_idle, self)
##
##   func _process(delta):
##       fsm.update(delta)
##
##   func _on_hitbox():
##       fsm.send(state_hurt)

var _locked: bool = false

## Force an immediate transition to state, bypassing locked.
## Use this from signals, hitboxes, external events:
##   fsm.force(state_hurt)
func force(state: DogState) -> void:
	if state == null:
		push_warning("DogMachine: force received null state.")
		return
	_transition(state)

func lock() -> void:
	if not _locked:
		_locked = true

func unlock() -> void:
	if _locked:
		_locked = false
