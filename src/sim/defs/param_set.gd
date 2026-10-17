class_name ParamSet
extends RefCounted
## Balancing parameters (rechenmodell.md section 13), keyed by their code name.
##
## Each entry in params.json carries the symbol used in rechenmodell.md so the
## data file stays traceable to the documentation.

## Every parameter the simulation reads. Missing or unknown names are load errors.
const REQUIRED: PackedStringArray = [
	"polling_base", "topic_weight", "anchoring_weight", "leadership_weight",
	"stigma_per_level", "polarization_penalty", "polling_alpha", "polling_noise",
	"polling_max", "election_noise", "position_change_cost", "contradiction_growth",
	"contradiction_decay", "member_fee", "state_funding_per_vote", "fixed_costs",
	"member_growth", "platform_reach_decay", "municipal_anchoring_gain", "press_strength",
	"crisis_probability", "crisis_bonus", "rival_proximity_range", "rival_pressure",
	"media_climate_effect", "media_climate_credibility_shift", "media_sensationalism_reach",
	"donor_base", "donor_topic_weight", "donor_ideology_weight",
	"member_small_party", "members_per_polling_point",
	"mobilization_weight", "turnout_base", "turnout_gap_effect",
]

var _values: Dictionary[String, float] = {}


## Builds the parameter set from the parsed params.json object.
static func from_dict(raw: Dictionary, reader: JsonReader) -> ParamSet:
	var params := ParamSet.new()
	for name: String in raw:
		var ctx := "params.%s" % name
		if not REQUIRED.has(name):
			reader.error(ctx, "unknown parameter")
			continue
		if typeof(raw[name]) != TYPE_DICTIONARY:
			reader.error(ctx, "must be an object with 'symbol' and 'value'")
			continue
		reader.read_string(raw[name], "symbol", ctx)
		params._values[name] = reader.read_float(raw[name], "value", ctx)
	for name in REQUIRED:
		if not params._values.has(name):
			reader.error("params", "missing parameter '%s'" % name)
	return params


## Returns the value of a parameter. Unknown names are programming errors.
func value(name: String) -> float:
	assert(_values.has(name), "Unknown parameter: %s" % name)
	return _values.get(name, 0.0)


## Overrides the value of a known parameter. Meant for balancing tools and tests;
## the game itself never changes parameters.
func override(name: String, new_value: float) -> void:
	assert(_values.has(name), "Unknown parameter: %s" % name)
	_values[name] = new_value
