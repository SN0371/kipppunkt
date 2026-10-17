extends GutTest
## Tests for elections (rechenmodell.md section 7).

var _defs: GameDefs
var _state: GameState


func before_each() -> void:
	_defs = SimFixture.defs_with({"election_noise": 0.0})
	_state = StateFactory.create(_defs, SimFixture.SCENARIO, 1)


func test_calendar() -> void:
	_state.turn = 3
	assert_eq(ElectionSystem.due(_state, _defs).size(), 1)
	assert_true(ElectionSystem.land_votes(_state, _defs, "land.by"))
	assert_false(ElectionSystem.land_votes(_state, _defs, "land.ni"))
	_state.turn = 8
	assert_true(ElectionSystem.land_votes(_state, _defs, "land.ni"), "Federal election")
	_state.turn = 4
	assert_false(ElectionSystem.is_campaign_turn(_state, _defs))
	_state.turn = 23
	assert_true(ElectionSystem.is_campaign_turn(_state, _defs), "Second municipal election in Bavaria")


func test_municipal_election_anchors_the_party() -> void:
	_state.turn = 3
	_state.lands["land.by"].polling = 3.0
	ElectionSystem.step(_state, _defs)
	assert_almost_eq(_state.lands["land.by"].last_municipal_result, 3.0, 0.00001)
	# 2 + 2 * 3
	assert_almost_eq(_state.regions["region.south"].anchoring, 8.0, 0.00001)
	assert_eq(_state.party.members, 315)


func test_state_election_needs_five_percent() -> void:
	_state.turn = 11
	_state.lands["land.sh"].polling = 4.9
	ElectionSystem.step(_state, _defs)
	assert_false(_state.lands["land.sh"].in_landtag)
	_state.turn = 31
	_state.lands["land.sh"].polling = 5.0
	ElectionSystem.step(_state, _defs)
	assert_true(_state.lands["land.sh"].in_landtag)
	assert_almost_eq(_state.party.reach_classic_bonus, ElectionSystem.LANDTAG_CLASSIC_BONUS, 0.00001)


func test_campaign_bonus_counts() -> void:
	_state.turn = 11
	_state.lands["land.sh"].polling = 4.0
	ModifierSystem.add(_state, "test", "election_bonus.land.sh", 1.5, 1)
	ElectionSystem.step(_state, _defs)
	assert_true(_state.lands["land.sh"].in_landtag)


func test_federal_election() -> void:
	_state.turn = 8
	for land: LandState in _state.lands.values():
		land.polling = 6.0
	ElectionSystem.step(_state, _defs)
	assert_almost_eq(_state.party.last_federal_result, 6.0, 0.0001)
	assert_true(_state.party.in_bundestag)
