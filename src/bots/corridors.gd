class_name Corridors
extends RefCounted
## Balancing corridors of rechenmodell.md section 14, made measurable.
##
## Each check takes the metrics of many games of one bot (see GameMetrics) and returns
## {"passed": bool, "summary": String}.

## Federal elections take place in turns 8, 24, 40, ... (scenario calendar), so the corridors
## are expressed as "won by turn": patient by the third election, radical by the second.
const PATIENT_WON_BY_TURN := 40
const RADICAL_WON_BY_TURN := 24
const RADICAL_MIN_SUSPECTED_SHARE := 1.0 / 3.0
const TWO_FACED_DELAY := Vector2i(6, 10)
const RANDOM_MAX_WIN_SHARE := 0.1
const MAJORITY := 0.5


## Checks the corridor of a bot. Unknown bots pass without check.
static func check(bot_id: String, rows: Array[Dictionary]) -> Dictionary:
	if rows.is_empty():
		return {"passed": false, "summary": "no games"}
	match bot_id:
		"patient":
			var share := _won_by(rows, PATIENT_WON_BY_TURN)
			return _result(share > MAJORITY,
				"Bundestag by turn %d: %s (needs > 50 %%), %s" % [PATIENT_WON_BY_TURN, _percent(share), _outcomes(rows)])
		"radical":
			var share := _won_by(rows, RADICAL_WON_BY_TURN)
			var suspected := _share(rows, func(r: Dictionary) -> bool:
				return r["suspected_turn"] != GameMetrics.NEVER \
					and (r["bundestag_turn"] == GameMetrics.NEVER or r["suspected_turn"] <= r["bundestag_turn"]))
			return _result(share >= MAJORITY and suspected >= RADICAL_MIN_SUSPECTED_SHARE,
				"Bundestag by turn %d: %s (needs >= 50 %%), suspected case before %s (needs >= 33 %%), %s"
				% [RADICAL_WON_BY_TURN, _percent(share), _percent(suspected), _outcomes(rows)])
		"two_faced":
			var share := _share(rows, func(r: Dictionary) -> bool:
				return r["first_exposure_turn"] != GameMetrics.NEVER \
					and _within(r["first_exposure_turn"] - r["first_message_turn"], TWO_FACED_DELAY))
			var exposed := rows.filter(func(r: Dictionary) -> bool: return r["first_exposure_turn"] != GameMetrics.NEVER)
			var median_delay := _median(exposed.map(func(r: Dictionary) -> int:
				return r["first_exposure_turn"] - r["first_message_turn"]))
			return _result(share > MAJORITY,
				"exposed %d-%d turns after first message: %s (needs > 50 %%), exposed at all %s, median delay %d"
				% [TWO_FACED_DELAY.x, TWO_FACED_DELAY.y, _percent(share), _percent(exposed.size() / float(rows.size())), median_delay])
		"passive":
			var share := _share(rows, func(r: Dictionary) -> bool: return r["outcome"] == "irrelevant")
			return _result(share > MAJORITY, "irrelevant %s (needs > 50 %%), %s" % [_percent(share), _outcomes(rows)])
		"random":
			var share := _share(rows, func(r: Dictionary) -> bool: return r["outcome"] == "won")
			return _result(share <= RANDOM_MAX_WIN_SHARE, "wins %s (needs <= 10 %%), %s" % [_percent(share), _outcomes(rows)])
	return {"passed": true, "summary": "no corridor defined"}


static func _result(passed: bool, summary: String) -> Dictionary:
	return {"passed": passed, "summary": summary}


static func _won_by(rows: Array[Dictionary], turn: int) -> float:
	return _share(rows, func(r: Dictionary) -> bool:
		return r["outcome"] == "won" and r["bundestag_turn"] <= turn)


static func _share(rows: Array[Dictionary], condition: Callable) -> float:
	return rows.filter(condition).size() / float(rows.size())


static func _within(value: int, bounds: Vector2i) -> bool:
	return value >= bounds.x and value <= bounds.y


## Returns the median of integer values, or GameMetrics.NEVER for an empty list.
static func _median(values: Array) -> int:
	if values.is_empty():
		return GameMetrics.NEVER
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2]


static func _percent(share: float) -> String:
	return "%d %%" % roundi(share * 100.0)


## Returns a compact count of all outcomes, for example "won 12, timeout 8".
static func _outcomes(rows: Array[Dictionary]) -> String:
	var counts: Dictionary = {}
	for row in rows:
		counts[row["outcome"]] = counts.get(row["outcome"], 0) + 1
	var parts := PackedStringArray()
	for outcome: String in counts:
		parts.append("%s %d" % [outcome, counts[outcome]])
	return ", ".join(parts)
