@tool
class_name DogGlobalsInstaller
extends DogEditor

const GLOBALS_SRC := "res://addons/dog/globals"
const GLOBALS_DEST := "res://globals"

## Global class name -> template filename.
const STATIC_GLOBALS := {
	"Rule": "rule.gd",
	"Action": "action.gd",
}


## Public
static func install() -> void:
	DirAccess.make_dir_recursive_absolute(GLOBALS_DEST)

	for target_class: String in STATIC_GLOBALS.keys():
		var file_name: String = STATIC_GLOBALS[target_class]
		var dest_path := "%s/%s" % [GLOBALS_DEST, file_name]

		if FileAccess.file_exists(dest_path):
			continue

		var src_path := "%s/%s" % [GLOBALS_SRC, file_name]
		if not FileAccess.file_exists(src_path):
			push_warning("DOG: default global not found at %s" % src_path)
			continue

		var body := FileAccess.open(src_path, FileAccess.READ).get_as_text()
		var out := FileAccess.open(dest_path, FileAccess.WRITE)
		out.store_string("class_name %s\nextends RefCounted\n\n%s" % [target_class, body])
