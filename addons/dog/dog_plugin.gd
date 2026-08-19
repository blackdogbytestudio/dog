@tool
extends EditorPlugin

const TERMINAL_SCENE = preload("res://addons/my_custom_addon/dog_terminal.tscn")
var terminal: Control

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	terminal = TERMINAL_SCENE.instantiate()
	
	terminal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	terminal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Load it next to Output/Debugger
	add_control_to_bottom_panel(terminal, "Dog Terminal")



func _exit_tree() -> void:
	if terminal:
		remove_control_from_bottom_panel(terminal)
		terminal.queue_free()
