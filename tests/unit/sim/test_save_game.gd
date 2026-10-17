extends GutTest
## Tests that saving and loading reproduces a game state exactly.

const SCENARIO := "scenario.new_party"
const SAVE_PATH := "user://test_save_game.json"

var _defs: GameDefs


func before_all() -> void:
	_defs = GameDefs.load_from_dir("res://data")
	assert_true(_defs.is_valid(), "Data must be valid")


func after_all() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func test_round_trip_reproduces_state() -> void:
	var state := _populated_state(42)
	var loaded := _round_trip(state)
	assert_not_null(loaded)
	assert_eq_deep(loaded.to_dict(), state.to_dict())


func test_random_numbers_continue_identically_after_loading() -> void:
	var state := _populated_state(42)
	var loaded := _round_trip(state)
	for i in 10:
		assert_eq(loaded.rng.randi(), state.rng.randi(), "Draw %d" % i)


func test_large_seed_survives_round_trip() -> void:
	# 2^53 + 1 cannot be represented exactly as a JSON number.
	var state := StateFactory.create(_defs, SCENARIO, 9007199254740993)
	var loaded := _round_trip(state)
	assert_eq(loaded.game_seed, 9007199254740993)


func test_fractional_values_survive_round_trip() -> void:
	var state := _populated_state(1)
	state.party.credibility = 1.0 / 3.0
	var loaded := _round_trip(state)
	assert_eq(loaded.party.credibility, 1.0 / 3.0)


func test_save_and_load_file() -> void:
	var state := _populated_state(5)
	assert_eq(SaveGame.save_to_file(state, SAVE_PATH), OK)
	var reader := JsonReader.new()
	var loaded := SaveGame.load_from_file(SAVE_PATH, _defs, reader)
	assert_eq(reader.errors, PackedStringArray())
	assert_eq_deep(loaded.to_dict(), state.to_dict())


func test_out_of_range_value_is_rejected() -> void:
	var data := _save_data(_populated_state(1))
	data["state"]["lands"]["land.by"]["polling"] = 150
	var reader := JsonReader.new()
	assert_null(SaveGame.from_json(JSON.stringify(data), _defs, reader))
	assert_true(_contains(reader.errors, "state.lands.land.by.polling"))


func test_unknown_land_is_rejected() -> void:
	var data := _save_data(_populated_state(1))
	data["state"]["lands"]["land.xx"] = data["state"]["lands"]["land.by"]
	var reader := JsonReader.new()
	assert_null(SaveGame.from_json(JSON.stringify(data), _defs, reader))
	assert_true(_contains(reader.errors, "unknown id 'land.xx'"))


func test_wrong_format_version_is_rejected() -> void:
	var data := _save_data(_populated_state(1))
	data["format_version"] = 99
	var reader := JsonReader.new()
	assert_null(SaveGame.from_json(JSON.stringify(data), _defs, reader))
	assert_true(_contains(reader.errors, "unsupported format version 99"))


func test_invalid_json_is_rejected() -> void:
	var reader := JsonReader.new()
	assert_null(SaveGame.from_json("{ not json", _defs, reader))
	assert_true(_contains(reader.errors, "invalid JSON"))


## Creates a state that uses every serialized field, including persons and crises.
func _populated_state(game_seed: int) -> GameState:
	var state := StateFactory.create(_defs, SCENARIO, game_seed)
	state.rng.randf()
	state.turn = 7
	state.party.positions["topic.taxes"] = 2
	state.party.position_age["topic.taxes"] = 3
	state.party.regional_messages["region.south"] = {"topic.wind_power": -2}
	state.lands["land.by"].polling = 3.75
	state.lands["land.by"].in_landtag = true
	var person := PersonState.new()
	person.id = "person.1"
	person.name = "Test Person"
	person.role = "treasurer"
	person.loyalty = 61.5
	person.agenda = "careerist"
	state.persons.append(person)
	var crisis := CrisisState.new()
	crisis.crisis_id = "crisis.energy"
	crisis.remaining_turns = 3
	crisis.elapsed_turns = 2
	state.crises.append(crisis)
	return state


func _round_trip(state: GameState) -> GameState:
	var reader := JsonReader.new()
	var loaded := SaveGame.from_json(SaveGame.to_json(state), _defs, reader)
	assert_eq(reader.errors, PackedStringArray(), "Round trip must not produce errors")
	return loaded


func _save_data(state: GameState) -> Dictionary:
	return JSON.parse_string(SaveGame.to_json(state))


func _contains(errors: PackedStringArray, part: String) -> bool:
	for e in errors:
		if e.contains(part):
			return true
	gut.p("Errors were: %s" % [errors])
	return false
