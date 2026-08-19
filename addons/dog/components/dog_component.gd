@tool
class_name DogComponent
extends Node
## Base class for all components in Dog.
##
## Dog it's your best friend. Components exist to run the host's logic
## and calculations. The host has to be of a type other than null.
## [br][br]
## A component is meant to be unique on its host, you can have
## multiple different types, but not two of the same type. If you
## want more functionality, or want to disable one, prefer creating
## a new component that extends the previous one.

## The node that owns this component. Set from [member Node.owner]
## on [method _ready]; guaranteed non-null once the game is running.
var host: Node

func _ready() -> void:
	host = owner
	if Engine.is_editor_hint():
		return
	if host == null:
		push_error("%s needs a host." % name)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if owner == null:
		warnings.append("This component needs a host.")
	return warnings
