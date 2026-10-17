class_name StateFactory
extends RefCounted
## Creates the initial game state for a scenario (rechenmodell.md section 13).


## Creates a new game state. The seed alone determines every random roll at game start.
static func create(defs: GameDefs, scenario_id: String, game_seed: int) -> GameState:
	assert(defs.is_valid(), "Definitions must be valid")
	assert(defs.scenarios.has(scenario_id), "Unknown scenario: %s" % scenario_id)
	var scenario: ScenarioDef = defs.scenarios[scenario_id]
	var state := GameState.new()
	state.game_seed = game_seed
	state.rng.seed = game_seed
	state.scenario_id = scenario_id
	state.resilience = scenario.resilience
	_init_party(state.party, scenario)
	for land_id: String in defs.lands:
		var land := LandState.new()
		land.polling = scenario.polling_default
		state.lands[land_id] = land
	for region_id: String in defs.regions:
		var region := RegionState.new()
		region.anchoring = scenario.anchoring.get(region_id, 0.0)
		state.regions[region_id] = region
	for media_id: String in defs.media:
		state.media[media_id] = _create_media(defs.media[media_id], scenario, state.rng)
	for donor_id: String in defs.donors:
		var donor := DonorState.new()
		donor.satisfaction = scenario.donor_satisfaction_default
		donor.max_payment = defs.donors[donor_id].max_payment
		state.donors[donor_id] = donor
	return state


static func _init_party(party: PartyState, scenario: ScenarioDef) -> void:
	var start := scenario.party_start
	party.money = start["money"]
	party.members = int(start["members"])
	party.credibility = start["credibility"]
	party.radicalism = start["radicalism"]
	party.scrutiny = start["scrutiny"]
	party.vs_level = int(start["vs_level"])
	party.unity = start["unity"]
	party.reach_platform = start["reach_platform"]
	party.reach_classic_bonus = start["reach_classic_bonus"]
	party.contradiction_risk = start["contradiction_risk"]
	party.intransparency = start["intransparency"]


static func _create_media(def: MediaDef, scenario: ScenarioDef, rng: RandomNumberGenerator) -> MediaState:
	var house := MediaState.new()
	house.reach = def.reach
	house.independence = def.independence
	house.credibility = MediaSystem.target_credibility(def.independence)
	if def.owner == "family":
		house.owner_ideology = _random_point_in_disc(scenario.media_owner_ideology_radius, rng)
	return house


## Returns a point uniformly distributed in a disc around the origin.
static func _random_point_in_disc(radius: float, rng: RandomNumberGenerator) -> Vector2:
	var angle := rng.randf() * TAU
	var distance := radius * sqrt(rng.randf())
	return Vector2.from_angle(angle) * distance
