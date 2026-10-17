@tool
class_name DogStateGenerator
extends RefCounted
## Builds actor state scripts from the DOG script_templates.
##
## The actor base is created from class.gd (its own enter/exit/update
## wrappers); every tree node is created from state.gd, extending its
## parent state's class. Existing files are kept unless force is set.
##
## The actor's scene is required: `<root>/<folder or actor>/<actor>.tscn`, with a
## saved .gd script on its root and exactly one direct child whose script is the
## machine class of `type` (see FAMILIES). Everything is checked before any file
## is written.

const ROOT := "res://scenes/characters"
const STATES_DIR := "states"

const TEMPLATE_ROOTS: PackedStringArray = [
	"res://script_templates",
	"res://addons/dog/script_templates",
]

const ACTOR_TEMPLATE := "class.gd"
const NODE_TEMPLATE := "state.gd"

## The only supported machines: one row per `type`. `machine` is the class_name
## of the machine node the host must have as a direct child.
const FAMILIES := {
	"fsm": {"dir": "DogFSMState", "base": "DogFSMState", "machine": "DogFSM"},
	"pda": {"dir": "DogPDAState", "base": "DogPDAState", "machine": "DogPDA"},
	"hfsm": {"dir": "DogHState", "base": "DogHFSMState", "machine": "DogHFSM"},
	"hpda": {"dir": "DogHPDAState", "base": "DogHPDAState", "machine": "DogHPDA"},
}


class Result:
	var written: Array[String] = []
	var skipped: Array[String] = []
	var warnings: Array[String] = []
	var error := ""
	var scene := ""
	var host_path := ""
	var machine_node := ""


static func generate(
	type: String,
	actor: String,
	folder: String,
	base: String,
	tree: DogStateTree,
	force: bool,
	root: String = ROOT
) -> Result:
	var result := Result.new()

	var family: Dictionary = FAMILIES[type]
	var host_class := _pascal(actor)
	var base_class := _pascal(base) if not base.is_empty() else ""

	var template_dir := _find_template_dir(family["dir"])
	if template_dir.is_empty():
		result.error = "template folder '%s' not found." % family["dir"]
		return result

	_inspect_scene(result, actor, folder, root, family["machine"], host_class)
	if not result.error.is_empty():
		return result

	var dir := output_dir(folder, actor, root)
	var make_error := DirAccess.make_dir_recursive_absolute(dir)
	if make_error != OK:
		result.error = "could not create '%s' (error %d)." % [dir, make_error]
		return result

	# Without --extends the actor base is the root of the hierarchy.
	if base_class.is_empty():
		var base_write := _write(
			result, dir, file_name(actor), template_dir.path_join(ACTOR_TEMPLATE),
			state_class(actor), host_class, family["base"], force
		)
		if not base_write.is_empty():
			result.error = base_write
			return result

	for node in tree.nodes:
		var parent: String
		if node.depth > 0:
			parent = state_class(actor, node.parent)
		elif not base_class.is_empty():
			parent = base_class
		else:
			parent = state_class(actor)

		var write_error := _write(
			result, dir, file_name(actor, node.name), template_dir.path_join(NODE_TEMPLATE),
			state_class(actor, node.name), host_class, parent, force
		)
		if not write_error.is_empty():
			result.error = write_error
			return result

	_scan()
	return result


static func output_dir(folder: String, actor: String, root: String = ROOT) -> String:
	var category := folder if not folder.is_empty() else actor
	return root.path_join(category).path_join(STATES_DIR)


static func scene_path(folder: String, actor: String, root: String = ROOT) -> String:
	return output_dir(folder, actor, root).get_base_dir().path_join(actor + ".tscn")


## Fills result.scene, host_path, machine_node and warnings, or result.error.
static func _inspect_scene(
	result: Result,
	actor: String,
	folder: String,
	root: String,
	machine_class: String,
	host_class: String
) -> void:
	var path := scene_path(folder, actor, root)
	if not FileAccess.file_exists(path):
		result.error = "no %s.tscn in %s." % [actor, path.get_base_dir()]
		var found := DogApiGenerator.find_scene(actor, "", root)
		var elsewhere: String = found["path"]
		if not elsewhere.is_empty():
			var actor_dir := elsewhere.get_base_dir().trim_prefix(root.trim_suffix("/") + "/")
			result.error += " found %s: use --folder %s." % [elsewhere, actor_dir]
		return

	var packed := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var host := packed.instantiate() if packed != null else null
	if host == null:
		result.error = "could not load %s." % path
		return

	var host_script := host.get_script() as Script
	var host_path := host_script.resource_path if host_script != null else ""
	var nodes: Array[String] = []
	var with_class: Array[String] = []
	for child in host.get_children():
		var script := child.get_script() as Script
		var klass := String(script.get_global_name()) if script != null else ""
		if klass.is_empty():
			continue
		with_class.append("%s (%s)" % [child.name, klass])
		if klass == machine_class:
			nodes.append(child.name)
	host.free()

	var scene_file := path.get_file()
	if host_script == null:
		result.error = "the root node of %s has no script: attach one in Godot first." % scene_file
	elif host_path.is_empty() or host_path.contains("::"):
		result.error = "the script of %s is built into the scene: save it as a .gd file first." % scene_file
	elif nodes.is_empty():
		result.error = "no %s child in %s. children with a class: %s." % [
			machine_class, scene_file, ", ".join(with_class) if not with_class.is_empty() else "none"
		]
	elif nodes.size() > 1:
		result.error = "more than one %s child in %s: %s." % [machine_class, scene_file, ", ".join(nodes)]
	if not result.error.is_empty():
		return

	result.scene = path
	result.host_path = host_path
	result.machine_node = nodes[0]
	var found_class := _declared_class_name(_read_text(host_path))
	if found_class != host_class:
		var warning := "states cast host as %s, but %s has no class_name %s" % [host_class, host_path.get_file(), host_class]
		if not found_class.is_empty():
			warning += " (found: %s)" % found_class
		result.warnings.append(warning)


## The `class_name` written in `source`, or "".
static func _declared_class_name(source: String) -> String:
	var re := RegEx.create_from_string("(?m)^class_name\\s+(\\w+)")
	var found := re.search(source)
	return found.get_string(1) if found != null else ""


static func file_name(actor: String, node: String = "") -> String:
	if node.is_empty():
		return "%s_state.gd" % actor
	return "%s_%s_state.gd" % [actor, node]


static func state_class(actor: String, node: String = "") -> String:
	return "%s%sState" % [_pascal(actor), _pascal(node)]


# Returns an error message, or "" on success (written/skipped go into result).
static func _write(
	result: Result,
	dir: String,
	file: String,
	template: String,
	cls: String,
	host: String,
	parent: String,
	force: bool
) -> String:
	var path := dir.path_join(file)
	if FileAccess.file_exists(path) and not force:
		result.skipped.append(path)
		return ""

	var source := _read_text(template)
	if source.is_empty():
		return "template '%s' is missing or empty." % template

	var write_error := _write_text(path, _substitute(source, cls, host, parent))
	if write_error != OK:
		return "could not write '%s' (error %d)." % [path, write_error]

	result.written.append(path)
	return ""


static func _pascal(name: String) -> String:
	return DogNames.to_pascal(name)


static func _find_template_dir(family_dir: String) -> String:
	for root in TEMPLATE_ROOTS:
		var path := root.path_join(family_dir)
		if DirAccess.dir_exists_absolute(path):
			return path
	return ""


static func _substitute(source: String, cls: String, host: String, parent: String) -> String:
	var text := source
	text = text.replace("_CLASS_", cls)
	text = text.replace("CUSTOM_HOST", host)
	text = text.replace("CUSTOM_BASE", parent)
	text = text.replace("_BASE_", parent)
	return _strip_instructions(text)


# The templates carry "Replace 'X' with..." comments for manual use.
static func _strip_instructions(text: String) -> String:
	var kept: PackedStringArray = []
	for line in text.split("\n"):
		if line.begins_with("# Replace '"):
			continue
		kept.append(line)
	return "\n".join(kept)


static func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


static func _write_text(path: String, text: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.close()
	return OK


static func _scan() -> void:
	if not Engine.is_editor_hint():
		return
	var fs := EditorInterface.get_resource_filesystem()
	if fs != null and not fs.is_scanning():
		fs.scan()
