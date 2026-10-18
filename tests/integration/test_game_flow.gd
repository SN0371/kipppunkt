extends GutTest
## Plays whole games and checks invariants, determinism and save/load during a game.
##
## Replaying from seed and orders is exact. A loaded save game continues practically
## identically: Godot's float parsing can differ in the last binary digit (see StateCompare).

const MAX_TURNS := 100

var _defs: GameDefs


func before_all() -> void:
	_defs = SimFixture.defs()


func test_game_without_orders_ends_and_keeps_invariants() -> void:
	var state := SimFixture.new_state(11)
	var turns := _play(state, MAX_TURNS, false)
	assert_true(state.is_over(), "Game ended after %d turns with '%s'" % [turns, state.outcome])


func test_scripted_game_keeps_invariants() -> void:
	var state := SimFixture.new_state(12)
	_play(state, MAX_TURNS, true)
	assert_true(state.is_over(), "Outcome: %s" % state.outcome)
	assert_gt(SimLog.find(state, "action").size(), 0, "Actions were carried out")


func test_same_seed_gives_same_game() -> void:
	var first := SimFixture.new_state(99)
	var second := SimFixture.new_state(99)
	for turn in 40:
		if first.is_over():
			break
		TurnRunner.play_turn(first, _defs, _scripted_orders(first))
		TurnRunner.play_turn(second, _defs, _scripted_orders(second))
		assert_eq(SaveGame.to_json(first), SaveGame.to_json(second), "Turn %d" % first.turn)


func test_different_seeds_give_different_games() -> void:
	var first := SimFixture.new_state(1)
	var second := SimFixture.new_state(2)
	for turn in 5:
		TurnRunner.play_turn(first, _defs, _scripted_orders(first))
		TurnRunner.play_turn(second, _defs, _scripted_orders(second))
	assert_ne(SaveGame.to_json(first), SaveGame.to_json(second))


func test_loaded_game_continues_identically() -> void:
	var original := SimFixture.new_state(7)
	_play(original, 15, true)
	var loaded := _reload(original)
	for turn in 15:
		if original.is_over():
			break
		TurnRunner.play_turn(original, _defs, _scripted_orders(original))
		TurnRunner.play_turn(loaded, _defs, _scripted_orders(loaded))
	assert_eq(StateCompare.differences(loaded.to_dict(), original.to_dict()), PackedStringArray())


func test_game_saved_while_planning_continues_identically() -> void:
	var original := SimFixture.new_state(8)
	_play(original, 5, true)
	TurnRunner.start_turn(original, _defs)
	var loaded := _reload(original)
	assert_true(loaded.awaiting_orders)
	TurnRunner.finish_turn(original, _defs, _scripted_orders(original))
	TurnRunner.finish_turn(loaded, _defs, _scripted_orders(loaded))
	assert_eq(StateCompare.differences(loaded.to_dict(), original.to_dict()), PackedStringArray())


## Plays up to max_turns turns or until the game ends, checking invariants after every turn.
## Returns the number of turns played.
func _play(state: GameState, max_turns: int, with_orders: bool) -> int:
	var played := 0
	while played < max_turns and not state.is_over():
		var orders: Array[ActionOrder] = []
		TurnRunner.start_turn(state, _defs)
		if with_orders:
			orders = _scripted_orders(state)
		TurnRunner.finish_turn(state, _defs, orders)
		played += 1
		var problems := _invariant_violations(state)
		assert_eq(problems, PackedStringArray(), "Invariants after turn %d" % state.turn)
		if not problems.is_empty():
			break
	return played


## A simple, deterministic strategy that only depends on the state.
func _scripted_orders(state: GameState) -> Array[ActionOrder]:
	var orders: Array[ActionOrder] = []
	if state.turn == 1:
		orders.append(ActionOrder.create("action.set_position", "topic.organic_farming", {"value": -2}))
		orders.append(ActionOrder.create("action.set_position", "topic.combustion_ban", {"value": -1}))
	for role in PersonSystem.STAFF_FUNCTIONS:
		if PersonSystem.by_role(state, role) == null:
			for person in state.persons:
				if person.role.is_empty():
					orders.append(ActionOrder.create("action.appoint", person.id, {"role": role}))
					break
			break
	for land_id in ["land.by", "land.bw", "land.ni", "land.sh"]:
		if ElectionSystem.land_votes(state, _defs, land_id):
			orders.append(ActionOrder.create("action.campaign", land_id))
			break
	var region := "region.south" if state.turn % 2 == 0 else "region.north"
	orders.append(ActionOrder.create("action.found_local_branch", region))
	orders.append(ActionOrder.create("action.social_media_campaign"))
	orders.append(ActionOrder.create("action.press_conference"))
	return orders


func _reload(state: GameState) -> GameState:
	var reader := JsonReader.new()
	var loaded := SaveGame.from_json(SaveGame.to_json(state), _defs, reader)
	assert_eq(reader.errors, PackedStringArray())
	return loaded


## Returns descriptions of all values outside their allowed ranges.
func _invariant_violations(state: GameState) -> PackedStringArray:
	var problems := PackedStringArray()
	var party := state.party
	for field in [
		"credibility", "radicalism", "scrutiny", "unity", "reach_platform", "reach_classic_bonus",
		"contradiction_risk", "intransparency",
	]:
		var value: float = party.get(field)
		if value < 0.0 or value > 100.0:
			problems.append("party.%s = %s" % [field, value])
	if party.members < 0 or party.activists < 0 or party.action_points < 0:
		problems.append("negative members, activists or action points")
	if party.vs_level < 0 or party.vs_level > 3:
		problems.append("vs_level = %d" % party.vs_level)
	if state.resilience < 0.0 or state.resilience > 100.0:
		problems.append("resilience = %s" % state.resilience)
	for land_id: String in state.lands:
		var polling := state.lands[land_id].polling
		if polling < 0.0 or polling > _defs.params.value("polling_max") or is_nan(polling):
			problems.append("%s polling = %s" % [land_id, polling])
	for media_id: String in state.media:
		var house := state.media[media_id]
		for value in [house.reach, house.credibility, house.independence]:
			if value < 0.0 or value > 100.0:
				problems.append("%s out of range" % media_id)
	for person in state.persons:
		if person.role == "chair" and person.agenda != "none":
			problems.append("chair has an agenda")
	if PersonSystem.by_role(state, "chair") == null:
		problems.append("chair missing")
	return problems
