# DOG — Develop Original Games

An opinionated, component-based framework with state machines, built for fast prototyping that scales into full games.

> **Status:** Still in early experimentation and likely to have bugs. Good for testing ideas and prototypes — not yet validated for a full game.

## Philosophy

Godot gives you total freedom — which is great, until your `Player.gd` turns into a 500-line file mixing movement, state, input, and everything else. DOG borrows Rails' idea of **convention over configuration**: follow its structure and it handles the plumbing (component wiring, state transitions, project scaffolding), so you focus on the game.

It's "dumb by design." DOG doesn't guard against every possible misuse — if you attach the wrong component to the wrong host, it fails loudly and predictably instead of silently working around it.

## Core Concepts

### Components
A `DogComponent` is a `Node` that encapsulates one isolated behavior (movement, jumping, gravity...) and validates its own host type automatically — attach it to the wrong node and Godot flags a configuration warning right in the Scene dock.

### Facades
A `DogFacade` orchestrates several components and exposes them as a single, flattened `@export` surface — so your Inspector shows one clean set of grouped properties instead of five separate component nodes cluttering your scene tree. Facades register their components in `dog_leash()`:

```gdscript
func dog_leash(...components: Array) -> void:
    super.dog_leash(_jump, _move, _gravity)
```

`DogPlatformerFacade2D` ships out of the box, wrapping `DogJump2D` (multi-jump, coyote time, jump buffering, jump cut, wall jump/slide), `DogMove2D`, and `DogGravity2D` behind grouped `@export_group` properties (Jump / Move / Gravity).

### State Machines
States are pure `RefCounted` objects — they never enter the scene tree. The host is passed explicitly into `enter(host)`, `exit(host)`, and `update(host, delta)`.

- **`DogFSM`** — flat state machine. States return the next `DogState` from `update()` to transition; `force()` transitions from the outside; `lock()`/`unlock()` blocks transitions when needed (e.g. mid-animation).
- **`DogHFSM`** — hierarchical FSM. State hierarchy is just GDScript inheritance — call `super()` first in `update()` so parent states can intercept transitions before child logic runs.
- **`DogPDA`** — pushdown automaton. `push()` suspends the current state (`pause()`) and activates a new one; `pop()` exits the top and resumes the one below. Built for interrupt states like pause menus or hit-stun.
- **`DogHPDA`** — combines the guard hierarchy of HFSM with the pause/resume stack of PDA.

```gdscript
func _ready() -> void:
    fsm.init(idle_state)

func _physics_process(delta: float) -> void:
    fsm.update(delta)

func _on_hitbox_area_entered(_area: Area2D) -> void:
    fsm.force(hurt_state)
```

## Installation

1. Copy `addons/dog/` into your project's `addons/` folder.
2. Enable **dog** under **Project → Project Settings → Plugins**.
3. Enabling the plugin automatically:
   - Scaffolds your project's folder structure from `config/scaffold.json` (assets, scenes, scripts, components — editable after first install, idempotent on re-enable)
   - Installs DOG's script templates into `res://script_templates`

> **Note:** Disabling the plugin does not remove anything it installed — the scaffolded folders, `config/scaffold.json`, and `res://script_templates` are left untouched. Removing them is a manual step.

## Project Structure (addon)

```
addons/dog/
  components/
    dog_component.gd          # base for all components
    facades/
      dog_facade.gd            # base for all facades
      2d/character/
        dog_character_facade_2d.gd
        dog_platformer_facade_2d.gd
    machines/
      dog_machine.gd  dog_fsm.gd  dog_hfsm.gd  dog_pda.gd  dog_hpda.gd
    2d/character/
      dog_move_2d.gd  dog_jump_2d.gd  dog_gravity_2d.gd  dog_character_2d.gd
  states/
    dog_state.gd  dog_fsm_state.gd  dog_hfsm_state.gd  dog_pda_state.gd  dog_h_pda_state.gd
  setup/                       # scaffolding + template installers
  scaffold.json                # default project scaffold
```

## License

MIT — see [LICENSE](./LICENSE).
