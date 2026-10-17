class_name LandState
extends RefCounted
## Dynamic state of the party in one land (rechenmodell.md section 1.4).

## Polling of the party in percent (U_l).
var polling: float = 0.0
## Party is represented in the land parliament (LT_l).
var in_landtag: bool = false
## Result of the last state election in percent.
var last_state_result: float = 0.0
## Result of the last municipal election in percent.
var last_municipal_result: float = 0.0


## Serializes the land state to plain JSON-compatible data.
func to_dict() -> Dictionary:
	return {
		"polling": polling,
		"in_landtag": in_landtag,
		"last_state_result": last_state_result,
		"last_municipal_result": last_municipal_result,
	}


## Restores a land state from data written by to_dict().
static func from_dict(d: Dictionary, reader: JsonReader, ctx: String) -> LandState:
	var land := LandState.new()
	land.polling = reader.read_float(d, "polling", ctx, 0.0, 100.0)
	land.in_landtag = reader.read_bool(d, "in_landtag", ctx)
	land.last_state_result = reader.read_float(d, "last_state_result", ctx, 0.0, 100.0)
	land.last_municipal_result = reader.read_float(d, "last_municipal_result", ctx, 0.0, 100.0)
	return land
