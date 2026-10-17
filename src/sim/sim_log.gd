class_name SimLog
extends RefCounted
## Structured protocol of everything the simulation does (prototyp-plan.md section 2).
##
## Entries feed the history view, the debriefing and the bot analysis. Each entry
## is a plain dictionary {"turn", "kind", "data"} stored in the game state.


## Appends an entry for the current turn.
## Integers in the data are stored as floats, because JSON does not distinguish the two
## and a loaded state must equal the saved one.
static func add(state: GameState, kind: String, data: Dictionary = {}) -> void:
	state.log_entries.append({"turn": float(state.turn), "kind": kind, "data": _normalize(data)})


## Returns all entries of a kind, optionally limited to one turn.
static func find(state: GameState, kind: String, turn: int = -1) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in state.log_entries:
		if entry["kind"] == kind and (turn < 0 or int(entry["turn"]) == turn):
			result.append(entry)
	return result


static func _normalize(value: Variant) -> Variant:
	match typeof(value):
		TYPE_INT:
			return float(value)
		TYPE_DICTIONARY:
			var result: Dictionary = {}
			for key: Variant in value:
				result[key] = _normalize(value[key])
			return result
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY:
			var items: Array = []
			for item: Variant in value:
				items.append(_normalize(item))
			return items
	return value
