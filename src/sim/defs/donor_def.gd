class_name DonorDef
extends RefCounted
## A company that may fund the party (rechenmodell.md 1.8, 5.4).

## Family businesses react later to surveillance than stock companies (rechenmodell.md 5.4).
const KINDS: PackedStringArray = ["family", "stock", "midsize"]

var id: String
var name_key: String
var kind: String
## "national" or a region id.
var region: String
## Preferred position on the axes (economy, society), each -100..+100.
var ideology: Vector2
## Maximum payment per round in thousand euros.
var max_payment: float
## Preferred position per topic (-2..+2).
var topic_preferences: Dictionary[String, int] = {}


## Builds a donor definition from a parsed JSON object.
static func from_dict(d: Dictionary, reader: JsonReader) -> DonorDef:
	var def := DonorDef.new()
	def.id = reader.read_string(d, "id", "donors")
	var ctx := "donors[%s]" % def.id
	def.name_key = reader.read_string(d, "name_key", ctx)
	def.kind = reader.read_enum(d, "kind", ctx, KINDS)
	def.region = reader.read_string(d, "region", ctx)
	def.ideology = reader.read_vector2(d, "ideology", ctx, 100.0)
	def.max_payment = reader.read_float(d, "max_payment", ctx, 0.0)
	def.topic_preferences = reader.read_int_map(d, "topic_preferences", ctx, -2, 2)
	return def
