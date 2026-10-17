class_name RegionDef
extends RefCounted
## A region grouping several lands (game-design.md 3.4).

var id: String
var name_key: String
## False for city states, where municipality and land are the same.
var has_municipal_level: bool
## Ids of the lands in this region, derived from the land definitions.
var lands: PackedStringArray = PackedStringArray()


## Builds a region definition from a parsed JSON object.
static func from_dict(d: Dictionary, reader: JsonReader) -> RegionDef:
	var def := RegionDef.new()
	def.id = reader.read_string(d, "id", "regions")
	var ctx := "regions[%s]" % def.id
	def.name_key = reader.read_string(d, "name_key", ctx)
	def.has_municipal_level = reader.read_bool(d, "has_municipal_level", ctx)
	return def
