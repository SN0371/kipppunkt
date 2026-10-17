class_name CrisisDef
extends RefCounted
## A crisis that can be drawn during the game (rechenmodell.md section 11).

var id: String
var name_key: String
var min_duration: int
var max_duration: int
## Salience multiplier per affected topic.
var salience: Dictionary[String, float] = {}
## Factor applied to all donor payments while the crisis lasts.
var donor_payment_factor: float
## Factor applied to member growth while the crisis lasts.
var member_growth_factor: float


## Builds a crisis definition from a parsed JSON object.
static func from_dict(d: Dictionary, reader: JsonReader) -> CrisisDef:
	var def := CrisisDef.new()
	def.id = reader.read_string(d, "id", "crises")
	var ctx := "crises[%s]" % def.id
	def.name_key = reader.read_string(d, "name_key", ctx)
	def.min_duration = reader.read_int(d, "min_duration", ctx, 1, 100)
	def.max_duration = reader.read_int(d, "max_duration", ctx, 1, 100)
	if def.max_duration < def.min_duration:
		reader.error(ctx, "max_duration must not be smaller than min_duration")
	def.salience = reader.read_float_map(d, "salience", ctx, 0.0, 5.0)
	def.donor_payment_factor = reader.read_float(d, "donor_payment_factor", ctx, 0.0, 2.0)
	def.member_growth_factor = reader.read_float(d, "member_growth_factor", ctx, 0.0, 2.0)
	return def
