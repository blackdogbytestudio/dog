@tool
class_name DogStateCommand
extends DogCommand
## state <type> <actor> <tree...> [--folder f] [--extends State] [-f]
## The states' host is always the actor's class (actor in PascalCase).


const FLAT_TYPES: PackedStringArray = ["fsm", "pda"]
const TREE_TYPES: PackedStringArray = ["hfsm", "hpda"]

# Overridable so tests never write into res://.
var root: String = DogStateGenerator.ROOT


class Request:
	var type: String = ""
	var actor: String = ""
	var folder: String = ""
	var extends_state: String = ""
	var force: bool = false
	var tree: DogStateTree
	var error: String = ""


func command_name() -> String:
	return "state"


func description() -> String:
	return "Generate actor state scripts."


func usage() -> String:
	return "state <fsm|pda|hfsm|hpda> <actor> <tree...> [--folder path] [--extends State] [-f]"


func run(args: PackedStringArray) -> Error:
	var request := parse_request(args)
	if not request.error.is_empty():
		print_line("DOG: state: %s" % request.error)
		return ERR_INVALID_PARAMETER

	var result := DogStateGenerator.generate(
		request.type,
		request.actor,
		request.folder,
		request.extends_state,
		request.tree,
		request.force,
		root
	)
	if not result.error.is_empty():
		print_line("DOG: state: %s" % result.error)
		return FAILED

	for path in result.written:
		print_line("created %s" % path)
	for path in result.skipped:
		print_line("kept %s" % path)
	return OK


static func parse_request(args: PackedStringArray) -> Request:
	var request: Request = Request.new()

	var parser := DogOptParse.new()
	parser.add_positional_required("type", "", "type: fsm | pda | hfsm | hpda")
	parser.add_positional_required("actor", "", "actor name (snake_case)")
	parser.add("--folder", "", "category folder, e.g. enemies/slime -> scenes/characters/enemies/slime/states")
	parser.add("--extends", "", "state class the root states inherit from")
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
	if not DogNames.is_valid_name(request.actor):
		request.error = "'%s' is not a valid actor name (use snake_case)." % request.actor
		return request

	request.folder = parser.get_value("--folder")
	request.extends_state = parser.get_value("--extends")
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
