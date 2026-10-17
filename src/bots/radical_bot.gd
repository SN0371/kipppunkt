class_name RadicalBot
extends Bot
## Radical and fast: extreme positions, outrage, discrediting opponents and hidden
## funding. Ignores scrutiny and welcomes persuasive firebrands.

const MIN_PREFERENCE := 0.25
const POSITIONS_PER_TURN := 2
const DONATION_SATISFACTION := 60.0
const HIDDEN_FUNDING_SATISFACTION := 50.0


## Returns the short name used on the command line and in reports.
func id() -> String:
	return "radical"


## Returns the orders for the current turn, most important first.
func orders(state: GameState, defs: GameDefs) -> Array[ActionOrder]:
	var result: Array[ActionOrder] = []
	var regions := playable_regions(state, defs)
	appoint_staff(state, result, func(p: PersonState) -> float: return 2.0 * p.persuasion + p.competence)
	campaign(state, defs, result)
	var wanted := preferences(defs, regions)
	var topics := topics_by_importance(defs, regions)
	var new_positions := 0
	for topic_id in topics:
		if new_positions < POSITIONS_PER_TURN and not state.party.positions.has(topic_id) \
				and absf(wanted[topic_id]) >= MIN_PREFERENCE:
			result.append(ActionOrder.create("action.set_position", topic_id, {"value": 2 * int(signf(wanted[topic_id]))}))
			new_positions += 1
	for donor_id: String in state.donors:
		var donor := state.donors[donor_id]
		if donor.active and donor.satisfaction >= DONATION_SATISFACTION:
			result.append(ActionOrder.create("action.accept_large_donation", donor_id))
		elif donor.active and donor.satisfaction >= HIDDEN_FUNDING_SATISFACTION:
			result.append(ActionOrder.create("action.third_party_funding", donor_id))
	result.append(ActionOrder.create("action.outrage_wave", topics[0]))
	result.append(ActionOrder.create("action.discredit_opponents"))
	result.append(ActionOrder.create("action.win_influencer"))
	result.append(ActionOrder.create("action.found_local_branch", weakest_region(state, defs)))
	result.append(ActionOrder.create("action.social_media_campaign"))
	return result
