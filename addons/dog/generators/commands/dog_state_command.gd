@tool
class_name DogStateCommand
extends DogCommand
## state <type> <actor> <tree...> [--folder f] [--extends actor] [-f]

const OptParse := preload("res://addons/dog/generators/third_party/optparse.gd")

const FLAT_TYPES: PackedStringArray = ["fsm", "pda"]
const TREE_TYPES: PackedStringArray = ["hfsm", "hpda"]


class Request:
	var type: String = ""
	var actor: String = ""
	var folder: String = ""
	var extends_actor: String = ""
	var force: bool = false
	var tree: DogStateTree
	var error: String = ""


func command_name() -> String:
	return "state"


static func parse_request(args: PackedStringArray) -> Request:
	var request: Request = Request.new()

	var parser := OptParse.new()
	parser.add_positional_required("type", "", "type: fsm | pda | hfsm | hpda")
	parser.add_positional_required("actor", "", "actor name (snake_case)")
	parser.add("--folder", "", "category folder, e.g. enemy -> enemies/")
	parser.add("--extends", "", "inherit the states of another actor")
	parser.add(["--force", "-f"], false, "recreate from scratch")
	parser.parse(args)  # always pass args: null would read the editor's cmdline

	var missing: Array = parser.get_missing_required_options()
	if not missing.is_empty():
		request.error = "missing <%s>." % missing[0].option_name
		return request

	for token in parser.unused:
		if parser.is_option(token):
			request.error = "unknown option '%s'." % token
			return request

	request.type = parser.get_value("type")
	if request.type not in FLAT_TYPES and request.type not in TREE_TYPES:
		request.error = "unknown type '%s'." % request.type
		return request

	request.actor = parser.get_value("actor")
	request.folder = parser.get_value("--folder")
	request.extends_actor = parser.get_value("--extends")
	request.force = parser.get_value("--force")

	var tree := DogStateTree.parse(PackedStringArray(parser.unused))
	if not tree.error.is_empty():
		request.error = tree.error
		return request

	if request.type in FLAT_TYPES and tree.nodes.any(func(n): return n.depth > 0):
		request.error = "'%s' is flat: nested states are not allowed." % request.type
		return request

	request.tree = tree
	return request
