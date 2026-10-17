class_name CrisisState
extends RefCounted
## An ongoing crisis (rechenmodell.md section 11).

var crisis_id: String = ""
var remaining_turns: int = 0
var elapsed_turns: int = 0


## Serializes the crisis to plain JSON-compatible data.
func to_dict() -> Dictionary:
	return {
		"crisis_id": crisis_id,
		"remaining_turns": remaining_turns,
		"elapsed_turns": elapsed_turns,
	}


## Restores a crisis from data written by to_dict().
static func from_dict(d: Dictionary, reader: JsonReader, ctx: String) -> CrisisState:
	var crisis := CrisisState.new()
	crisis.crisis_id = reader.read_string(d, "crisis_id", ctx)
	crisis.remaining_turns = reader.read_int(d, "remaining_turns", ctx, 0)
	crisis.elapsed_turns = reader.read_int(d, "elapsed_turns", ctx, 0)
	return crisis
