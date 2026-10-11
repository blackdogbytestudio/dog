@tool
class_name DogStateTree
extends RefCounted
## Parses a dot-depth state tree into a flat, ordered list of nodes.
## Example: alive .grounded ..run ...run_ground ..idle dead

class StateNode:
	var name: String
	var parent: String  # Empty for roots.
	var depth: int


static var _valid_name := RegEx.create_from_string("^[a-z][a-z0-9_]*$")

var nodes: Array[StateNode] = []
var error := ""


static func parse(tokens: PackedStringArray) -> DogStateTree:
	var tree := DogStateTree.new()
	if tokens.is_empty():
		tree.error = "no states given."
		return tree

	var path: Array[String] = []
	var seen: Dictionary[String, bool] = {}

	for token in tokens:
		var depth := 0
		while depth < token.length() and token[depth] == ".":
			depth += 1

		var state_name := token.substr(depth)
		if state_name.is_empty():
			tree.error = "'%s' has dots but no name." % token
			return tree

		if _valid_name.search(state_name) == null:
			tree.error = "'%s' is not a valid state name (use snake_case)." % state_name
			return tree

		if depth > path.size():
			tree.error = "'%s' is nested too deep: previous state is at depth %d." % [state_name, path.size() - 1]
			return tree

		if seen.has(state_name):
			tree.error = "'%s' is declared twice." % state_name
			return tree
		seen[state_name] = true

		path.resize(depth)

		var node := StateNode.new()
		node.name = state_name
		node.parent = path[depth - 1] if depth > 0 else ""
		node.depth = depth
		tree.nodes.append(node)

		path.append(state_name)

	return tree
