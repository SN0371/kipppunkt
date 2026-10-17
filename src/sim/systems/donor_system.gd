class_name DonorSystem
extends RefCounted
## Donors: satisfaction, payments, withdrawal and return (rechenmodell.md section 5.4).

const SATISFACTION_RATE := 0.3
## Ideology distance at which a donor's satisfaction from ideology reaches 0.
const DISTANCE_SCALE := 200.0
## Satisfaction lost per topic on which party and donor stand on opposite sides.
const TOPIC_CONFLICT_PENALTY := 15.0
## Satisfaction from which a donor starts paying, and the range up to full payment.
const PAYMENT_THRESHOLD := 40.0
const PAYMENT_RANGE := 60.0
const WITHDRAWAL_THRESHOLD := 30.0
const WITHDRAWAL_TURNS := 2
const RETURN_DELAY_TURNS := 8
## Satisfaction a withdrawn donor needs to return after the delay.
const RETURN_THRESHOLD := 50.0
## Surveillance reaction per donor kind: [first level that matters, penalty per level from there].
## Stock companies react first, family businesses last, midsize companies in between.
const SURVEILLANCE_PENALTIES: Dictionary = {
	"stock": [1, 20.0],
	"midsize": [1, 15.0],
	"family": [2, 15.0],
}


## Returns the satisfaction penalty from the party's surveillance level for a donor kind.
static func surveillance_penalty(kind: String, vs_level: int) -> float:
	var rule: Array = SURVEILLANCE_PENALTIES[kind]
	var first_level: int = rule[0]
	if vs_level < first_level:
		return 0.0
	return float(rule[1]) * (vs_level - first_level + 1)


## Returns the number of topics on which party and donor take opposite sides.
static func topic_conflicts(def: DonorDef, party: PartyState) -> int:
	var count := 0
	for topic_id: String in def.topic_preferences:
		if party.positions.get(topic_id, 0) * def.topic_preferences[topic_id] < 0:
			count += 1
	return count


## Returns the satisfaction a donor converges to (Ziel_Z_u).
static func target_satisfaction(state: GameState, defs: GameDefs, donor_id: String, ideology: Vector2) -> float:
	var def := defs.donors[donor_id]
	var distance := minf(1.0, ideology.distance_to(def.ideology) / DISTANCE_SCALE)
	var value := 100.0 * (1.0 - distance) \
		- TOPIC_CONFLICT_PENALTY * topic_conflicts(def, state.party) \
		- surveillance_penalty(def.kind, state.party.vs_level)
	return ModifierSystem.apply(state, "donor_target." + donor_id, value)


## Returns the payment of a donor for this turn (Zahlung_u), in thousand euros.
static func payment(state: GameState, defs: GameDefs, donor_id: String) -> float:
	var donor := state.donors[donor_id]
	if not donor.active:
		return 0.0
	var willingness := maxf(0.0, (donor.satisfaction - PAYMENT_THRESHOLD) / PAYMENT_RANGE)
	var credibility_factor := 0.5 + state.party.credibility / 200.0
	return donor.max_payment * willingness * credibility_factor * CrisisSystem.donor_payment_factor(state, defs)


## Updates satisfaction, withdrawals and returns of all donors (step 7 of the turn).
static func step(state: GameState, defs: GameDefs, ideology: Vector2) -> void:
	for donor_id: String in defs.donors:
		var donor := state.donors[donor_id]
		var target := target_satisfaction(state, defs, donor_id, ideology)
		donor.satisfaction = SimMath.clamp100(SimMath.approach(donor.satisfaction, target, SATISFACTION_RATE))
		if donor.active:
			donor.low_turns = donor.low_turns + 1 if donor.satisfaction < WITHDRAWAL_THRESHOLD else 0
			if donor.low_turns >= WITHDRAWAL_TURNS:
				donor.active = false
				donor.low_turns = 0
				donor.return_turn = state.turn + RETURN_DELAY_TURNS
				SimLog.add(state, "donor_withdrew", {"donor": donor_id})
		elif state.turn >= donor.return_turn and donor.satisfaction >= RETURN_THRESHOLD:
			donor.active = true
			donor.max_payment /= 2.0
			SimLog.add(state, "donor_returned", {"donor": donor_id})
