class_name MediaDef
extends RefCounted
## A media house with its start values (rechenmodell.md 5.6).

const KINDS: PackedStringArray = ["tabloid", "quality", "regional", "public"]
## "family": a dynasty owns the house; "boards": public broadcasting governed by supervisory boards.
const OWNERS: PackedStringArray = ["family", "boards"]

var id: String
var name_key: String
var kind: String
## "national" or a region id.
var area: String
## Start reach (0..100).
var reach: float
## Start independence of the newsroom (0..100).
var independence: float
## True if the independence never changes (programme autonomy of public broadcasting).
var independence_fixed: bool
var owner: String


## Builds a media house definition from a parsed JSON object.
static func from_dict(d: Dictionary, reader: JsonReader) -> MediaDef:
	var def := MediaDef.new()
	def.id = reader.read_string(d, "id", "media")
	var ctx := "media[%s]" % def.id
	def.name_key = reader.read_string(d, "name_key", ctx)
	def.kind = reader.read_enum(d, "kind", ctx, KINDS)
	def.area = reader.read_string(d, "area", ctx)
	def.reach = reader.read_float(d, "reach", ctx, 0.0, 100.0)
	def.independence = reader.read_float(d, "independence", ctx, 0.0, 100.0)
	def.independence_fixed = reader.read_bool(d, "independence_fixed", ctx)
	def.owner = reader.read_enum(d, "owner", ctx, OWNERS)
	return def
