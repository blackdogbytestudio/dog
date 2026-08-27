extends Node2D


# somewhere reachable by input, e.g. in an autoload or your main scene
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"): # Esc, or bind any test key
		get_child(1).queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		print_orphan_nodes()
