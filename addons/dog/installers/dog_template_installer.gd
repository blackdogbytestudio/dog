@tool
class_name DogTemplateInstaller
extends DogInstaller

const TEMPLATE_SRC := "res://addons/dog/script_templates"
const TEMPLATE_DEST := "res://script_templates"

static func install() -> void:
	var src := DirAccess.open(TEMPLATE_SRC)
	if not src:
		return

	for family in src.get_directories():
		var dest_dir := "%s/%s" % [TEMPLATE_DEST, family]
		DirAccess.make_dir_recursive_absolute(dest_dir)

		var family_dir := DirAccess.open("%s/%s" % [TEMPLATE_SRC, family])
		for file in family_dir.get_files():
			var dest_file := "%s/%s" % [dest_dir, file]
			if FileAccess.file_exists(dest_file):
				continue
			DirAccess.copy_absolute(
				"%s/%s/%s" % [TEMPLATE_SRC, family, file],
				dest_file
			)
