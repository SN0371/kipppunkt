class_name GameSession
extends RefCounted
## Connects the user interface with the simulation: planning orders, ending turns,
## saving and loading (prototyp-plan.md section 9). Has no dependency on nodes, so it is testable.

## Emitted whenever the state or the planned orders change.
signal changed
## Emitted after a turn has been resolved, with the protocol entries of that turn.
signal turn_finished(report: Array[Dictionary])

const SCENARIO := "scenario.new_party"
const SAVE_DIR := "user://saves"

var defs: GameDefs
var state: GameState
## Orders planned for the current turn, in the order they will be carried out.
var planned: Array[ActionOrder] = []
## Protocol entries of the last resolved turn.
var last_report: Array[Dictionary] = []
## Staff member who carries out delegable actions planned from now on; empty means the chair.
var performer: String = ""


func _init(definitions: GameDefs) -> void:
	defs = definitions


## Returns true while a game is loaded.
func has_game() -> bool:
	return state != null


## Starts a new game and its first turn.
func new_game(game_seed: int) -> void:
	state = StateFactory.create(defs, SCENARIO, game_seed)
	planned.clear()
	last_report.clear()
	TurnRunner.start_turn(state, defs)
	changed.emit()


## Returns the resources left after all planned orders: {"action_points", "money", "activists"}.
func remaining() -> Dictionary:
	var budget := {
		"action_points": state.party.action_points,
		"money": state.party.money,
		"activists": state.party.activists,
	}
	for order in planned:
		var def := defs.actions[order.action_id]
		budget["action_points"] -= ActionResolver.action_point_cost(state, def, order)
		budget["money"] -= def.cost_money
		budget["activists"] -= def.cost_activists
	return budget


## Adds an order to the plan. Returns an empty string, or the reason why it cannot be planned.
func plan(order: ActionOrder) -> String:
	if not has_game() or state.is_over():
		return "game is over"
	var reason := ActionResolver.check(state, defs, order, remaining())
	if reason.is_empty():
		reason = _conflict_with_plan(order)
	if reason.is_empty():
		planned.append(order)
		changed.emit()
	return reason


## Plans the federal position on a topic, replacing an earlier plan for the same topic.
## Choosing the current position again just removes the plan. Returns the rejection reason or "".
func plan_position(topic_id: String, value: int) -> String:
	for i in planned.size():
		if planned[i].action_id == "action.set_position" and planned[i].target == topic_id:
			planned.remove_at(i)
			break
	if value == state.party.positions.get(topic_id, 0):
		changed.emit()
		return ""
	return plan(ActionOrder.create("action.set_position", topic_id, {"value": value}))


## Returns the planned position for a topic, or the current one if none is planned (0 = none).
func intended_position(topic_id: String) -> int:
	for order in planned:
		if order.action_id == "action.set_position" and order.target == topic_id:
			return order.value
	return state.party.positions.get(topic_id, 0)


## Returns true if a position change is planned for the topic.
func is_position_planned(topic_id: String) -> bool:
	return planned.any(func(o: ActionOrder) -> bool: return o.action_id == "action.set_position" and o.target == topic_id)


## Returns the year and quarter of a turn as [year, quarter].
func date_of(turn: int) -> Array[int]:
	return [defs.scenarios[state.scenario_id].start_year + (turn - 1) / 4, (turn - 1) % 4 + 1]


## Removes a planned order.
func unplan(index: int) -> void:
	if index >= 0 and index < planned.size():
		planned.remove_at(index)
		changed.emit()


## Resolves the turn with the planned orders and starts the next one.
## Returns the protocol entries of the resolved turn.
func end_turn() -> Array[Dictionary]:
	var first_entry := state.log_entries.size()
	TurnRunner.finish_turn(state, defs, planned)
	planned.clear()
	if PersonSystem.by_id(state, performer) == null:
		performer = ""
	if not state.is_over():
		TurnRunner.start_turn(state, defs)
	last_report.clear()
	for i in range(first_entry, state.log_entries.size()):
		last_report.append(state.log_entries[i])
	turn_finished.emit(last_report)
	changed.emit()
	return last_report


## Returns the fictional calendar year of the current turn.
func year() -> int:
	return defs.scenarios[state.scenario_id].start_year + (state.turn - 1) / 4


## Returns the quarter (1..4) of the current turn.
func quarter() -> int:
	return (state.turn - 1) % 4 + 1


## Saves the game in a named slot. Planned orders are not saved.
func save(slot: String) -> Error:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	return SaveGame.save_to_file(state, _slot_path(slot))


## Loads a game from a named slot. Returns an empty string, or the reasons for failure.
func load_game(slot: String) -> String:
	var reader := JsonReader.new()
	var loaded := SaveGame.load_from_file(_slot_path(slot), defs, reader)
	if loaded == null:
		return "\n".join(reader.errors)
	state = loaded
	planned.clear()
	last_report.clear()
	if not state.awaiting_orders and not state.is_over():
		TurnRunner.start_turn(state, defs)
	changed.emit()
	return ""


## Returns the names of all saved slots, sorted.
static func save_slots() -> PackedStringArray:
	var slots := PackedStringArray()
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		for file_name in DirAccess.get_files_at(SAVE_DIR):
			if file_name.get_extension() == "json":
				slots.append(file_name.get_basename())
	slots.sort()
	return slots


## Rejects a second appointment for the same role or person within one plan.
func _conflict_with_plan(order: ActionOrder) -> String:
	if order.action_id != "action.appoint":
		return ""
	for other in planned:
		if other.action_id == "action.appoint" and (other.role == order.role or other.target == order.target):
			return "already planned"
	return ""


static func _slot_path(slot: String) -> String:
	return SAVE_DIR.path_join(slot.validate_filename() + ".json")
