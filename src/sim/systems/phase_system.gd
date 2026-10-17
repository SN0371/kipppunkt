class_name PhaseSystem
extends RefCounted
## Phase transitions and end of the game in the MVP (rechenmodell.md section 12).

const BANKRUPTCY_TURNS := 2
const IRRELEVANCE_POLLING := 1.0
const IRRELEVANCE_TURNS := 8
## Irrelevance is only counted from this turn on, so a new party has time to grow.
const IRRELEVANCE_FROM_TURN := 8
const SPLIT_UNITY := 15.0
## Lands with municipal mandates needed for phase II.
const PHASE_TWO_LANDS := 2
## Lands with a state parliament group needed for phase III.
const PHASE_THREE_LANDS := 2


## Checks phase transitions and the end of the game (step 10 of the turn).
static func step(state: GameState, defs: GameDefs) -> void:
	_update_phase(state)
	_update_counters(state)
	var outcome := _outcome(state, defs)
	if not outcome.is_empty():
		state.outcome = outcome
		SimLog.add(state, "game_over", {"outcome": outcome})


static func _update_phase(state: GameState) -> void:
	var mandate_lands := 0
	var landtag_lands := 0
	for land: LandState in state.lands.values():
		if land.last_municipal_result >= ElectionSystem.MANDATE_THRESHOLD:
			mandate_lands += 1
		if land.in_landtag:
			landtag_lands += 1
	if state.phase == 1 and mandate_lands >= PHASE_TWO_LANDS:
		state.phase = 2
		SimLog.add(state, "phase", {"phase": 2})
	if state.phase == 2 and landtag_lands >= PHASE_THREE_LANDS:
		state.phase = 3
		SimLog.add(state, "phase", {"phase": 3})


static func _update_counters(state: GameState) -> void:
	state.negative_money_turns = state.negative_money_turns + 1 if state.party.money < 0.0 else 0
	var counts := state.turn >= IRRELEVANCE_FROM_TURN and state.latest_national_polling() < IRRELEVANCE_POLLING
	state.low_polling_turns = state.low_polling_turns + 1 if counts else 0


static func _outcome(state: GameState, defs: GameDefs) -> String:
	if state.party.in_bundestag:
		return "won"
	if state.negative_money_turns >= BANKRUPTCY_TURNS:
		return "bankrupt"
	if state.low_polling_turns >= IRRELEVANCE_TURNS:
		return "irrelevant"
	if state.party.unity < SPLIT_UNITY:
		return "split"
	if state.turn >= defs.scenarios[state.scenario_id].max_turns:
		return "timeout"
	return ""
