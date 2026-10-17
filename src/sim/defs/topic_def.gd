class_name TopicDef
extends RefCounted
## A political topic and its effect on the ideology axes (rechenmodell.md 1.5, 5.1).

const KINDS: PackedStringArray = ["location", "principle"]

var id: String
var name_key: String
## "location" topics differ by region, "principle" topics mainly move the ideology profile.
var kind: String
## Direction on the axes (economy, society) of a position of +1.
var ideology_vector: Vector2


## Builds a topic definition from a parsed JSON object.
static func from_dict(d: Dictionary, reader: JsonReader) -> TopicDef:
	var def := TopicDef.new()
	def.id = reader.read_string(d, "id", "topics")
	var ctx := "topics[%s]" % def.id
	def.name_key = reader.read_string(d, "name_key", ctx)
	def.kind = reader.read_enum(d, "kind", ctx, KINDS)
	def.ideology_vector = reader.read_vector2(d, "ideology_vector", ctx, 1.0)
	return def
