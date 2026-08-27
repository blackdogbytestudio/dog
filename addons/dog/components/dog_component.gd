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

var host: Node = owner:
	set = set_host,
	get = get_host

func _get_configuration_warnings() -> PackedStringArray:
	return _validate_host()


func get_host() -> Node:
	return owner as Node

func set_host(host: Node) -> void:
	owner = host


func _validate_host() -> PackedStringArray:
	if not host:
		var expected_type: String = "Node"
		
		for method in get_method_list():
			if method.name == "host":
				var return_info: Dictionary = method["return"]
				if return_info.has("class_name") and return_info["class_name"] != &"":
					expected_type = return_info["class_name"]
				break
				
		return [
			"This component needs a host as %s. Either place it under an owner of that type, or call set_host()." % expected_type
		]
		
	return []
