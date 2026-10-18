class_name ContradictionDef
extends RefCounted
## Positions that do not fit together (rechenmodell.md section 5.7). A contradiction applies
## when the party holds every listed topic in the listed direction.

var id: String
var name_key: String
## Direction per topic: +1 means "for", -1 means "against".
var topics: Dictionary[String, int] = {}
## Strength of the contradiction at full positions, 0..1.
var weight: float


## Builds a contradiction from a parsed JSON object.
static func from_dict(d: Dictionary, reader: JsonReader) -> ContradictionDef:
	var def := ContradictionDef.new()
	def.id = reader.read_string(d, "id", "contradictions")
	var ctx := "contradictions[%s]" % def.id
	def.name_key = reader.read_string(d, "name_key", ctx)
	def.topics = reader.read_int_map(d, "topics", ctx, -1, 1)
	for topic_id: String in def.topics:
		if def.topics[topic_id] == 0:
			reader.error(ctx + ".topics." + topic_id, "direction must be 1 or -1")
	if def.topics.size() < 2:
		reader.error(ctx, "needs at least two topics")
	def.weight = reader.read_float(d, "weight", ctx, 0.0, 1.0)
	return def


## Returns how strongly the party's positions fall into this contradiction, 0..weight:
## the weakest participating position decides.
func strength(positions: Dictionary[String, int]) -> float:
	var weakest := 1.0
	for topic_id: String in topics:
		var value: int = positions.get(topic_id, 0)
		weakest = minf(weakest, maxf(0.0, value * topics[topic_id]) / 2.0)
	return weight * weakest
