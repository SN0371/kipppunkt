class_name GameState
extends RefCounted
## The complete dynamic state of a game (rechenmodell.md section 1).
##
## Everything that changes during a game lives here, including the random number
## generator, so a saved state continues exactly as the original would have.

## Seed of the game; determines all random rolls together with the player's orders.
var game_seed: int = 0
## The only source of randomness in the simulation (prototyp-plan.md section 2).
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var scenario_id: String = ""
## Current turn (quarter), starting at 1.
var turn: int = 1
## Current phase (game-design.md section 6), starting at 1.
var phase: int = 1
## Democratic resilience (R), 0..100.
var resilience: float = 0.0
## Turn in which the last crisis ended; crises need a cooldown (rechenmodell.md 11).
var last_crisis_end_turn: int = 0
## Counter for unique person ids.
var next_person_id: int = 1
var party: PartyState = PartyState.new()
var lands: Dictionary[String, LandState] = {}
var regions: Dictionary[String, RegionState] = {}
var media: Dictionary[String, MediaState] = {}
var donors: Dictionary[String, DonorState] = {}
var persons: Array[PersonState] = []
var crises: Array[CrisisState] = []


## Serializes the state to plain JSON-compatible data.
## Seed and generator state are stored as strings because JSON numbers cannot hold 64-bit integers exactly.
func to_dict() -> Dictionary:
	return {
		"game_seed": str(game_seed),
		"rng_state": str(rng.state),
		"scenario_id": scenario_id,
		"turn": turn,
		"phase": phase,
		"resilience": resilience,
		"last_crisis_end_turn": last_crisis_end_turn,
		"next_person_id": next_person_id,
		"party": party.to_dict(),
		"lands": _map_to_dict(lands),
		"regions": _map_to_dict(regions),
		"media": _map_to_dict(media),
		"donors": _map_to_dict(donors),
		"persons": persons.map(func(p: PersonState) -> Dictionary: return p.to_dict()),
		"crises": crises.map(func(c: CrisisState) -> Dictionary: return c.to_dict()),
	}


## Restores a state from data written by to_dict(), recording type errors in the reader.
## The result is only usable if the reader reports no errors.
static func from_dict(d: Dictionary, reader: JsonReader) -> GameState:
	var ctx := "state"
	var state := GameState.new()
	state.game_seed = reader.read_int64_string(d, "game_seed", ctx)
	state.rng.seed = state.game_seed
	state.rng.state = reader.read_int64_string(d, "rng_state", ctx)
	state.scenario_id = reader.read_string(d, "scenario_id", ctx)
	state.turn = reader.read_int(d, "turn", ctx, 1)
	state.phase = reader.read_int(d, "phase", ctx, 1, 6)
	state.resilience = reader.read_float(d, "resilience", ctx, 0.0, 100.0)
	state.last_crisis_end_turn = reader.read_int(d, "last_crisis_end_turn", ctx)
	state.next_person_id = reader.read_int(d, "next_person_id", ctx, 1)
	state.party = PartyState.from_dict(reader.read_dict(d, "party", ctx), reader)
	var lands_raw := reader.read_dict(d, "lands", ctx)
	for id: String in lands_raw:
		state.lands[id] = LandState.from_dict(_entry(lands_raw, id, reader, "state.lands"), reader, "state.lands." + id)
	var regions_raw := reader.read_dict(d, "regions", ctx)
	for id: String in regions_raw:
		state.regions[id] = RegionState.from_dict(_entry(regions_raw, id, reader, "state.regions"), reader, "state.regions." + id)
	var media_raw := reader.read_dict(d, "media", ctx)
	for id: String in media_raw:
		state.media[id] = MediaState.from_dict(_entry(media_raw, id, reader, "state.media"), reader, "state.media." + id)
	var donors_raw := reader.read_dict(d, "donors", ctx)
	for id: String in donors_raw:
		state.donors[id] = DonorState.from_dict(_entry(donors_raw, id, reader, "state.donors"), reader, "state.donors." + id)
	var persons_raw := reader.read_array(d, "persons", ctx)
	for i in persons_raw.size():
		var person_ctx := "state.persons[%d]" % i
		if typeof(persons_raw[i]) != TYPE_DICTIONARY:
			reader.error(person_ctx, "must be an object")
			continue
		state.persons.append(PersonState.from_dict(persons_raw[i], reader, person_ctx))
	var crises_raw := reader.read_array(d, "crises", ctx)
	for i in crises_raw.size():
		var crisis_ctx := "state.crises[%d]" % i
		if typeof(crises_raw[i]) != TYPE_DICTIONARY:
			reader.error(crisis_ctx, "must be an object")
			continue
		state.crises.append(CrisisState.from_dict(crises_raw[i], reader, crisis_ctx))
	return state


## Checks that the state refers to exactly the entities of the given definitions.
## Protects against save games from other data versions.
func validate_against(defs: GameDefs, reader: JsonReader) -> void:
	if not defs.scenarios.has(scenario_id):
		reader.error("state", "unknown scenario '%s'" % scenario_id)
	GameDefs.check_same_ids(lands.keys(), defs.lands.keys(), "state.lands", reader)
	GameDefs.check_same_ids(regions.keys(), defs.regions.keys(), "state.regions", reader)
	GameDefs.check_same_ids(media.keys(), defs.media.keys(), "state.media", reader)
	GameDefs.check_same_ids(donors.keys(), defs.donors.keys(), "state.donors", reader)
	for topic_id: String in party.positions:
		if not defs.topics.has(topic_id):
			reader.error("state.party.positions", "unknown topic '%s'" % topic_id)
	for region_id: String in party.regional_messages:
		if not defs.regions.has(region_id):
			reader.error("state.party.regional_messages", "unknown region '%s'" % region_id)
	for crisis in crises:
		if not defs.crises.has(crisis.crisis_id):
			reader.error("state.crises", "unknown crisis '%s'" % crisis.crisis_id)


static func _map_to_dict(map: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for id: String in map:
		result[id] = map[id].to_dict()
	return result


static func _entry(raw: Dictionary, id: String, reader: JsonReader, ctx: String) -> Dictionary:
	if typeof(raw[id]) != TYPE_DICTIONARY:
		reader.error("%s.%s" % [ctx, id], "must be an object")
		return {}
	return raw[id]

