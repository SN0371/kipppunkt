class_name PartyState
extends RefCounted
## Dynamic state of the player's party (rechenmodell.md section 1.2).

## Money in thousand euros (G).
var money: float = 0.0
## Members (M).
var members: int = 0
## Activists available this turn (A).
var activists: int = 0
## Action points available this turn (AP).
var action_points: int = 0
## Credibility (C), 0..100.
var credibility: float = 0.0
## Radicalism of methods (Rad), 0..100.
var radicalism: float = 0.0
## Scrutiny by authorities, press and courts (B), 0..100.
var scrutiny: float = 0.0
## Surveillance level (VS): 0 none, 1 suspected case to check, 2 suspected, 3 confirmed extremist.
var vs_level: int = 0
## Party unity (E), 0..100.
var unity: float = 0.0
## Reach on platforms (RP), 0..100.
var reach_platform: float = 0.0
## Short-term attention in classic media from actions and events (RK_Bonus), 0..100.
var reach_classic_bonus: float = 0.0
## Risk that contradicting regional messages are exposed (W), 0..100.
var contradiction_risk: float = 0.0
## Share of funding that bypasses publication duties, 0..100.
var intransparency: float = 0.0
## Federal position per topic (-2..+2); topics without a position are absent.
var positions: Dictionary[String, int] = {}
## Turns the current position per topic has been held.
var position_age: Dictionary[String, int] = {}
## Deviating messages per region: region id -> {topic id -> position}.
var regional_messages: Dictionary[String, Dictionary] = {}
## Result of the last federal election in percent.
var last_federal_result: float = 0.0
var in_bundestag: bool = false
## Consecutive turns with scrutiny above the threshold of the next surveillance level.
var vs_up_turns: int = 0
## Consecutive turns with scrutiny far below the threshold of the current surveillance level.
var vs_down_turns: int = 0
## True if an action of the current turn raised radicalism; radicalism then does not decay.
var radical_action_this_turn: bool = false


## Serializes the party to plain JSON-compatible data.
func to_dict() -> Dictionary:
	var messages: Dictionary = {}
	for region_id: String in regional_messages:
		messages[region_id] = regional_messages[region_id].duplicate()
	return {
		"money": money,
		"members": members,
		"activists": activists,
		"action_points": action_points,
		"credibility": credibility,
		"radicalism": radicalism,
		"scrutiny": scrutiny,
		"vs_level": vs_level,
		"unity": unity,
		"reach_platform": reach_platform,
		"reach_classic_bonus": reach_classic_bonus,
		"contradiction_risk": contradiction_risk,
		"intransparency": intransparency,
		"positions": positions.duplicate(),
		"position_age": position_age.duplicate(),
		"regional_messages": messages,
		"last_federal_result": last_federal_result,
		"in_bundestag": in_bundestag,
		"vs_up_turns": vs_up_turns,
		"vs_down_turns": vs_down_turns,
		"radical_action_this_turn": radical_action_this_turn,
	}


## Restores a party from data written by to_dict(), recording type errors in the reader.
static func from_dict(d: Dictionary, reader: JsonReader) -> PartyState:
	var ctx := "state.party"
	var party := PartyState.new()
	party.money = reader.read_float(d, "money", ctx)
	party.members = reader.read_int(d, "members", ctx, 0)
	party.activists = reader.read_int(d, "activists", ctx, 0)
	party.action_points = reader.read_int(d, "action_points", ctx, 0)
	party.credibility = reader.read_float(d, "credibility", ctx, 0.0, 100.0)
	party.radicalism = reader.read_float(d, "radicalism", ctx, 0.0, 100.0)
	party.scrutiny = reader.read_float(d, "scrutiny", ctx, 0.0, 100.0)
	party.vs_level = reader.read_int(d, "vs_level", ctx, 0, 3)
	party.unity = reader.read_float(d, "unity", ctx, 0.0, 100.0)
	party.reach_platform = reader.read_float(d, "reach_platform", ctx, 0.0, 100.0)
	party.reach_classic_bonus = reader.read_float(d, "reach_classic_bonus", ctx, 0.0, 100.0)
	party.contradiction_risk = reader.read_float(d, "contradiction_risk", ctx, 0.0, 100.0)
	party.intransparency = reader.read_float(d, "intransparency", ctx, 0.0, 100.0)
	party.positions = reader.read_int_map(d, "positions", ctx, -2, 2)
	party.position_age = reader.read_int_map(d, "position_age", ctx, 0, 1000000)
	var messages := reader.read_dict(d, "regional_messages", ctx)
	for region_id: String in messages:
		party.regional_messages[region_id] = reader.read_int_map(
			messages, region_id, ctx + ".regional_messages", -2, 2
		)
	party.last_federal_result = reader.read_float(d, "last_federal_result", ctx, 0.0, 100.0)
	party.in_bundestag = reader.read_bool(d, "in_bundestag", ctx)
	party.vs_up_turns = reader.read_int(d, "vs_up_turns", ctx, 0)
	party.vs_down_turns = reader.read_int(d, "vs_down_turns", ctx, 0)
	party.radical_action_this_turn = reader.read_bool(d, "radical_action_this_turn", ctx)
	return party
