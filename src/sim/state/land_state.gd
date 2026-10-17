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
## Reach of the party in classic media (RK_l), computed by the last polling update.
var classic_reach: float = 0.0
## Media climate towards the party (MK_l), -1..+1, computed by the last polling update.
var media_climate: float = 0.0
## Share of unserved urgent concerns (Lücke_l), 0..1, computed by the last polling update.
var representation_gap: float = 0.0
## Expected turnout in percent, computed by the last polling update.
var turnout: float = 0.0


## Serializes the land state to plain JSON-compatible data.
func to_dict() -> Dictionary:
	return {
		"polling": polling,
		"in_landtag": in_landtag,
		"last_state_result": last_state_result,
		"last_municipal_result": last_municipal_result,
		"classic_reach": classic_reach,
		"media_climate": media_climate,
		"representation_gap": representation_gap,
		"turnout": turnout,
	}


## Restores a land state from data written by to_dict().
static func from_dict(d: Dictionary, reader: JsonReader, ctx: String) -> LandState:
	var land := LandState.new()
	land.polling = reader.read_float(d, "polling", ctx, 0.0, 100.0)
	land.in_landtag = reader.read_bool(d, "in_landtag", ctx)
	land.last_state_result = reader.read_float(d, "last_state_result", ctx, 0.0, 100.0)
	land.last_municipal_result = reader.read_float(d, "last_municipal_result", ctx, 0.0, 100.0)
	land.classic_reach = reader.read_float(d, "classic_reach", ctx, 0.0, 100.0)
	land.media_climate = reader.read_float(d, "media_climate", ctx, -1.0, 1.0)
	land.representation_gap = reader.read_float(d, "representation_gap", ctx, 0.0, 1.0)
	land.turnout = reader.read_float(d, "turnout", ctx, 0.0, 100.0)
	return land
