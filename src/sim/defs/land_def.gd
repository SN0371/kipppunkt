class_name LandDef
extends RefCounted
## A federal land with its static attributes (rechenmodell.md 1.4).

var id: String
var name_key: String
var region: String
## Share of all eligible voters in the federation (0..1).
var population_share: float
## Higher values mean an older population that relies more on classic media (0..100).
var age_index: float
## Higher values mean slower, less volatile polling (0..100).
var party_loyalty: float
## Importance of each topic in this land (0..3).
var topic_weights: Dictionary[String, int] = {}
## Preferred position on each topic (-2..+2).
var topic_preferences: Dictionary[String, int] = {}


## Builds a land definition from a parsed JSON object.
static func from_dict(d: Dictionary, reader: JsonReader) -> LandDef:
	var def := LandDef.new()
	def.id = reader.read_string(d, "id", "lands")
	var ctx := "lands[%s]" % def.id
	def.name_key = reader.read_string(d, "name_key", ctx)
	def.region = reader.read_string(d, "region", ctx)
	def.population_share = reader.read_float(d, "population_share", ctx, 0.0, 1.0)
	def.age_index = reader.read_float(d, "age_index", ctx, 0.0, 100.0)
	def.party_loyalty = reader.read_float(d, "party_loyalty", ctx, 0.0, 100.0)
	var topics := reader.read_dict(d, "topics", ctx)
	for topic_id: String in topics:
		var topic_ctx := "%s.topics.%s" % [ctx, topic_id]
		if typeof(topics[topic_id]) != TYPE_DICTIONARY:
			reader.error(topic_ctx, "must be an object with 'weight' and 'preference'")
			continue
		def.topic_weights[topic_id] = reader.read_int(topics[topic_id], "weight", topic_ctx, 0, 3)
		def.topic_preferences[topic_id] = reader.read_int(
			topics[topic_id], "preference", topic_ctx, -2, 2
		)
	return def
