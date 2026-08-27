@tool
class_name DogJump2D
extends DogBody2D
## Jump logic for a [CharacterBody2D] host.
##
## Pure calculation: this component never reads input and never decides
## when to jump. A state (or a facade forwarding to a state) calls
## [method jump] when it has already decided the jump should happen.
## [method reset_jumps] should be called by the grounded state's [method DogState.enter].
 
@export var max_jumps: int = 1
@export var jump_force: float = 400.0
 
var _jumps_remaining: int = max_jumps
 
## Applies the jump impulse to the host and consumes one jump.
## Callers must check [method can_jump] first.
func jump() -> void:
	host.velocity.y = -jump_force
	_jumps_remaining -= 1
 
 
func can_jump() -> bool:
	return _jumps_remaining > 0
 
 
## Call from the grounded state's enter() to refill jumps.
func reset_jumps() -> void:
	_jumps_remaining = max_jumps
 
