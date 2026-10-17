class_name CrisisSystem
extends RefCounted
## Crises with omens, duration and effects (rechenmodell.md section 11).

## Minimum turns between the end of a crisis and the next omen.
const COOLDOWN_TURNS := 8
## False alarms per real omen, so that 70 % of all omens come true.
const FALSE_ALARM_RATIO := 0.3 / 0.7
const OMEN_MIN_TURNS := 1
const OMEN_MAX_TURNS := 2


## Advances running crises, resolves due omens and may announce a new crisis.
## Called once at the start of a turn.
static func step(state: GameState, defs: GameDefs) -> void:
	_advance_running(state)
	_resolve_omen(state, defs)
	_maybe_announce(state, defs)


## Returns the factor applied to donor payments by all running crises.
static func donor_payment_factor(state: GameState, defs: GameDefs) -> float:
	var factor := 1.0
	for crisis in state.crises:
		factor *= defs.crises[crisis.crisis_id].donor_payment_factor
	return factor


## Returns the factor applied to member growth by all running crises.
static func member_growth_factor(state: GameState, defs: GameDefs) -> float:
	var factor := 1.0
	for crisis in state.crises:
		factor *= defs.crises[crisis.crisis_id].member_growth_factor
	return factor


## Starts a crisis immediately; used by omens and by scenarios or tests.
static func start(state: GameState, defs: GameDefs, crisis_id: String) -> void:
	var def := defs.crises[crisis_id]
	var crisis := CrisisState.new()
	crisis.crisis_id = crisis_id
	crisis.remaining_turns = state.rng.randi_range(def.min_duration, def.max_duration)
	state.crises.append(crisis)
	SimLog.add(state, "crisis_started", {"crisis": crisis_id, "duration": crisis.remaining_turns})


static func _advance_running(state: GameState) -> void:
	var running: Array[CrisisState] = []
	for crisis in state.crises:
		crisis.elapsed_turns += 1
		crisis.remaining_turns -= 1
		if crisis.remaining_turns > 0:
			running.append(crisis)
		else:
			state.last_crisis_end_turn = state.turn
			SimLog.add(state, "crisis_ended", {"crisis": crisis.crisis_id})
	state.crises = running


static func _resolve_omen(state: GameState, defs: GameDefs) -> void:
	if state.pending_crisis_id.is_empty():
		return
	state.pending_crisis_turns -= 1
	if state.pending_crisis_turns > 0:
		return
	if state.pending_crisis_real:
		start(state, defs, state.pending_crisis_id)
	else:
		SimLog.add(state, "crisis_false_alarm", {"crisis": state.pending_crisis_id})
	state.pending_crisis_id = ""
	state.pending_crisis_real = false


static func _maybe_announce(state: GameState, defs: GameDefs) -> void:
	if not state.crises.is_empty() or not state.pending_crisis_id.is_empty():
		return
	if state.turn - state.last_crisis_end_turn < COOLDOWN_TURNS or defs.crises.is_empty():
		return
	var probability := defs.params.value("crisis_probability")
	var roll := state.rng.randf()
	var real := roll < probability
	if not real and roll >= probability * (1.0 + FALSE_ALARM_RATIO):
		return
	var ids := defs.crises.keys()
	state.pending_crisis_id = ids[state.rng.randi_range(0, ids.size() - 1)]
	state.pending_crisis_turns = state.rng.randi_range(OMEN_MIN_TURNS, OMEN_MAX_TURNS)
	state.pending_crisis_real = real
	SimLog.add(state, "crisis_omen", {"crisis": state.pending_crisis_id, "turns": state.pending_crisis_turns})
