@tool
class_name DogCli
extends RefCounted
## Parses a command line and dispatches it to a registered DogCommand.

signal printed(text: String)

var _commands: Dictionary[String, DogCommand] = {}

func register(command: DogCommand) -> void:
	command.cli = self
	command.printed.connect(printed.emit)
	_commands[command.command_name()] = command


func register_folder(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		if not file.ends_with(".gd"):
			continue

		var script := load(path.path_join(file)) as GDScript
		if script == null or not script.can_instantiate():
			continue

		# Avoid leaking a Node (or anything non-RefCounted) by instantiating it.
		if script.get_instance_base_type() != "RefCounted":
			continue

		var command := script.new() as DogCommand
		if command != null:
			register(command)


func commands() -> Array[DogCommand]:
	return _commands.values()


func execute(line: String) -> Error:
	var tokens := tokenize(line)
	if tokens.is_empty():
		return OK

	# Same syntax as in a shell, so the "dog" prefix is optional.
	if tokens[0] == "dog":
		tokens.remove_at(0)
		if tokens.is_empty():
			return OK

	var command: DogCommand = _commands.get(tokens[0])
	if command == null:
		printed.emit("DOG: unknown command '%s'. Try 'help'." % tokens[0])
		return ERR_DOES_NOT_EXIST

	tokens.remove_at(0)
	return command.run(tokens)


static func tokenize(line: String) -> PackedStringArray:
	return line.split(" ", false)
