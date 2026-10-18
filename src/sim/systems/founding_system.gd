class_name FoundingSystem
extends RefCounted
## Founding of the party before the first turn (rechenmodell.md section 5.8): name,
## abbreviation, the chair's name and the founding programme.

## Positions of the founding programme: a party is founded for a reason.
const FOUNDING_POSITIONS := 2
const MAX_NAME_LENGTH := 60
const MAX_ABBREVIATION_LENGTH := 8


## Returns why the founding data is invalid, or an empty string.
static func check(defs: GameDefs, party_name: String, abbreviation: String, chair_name: String, positions: Dictionary) -> String:
	if party_name.strip_edges().is_empty() or party_name.length() > MAX_NAME_LENGTH:
		return "invalid party name"
	if abbreviation.strip_edges().is_empty() or abbreviation.length() > MAX_ABBREVIATION_LENGTH:
		return "invalid abbreviation"
	if chair_name.strip_edges().is_empty() or chair_name.length() > MAX_NAME_LENGTH:
		return "invalid chair name"
	if positions.size() != FOUNDING_POSITIONS:
		return "founding programme needs two positions"
	for topic_id: String in positions:
		var value: int = positions[topic_id]
		if not defs.topics.has(topic_id):
			return "unknown topic"
		if value == 0 or absi(value) > 2:
			return "founding positions must be for or against"
	return ""


## Founds the party. The founding programme is free; it costs neither action points nor credibility.
static func found(
	state: GameState, defs: GameDefs, party_name: String, abbreviation: String, chair_name: String, positions: Dictionary
) -> void:
	assert(check(defs, party_name, abbreviation, chair_name, positions).is_empty(), "Invalid founding data")
	var party := state.party
	party.name = party_name.strip_edges()
	party.abbreviation = abbreviation.strip_edges()
	PersonSystem.by_role(state, "chair").name = chair_name.strip_edges()
	for topic_id: String in positions:
		party.positions[topic_id] = positions[topic_id]
		party.position_age[topic_id] = 0
		state.topic_waiting.erase(topic_id)
	SimLog.add(state, "party_founded", {"name": party.name, "abbreviation": party.abbreviation, "positions": positions.duplicate()})
