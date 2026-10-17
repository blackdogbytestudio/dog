class_name HeroState
extends DogHPDAState


func enter(host: Node) -> void:
	_enter(host as Hero)


func exit(host: Node) -> void:
	_exit(host as Hero)


func update(host: Node, delta: float) -> DogState:
	return _update(host as Hero, delta)


func pause(host: Node) -> void:
	_pause(host as Hero)


func resume(host: Node) -> void:
	_resume(host as Hero)


func _enter(host: Hero) -> void:
	pass


func _exit(host: Hero) -> void:
	pass


func _update(host: Hero, delta: float) -> DogState:
	return null


func _pause(host: Hero) -> void:
	pass


func _resume(host: Hero) -> void:
	pass
