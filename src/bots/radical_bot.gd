class_name RadicalBot
extends Bot
## Radical and fast: extreme positions, outrage, discrediting opponents and hidden
## funding. Ignores scrutiny and welcomes persuasive firebrands.

const MIN_PREFERENCE := 0.25
const DONATION_SATISFACTION := 60.0
const HIDDEN_FUNDING_SATISFACTION := 50.0


## Returns the short name used on the command line and in reports.
func id() -> String:
	return "radical"


## Founds the party on two extreme positions.
func founding_strength() -> int:
	return 2


## Takes the extreme stand voters lean towards, unless it contradicts earlier positions.
## Keeps known positions.
func respond(state: GameState, defs: GameDefs, event: EventDef) -> Variant:
	if state.party.positions.has(event.topic):
		return null
	var wanted: float = preferences(defs, playable_regions(state, defs))[event.topic]
	if absf(wanted) < MIN_PREFERENCE:
		return 0
	var position := 2 * int(signf(wanted))
	return position if consistent(state, defs, event.topic, position) else 0


## Returns the orders for the current turn, most important first.
func orders(state: GameState, defs: GameDefs) -> Array[ActionOrder]:
	var result: Array[ActionOrder] = []
	var regions := playable_regions(state, defs)
	appoint_staff(state, result, func(p: PersonState) -> float: return 2.0 * p.persuasion + p.competence)
	campaign(state, defs, result)
	var topics := topics_by_importance(defs, regions)
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
