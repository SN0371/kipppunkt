class_name ActionDef
extends RefCounted
## An action the party can take, described as data (rechenmodell.md section 4).
##
## Effects are lists of simple operations instead of code, for example
## {"op": "add", "stat": "party.reach_platform", "value": 6}.

const TARGETS: PackedStringArray = ["none", "region", "land", "topic", "person", "donor"]
## Order fields an action may require in addition to its target.
const PARAMETERS: PackedStringArray = ["topic", "value", "role"]
## Stats an "add" operation may change. "target.*" refers to the order's target.
const ADD_STATS: PackedStringArray = [
	"party.money", "party.credibility", "party.radicalism", "party.scrutiny", "party.unity",
	"party.reach_platform", "party.reach_classic_bonus", "party.contradiction_risk",
	"party.intransparency", "resilience", "lands.polling", "target.anchoring", "target.satisfaction",
]
const SCALE_STATS: PackedStringArray = ["party.members"]
## Operations and the target type they need ("" = any).
const OPS: Dictionary = {
	"add": "",
	"scale": "",
	"modifier": "",
	"set_position": "topic",
	"set_regional_message": "region",
	"donor_payment": "donor",
	"reveal_agenda": "person",
	"purge": "none",
	"appoint": "person",
	"dismiss": "person",
}
## Optional preconditions.
const REQUIREMENTS: PackedStringArray = [
	"campaign", "municipal_level", "candidate", "staff", "min_target_satisfaction",
]

var id: String
var name_key: String
var target: String
var parameters: PackedStringArray
var cost_action_points: int
var cost_money: float
var cost_activists: int
## Success chance before competence and modifiers; 1 means the action always succeeds.
var base_chance: float
## False for actions the chair must take personally.
var delegable: bool
var requires: Dictionary = {}
## Hidden agendas that refuse this action when it is delegated to them.
var agenda_conflicts: PackedStringArray
var effects: Array[Dictionary] = []
var failure_effects: Array[Dictionary] = []
## Applied whether the action succeeds or not.
var side_effects: Array[Dictionary] = []


## Builds an action definition from a parsed JSON object.
static func from_dict(d: Dictionary, reader: JsonReader) -> ActionDef:
	var def := ActionDef.new()
	def.id = reader.read_string(d, "id", "actions")
	var ctx := "actions[%s]" % def.id
	def.name_key = reader.read_string(d, "name_key", ctx)
	def.target = reader.read_enum(d, "target", ctx, TARGETS)
	def.parameters = reader.read_string_array(d, "parameters", ctx)
	for parameter in def.parameters:
		if not PARAMETERS.has(parameter):
			reader.error(ctx, "unknown parameter '%s'" % parameter)
	var cost := reader.read_dict(d, "cost", ctx)
	def.cost_action_points = reader.read_int(cost, "action_points", ctx + ".cost", 0, 10)
	def.cost_money = reader.read_float(cost, "money", ctx + ".cost", 0.0)
	def.cost_activists = reader.read_int(cost, "activists", ctx + ".cost", 0)
	def.base_chance = reader.read_float(d, "base_chance", ctx, 0.0, 1.0)
	def.delegable = reader.read_bool(d, "delegable", ctx)
	def.requires = reader.read_dict(d, "requires", ctx)
	for key: String in def.requires:
		if not REQUIREMENTS.has(key):
			reader.error(ctx + ".requires", "unknown requirement '%s'" % key)
	def.agenda_conflicts = reader.read_string_array(d, "agenda_conflicts", ctx)
	for agenda in def.agenda_conflicts:
		if not PersonState.AGENDAS.has(agenda) or agenda == "none":
			reader.error(ctx, "unknown agenda '%s'" % agenda)
	def.effects = _read_ops(d, "effects", ctx, def, reader)
	def.failure_effects = _read_ops(d, "failure_effects", ctx, def, reader)
	def.side_effects = _read_ops(d, "side_effects", ctx, def, reader)
	return def


## Returns true if a parameter must be given in the order.
func needs(parameter: String) -> bool:
	return parameters.has(parameter)


## Returns true if the action raises a stat through an "add" operation (success or side effect).
## Used to find agenda conflicts: informants report actions that draw scrutiny,
## undercover journalists document actions that hide money.
func raises(stat: String) -> bool:
	for op in effects + side_effects:
		if op["op"] == "add" and op["stat"] == stat and float(op["value"]) > 0.0:
			return true
	return false


static func _read_ops(
	d: Dictionary, key: String, ctx: String, def: ActionDef, reader: JsonReader
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var items := reader.read_array(d, key, ctx)
	for i in items.size():
		var op_ctx := "%s.%s[%d]" % [ctx, key, i]
		if typeof(items[i]) != TYPE_DICTIONARY:
			reader.error(op_ctx, "must be an object")
			continue
		var op: Dictionary = items[i]
		var name := reader.read_enum(op, "op", op_ctx, PackedStringArray(OPS.keys()))
		var needed_target: String = OPS.get(name, "")
		if not needed_target.is_empty() and def.target != needed_target:
			reader.error(op_ctx, "operation '%s' needs target '%s'" % [name, needed_target])
		match name:
			"add":
				var stat := reader.read_enum(op, "stat", op_ctx, ADD_STATS)
				reader.read_float(op, "value", op_ctx)
				if stat == "target.anchoring" and def.target != "region":
					reader.error(op_ctx, "'target.anchoring' needs target 'region'")
				if stat == "target.satisfaction" and def.target != "donor":
					reader.error(op_ctx, "'target.satisfaction' needs target 'donor'")
			"scale":
				reader.read_enum(op, "stat", op_ctx, SCALE_STATS)
				reader.read_float(op, "value", op_ctx, 0.0)
			"modifier":
				reader.read_string(op, "target", op_ctx)
				reader.read_float(op, "value", op_ctx)
				reader.read_int(op, "turns", op_ctx, ModifierState.PERMANENT)
			"set_position":
				if not def.needs("value"):
					reader.error(op_ctx, "'set_position' needs parameter 'value'")
			"set_regional_message":
				if not def.needs("topic") or not def.needs("value"):
					reader.error(op_ctx, "'set_regional_message' needs parameters 'topic' and 'value'")
			"donor_payment":
				reader.read_float(op, "factor", op_ctx, 0.0)
			"purge":
				reader.read_float(op, "loyalty_below", op_ctx, 0.0, 100.0)
				reader.read_float(op, "competence_loss", op_ctx, 0.0, 100.0)
			"appoint":
				if not def.needs("role"):
					reader.error(op_ctx, "'appoint' needs parameter 'role'")
		result.append(op)
	return result
