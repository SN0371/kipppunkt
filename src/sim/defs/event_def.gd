class_name EventDef
extends RefCounted
## An event that forces the party to take a stand on a topic (rechenmodell.md section 5.8).

var id: String
var name_key: String
var text_key: String
## Topic the party has to take a stand on.
var topic: String
## "national" or a region id; where the event happens.
var area: String
## Relative chance among the events of the same topic.
var weight: float
## Crisis that must be running for the event to occur; empty if none.
var crisis: String


## Builds an event definition from a parsed JSON object.
static func from_dict(d: Dictionary, reader: JsonReader) -> EventDef:
	var def := EventDef.new()
	def.id = reader.read_string(d, "id", "events")
	var ctx := "events[%s]" % def.id
	def.name_key = reader.read_string(d, "name_key", ctx)
	def.text_key = reader.read_string(d, "text_key", ctx)
	def.topic = reader.read_string(d, "topic", ctx)
	def.area = reader.read_string(d, "area", ctx)
	def.weight = reader.read_float(d, "weight", ctx, 0.001)
	def.crisis = reader.read_optional_string(d, "crisis", ctx, "")
	return def
