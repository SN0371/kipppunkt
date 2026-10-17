class_name PersonSystem
extends RefCounted
## Persons: generation, hidden agendas and loyalty checks (rechenmodell.md section 10).

const ATTRIBUTE_MEAN := 50.0
const ATTRIBUTE_SPREAD := 15.0
const ATTRIBUTE_MIN := 5.0
const ATTRIBUTE_MAX := 95.0
## Bonus on matching attributes for persons with an agenda or a talent.
const BONUS := 15.0
const TALENT_PROBABILITY := 0.05
## Probability of each agenda; the informant probability grows with the surveillance level.
const AGENDA_PROBABILITIES: Dictionary = {"careerist": 0.10, "ideologue": 0.08, "journalist": 0.03}
const INFORMANT_BASE_PROBABILITY := 0.02
const INFORMANT_PROBABILITY_PER_LEVEL := 0.03
const AGENDA_BONUS_ATTRIBUTES: Dictionary = {
	"careerist": ["network", "competence"],
	"ideologue": ["persuasion"],
	"journalist": ["competence", "network"],
	"informant": ["competence", "network"],
}
## Attributes a talent may excel in; loyalty is never boosted.
const TALENT_ATTRIBUTES: PackedStringArray = ["persuasion", "network", "competence"]
## Party functions that add an action point when filled (rechenmodell.md section 6).
const STAFF_FUNCTIONS: PackedStringArray = [
	"general_secretary", "treasurer", "state_chair_south", "state_chair_north",
]
## State chair role leading each playable region in the MVP.
const REGION_CHAIRS: Dictionary = {
	"region.south": "state_chair_south",
	"region.north": "state_chair_north",
}
## New candidates per turn: base plus total anchoring divided by this value (rechenmodell.md 10.1).
const POOL_BASE := 2
const POOL_ANCHORING_DIVISOR := 25.0
## Ideologues push radicalism up and unity down every turn.
const IDEOLOGUE_RADICALISM_PER_TURN := 1.0
const IDEOLOGUE_UNITY_PER_TURN := 1.0
## Undercover journalists collect network / 10 material per turn.
const JOURNALIST_MATERIAL_DIVISOR := 10.0
## A well-connected careerist takes voters along when defecting.
const CAREERIST_DEFECTION_NETWORK := 70.0
const CAREERIST_DEFECTION_POLLING_LOSS := 0.5


## Generates a new person with rolled attributes and a possibly hidden agenda.
static func generate(state: GameState) -> PersonState:
	var rng := state.rng
	var person := PersonState.new()
	person.id = "person.%d" % state.next_person_id
	state.next_person_id += 1
	person.loyalty = _roll_attribute(rng)
	person.persuasion = _roll_attribute(rng)
	person.network = _roll_attribute(rng)
	person.competence = _roll_attribute(rng)
	person.agenda = _roll_agenda(state.party.vs_level, rng)
	if person.agenda != "none":
		for attribute: String in AGENDA_BONUS_ATTRIBUTES[person.agenda]:
			_boost(person, attribute)
	elif rng.randf() < TALENT_PROBABILITY:
		var first := rng.randi_range(0, TALENT_ATTRIBUTES.size() - 1)
		var second := (first + rng.randi_range(1, TALENT_ATTRIBUTES.size() - 1)) % TALENT_ATTRIBUTES.size()
		_boost(person, TALENT_ATTRIBUTES[first])
		_boost(person, TALENT_ATTRIBUTES[second])
	return person


## Creates the party chair: the player's own figure, always loyal and without a hidden agenda.
static func create_chair(state: GameState) -> PersonState:
	var chair := generate(state)
	chair.role = "chair"
	chair.agenda = "none"
	chair.loyalty = 100.0
	return chair


## Returns the person holding a role, or null if the role is vacant.
static func by_role(state: GameState, role: String) -> PersonState:
	for person in state.persons:
		if person.role == role:
			return person
	return null


## Returns the person with the given id, or null.
static func by_id(state: GameState, id: String) -> PersonState:
	for person in state.persons:
		if person.id == id:
			return person
	return null


## Returns all persons holding a party function, including the chair.
static func staff(state: GameState) -> Array[PersonState]:
	var result: Array[PersonState] = []
	for person in state.persons:
		if not person.role.is_empty():
			result.append(person)
	return result


## Returns the number of filled party functions that add action points.
static func filled_functions(state: GameState) -> int:
	var count := 0
	for person in state.persons:
		if STAFF_FUNCTIONS.has(person.role):
			count += 1
	return count


## Returns the persuasion of the leadership for a region (Ü_Führung, rechenmodell.md 3.4)
## and whether an ideologue is part of it (polarization, rechenmodell.md 10.2).
static func leadership(state: GameState, region_id: String) -> Dictionary:
	var leaders: Array[PersonState] = []
	var chair := by_role(state, "chair")
	if chair != null:
		leaders.append(chair)
	if REGION_CHAIRS.has(region_id):
		var state_chair := by_role(state, REGION_CHAIRS[region_id])
		if state_chair != null:
			leaders.append(state_chair)
	if leaders.is_empty():
		return {"persuasion": ATTRIBUTE_MEAN, "ideologue": false}
	var total := 0.0
	var ideologue := false
	for leader in leaders:
		total += leader.persuasion
		ideologue = ideologue or leader.agenda == "ideologue"
	return {"persuasion": total / leaders.size(), "ideologue": ideologue}


## Replaces the candidate pool with new candidates (start of each turn).
static func refresh_pool(state: GameState) -> void:
	state.persons = staff(state)
	var anchoring := 0.0
	for region: RegionState in state.regions.values():
		anchoring += region.anchoring
	var count := POOL_BASE + int(anchoring / POOL_ANCHORING_DIVISOR)
	for i in count:
		state.persons.append(generate(state))


## Rolls a loyalty check (rechenmodell.md 10.3). Returns true if the person stays loyal.
static func loyalty_check(state: GameState, person: PersonState) -> bool:
	var probability := person.loyalty / 100.0 * (0.5 + state.party.unity / 200.0)
	return state.rng.randf() < probability


## Applies the ongoing effects of hidden agendas on the staff (rechenmodell.md 10.2).
## Called once per turn after the actions.
static func turn_effects(state: GameState, defs: GameDefs) -> void:
	var party := state.party
	var falling := _national_polling_fell_twice(state)
	for person in staff(state):
		match person.agenda:
			"ideologue":
				party.radicalism = SimMath.clamp100(party.radicalism + IDEOLOGUE_RADICALISM_PER_TURN)
				party.unity = SimMath.clamp100(party.unity - IDEOLOGUE_UNITY_PER_TURN)
			"journalist":
				person.material += person.network / JOURNALIST_MATERIAL_DIVISOR
			"careerist":
				if falling and not loyalty_check(state, person):
					_careerist_leaves(state, defs, person)


static func _national_polling_fell_twice(state: GameState) -> bool:
	var history := state.national_polling_history
	return history.size() >= 3 and history[-1] < history[-2] and history[-2] < history[-3]


## Removes a careerist who jumps ship. A well-connected one costs polling in the region
## the person led, or everywhere for a national function.
static func _careerist_leaves(state: GameState, defs: GameDefs, person: PersonState) -> void:
	state.persons.erase(person)
	var defects := person.network > CAREERIST_DEFECTION_NETWORK
	if defects:
		var region_id := ""
		for id: String in REGION_CHAIRS:
			if REGION_CHAIRS[id] == person.role:
				region_id = id
		for land_id: String in defs.lands:
			if region_id.is_empty() or defs.lands[land_id].region == region_id:
				var land := state.lands[land_id]
				land.polling = maxf(0.0, land.polling - CAREERIST_DEFECTION_POLLING_LOSS)
	SimLog.add(state, "person_left", {"person": person.id, "role": person.role, "agenda": "careerist", "defected": defects})


static func _roll_attribute(rng: RandomNumberGenerator) -> float:
	return clampf(rng.randfn(ATTRIBUTE_MEAN, ATTRIBUTE_SPREAD), ATTRIBUTE_MIN, ATTRIBUTE_MAX)


static func _roll_agenda(vs_level: int, rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	var threshold := 0.0
	for agenda: String in AGENDA_PROBABILITIES:
		threshold += AGENDA_PROBABILITIES[agenda]
		if roll < threshold:
			return agenda
	threshold += INFORMANT_BASE_PROBABILITY + INFORMANT_PROBABILITY_PER_LEVEL * vs_level
	if roll < threshold:
		return "informant"
	return "none"


static func _boost(person: PersonState, attribute: String) -> void:
	person.set(attribute, minf(100.0, person.get(attribute) + BONUS))
