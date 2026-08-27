@tool
class_name DogHFSM
extends DogFSM
## DogHFSM — hierarchical state machine component.
## Works exactly like DogFSM — the hierarchy lives inside
## the states via GDScript inheritance and super().
## The machine itself does not change.
##
## Usage in actor:
##   @onready var hfsm: DogHFSM = $DogHFSM
##   var state_idle    = StateIdle.new()    # extends StateGrounded
##   var state_walk    = StateWalk.new()    # extends StateGrounded
##   var state_airborne= StateAirborne.new()# extends StateAlive
##
##   func _ready():
##       hfsm.init(state_idle, self)
##
##   func _process(delta):
##       hfsm.update(delta)
