@tool
class_name DogHelpCommand
extends DogCommand

var _cli: DogCli


func _init(cli: DogCli) -> void:
	_cli = cli


func command_name() -> String:
	return "help"


func description() -> String:
	return "List all commands."


func run(_args: PackedStringArray) -> Error:
	for command in _cli.commands():
		print_line("%s  -  %s" % [command.command_name(), command.description()])
		if command.usage() != "":
			print_line("    usage: %s" % command.usage())
	return OK
