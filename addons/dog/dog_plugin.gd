@tool
extends EditorPlugin

var _panel: DogPanel

func _enable_plugin() -> void:
	DogScaffoldSetup.install()
	DogTemplateSetup.install()


func _disable_plugin() -> void:
	pass


func _enter_tree() -> void:
	var cli := DogCli.new()
	cli.register_folder("res://addons/dog/generators/commands")
	_panel = DogPanel.new(cli)
	add_control_to_bottom_panel(_panel, "DOG")


func _exit_tree() -> void:
	remove_control_from_bottom_panel(_panel)
	_panel.free()
