class_name Bot
extends RefCounted
## Base class of the strategy bots used for balancing (rechenmodell.md section 14).
##
## A bot turns the state into the orders of one turn, most important first. It may order
## more than the party can afford: the resolver rejects what no longer fits.
## Bots that roll dice use their own generator, so they never change the game's randomness.

## Staff functions in the order bots fill them.
const ROLES_BY_PRIORITY: PackedStringArray = [
	"general_secretary", "state_chair_south", "state_chair_north", "treasurer",
]
## Playable lands by population, used to choose where to campaign first.
const CAMPAIGN_PRIORITY: PackedStringArray = ["land.by", "land.bw", "land.ni", "land.sh"]

## Generator for the bot's own decisions.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Returns the short name used on the command line and in reports.
func id() -> String:
	return ""


## Prepares the bot for a new game.
func reset(game_seed: int) -> void:
	rng.seed = game_seed * 7919 + 13


## Returns the orders for the current turn, most important first.
func orders(_state: GameState, _defs: GameDefs) -> Array[ActionOrder]:
	return []


## Returns the founding programme: two topics with a position each. By default the two most
## important topics in the playable regions, in the direction voters there prefer.
func founding_programme(state: GameState, defs: GameDefs) -> Dictionary:
	var regions := playable_regions(state, defs)
	var wanted := preferences(defs, regions)
	var programme := {}
	for topic_id in topics_by_importance(defs, regions):
		if programme.size() < FoundingSystem.FOUNDING_POSITIONS and absf(wanted[topic_id]) >= 0.25:
			programme[topic_id] = founding_strength() * int(signf(wanted[topic_id]))
	return programme


## Returns how strongly the bot founds its party on its two topics (1 or 2).
func founding_strength() -> int:
	return 1


## Returns the response to an event: a position -2..+2, or null for silence (new topic) or
## keeping the position (known topic). By default the bot keeps known positions and stays silent.
func respond(_state: GameState, _defs: GameDefs, _event: EventDef) -> Variant:
	return null


## Founds the party with the bot's programme.
func found(state: GameState, defs: GameDefs) -> void:
	FoundingSystem.found(state, defs, "Bot " + id(), id().left(3).to_upper(), "Bot", founding_programme(state, defs))


## Plays one whole turn: answers a pending event, then gives the orders.
func play_turn(state: GameState, defs: GameDefs) -> void:
	TurnRunner.start_turn(state, defs)
	var event := EventSystem.pending(state, defs)
	if event != null:
		EventSystem.resolve(state, defs, respond(state, defs, event))
	TurnRunner.finish_turn(state, defs, orders(state, defs))


## Returns the population- and weight-averaged preference per topic in the given regions
## (-2..+2). Bots use it to decide which positions voters there want.
static func preferences(defs: GameDefs, regions: PackedStringArray) -> Dictionary[String, float]:
	var result: Dictionary[String, float] = {}
	for topic_id: String in defs.topics:
		var weighted := 0.0
		var weight := 0.0
		for land: LandDef in defs.lands.values():
			if regions.has(land.region):
				var w := land.population_share * land.topic_weights[topic_id]
				weighted += w * land.topic_preferences[topic_id]
				weight += w
		result[topic_id] = weighted / weight if weight > 0.0 else 0.0
	return result


## Returns true if taking the position would not add a contradiction (rechenmodell.md 5.7).
## Bots that plan their positions avoid obvious contradictions, as a thoughtful player would.
static func consistent(state: GameState, defs: GameDefs, topic_id: String, value: int) -> bool:
	var before := IdeologySystem.inconsistency(state.party, defs)
	var hypothetical := PartyState.new()
	hypothetical.positions = state.party.positions.duplicate()
	hypothetical.positions[topic_id] = value
	return IdeologySystem.inconsistency(hypothetical, defs) <= before


## Returns the regions the player may act in.
static func playable_regions(state: GameState, defs: GameDefs) -> PackedStringArray:
	return defs.scenarios[state.scenario_id].playable_regions


## Appends orders that fill vacant staff functions with the best candidates by the given score.
## Candidates whose agenda was revealed are skipped.
static func appoint_staff(state: GameState, orders: Array[ActionOrder], score: Callable) -> void:
	var taken: Array[String] = []
	for role in ROLES_BY_PRIORITY:
		if PersonSystem.by_role(state, role) != null:
			continue
		var best: PersonState = null
		for person in state.persons:
			if not person.role.is_empty() or person.agenda_revealed or taken.has(person.id):
				continue
			if best == null or score.call(person) > score.call(best):
				best = person
		if best == null:
			return
		taken.append(best.id)
		orders.append(ActionOrder.create("action.appoint", best.id, {"role": role}))


## Appends a campaign order for every playable land that votes this turn, largest first.
static func campaign(state: GameState, defs: GameDefs, orders: Array[ActionOrder]) -> void:
	for land_id in CAMPAIGN_PRIORITY:
		if ElectionSystem.land_votes(state, defs, land_id):
			orders.append(ActionOrder.create("action.campaign", land_id))


## Returns the playable region with the lowest anchoring.
static func weakest_region(state: GameState, defs: GameDefs) -> String:
	var weakest := ""
	for region_id in playable_regions(state, defs):
		if weakest.is_empty() or state.regions[region_id].anchoring < state.regions[weakest].anchoring:
			weakest = region_id
	return weakest


## Returns topic ids sorted by their importance in the given regions, most important first.
static func topics_by_importance(defs: GameDefs, regions: PackedStringArray) -> Array[String]:
	var importance: Dictionary[String, float] = {}
	for topic_id: String in defs.topics:
		var total := 0.0
		for land: LandDef in defs.lands.values():
			if regions.has(land.region):
				total += land.population_share * land.topic_weights[topic_id]
		importance[topic_id] = total
	var ids: Array[String] = []
	ids.assign(defs.topics.keys())
	ids.sort_custom(func(a: String, b: String) -> bool: return importance[a] > importance[b])
	return ids
