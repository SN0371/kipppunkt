class_name RivalPartyDef
extends RefCounted
## An established rival party with a fixed ideology (rechenmodell.md 5.5).

var id: String
var name_key: String
## Position on the axes (economy, society), each -100..+100.
var ideology: Vector2
## Vote share per land in percent.
var strength: Dictionary[String, float] = {}


## Builds a rival party definition from a parsed JSON object.
static func from_dict(d: Dictionary, reader: JsonReader) -> RivalPartyDef:
	var def := RivalPartyDef.new()
	def.id = reader.read_string(d, "id", "parties")
	var ctx := "parties[%s]" % def.id
	def.name_key = reader.read_string(d, "name_key", ctx)
	def.ideology = reader.read_vector2(d, "ideology", ctx, 100.0)
	def.strength = reader.read_float_map(d, "strength", ctx, 0.0, 100.0)
	return def
