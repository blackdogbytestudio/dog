extends GutTest

const Command := preload("res://addons/dog/generators/commands/dog_state_command.gd")
const Generator := preload("res://addons/dog/generators/dog_state_generator.gd")

const ROOT := "user://dog_state_command_test"


func before_each() -> void:
	_remove(ROOT)


func after_each() -> void:
	_remove(ROOT)


func _request(args: PackedStringArray):
	return Command.parse_request(args)


func _generate(args: PackedStringArray):
	var request = _request(args)
	assert_eq(request.error, "", "unexpected parse error: %s" % request.error)
	return Generator.generate(
		request.type, request.actor, request.folder, request.host,
		request.extends_state, request.tree, request.force, ROOT
	)


func _run(args: PackedStringArray) -> Array:
	var command = Command.new()
	command.root = ROOT
	var lines: Array[String] = []
	command.printed.connect(func(text: String) -> void: lines.append(text))
	var error := command.run(args)
	return [error, lines]


func _states(folder: String) -> String:
	return ROOT.path_join(folder).path_join("states")


func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file in dir.get_files():
		dir.remove(file)
	for sub in dir.get_directories():
		_remove(path.path_join(sub))
	DirAccess.remove_absolute(path)


# --- parse ------------------------------------------------------------------

func test_parse_accepts_hpda() -> void:
	var request = _request(PackedStringArray(["hpda", "enemy", "alive", ".grounded", "dead"]))
	assert_eq(request.error, "")
	assert_eq(request.type, "hpda")
	assert_eq(request.actor, "enemy")
	assert_eq(request.tree.nodes.size(), 3)


func test_parse_reads_folder_host_and_extends() -> void:
	var request = _request(PackedStringArray([
		"hpda", "slime", "--folder", "enemies/slime",
		"--host", "Slime", "--extends", "enemy_alive_state", "jump",
	]))
	assert_eq(request.error, "")
	assert_eq(request.folder, "enemies/slime")
	assert_eq(request.host, "Slime")
	assert_eq(request.extends_state, "enemy_alive_state")


func test_parse_rejects_hdpa() -> void:
	assert_ne(_request(PackedStringArray(["hdpa", "enemy", "alive"])).error, "")


func test_parse_requires_actor() -> void:
	assert_ne(_request(PackedStringArray(["fsm"])).error, "")


func test_parse_rejects_invalid_actor() -> void:
	assert_ne(_request(PackedStringArray(["fsm", "Player"])).error, "")


func test_parse_rejects_unknown_option() -> void:
	assert_ne(_request(PackedStringArray(["fsm", "player", "--nope"])).error, "")


func test_parse_rejects_nesting_on_flat_types() -> void:
	assert_ne(_request(PackedStringArray(["fsm", "player", "alive", ".run"])).error, "")


func test_flat_types_accept_multiple_roots() -> void:
	var request = _request(PackedStringArray(["fsm", "player", "alive", "dead"]))
	assert_eq(request.error, "")
	assert_eq(request.tree.nodes.size(), 2)


# --- generate ---------------------------------------------------------------

func test_generate_creates_actor_and_nodes() -> void:
	_generate(PackedStringArray([
		"hpda", "enemy", "--folder", "enemies",
		"alive", ".grounded", "..idle", ".airborne", "dead",
	]))
	var dir := _states("enemies")

	assert_true(FileAccess.file_exists(dir.path_join("enemy_state.gd")))
	assert_true(FileAccess.file_exists(dir.path_join("enemy_grounded_state.gd")))
	assert_true(FileAccess.file_exists(dir.path_join("enemy_idle_state.gd")))
	assert_true(FileAccess.file_exists(dir.path_join("enemy_dead_state.gd")))

	assert_string_contains(_text(dir.path_join("enemy_state.gd")), "class_name EnemyState")
	assert_string_contains(_text(dir.path_join("enemy_state.gd")), "extends DogHPDAState")
	assert_string_contains(_text(dir.path_join("enemy_grounded_state.gd")), "extends EnemyAliveState")
	assert_string_contains(_text(dir.path_join("enemy_idle_state.gd")), "extends EnemyGroundedState")


func test_generate_replaces_every_placeholder() -> void:
	_generate(PackedStringArray(["hpda", "enemy", "alive", ".grounded"]))
	var text := _text(_states("enemy").path_join("enemy_alive_state.gd"))
	assert_false(text.contains("_CLASS_"))
	assert_false(text.contains("_BASE_"))
	assert_false(text.contains("CUSTOM_HOST"))
	assert_false(text.contains("CUSTOM_BASE"))
	assert_false(text.contains("# Replace '"))


func test_generate_skips_existing_and_force_rewrites() -> void:
	var args := PackedStringArray(["hpda", "player", "alive", ".grounded", "..run"])
	_generate(args)
	var run_path := _states("player").path_join("player_run_state.gd")
	_write(run_path, "custom")

	var kept = _generate(args)
	assert_has(kept.skipped, run_path)
	assert_eq(_text(run_path), "custom")

	_generate(PackedStringArray(["hpda", "player", "-f", "alive", ".grounded", "..run"]))
	assert_ne(_text(run_path), "custom")
	assert_string_contains(_text(run_path), "class_name PlayerRunState")


func test_generate_extends_suppresses_actor_base() -> void:
	var result = _generate(PackedStringArray([
		"hpda", "slime", "--extends", "enemy_alive_state",
		"--folder", "enemies/slime", "jump",
	]))
	var dir := _states("enemies/slime")

	assert_eq(result.written.size(), 1)
	assert_false(FileAccess.file_exists(dir.path_join("slime_state.gd")))
	assert_string_contains(_text(dir.path_join("slime_jump_state.gd")), "class_name SlimeJumpState")
	assert_string_contains(_text(dir.path_join("slime_jump_state.gd")), "extends EnemyAliveState")


func test_generate_extends_only_applies_to_root_states() -> void:
	_generate(PackedStringArray([
		"hpda", "slime", "--extends", "enemy_alive_state",
		"--folder", "enemies/slime", "jump", ".air", "..land", "walk",
	]))
	var dir := _states("enemies/slime")

	# Roots inherit from the --extends state.
	assert_string_contains(_text(dir.path_join("slime_jump_state.gd")), "extends EnemyAliveState")
	assert_string_contains(_text(dir.path_join("slime_walk_state.gd")), "extends EnemyAliveState")
	# Nested states inherit from their parent in the tree, not from --extends.
	assert_string_contains(_text(dir.path_join("slime_air_state.gd")), "extends SlimeJumpState")
	assert_string_contains(_text(dir.path_join("slime_land_state.gd")), "extends SlimeAirState")


func test_generate_flat_states_extend_the_actor_state() -> void:
	_generate(PackedStringArray(["fsm", "player", "alive", "dead"]))
	var dir := _states("player")

	assert_string_contains(_text(dir.path_join("player_state.gd")), "extends DogFSMState")
	assert_string_contains(_text(dir.path_join("player_alive_state.gd")), "extends PlayerState")
	assert_string_contains(_text(dir.path_join("player_dead_state.gd")), "extends PlayerState")


func test_generate_uses_host_override() -> void:
	_generate(PackedStringArray(["hpda", "enemy", "--host", "Monster", "alive"]))
	assert_string_contains(_text(_states("enemy").path_join("enemy_alive_state.gd")), "Monster")


func test_generate_uses_actor_as_default_host() -> void:
	_generate(PackedStringArray(["hpda", "enemy", "alive"]))
	assert_string_contains(_text(_states("enemy").path_join("enemy_alive_state.gd")), "Enemy")


func test_parse_accepts_actor_with_a_digit_part() -> void:
	assert_eq(_request(PackedStringArray(["fsm", "character_body_2d", "idle"])).error, "")


func test_generate_capitalizes_the_letter_after_a_number() -> void:
	_generate(PackedStringArray(["fsm", "character_body_2d", "idle"]))
	var dir := _states("character_body_2d")
	assert_string_contains(_text(dir.path_join("character_body_2d_state.gd")), "class_name CharacterBody2DState")
	assert_string_contains(_text(dir.path_join("character_body_2d_idle_state.gd")), "class_name CharacterBody2DIdleState")


# --- run --------------------------------------------------------------------

func test_run_prints_created_and_keeps() -> void:
	var first = _run(PackedStringArray(["hpda", "player", "alive"]))
	assert_eq(first[0], OK)
	assert_eq(first[1].size(), 2)
	assert_string_contains(first[1][0], "created")

	var second = _run(PackedStringArray(["hpda", "player", "alive", ".grounded"]))
	assert_eq(second[0], OK)
	assert_string_contains(" ".join(second[1]), "kept %s" % _states("player").path_join("player_state.gd"))
	assert_string_contains(" ".join(second[1]), "created")


func test_run_reports_parse_errors() -> void:
	var result = _run(PackedStringArray(["hdpa", "enemy", "alive"]))
	assert_eq(result[0], ERR_INVALID_PARAMETER)
	assert_eq(result[1].size(), 1)
	assert_string_contains(result[1][0], "DOG: state:")
	assert_eq(DirAccess.open(ROOT), null)


func test_run_reports_unknown_type() -> void:
	var result = _run(PackedStringArray(["nope", "enemy", "alive"]))
	assert_eq(result[0], ERR_INVALID_PARAMETER)
	assert_string_contains(result[1][0], "unknown type")
