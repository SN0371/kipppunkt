class_name TwoFacedBot
extends Bot
## Two-faced: tells every region what it wants to hear. Takes federal positions only where
## the regions agree and sends contradicting regional messages everywhere else.

const MIN_PREFERENCE := 0.25
const MESSAGES_PER_TURN := 2


## Returns the short name used on the command line and in reports.
func id() -> String:
	return "two_faced"


## Returns the orders for the current turn, most important first.
func orders(state: GameState, defs: GameDefs) -> Array[ActionOrder]:
	var result: Array[ActionOrder] = []
	var regions := playable_regions(state, defs)
	appoint_staff(state, result, func(p: PersonState) -> float: return p.competence + p.persuasion + p.loyalty)
	campaign(state, defs, result)
	var topics := topics_by_importance(defs, regions)
	var by_region: Dictionary[String, Dictionary] = {}
	for region_id in regions:
		by_region[region_id] = preferences(defs, PackedStringArray([region_id]))
	var messages := 0
	for topic_id in topics:
		for region_id in regions:
			var preference: float = by_region[region_id][topic_id]
			if messages >= MESSAGES_PER_TURN or absf(preference) < MIN_PREFERENCE:
				continue
			var promise := 2 * int(signf(preference))
			var current: Variant = state.party.regional_messages.get(region_id, {}).get(topic_id)
			if promise != state.party.positions.get(topic_id, 0) and current != promise:
				result.append(ActionOrder.create(
					"action.regional_message", region_id, {"topic": topic_id, "value": promise}
				))
				messages += 1
	for topic_id in topics:
		if state.party.positions.has(topic_id):
			continue
		var signs: Array[int] = []
		for region_id in regions:
			signs.append(int(signf(by_region[region_id][topic_id])))
		if signs.min() == signs.max() and signs[0] != 0:
			result.append(ActionOrder.create("action.set_position", topic_id, {"value": signs[0]}))
			break
	result.append(ActionOrder.create("action.found_local_branch", weakest_region(state, defs)))
	result.append(ActionOrder.create("action.social_media_campaign"))
	result.append(ActionOrder.create("action.press_conference"))
	return result
