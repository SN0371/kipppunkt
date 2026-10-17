class_name SurveillanceSystem
extends RefCounted
## Scrutiny and the escalation levels of domestic intelligence (rechenmodell.md section 8).

## Scrutiny thresholds of the levels 1 (case to check), 2 (suspected), 3 (confirmed extremist).
const THRESHOLDS: Array[float] = [35.0, 55.0, 75.0]
## Consecutive turns above the threshold needed before a level can rise.
const REQUIRED_TURNS: Array[int] = [2, 3, 4]
## Authorities do not act mechanically: chance per turn once the condition holds.
const ESCALATION_PROBABILITY := 0.6
const DOWNGRADE_MARGIN := 15.0
const DOWNGRADE_TURNS := 6
## Each informant on the staff lowers all thresholds by this amount.
const INFORMANT_THRESHOLD_REDUCTION := 5.0
const SCRUTINY_RATE := 0.25
## From this level on, members in public service leave when the level is reached.
const MEMBER_LOSS_FROM_LEVEL := 2
const MEMBER_LOSS_SHARE := 0.03


## Returns the scrutiny threshold of a level (1..3), lowered by informants on the staff.
static func threshold(state: GameState, level: int) -> float:
	var informants := 0
	for person in PersonSystem.staff(state):
		if person.agenda == "informant":
			informants += 1
	return THRESHOLDS[level - 1] - INFORMANT_THRESHOLD_REDUCTION * informants


## Returns the scrutiny the party converges to (Ziel_B): larger parties are watched more closely.
static func target_scrutiny(state: GameState, defs: GameDefs) -> float:
	var national := PollingSystem.national(state, defs)
	var value := state.party.radicalism * (0.6 + national / 20.0) * state.resilience / 100.0
	return ModifierSystem.apply(state, "scrutiny_target", value)


## Updates scrutiny and the surveillance level (step 5 of the turn).
static func step(state: GameState, defs: GameDefs) -> void:
	var party := state.party
	party.scrutiny = SimMath.clamp100(SimMath.approach(party.scrutiny, target_scrutiny(state, defs), SCRUTINY_RATE))
	if party.vs_level < THRESHOLDS.size():
		var next_level := party.vs_level + 1
		party.vs_up_turns = party.vs_up_turns + 1 if party.scrutiny > threshold(state, next_level) else 0
		if party.vs_up_turns >= REQUIRED_TURNS[next_level - 1] and state.rng.randf() < ESCALATION_PROBABILITY:
			_set_level(state, next_level)
			return
	if party.vs_level > 0:
		var far_below := party.scrutiny < threshold(state, party.vs_level) - DOWNGRADE_MARGIN
		party.vs_down_turns = party.vs_down_turns + 1 if far_below else 0
		if party.vs_down_turns >= DOWNGRADE_TURNS:
			_set_level(state, party.vs_level - 1)


static func _set_level(state: GameState, level: int) -> void:
	var party := state.party
	var raised := level > party.vs_level
	party.vs_level = level
	party.vs_up_turns = 0
	party.vs_down_turns = 0
	if raised and level >= MEMBER_LOSS_FROM_LEVEL:
		party.members = roundi(party.members * (1.0 - MEMBER_LOSS_SHARE))
	SimLog.add(state, "surveillance_level", {"level": level, "raised": raised})
