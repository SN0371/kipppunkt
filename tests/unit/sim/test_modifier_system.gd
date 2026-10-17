extends GutTest
## Tests for the modifier system.

var _state: GameState


func before_each() -> void:
	_state = SimFixture.new_state()


func test_apply_multiplies_then_adds() -> void:
	ModifierSystem.add(_state, "a", "x", 1.0)
	ModifierSystem.add(_state, "b", "x", 0.0, ModifierState.PERMANENT, 2.0)
	ModifierSystem.add(_state, "c", "y", 100.0)
	assert_eq(ModifierSystem.apply(_state, "x", 3.0), 7.0)


func test_temporary_modifier_expires() -> void:
	ModifierSystem.add(_state, "a", "x", 1.0, 2)
	ModifierSystem.tick(_state)
	assert_eq(ModifierSystem.total_add(_state, "x"), 1.0, "Active in the second turn")
	ModifierSystem.tick(_state)
	assert_eq(ModifierSystem.total_add(_state, "x"), 0.0, "Expired after two turns")


func test_permanent_modifier_stays() -> void:
	ModifierSystem.add(_state, "a", "x", 1.0)
	for i in 10:
		ModifierSystem.tick(_state)
	assert_eq(ModifierSystem.total_add(_state, "x"), 1.0)
