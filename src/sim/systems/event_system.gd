class_name EventSystem
extends RefCounted
## Events that force the party to take a stand (rechenmodell.md section 5.8).
##
## A topic the party has not yet addressed becomes more likely to come up every turn and comes
## up for sure after a maximum wait. Topics already addressed come up again now and then; then
## the party may rethink its position without action points, paying the full lock-in cost.

## Events start in the second turn, so the player can look around first.
const FIRST_EVENT_TURN := 2
## Turns the topic of an event stays more salient.
const SALIENCE_TURNS := 2


## Advances the waiting time of unaddressed topics and may raise an event (start of a turn).
static func step(state: GameState, defs: GameDefs) -> void:
	if not state.pending_event_id.is_empty():
		return
	for topic_id: String in defs.topics:
		if not state.party.positions.has(topic_id):
			state.topic_waiting[topic_id] = state.topic_waiting.get(topic_id, 0) + 1
	if state.turn < FIRST_EVENT_TURN:
		return
	var topic_id := _draw_topic(state, defs)
	if topic_id.is_empty():
		return
	var event_id := _draw_event(state, defs, topic_id)
	state.pending_event_id = event_id
	ModifierSystem.add(state, event_id, "salience." + topic_id, defs.params.value("event_salience_boost"), SALIENCE_TURNS)
	SimLog.add(state, "event", {"event": event_id, "topic": topic_id, "first": not state.party.positions.has(topic_id)})


## Returns the event waiting for a response, or null.
static func pending(state: GameState, defs: GameDefs) -> EventDef:
	return defs.events.get(state.pending_event_id)


## Returns the probability that an unaddressed topic comes up this turn.
static func first_event_probability(state: GameState, defs: GameDefs, topic_id: String) -> float:
	var params := defs.params
	var waiting: int = state.topic_waiting.get(topic_id, 0)
	if waiting >= int(params.value("event_max_wait")):
		return 1.0
	return minf(1.0, params.value("event_base_probability") + params.value("event_probability_growth") * waiting)


## Applies the party's response to the pending event. A value -2..+2 takes (or changes to) that
## position; null means staying silent on a new topic or keeping the position on a known one.
## A first stand is free; rethinking a known position costs credibility but no action points;
## silence on a new topic costs credibility and leaves the topic open.
static func resolve(state: GameState, defs: GameDefs, choice: Variant) -> void:
	var event := pending(state, defs)
	assert(event != null, "No pending event")
	var party := state.party
	var topic_id := event.topic
	var addressed := party.positions.has(topic_id)
	if choice == null:
		if addressed:
			SimLog.add(state, "event_position_kept", {"event": event.id, "topic": topic_id})
		else:
			var cost := defs.params.value("silence_credibility_cost")
			party.credibility = SimMath.clamp100(party.credibility - cost)
			state.topic_waiting[topic_id] = 0
			SimLog.add(state, "event_silence", {"event": event.id, "topic": topic_id, "credibility_cost": cost})
	elif addressed and int(choice) == party.positions[topic_id]:
		SimLog.add(state, "event_position_kept", {"event": event.id, "topic": topic_id})
	else:
		IdeologySystem.set_position(state, defs, topic_id, clampi(int(choice), -2, 2))
		state.topic_waiting.erase(topic_id)
	state.pending_event_id = ""


static func _draw_topic(state: GameState, defs: GameDefs) -> String:
	var chosen := ""
	var longest := -1
	for topic_id: String in defs.topics:
		if state.party.positions.has(topic_id) or _available(state, defs, topic_id).is_empty():
			continue
		if state.rng.randf() < first_event_probability(state, defs, topic_id):
			var waiting: int = state.topic_waiting.get(topic_id, 0)
			if waiting > longest:
				chosen = topic_id
				longest = waiting
	if not chosen.is_empty():
		return chosen
	for topic_id: String in defs.topics:
		if state.party.positions.has(topic_id) and not _available(state, defs, topic_id).is_empty() \
				and state.rng.randf() < defs.params.value("event_repeat_probability"):
			return topic_id
	return ""


static func _draw_event(state: GameState, defs: GameDefs, topic_id: String) -> String:
	var candidates := _available(state, defs, topic_id)
	var total := 0.0
	for event in candidates:
		total += event.weight
	var roll := state.rng.randf() * total
	for event in candidates:
		roll -= event.weight
		if roll < 0.0:
			return event.id
	return candidates.back().id


## Returns the events of a topic whose conditions hold now.
static func _available(state: GameState, defs: GameDefs, topic_id: String) -> Array[EventDef]:
	var result: Array[EventDef] = []
	for event: EventDef in defs.events.values():
		if event.topic != topic_id:
			continue
		if not event.crisis.is_empty() and not state.crises.any(func(c: CrisisState) -> bool: return c.crisis_id == event.crisis):
			continue
		result.append(event)
	return result
