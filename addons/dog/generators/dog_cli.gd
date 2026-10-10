@tool
class_name DogCli
extends RefCounted
## Parses a command line and dispatches it to a registered DogCommand.

signal printed(text: String)

var _commands: Dictionary[String, DogCommand] = {}


func register(command: DogCommand) -> void:
	command.printed.connect(printed.emit)
	_commands[command.command_name()] = command


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
	var tokens := PackedStringArray()
	var current := ""
	var quote := ""

	for character in line:
		if quote != "":
			if character == quote:
				quote = ""
			else:
				current += character
		elif character == "'" or character == '"':
			quote = character
		elif character == " ":
			if current != "":
				tokens.append(current)
				current = ""
		else:
			current += character

	if current != "":
		tokens.append(current)
	return tokens
