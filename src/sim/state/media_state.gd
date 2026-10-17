class_name MediaState
extends RefCounted
## Dynamic state of one media house (rechenmodell.md section 5.6).

## Share of the audience reached (Reach_m), 0..100.
var reach: float = 0.0
## Trust of the audience (Glaub_m), 0..100.
var credibility: float = 0.0
## Independence of the newsroom (Unab_m), 0..100.
var independence: float = 0.0
## Ideology of the owner (I_m). Unused for houses governed by boards.
var owner_ideology: Vector2 = Vector2.ZERO


## Serializes the media state to plain JSON-compatible data.
func to_dict() -> Dictionary:
	return {
		"reach": reach,
		"credibility": credibility,
		"independence": independence,
		"owner_ideology": [owner_ideology.x, owner_ideology.y],
	}


## Restores a media state from data written by to_dict().
static func from_dict(d: Dictionary, reader: JsonReader, ctx: String) -> MediaState:
	var house := MediaState.new()
	house.reach = reader.read_float(d, "reach", ctx, 0.0, 100.0)
	house.credibility = reader.read_float(d, "credibility", ctx, 0.0, 100.0)
	house.independence = reader.read_float(d, "independence", ctx, 0.0, 100.0)
	house.owner_ideology = reader.read_vector2(d, "owner_ideology", ctx, 100.0)
	return house
