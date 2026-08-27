@tool
extends EditorPlugin

func _enable_plugin() -> void:
	DogScaffoldInstaller.install()
	DogTemplateInstaller.install()
	DogGlobalsInstaller.install()
	DogAutoloadInstaller.install(self)


func _disable_plugin() -> void:
	DogAutoloadInstaller.uninstall(self)


func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	pass
