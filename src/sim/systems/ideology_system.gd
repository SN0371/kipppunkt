class_name IdeologySystem
extends RefCounted
## Ideology profile, position changes and contradiction risk (rechenmodell.md 5.1–5.3).

## Scales the weighted position sum to the axis range -100..+100.
const PROFILE_SCALE := 50.0
## Donor preference strength that counts as "strong" for the lock-in (rechenmodell.md 5.2).
const STRONG_PREFERENCE := 2
## Turns after which the lock-in cost of a position has doubled.
const LOCK_IN_TURNS := 8.0
## Unity lost per step of a position change; the model only says "lowers unity".
const UNITY_COST_PER_STEP := 2.0


## Returns the ideology profile computed from the federal positions (rechenmodell.md 5.1).
static func profile(party: PartyState, defs: GameDefs) -> Vector2:
	var weighted := Vector2.ZERO
	var weight := 0.0
	for topic_id: String in party.positions:
		var vector: Vector2 = defs.topics[topic_id].ideology_vector
		weighted += vector * party.positions[topic_id]
		weight += vector.length()
	if weight == 0.0:
		return Vector2.ZERO
	return weighted * PROFILE_SCALE / weight


## Returns the credibility a position change would cost (rechenmodell.md 5.2).
## Taking a first position on a topic is free.
static func change_cost(state: GameState, defs: GameDefs, topic_id: String, new_value: int) -> float:
	var party := state.party
	if not party.positions.has(topic_id):
		return 0.0
	var delta := absi(new_value - party.positions[topic_id])
	var strong_donors := 0
	for donor_id: String in defs.donors:
		var preferences := defs.donors[donor_id].topic_preferences
		if state.donors[donor_id].active and absi(preferences.get(topic_id, 0)) >= STRONG_PREFERENCE:
			strong_donors += 1
	var age: int = party.position_age.get(topic_id, 0)
	return defs.params.value("position_change_cost") * delta \
		* (1.0 + age / LOCK_IN_TURNS) * (1.0 + strong_donors / 2.0)


## Sets the federal position on a topic, paying the lock-in cost for a change.
## Value 0 withdraws the position: the party no longer speaks about the topic.
static func set_position(state: GameState, defs: GameDefs, topic_id: String, value: int) -> void:
	var party := state.party
	var previous: Variant = party.positions.get(topic_id)
	var cost := change_cost(state, defs, topic_id, value)
	party.credibility = SimMath.clamp100(party.credibility - cost)
	if previous != null:
		party.unity = SimMath.clamp100(party.unity - UNITY_COST_PER_STEP * absi(value - int(previous)))
	if value == 0:
		party.positions.erase(topic_id)
		party.position_age.erase(topic_id)
	else:
		party.positions[topic_id] = value
		party.position_age[topic_id] = 0
	for region_id: String in party.regional_messages.keys():
		if party.regional_messages[region_id].get(topic_id) == value:
			_erase_message(party, region_id, topic_id)
	SimLog.add(state, "position_set", {
		"topic": topic_id, "value": value, "previous": previous, "credibility_cost": cost,
	})


## Returns the total strength of all contradictions in the party's federal positions
## (rechenmodell.md 5.7).
static func inconsistency(party: PartyState, defs: GameDefs) -> float:
	var total := 0.0
	for contradiction: ContradictionDef in defs.contradictions.values():
		total += contradiction.strength(party.positions)
	return total


## Returns the contradictions the party currently falls into, with their strength.
static func active_contradictions(party: PartyState, defs: GameDefs) -> Dictionary[String, float]:
	var result: Dictionary[String, float] = {}
	for contradiction: ContradictionDef in defs.contradictions.values():
		var strength := contradiction.strength(party.positions)
		if strength > 0.0:
			result[contradiction.id] = strength
	return result


## Sets a regional message that deviates from the federal position (rechenmodell.md 5.3).
## A message equal to the federal position is removed instead.
static func set_regional_message(state: GameState, region_id: String, topic_id: String, value: int) -> void:
	var party := state.party
	if value == party.positions.get(topic_id, 0):
		_erase_message(party, region_id, topic_id)
	else:
		if not party.regional_messages.has(region_id):
			party.regional_messages[region_id] = {}
		party.regional_messages[region_id][topic_id] = value
	SimLog.add(state, "regional_message_set", {"region": region_id, "topic": topic_id, "value": value})


## Returns the summed, salience-weighted deviation of all regional messages from the federal
## positions. Without a federal position the reference is 0, so contradicting messages in
## two regions count even if the party never took a federal position.
static func message_deviation(party: PartyState, salience: Dictionary[String, float]) -> float:
	var total := 0.0
	for region_id: String in party.regional_messages:
		var messages: Dictionary = party.regional_messages[region_id]
		for topic_id: String in messages:
			var reference: int = party.positions.get(topic_id, 0)
			total += absi(int(messages[topic_id]) - reference) * salience.get(topic_id, 1.0)
	return total


## Updates the contradiction risk for one turn (rechenmodell.md 5.3).
static func update_contradiction(state: GameState, defs: GameDefs, salience: Dictionary[String, float]) -> void:
	var party := state.party
	var growth := defs.params.value("contradiction_growth") * message_deviation(party, salience)
	party.contradiction_risk = SimMath.clamp100(
		party.contradiction_risk + growth - defs.params.value("contradiction_decay")
	)


## Increases the holding time of every federal position by one turn.
static func age_positions(party: PartyState) -> void:
	for topic_id: String in party.positions:
		party.position_age[topic_id] = party.position_age.get(topic_id, 0) + 1


static func _erase_message(party: PartyState, region_id: String, topic_id: String) -> void:
	if not party.regional_messages.has(region_id):
		return
	party.regional_messages[region_id].erase(topic_id)
	if party.regional_messages[region_id].is_empty():
		party.regional_messages.erase(region_id)
