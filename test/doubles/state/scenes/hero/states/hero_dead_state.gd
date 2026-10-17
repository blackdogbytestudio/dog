class_name HeroDeadState
extends HeroState


func _enter(host: Hero) -> void:
	pass


func _exit(host: Hero) -> void:
	pass


func _update(host: Hero, delta: float) -> DogState:
	var next := super(host, delta)
	if next:
		return next
	return null


func _pause(host: Hero) -> void:
	pass


func _resume(host: Hero) -> void:
	pass
