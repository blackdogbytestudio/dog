@tool
extends EditorPlugin

func _enable_plugin() -> void:
	DogScaffoldSetup.install()
	DogTemplateSetup.install()


func _disable_plugin() -> void:
	pass


func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	pass
