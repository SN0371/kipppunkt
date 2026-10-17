class_name PressSystem
extends RefCounted
## Investigative press: contradictions, funding and undercover journalists (rechenmodell.md section 9).

const CONTRADICTION_BASE := 0.5
const CONTRADICTION_REACH_DIVISOR := 200.0
## Share of the contradiction risk lost as credibility when contradictions are exposed.
const CONTRADICTION_CREDIBILITY_SHARE := 1.0 / 3.0
const FINANCE_CREDIBILITY_LOSS := 10.0
const FINANCE_SCRUTINY_GAIN := 10.0
const JOURNALIST_MATERIAL_THRESHOLD := 100.0
const JOURNALIST_CREDIBILITY_LOSS := 15.0
const JOURNALIST_UNITY_LOSS := 10.0


## Returns the strength of the press (PS); a weaker democracy has a weaker press.
static func strength(state: GameState, defs: GameDefs) -> float:
	return state.resilience / 100.0 * defs.params.value("press_strength")


## Returns the chance per turn that contradicting regional messages are exposed.
static func contradiction_probability(state: GameState, defs: GameDefs) -> float:
	var party := state.party
	return strength(state, defs) * party.contradiction_risk / 100.0 \
		* (CONTRADICTION_BASE + party.reach_platform / CONTRADICTION_REACH_DIVISOR)


## Returns the chance per turn that hidden funding is exposed.
static func finance_probability(state: GameState, defs: GameDefs) -> float:
	return strength(state, defs) * state.party.intransparency / 100.0


## Rolls the three investigations of a turn in a fixed order (step 5 of the turn).
static func step(state: GameState, defs: GameDefs) -> void:
	var party := state.party
	if state.rng.randf() < contradiction_probability(state, defs):
		var loss := party.contradiction_risk * CONTRADICTION_CREDIBILITY_SHARE
		party.credibility = SimMath.clamp100(party.credibility - loss)
		party.contradiction_risk /= 2.0
		# The messages are public now; keeping them up would be pointless.
		party.regional_messages.clear()
		SimLog.add(state, "press_exposed_contradiction", {"credibility_loss": loss})
	if state.rng.randf() < finance_probability(state, defs):
		party.credibility = SimMath.clamp100(party.credibility - FINANCE_CREDIBILITY_LOSS)
		party.scrutiny = SimMath.clamp100(party.scrutiny + FINANCE_SCRUTINY_GAIN)
		party.intransparency = 0.0
		SimLog.add(state, "press_exposed_funding")
	for person in PersonSystem.staff(state):
		if person.agenda == "journalist" and person.material >= JOURNALIST_MATERIAL_THRESHOLD:
			party.credibility = SimMath.clamp100(party.credibility - JOURNALIST_CREDIBILITY_LOSS)
			party.unity = SimMath.clamp100(party.unity - JOURNALIST_UNITY_LOSS)
			state.persons.erase(person)
			SimLog.add(state, "press_exposed_insider", {"person": person.id})
