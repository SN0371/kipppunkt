class_name ElectionCycleDef
extends RefCounted
## A recurring election in a scenario's calendar (rechenmodell.md section 7).

const TYPES: PackedStringArray = ["municipal", "state", "federal"]

var type: String
## Land id for municipal and state elections, empty for federal elections.
var land: String
## Turn of the first election (1-based).
var first_turn: int
## Turns between two elections.
var interval: int


## Builds an election cycle from a parsed JSON object.
static func from_dict(d: Dictionary, reader: JsonReader, ctx: String) -> ElectionCycleDef:
	var def := ElectionCycleDef.new()
	def.type = reader.read_enum(d, "type", ctx, TYPES)
	if def.type == "federal":
		if d.has("land"):
			reader.error(ctx, "federal elections must not name a land")
	else:
		def.land = reader.read_string(d, "land", ctx)
	def.first_turn = reader.read_int(d, "first_turn", ctx, 1, 1000)
	def.interval = reader.read_int(d, "interval", ctx, 1, 1000)
	return def


## Returns true if this election takes place in the given turn.
func is_due(turn: int) -> bool:
	return turn >= first_turn and (turn - first_turn) % interval == 0
