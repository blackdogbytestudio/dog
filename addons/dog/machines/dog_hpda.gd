class_name DogHPDA
extends DogPDA
## DogHPDA — hierarchical pushdown automaton component.
## Combines DogHFSM guard hierarchy with DogPDA stack behavior.
## Expects DogHPDAState instances on the stack.
##
## push() — suspends current via pause(), activates new via enter().
## pop()  — exits top via exit(), resumes below via resume().
## send() — replaces top of stack, not a push.
##
## Usage in actor:
##   @onready var hpda: DogHPDA = $DogHPDA
##   var state_idle     = StateIdle.new()     # extends DogHPDAState
##   var state_dialogue = StateDialogue.new() # extends DogHPDAState
##
##   func _ready():
##       hpda.init(state_idle, self)
##
##   func _process(delta):
##       hpda.update(delta)
##
##   func _on_dialogue_started():
##       hpda.push(state_dialogue)
##
##   func _on_dialogue_ended():
##       hpda.pop()

## Init: validates DogHPDAState and delegates to DogPDA.
func init(initial: DogState, host: Node) -> void:
	var hpda_state := initial as DogHPDAState
	if hpda_state == null:
		push_error("DogHPDA: state must extend DogHPDAState.")
		return
	_host = host
	push(hpda_state)


## Push: validates DogHPDAState then delegates to DogPDA.
func push(state: DogState) -> void:
	var hpda_state := state as DogHPDAState
	if hpda_state == null:
		push_error("DogHPDA: state must extend DogHPDAState.")
		return
	super(hpda_state)
