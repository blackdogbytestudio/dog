extends GutTest

const COMMANDS_PATH := "res://addons/dog/generators/commands"


class SpyCommand extends DogCommand:
	var received := PackedStringArray()

	func command_name() -> String:
		return "spy"

	func run(args: PackedStringArray) -> Error:
		received = args
		return OK


func test_tokenize_state_tree() -> void:
	var tokens := DogCli.tokenize("hpda player alive .grounded ..run ..idle dead")
	assert_eq(tokens, PackedStringArray(["hpda", "player", "alive", ".grounded", "..run", "..idle", "dead"]))


func test_tokenize_ignores_extra_spaces() -> void:
	assert_eq(DogCli.tokenize("  help   "), PackedStringArray(["help"]))


func test_execute_empty_line_does_nothing() -> void:
	var cli := DogCli.new()
	assert_eq(cli.execute("   "), OK)


func test_execute_unknown_command() -> void:
	var cli := DogCli.new()
	var lines := []
	cli.printed.connect(func(text: String) -> void: lines.append(text))
	assert_eq(cli.execute("nope"), ERR_DOES_NOT_EXIST)
	assert_eq(lines.size(), 1)


func test_command_receives_clean_tokens() -> void:
	var cli := DogCli.new()
	var spy := SpyCommand.new()
	cli.register(spy)

	cli.execute("dog spy player alive .grounded ..run")
	assert_eq(spy.received, PackedStringArray(["player", "alive", ".grounded", "..run"]))

	cli.execute("spy player alive .grounded ..run")
	assert_eq(spy.received, PackedStringArray(["player", "alive", ".grounded", "..run"]))


func test_register_folder_finds_commands() -> void:
	var cli := DogCli.new()
	cli.register_folder(COMMANDS_PATH)
	var names := cli.commands().map(func(c: DogCommand) -> String: return c.command_name())
	assert_has(names, "help")
	assert_has(names, "hello")


func test_help_lists_registered_commands() -> void:
	var cli := DogCli.new()
	cli.register_folder(COMMANDS_PATH)
	var lines := []
	cli.printed.connect(func(text: String) -> void: lines.append(text))
	cli.execute("help")
	assert_gt(lines.size(), 0)
