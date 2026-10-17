class_name SimFixture
extends RefCounted
## Shared setup for simulation tests: loads the shipped data once and creates states.

const DATA_DIR := "res://data"
const SCENARIO := "scenario.new_party"

static var _defs: GameDefs


## Returns the shipped definitions, loaded once per test run.
static func defs() -> GameDefs:
	if _defs == null:
		_defs = GameDefs.load_from_dir(DATA_DIR)
		assert(_defs.is_valid(), "Shipped data must be valid: %s" % [_defs.errors])
	return _defs


## Returns a fresh start state of the default scenario.
static func new_state(game_seed: int = 1) -> GameState:
	return StateFactory.create(defs(), SCENARIO, game_seed)
