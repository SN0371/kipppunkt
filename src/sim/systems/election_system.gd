class_name ElectionSystem
extends RefCounted
## Municipal, state and federal elections (rechenmodell.md section 7).

## Electoral threshold for state parliaments and the Bundestag, in percent.
const HURDLE := 5.0
## Municipal result from which the party holds municipal mandates (phase I -> II).
## The model has no threshold for municipal elections; about one seat needs about 1 %.
const MANDATE_THRESHOLD := 1.0
## Member growth after a municipal election.
const MUNICIPAL_MEMBER_BONUS := 0.05
## Classic media attention gained when entering a state parliament.
const LANDTAG_CLASSIC_BONUS := 10.0


## Returns the elections taking place in the current turn, in scenario order.
static func due(state: GameState, defs: GameDefs) -> Array[ElectionCycleDef]:
	var result: Array[ElectionCycleDef] = []
	for election in defs.scenarios[state.scenario_id].elections:
		if election.is_due(state.turn):
			result.append(election)
	return result


## Returns true if an election takes place this turn (campaign quarter).
static func is_campaign_turn(state: GameState, defs: GameDefs) -> bool:
	return not due(state, defs).is_empty()


## Returns true if the land votes this turn, including federal elections.
static func land_votes(state: GameState, defs: GameDefs, land_id: String) -> bool:
	for election in due(state, defs):
		if election.type == "federal" or election.land == land_id:
			return true
	return false


## Holds all elections due this turn (step 8 of the turn).
static func step(state: GameState, defs: GameDefs) -> void:
	for election in due(state, defs):
		match election.type:
			"municipal":
				_municipal(state, defs, election.land)
			"state":
				_state_election(state, defs, election.land)
			"federal":
				_federal(state, defs)


## Rolls the result of the party in a land (Ergebnis_l).
static func result(state: GameState, defs: GameDefs, land_id: String) -> float:
	var campaign := ModifierSystem.total_add(state, "election_bonus." + land_id)
	var noise := state.rng.randfn(0.0, defs.params.value("election_noise"))
	return maxf(0.0, state.lands[land_id].polling + campaign + noise)


static func _municipal(state: GameState, defs: GameDefs, land_id: String) -> void:
	var value := result(state, defs, land_id)
	var land := state.lands[land_id]
	land.last_municipal_result = value
	var region_id := defs.lands[land_id].region
	if defs.regions[region_id].has_municipal_level:
		var region := state.regions[region_id]
		region.anchoring = SimMath.clamp100(region.anchoring + defs.params.value("municipal_anchoring_gain") * value)
	state.party.members = roundi(state.party.members * (1.0 + MUNICIPAL_MEMBER_BONUS))
	SimLog.add(state, "election", {"type": "municipal", "land": land_id, "result": value})


static func _state_election(state: GameState, defs: GameDefs, land_id: String) -> void:
	var value := result(state, defs, land_id)
	var land := state.lands[land_id]
	var entered := value >= HURDLE and not land.in_landtag
	land.last_state_result = value
	land.in_landtag = value >= HURDLE
	if entered:
		state.party.reach_classic_bonus = SimMath.clamp100(state.party.reach_classic_bonus + LANDTAG_CLASSIC_BONUS)
	SimLog.add(state, "election", {"type": "state", "land": land_id, "result": value, "seats": land.in_landtag})


static func _federal(state: GameState, defs: GameDefs) -> void:
	var total := 0.0
	for land_id: String in defs.lands:
		total += defs.lands[land_id].population_share * result(state, defs, land_id)
	state.party.last_federal_result = total
	state.party.in_bundestag = total >= HURDLE
	SimLog.add(state, "election", {"type": "federal", "result": total, "seats": state.party.in_bundestag})
