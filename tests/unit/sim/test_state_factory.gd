extends GutTest
## Tests creating the start state of a scenario.

const SCENARIO := "scenario.new_party"

var _defs: GameDefs


func before_all() -> void:
	_defs = GameDefs.load_from_dir("res://data")
	assert_true(_defs.is_valid(), "Data must be valid")


func test_party_starts_with_scenario_values() -> void:
	var state := StateFactory.create(_defs, SCENARIO, 1)
	assert_eq(state.party.money, 50.0)
	assert_eq(state.party.members, 300)
	assert_eq(state.party.credibility, 50.0)
	assert_eq(state.party.vs_level, 0)
	assert_eq(state.party.positions.size(), 0, "No positions at start")
	assert_eq(state.turn, 1)
	assert_eq(state.resilience, 75.0)


func test_all_entities_get_a_state() -> void:
	var state := StateFactory.create(_defs, SCENARIO, 1)
	assert_eq(state.lands.keys(), _defs.lands.keys())
	assert_eq(state.regions.keys(), _defs.regions.keys())
	assert_eq(state.media.keys(), _defs.media.keys())
	assert_eq(state.donors.keys(), _defs.donors.keys())


func test_anchoring_only_in_listed_regions() -> void:
	var state := StateFactory.create(_defs, SCENARIO, 1)
	assert_eq(state.regions["region.south"].anchoring, 2.0)
	assert_eq(state.regions["region.east"].anchoring, 0.0)


func test_media_credibility_starts_at_target() -> void:
	var state := StateFactory.create(_defs, SCENARIO, 1)
	assert_almost_eq(state.media["media.tabloid"].credibility, 20.0 + 0.7 * 30.0, 0.0001)
	assert_almost_eq(state.media["media.public"].credibility, 20.0 + 0.7 * 85.0, 0.0001)


func test_media_owners_are_rolled_within_radius() -> void:
	for game_seed in range(1, 50):
		var state := StateFactory.create(_defs, SCENARIO, game_seed)
		for house: MediaState in state.media.values():
			assert_true(house.owner_ideology.length() <= 50.0 + 0.001, "Owner within radius")


func test_public_broadcasting_has_no_owner_ideology() -> void:
	var state := StateFactory.create(_defs, SCENARIO, 7)
	assert_eq(state.media["media.public"].owner_ideology, Vector2.ZERO)


func test_same_seed_gives_same_state() -> void:
	var first := StateFactory.create(_defs, SCENARIO, 1234)
	var second := StateFactory.create(_defs, SCENARIO, 1234)
	assert_eq_deep(first.to_dict(), second.to_dict())


func test_different_seeds_give_different_owners() -> void:
	var first := StateFactory.create(_defs, SCENARIO, 1)
	var second := StateFactory.create(_defs, SCENARIO, 2)
	assert_ne(first.media["media.tabloid"].owner_ideology, second.media["media.tabloid"].owner_ideology)
