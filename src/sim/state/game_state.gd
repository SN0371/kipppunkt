class_name GameState
extends RefCounted
## The complete dynamic state of a game (rechenmodell.md section 1).
##
## Everything that changes during a game lives here, including the random number
## generator, so a saved state continues exactly as the original would have.

## Possible game outcomes; empty while the game is running (rechenmodell.md section 12).
const OUTCOMES: PackedStringArray = ["", "won", "bankrupt", "irrelevant", "split", "timeout"]
## Number of national polling values kept for trend checks.
const POLLING_HISTORY_LENGTH := 4

## Seed of the game; determines all random rolls together with the player's orders.
var game_seed: int = 0
## The only source of randomness in the simulation (prototyp-plan.md section 2).
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var scenario_id: String = ""
## Current turn (quarter), starting at 1.
var turn: int = 1
## Current phase (game-design.md section 6), starting at 1.
var phase: int = 1
## Result of the game; empty while it is running.
var outcome: String = ""
## True between start_turn() and finish_turn(): the turn waits for the player's orders.
var awaiting_orders: bool = false
## Democratic resilience (R), 0..100.
var resilience: float = 0.0
## National media climate towards the party (MK_Bund), -1..+1, from the last polling update.
var media_climate: float = 0.0
## Last national polling values, oldest first.
var national_polling_history: Array[float] = []
## Consecutive turns with negative money (bankruptcy check).
var negative_money_turns: int = 0
## Consecutive turns with national polling below 1 % (irrelevance check).
var low_polling_turns: int = 0
## Turn in which the last crisis ended; crises need a cooldown (rechenmodell.md 11).
var last_crisis_end_turn: int = 0
## Announced crisis (omen); empty if none is announced.
var pending_crisis_id: String = ""
## Turns until the announced crisis would start.
var pending_crisis_turns: int = 0
## False for a false alarm: the announced crisis will not come.
var pending_crisis_real: bool = false
## Event waiting for the party's response before the turn can be planned; empty if none.
var pending_event_id: String = ""
## Turns each topic has waited for its first event since the game started (rechenmodell.md 5.8).
var topic_waiting: Dictionary[String, int] = {}
## Counter for unique person ids.
var next_person_id: int = 1
var party: PartyState = PartyState.new()
var lands: Dictionary[String, LandState] = {}
var regions: Dictionary[String, RegionState] = {}
var media: Dictionary[String, MediaState] = {}
var donors: Dictionary[String, DonorState] = {}
var persons: Array[PersonState] = []
var crises: Array[CrisisState] = []
var modifiers: Array[ModifierState] = []
## Protocol entries {"turn", "kind", "data"}, see SimLog.
var log_entries: Array[Dictionary] = []


## Returns true once the game has an outcome.
func is_over() -> bool:
	return not outcome.is_empty()


## Returns the latest national polling value, or 0 before the first polling update.
func latest_national_polling() -> float:
	return national_polling_history.back() if not national_polling_history.is_empty() else 0.0


## Serializes the state to plain JSON-compatible data.
## Seed and generator state are stored as strings because JSON numbers cannot hold 64-bit integers exactly.
func to_dict() -> Dictionary:
	return {
		"game_seed": str(game_seed),
		"rng_state": str(rng.state),
		"scenario_id": scenario_id,
		"turn": turn,
		"phase": phase,
		"outcome": outcome,
		"awaiting_orders": awaiting_orders,
		"resilience": resilience,
		"media_climate": media_climate,
		"national_polling_history": national_polling_history.duplicate(),
		"negative_money_turns": negative_money_turns,
		"low_polling_turns": low_polling_turns,
		"last_crisis_end_turn": last_crisis_end_turn,
		"pending_crisis_id": pending_crisis_id,
		"pending_crisis_turns": pending_crisis_turns,
		"pending_crisis_real": pending_crisis_real,
		"pending_event_id": pending_event_id,
		"topic_waiting": topic_waiting.duplicate(),
		"next_person_id": next_person_id,
		"party": party.to_dict(),
		"lands": _map_to_dict(lands),
		"regions": _map_to_dict(regions),
		"media": _map_to_dict(media),
		"donors": _map_to_dict(donors),
		"persons": persons.map(func(p: PersonState) -> Dictionary: return p.to_dict()),
		"crises": crises.map(func(c: CrisisState) -> Dictionary: return c.to_dict()),
		"modifiers": modifiers.map(func(m: ModifierState) -> Dictionary: return m.to_dict()),
		"log_entries": log_entries.duplicate(true),
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
	state.outcome = reader.read_enum(d, "outcome", ctx, OUTCOMES)
	state.awaiting_orders = reader.read_bool(d, "awaiting_orders", ctx)
	state.resilience = reader.read_float(d, "resilience", ctx, 0.0, 100.0)
	state.media_climate = reader.read_float(d, "media_climate", ctx, -1.0, 1.0)
	var history := reader.read_array(d, "national_polling_history", ctx)
	for i in history.size():
		state.national_polling_history.append(
			reader.check_float(history[i], "%s.national_polling_history[%d]" % [ctx, i], 0.0, 100.0)
		)
	state.negative_money_turns = reader.read_int(d, "negative_money_turns", ctx, 0)
	state.low_polling_turns = reader.read_int(d, "low_polling_turns", ctx, 0)
	state.last_crisis_end_turn = reader.read_int(d, "last_crisis_end_turn", ctx)
	state.pending_crisis_id = reader.read_string(d, "pending_crisis_id", ctx)
	state.pending_crisis_turns = reader.read_int(d, "pending_crisis_turns", ctx, 0)
	state.pending_crisis_real = reader.read_bool(d, "pending_crisis_real", ctx)
	state.pending_event_id = reader.read_string(d, "pending_event_id", ctx)
	state.topic_waiting = reader.read_int_map(d, "topic_waiting", ctx, 0, 1000000)
	state.next_person_id = reader.read_int(d, "next_person_id", ctx, 1)
	state.party = PartyState.from_dict(reader.read_dict(d, "party", ctx), reader)
	var lands_raw := reader.read_dict(d, "lands", ctx)
	for id: String in lands_raw:
		var land_ctx := "state.lands." + id
		state.lands[id] = LandState.from_dict(_entry(lands_raw, id, reader, land_ctx), reader, land_ctx)
	var regions_raw := reader.read_dict(d, "regions", ctx)
	for id: String in regions_raw:
		var region_ctx := "state.regions." + id
		state.regions[id] = RegionState.from_dict(_entry(regions_raw, id, reader, region_ctx), reader, region_ctx)
	var media_raw := reader.read_dict(d, "media", ctx)
	for id: String in media_raw:
		var media_ctx := "state.media." + id
		state.media[id] = MediaState.from_dict(_entry(media_raw, id, reader, media_ctx), reader, media_ctx)
	var donors_raw := reader.read_dict(d, "donors", ctx)
	for id: String in donors_raw:
		var donor_ctx := "state.donors." + id
		state.donors[id] = DonorState.from_dict(_entry(donors_raw, id, reader, donor_ctx), reader, donor_ctx)
	for item in _objects(d, "persons", reader):
		state.persons.append(PersonState.from_dict(item["value"], reader, item["ctx"]))
	for item in _objects(d, "crises", reader):
		state.crises.append(CrisisState.from_dict(item["value"], reader, item["ctx"]))
	for item in _objects(d, "modifiers", reader):
		state.modifiers.append(ModifierState.from_dict(item["value"], reader, item["ctx"]))
	for item in _objects(d, "log_entries", reader):
		var entry: Dictionary = item["value"]
		reader.read_int(entry, "turn", item["ctx"], 1)
		reader.read_string(entry, "kind", item["ctx"])
		reader.read_dict(entry, "data", item["ctx"])
		state.log_entries.append(entry)
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
	if not pending_crisis_id.is_empty() and not defs.crises.has(pending_crisis_id):
		reader.error("state", "unknown pending crisis '%s'" % pending_crisis_id)
	if not pending_event_id.is_empty() and not defs.events.has(pending_event_id):
		reader.error("state", "unknown pending event '%s'" % pending_event_id)
	for topic_id: String in topic_waiting:
		if not defs.topics.has(topic_id):
			reader.error("state.topic_waiting", "unknown topic '%s'" % topic_id)


static func _map_to_dict(map: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for id: String in map:
		result[id] = map[id].to_dict()
	return result


static func _entry(raw: Dictionary, id: String, reader: JsonReader, ctx: String) -> Dictionary:
	if typeof(raw[id]) != TYPE_DICTIONARY:
		reader.error(ctx, "must be an object")
		return {}
	return raw[id]


## Returns the objects of an array field as {"value", "ctx"} pairs, recording errors for non-objects.
static func _objects(d: Dictionary, key: String, reader: JsonReader) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var items := reader.read_array(d, key, "state")
	for i in items.size():
		var ctx := "state.%s[%d]" % [key, i]
		if typeof(items[i]) != TYPE_DICTIONARY:
			reader.error(ctx, "must be an object")
		else:
			result.append({"value": items[i], "ctx": ctx})
	return result
