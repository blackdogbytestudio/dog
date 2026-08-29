extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var _dog:= $DogPlatformerFacade2D as DogPlatformerFacade2D


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		
			_dog.apply_gravity(delta)
	else:
		_dog.reset_jumps()
	if Input.is_action_just_pressed("ui_accept") and _dog.can_jump():
		_dog.jump()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	_dog.move_x(direction, delta)

	move_and_slide()
