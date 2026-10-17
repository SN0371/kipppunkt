class_name GameMetrics
extends RefCounted
## Key figures of a finished game, read from the state and its protocol (prototyp-plan.md 7).

## Column order of the CSV output.
const COLUMNS: PackedStringArray = [
	"bot", "seed", "outcome", "end_turn", "bundestag_turn", "max_vs_level", "suspected_turn",
	"first_message_turn", "first_exposure_turn", "peak_polling", "final_polling", "phase",
	"landtag_count", "money", "members", "credibility", "radicalism", "unity", "resilience",
]
## Turn value for events that never happened.
const NEVER := -1


## Collects the key figures of a game. The peak polling is tracked by the caller,
## because the state only keeps the last few national values.
static func collect(state: GameState, bot_id: String, peak_polling: float) -> Dictionary:
	var party := state.party
	var landtag_count := 0
	for land: LandState in state.lands.values():
		if land.in_landtag:
			landtag_count += 1
	var max_vs := 0
	for entry in SimLog.find(state, "surveillance_level"):
		max_vs = maxi(max_vs, int(entry["data"]["level"]))
	return {
		"bot": bot_id,
		"seed": state.game_seed,
		"outcome": state.outcome,
		"end_turn": state.turn,
		"bundestag_turn": _first_turn(state, "election", func(d: Dictionary) -> bool: return d["type"] == "federal" and d["seats"]),
		"max_vs_level": max_vs,
		"suspected_turn": _first_turn(state, "surveillance_level", func(d: Dictionary) -> bool: return int(d["level"]) >= 2),
		"first_message_turn": _first_turn(state, "regional_message_set"),
		"first_exposure_turn": _first_turn(state, "press_exposed_contradiction"),
		"peak_polling": snappedf(peak_polling, 0.01),
		"final_polling": snappedf(state.latest_national_polling(), 0.01),
		"phase": state.phase,
		"landtag_count": landtag_count,
		"money": snappedf(party.money, 0.1),
		"members": party.members,
		"credibility": snappedf(party.credibility, 0.1),
		"radicalism": snappedf(party.radicalism, 0.1),
		"unity": snappedf(party.unity, 0.1),
		"resilience": snappedf(state.resilience, 0.1),
	}


## Returns one CSV line with the values in COLUMNS order.
static func to_csv_line(row: Dictionary) -> String:
	var values := PackedStringArray()
	for column in COLUMNS:
		values.append(str(row[column]))
	return ",".join(values)


static func _first_turn(state: GameState, kind: String, condition: Callable = Callable()) -> int:
	for entry in SimLog.find(state, kind):
		if not condition.is_valid() or condition.call(entry["data"]):
			return int(entry["turn"])
	return NEVER
