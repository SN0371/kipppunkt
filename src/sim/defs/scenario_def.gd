class_name ScenarioDef
extends RefCounted
## A scenario: the start state of a game (game-design.md 4.5, rechenmodell.md 13).

## Start values of the party with their allowed ranges [min, max].
const PARTY_FIELDS: Dictionary = {
	"money": [-INF, INF],
	"members": [0.0, INF],
	"credibility": [0.0, 100.0],
	"radicalism": [0.0, 100.0],
	"scrutiny": [0.0, 100.0],
	"vs_level": [0.0, 3.0],
	"unity": [0.0, 100.0],
	"reach_platform": [0.0, 100.0],
	"reach_classic_bonus": [0.0, 100.0],
	"contradiction_risk": [0.0, 100.0],
	"intransparency": [0.0, 100.0],
}

var id: String
var name_key: String
## Fictional calendar year of turn 1.
var start_year: int
var max_turns: int
var playable_regions: PackedStringArray
var resilience: float
## Start polling in percent for every land.
var polling_default: float
var donor_satisfaction_default: float
## Media owners' ideologies are rolled uniformly within this radius around the centre.
var media_owner_ideology_radius: float
## Start anchoring per region; regions not listed start at 0.
var anchoring: Dictionary[String, float] = {}
var party_start: Dictionary[String, float] = {}
var elections: Array[ElectionCycleDef] = []


## Builds a scenario definition from a parsed JSON object.
static func from_dict(d: Dictionary, reader: JsonReader) -> ScenarioDef:
	var def := ScenarioDef.new()
	def.id = reader.read_string(d, "id", "scenarios")
	var ctx := "scenarios[%s]" % def.id
	def.name_key = reader.read_string(d, "name_key", ctx)
	def.start_year = reader.read_int(d, "start_year", ctx, 1, 9999)
	def.max_turns = reader.read_int(d, "max_turns", ctx, 1, 1000)
	def.playable_regions = reader.read_string_array(d, "playable_regions", ctx)
	def.resilience = reader.read_float(d, "resilience", ctx, 0.0, 100.0)
	def.polling_default = reader.read_float(d, "polling_default", ctx, 0.0, 100.0)
	def.donor_satisfaction_default = reader.read_float(
		d, "donor_satisfaction_default", ctx, 0.0, 100.0
	)
	def.media_owner_ideology_radius = reader.read_float(
		d, "media_owner_ideology_radius", ctx, 0.0, 100.0
	)
	def.anchoring = reader.read_float_map(d, "anchoring", ctx, 0.0, 100.0)
	var party := reader.read_dict(d, "party", ctx)
	for field: String in PARTY_FIELDS:
		var bounds: Array = PARTY_FIELDS[field]
		def.party_start[field] = reader.read_float(party, field, ctx + ".party", bounds[0], bounds[1])
	for field: String in party:
		if not PARTY_FIELDS.has(field):
			reader.error(ctx + ".party", "unknown field '%s'" % field)
	var elections := reader.read_array(d, "elections", ctx)
	for i in elections.size():
		var election_ctx := "%s.elections[%d]" % [ctx, i]
		if typeof(elections[i]) != TYPE_DICTIONARY:
			reader.error(election_ctx, "must be an object")
			continue
		def.elections.append(ElectionCycleDef.from_dict(elections[i], reader, election_ctx))
	return def
