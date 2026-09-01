class_name NewScript
extends DogHPDAState

func enter(host: Node) -> void:
	_enter(host as _HOST_)


func exit(host: Node) -> void:
	_exit(host as _HOST_)


func update(host: Node, delta: float) -> DogState:
	return _update(host as _HOST_, delta)


func pause(host: Node) -> void:
	_pause(host as _HOST_)


func resume(host: Node) -> void:
	_resume(host as _HOST_)


func _enter(host: _HOST_) -> void:
	pass


func _exit(host: _HOST_) -> void:
	pass


func _update(host: _HOST_, delta: float) -> DogState:
	return null


func _pause(host: _HOST_) -> void:
	pass


func _resume(host: _HOST_) -> void:
	pass
