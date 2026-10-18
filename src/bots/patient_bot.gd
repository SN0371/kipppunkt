class_name PatientBot
extends Bot
## Patient, moderate and consistent: takes moderate positions voters in the playable
## regions want, never changes them, builds anchoring and avoids radical actions.

## Moderate positions only.
const MAX_POSITION := 1
## Topics with a weaker average preference are left without position.
const MIN_PREFERENCE := 0.5
const TARGET_ANCHORING := 70.0
const CONGRESS_UNITY := 45.0
const COURT_SATISFACTION_MIN := 40.0
const DONATION_SATISFACTION := 60.0


## Returns the short name used on the command line and in reports.
func id() -> String:
	return "patient"


## Takes a moderate stand voters in the playable regions want; neutral where they are
## undecided or where a stand would contradict earlier positions. Keeps known positions.
func respond(state: GameState, defs: GameDefs, event: EventDef) -> Variant:
	if state.party.positions.has(event.topic):
		return null
	var wanted: float = preferences(defs, playable_regions(state, defs))[event.topic]
	var position := clampi(roundi(wanted), -MAX_POSITION, MAX_POSITION) if absf(wanted) >= MIN_PREFERENCE else 0
	return position if consistent(state, defs, event.topic, position) else 0


## Returns the orders for the current turn, most important first.
func orders(state: GameState, defs: GameDefs) -> Array[ActionOrder]:
	var result: Array[ActionOrder] = []
	var regions := playable_regions(state, defs)
	appoint_staff(state, result, func(p: PersonState) -> float: return p.competence + p.persuasion + p.loyalty)
	campaign(state, defs, result)
	if state.party.unity < CONGRESS_UNITY:
		result.append(ActionOrder.create("action.party_congress"))
	for donor_id: String in state.donors:
		var donor := state.donors[donor_id]
		if donor.active and donor.satisfaction >= DONATION_SATISFACTION:
			result.append(ActionOrder.create("action.accept_large_donation", donor_id))
		elif donor.active and donor.satisfaction >= COURT_SATISFACTION_MIN:
			result.append(ActionOrder.create("action.court_donor", donor_id))
	var region := weakest_region(state, defs)
	if state.regions[region].anchoring < TARGET_ANCHORING:
		result.append(ActionOrder.create("action.found_local_branch", region))
	result.append(ActionOrder.create("action.club_presence", region))
	result.append(ActionOrder.create("action.social_media_campaign"))
	result.append(ActionOrder.create("action.press_conference"))
	return result
