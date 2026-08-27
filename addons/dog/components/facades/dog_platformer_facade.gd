@tool
class_name DogPlatformerFacade
extends DogFacade
## Flattened configuration surface for a simple platformer character.
##
## Composes a [DogJump2D] internally and exposes its tunables directly
## on this node. As move/gravity components are added, they get exported
## and forwarded here the same way — the actor only ever talks to this
## single facade.
## [br][br]
## Usage in the actor:
## [codeblock]
## @onready var platformer: DogPlatformerFacade = $Platformer
##
## func _physics_process(delta):
##     if is_on_floor():
##         platformer.reset_jumps()
##     if Input.is_action_just_pressed("jump") and platformer.can_jump():
##         platformer.jump()
## [/codeblock]

@export var max_jumps: int = 1:
	set(value):
		max_jumps = value
		_jump.max_jumps = value

@export var jump_force: float = 400.0:
	set(value):
		jump_force = value
		_jump.jump_force = value

var _jump: DogJump2D = DogJump2D.new()

func get_host() -> CharacterBody2D:
	return owner


func dog_leash(...components: Array) -> void:
	super.dog_leash(_jump)


func jump() -> void:
	_jump.jump()


func can_jump() -> bool:
	return _jump.can_jump()


func reset_jumps() -> void:
	_jump.reset_jumps()
