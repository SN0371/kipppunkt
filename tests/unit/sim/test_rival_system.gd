extends GutTest
## Tests for competition pressure and attitude of rival parties (rechenmodell.md 3.3, 5.5).

# 1 - sqrt(9^2 + 34^2) / 60 and 1 - sqrt(25^2 + 25^2) / 60
const PROXIMITY_CONSERVATIVES_AT_CENTRE := 0.413817
const PROXIMITY_LIBERALS_AT_CENTRE := 0.410745

var _defs: GameDefs


func before_each() -> void:
	_defs = SimFixture.defs()


func test_proximity_at_centre() -> void:
	var conservatives := _defs.rivals["party.conservatives"]
	var liberals := _defs.rivals["party.liberals"]
	assert_almost_eq(RivalSystem.proximity(_defs, conservatives, Vector2.ZERO), PROXIMITY_CONSERVATIVES_AT_CENTRE, 0.00001)
	assert_almost_eq(RivalSystem.proximity(_defs, liberals, Vector2.ZERO), PROXIMITY_LIBERALS_AT_CENTRE, 0.00001)


func test_centre_is_equally_contested_in_every_direction() -> void:
	for rival: RivalPartyDef in _defs.rivals.values():
		assert_almost_eq(RivalSystem.proximity(_defs, rival, Vector2.ZERO), 0.41, 0.01, rival.id)


func test_pressure_in_bavaria_at_centre() -> void:
	# 0.40 * 0.413817 + 0.10 * 0.410745 + 0.15 * 0.413817
	assert_almost_eq(RivalSystem.pressure(_defs, "land.by", Vector2.ZERO), 0.268674, 0.00001)


func test_no_pressure_far_from_all_rivals() -> void:
	assert_eq(RivalSystem.pressure(_defs, "land.by", Vector2(100, 100)), 0.0)
	assert_eq(RivalSystem.pressure(_defs, "land.by", Vector2(-100, -100)), 0.0)


func test_attitude_falls_with_radicalism_and_surveillance() -> void:
	var state := SimFixture.new_state()
	var conservatives := _defs.rivals["party.conservatives"]
	state.party.radicalism = 10.0
	assert_almost_eq(RivalSystem.attitude(_defs, conservatives, Vector2.ZERO, state.party), 36.3817, 0.001)
	state.party.vs_level = 2
	assert_eq(RivalSystem.attitude(_defs, conservatives, Vector2.ZERO, state.party), 0.0, "Clamped at 0")
