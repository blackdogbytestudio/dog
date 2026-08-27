extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var _dog: DogPlatformerFacade = $DogPlatformerFacade

func _physics_process(delta: float) -> void:
	jump()
	move_and_slide()

func jump() -> void:
	_dog.jump()
