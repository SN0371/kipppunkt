class_name SimFixture
extends RefCounted
## Shared setup for simulation tests: loads the shipped data once and creates states.
##
## Formula tests must not break when balancing changes the shipped parameters, so all
## parameters are pinned to TEST_PARAMS (the start values of rechenmodell.md section 13).

const DATA_DIR := "res://data"
const SCENARIO := "scenario.new_party"
## Fixed parameters for tests, independent of balancing.
const TEST_PARAMS: Dictionary = {
	"polling_base": 1.0,
	"topic_weight": 14.0,
	"anchoring_weight": 6.0,
	"leadership_weight": 2.0,
	"stigma_per_level": 1.5,
	"polarization_penalty": 1.0,
	"polling_alpha": 0.25,
	"polling_noise": 0.6,
	"polling_max": 45.0,
	"election_noise": 0.8,
	"position_change_cost": 3.0,
	"contradiction_growth": 2.0,
	"contradiction_decay": 1.0,
	"member_fee": 0.03,
	"state_funding_per_vote": 0.0002,
	"fixed_costs": 8.0,
	"member_growth": 0.02,
	"platform_reach_decay": 0.08,
	"municipal_anchoring_gain": 2.0,
	"press_strength": 0.8,
	"crisis_probability": 0.03,
	"crisis_bonus": 4.0,
	"rival_proximity_range": 60.0,
	"rival_pressure": 1.0,
	"media_climate_effect": 0.2,
	"media_climate_credibility_shift": 20.0,
	"media_sensationalism_reach": 15.0,
	"donor_base": 35.0,
	"donor_topic_weight": 25.0,
	"donor_ideology_weight": 15.0,
	"member_small_party": 1000.0,
	"members_per_polling_point": 1000.0,
}

static var _defs: GameDefs


## Returns the shipped definitions with test parameters, loaded once per test run.
static func defs() -> GameDefs:
	if _defs == null:
		_defs = defs_with({})
	return _defs


## Returns a fresh start state of the default scenario.
static func new_state(game_seed: int = 1) -> GameState:
	return StateFactory.create(defs(), SCENARIO, game_seed)


## Returns freshly loaded definitions with test parameters and the given overrides,
## leaving the shared definitions untouched.
static func defs_with(overrides: Dictionary) -> GameDefs:
	var fresh := GameDefs.load_from_dir(DATA_DIR)
	assert(fresh.is_valid(), "Shipped data must be valid: %s" % [fresh.errors])
	for name in ParamSet.REQUIRED:
		assert(TEST_PARAMS.has(name), "TEST_PARAMS lacks %s" % name)
		fresh.params.override(name, TEST_PARAMS[name])
	for name: String in overrides:
		fresh.params.override(name, overrides[name])
	return fresh
