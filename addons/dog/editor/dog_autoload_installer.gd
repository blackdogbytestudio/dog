@tool
class_name DogAutoloadInstaller
extends DogEditor

## Default autoload scripts shipped with the addon; copied out on first install.
const AUTOLOAD_SRC := "res://addons/dog/scripts/autoloads"

## User-editable copies — the ones actually registered as autoloads.
const AUTOLOAD_DEST := "res://autoloads"

## Singleton name -> script filename.
const SINGLETONS := {
	"SignalBus": "signal_bus.gd",
}

## Public
static func install(plugin: EditorPlugin) -> void:
	DirAccess.make_dir_recursive_absolute(AUTOLOAD_DEST)
	
	for singleton_name: String in SINGLETONS.keys():
		var file_name: String = SINGLETONS[singleton_name]
		var src_path: String = "%s/%s" % [AUTOLOAD_SRC, file_name]
		var dest_path: String = "%s/%s" % [AUTOLOAD_DEST, file_name]
		
		if not FileAccess.file_exists(dest_path):
			if not FileAccess.file_exists(src_path):
				push_warning("DOG: default autoload not found at %s" % src_path)
				continue
			DirAccess.copy_absolute(src_path, dest_path)
			
		plugin.add_autoload_singleton(singleton_name, dest_path)


## Public
static func uninstall(plugin: EditorPlugin) -> void:
	for singleton_name: String in SINGLETONS.keys():
		plugin.remove_autoload_singleton(singleton_name)
