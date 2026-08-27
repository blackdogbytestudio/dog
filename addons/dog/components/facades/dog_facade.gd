@tool
class_name DogFacade
extends DogComponent
## Base class for facade components.
##
## A facade owns and composes several sub-components internally,
## then exposes a single, flattened [code]@export[/code] surface for them
## on itself. Callers only ever talk to the facade — they never touch
## the sub-components directly.
## [br][br]
## Override [method dog_leash] to register every sub-component this facade
## owns, e.g.:
## [codeblock]
## func dog_leash(...) -> void:
##     super.dog_leash(_jump, _move, _gravity)
## [/codeblock]
## [br][br]
## [b]Export setters that reach into a sub-component must guard for it not
## existing yet[/b]:
## [codeblock]
## @export var max_jumps: int = 1:
##     set(value):
##         max_jumps = value
##         if _jump:
##             _jump.max_jumps = value
## [/codeblock]

func _enter_tree() -> void:
	dog_leash()

## Abstract — subclasses MUST override this and call super.dog_leash(...)
## passing every sub-component they own.
func dog_leash(...components: Array) -> void:
	if components.is_empty():
		push_error("%s: must override dog_leash() and register its components" % [get_script().get_global_name()])
		return
	for c in components:
		if not c is DogComponent:
			push_error("%s: dog_leash() received a non-DogComponent (%s)" % [get_script().get_global_name(), c])
			continue
		c.name = c.get_script().get_global_name()
		c.set_host(host())
		if not c.get_parent():
			add_child(c)
