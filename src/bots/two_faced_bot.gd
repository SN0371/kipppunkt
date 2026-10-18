class_name TwoFacedBot
extends Bot
## Two-faced: tells every region what it wants to hear. Takes federal positions only where
## the regions agree and sends contradicting regional messages everywhere else.

const MIN_PREFERENCE := 0.25
const MESSAGES_PER_TURN := 2


## Returns the short name used on the command line and in reports.
func id() -> String:
	return "two_faced"


## Founds the party on two topics where the playable regions agree.
func founding_programme(state: GameState, defs: GameDefs) -> Dictionary:
	var programme := {}
	for topic_id in topics_by_importance(defs, playable_regions(state, defs)):
		var sign := _shared_sign(state, defs, topic_id)
		if programme.size() < FoundingSystem.FOUNDING_POSITIONS and sign != 0:
			programme[topic_id] = sign
	return programme


## Stays neutral at federal level where the regions disagree, so every region can be promised
## what it wants; takes the shared direction where they agree.
func respond(state: GameState, defs: GameDefs, event: EventDef) -> Variant:
	if state.party.positions.has(event.topic):
		return null
	var sign := _shared_sign(state, defs, event.topic)
	return sign if consistent(state, defs, event.topic, sign) else 0


## Returns the orders for the current turn, most important first.
func orders(state: GameState, defs: GameDefs) -> Array[ActionOrder]:
	var result: Array[ActionOrder] = []
	var regions := playable_regions(state, defs)
	appoint_staff(state, result, func(p: PersonState) -> float: return p.competence + p.persuasion + p.loyalty)
	campaign(state, defs, result)
	var messages := 0
	for topic_id in topics_by_importance(defs, regions):
		if not state.party.positions.has(topic_id):
			continue
		for region_id in regions:
			var preference: float = preferences(defs, PackedStringArray([region_id]))[topic_id]
			if messages >= MESSAGES_PER_TURN or absf(preference) < MIN_PREFERENCE:
				continue
			var promise := 2 * int(signf(preference))
			var current: Variant = state.party.regional_messages.get(region_id, {}).get(topic_id)
			if promise != state.party.positions[topic_id] and current != promise:
				result.append(ActionOrder.create(
					"action.regional_message", region_id, {"topic": topic_id, "value": promise}
				))
				messages += 1
	result.append(ActionOrder.create("action.found_local_branch", weakest_region(state, defs)))
	result.append(ActionOrder.create("action.social_media_campaign"))
	result.append(ActionOrder.create("action.press_conference"))
	return result


## Returns the direction all playable regions share on a topic, or 0 if they disagree.
func _shared_sign(state: GameState, defs: GameDefs, topic_id: String) -> int:
	var signs: Array[int] = []
	for region_id in playable_regions(state, defs):
		signs.append(int(signf(preferences(defs, PackedStringArray([region_id]))[topic_id])))
	return signs[0] if signs.min() == signs.max() else 0
