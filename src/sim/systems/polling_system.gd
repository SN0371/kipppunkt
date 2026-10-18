class_name PollingSystem
extends RefCounted
## Polling model: target value per land and inert movement (rechenmodell.md section 3).

const SALIENCE_MIN := 0.5
const SALIENCE_MAX := 3.0
## How strongly party loyalty slows polling movement (α_l).
const LOYALTY_DAMPING := 0.7
## Credibility factor at credibility 0 (f_C).
const CREDIBILITY_FLOOR := 0.5
## Leadership term multiplier if an ideologue leads (polarization, rechenmodell.md 10.2).
const POLARIZATION_FACTOR := 1.5
## Resilience above which an ideologue in the leadership costs votes.
const POLARIZATION_RESILIENCE := 60.0
## Rally-round-the-flag effect in the first turn of a crisis, in percentage points.
const RALLY_EFFECT := -1.0


## Values that are the same for all lands within one polling update.
class Context:
	var ideology: Vector2
	var salience: Dictionary[String, float]
	var tones: Dictionary[String, float]
	var attention: float


## Returns the salience of every topic (s_k): 1, multiplied by active crises, plus modifiers.
static func salience(state: GameState, defs: GameDefs) -> Dictionary[String, float]:
	var result: Dictionary[String, float] = {}
	for topic_id: String in defs.topics:
		var value := 1.0
		for crisis in state.crises:
			value *= defs.crises[crisis.crisis_id].salience.get(topic_id, 1.0)
		value = ModifierSystem.apply(state, "salience." + topic_id, value)
		result[topic_id] = clampf(value, SALIENCE_MIN, SALIENCE_MAX)
	return result


## Returns how well the party's positions fit a land's preferences (T_l), -1..+1
## (rechenmodell.md 3.1). Regional messages replace the federal position in their region.
## Only the given topics are considered; all topics if the list is empty.
static func topic_fit(
	defs: GameDefs, land: LandDef, party: PartyState, salience_by_topic: Dictionary[String, float],
	topics: PackedStringArray = PackedStringArray()
) -> float:
	var numerator := 0.0
	var denominator := 0.0
	for topic_id: String in defs.topics:
		if not topics.is_empty() and not topics.has(topic_id):
			continue
		var weight := salience_by_topic[topic_id] * land.topic_weights[topic_id]
		denominator += weight
		var position: Variant = effective_position(party, land, topic_id)
		if position != null:
			var agreement := 1.0 - absi(int(position) - land.topic_preferences[topic_id]) / 2.0
			numerator += weight * agreement
	return numerator / denominator if denominator > 0.0 else 0.0


## Returns the position voters in a land hear on a topic (p*_k): the regional message of
## the land's region if there is one, otherwise the federal position, or null without either.
static func effective_position(party: PartyState, land: LandDef, topic_id: String) -> Variant:
	var regional: Dictionary = party.regional_messages.get(land.region, {})
	return regional.get(topic_id, party.positions.get(topic_id))


## Returns the share of messages that arrive in a land (f_Reach), from the parameter
## reach_floor (no reach at all) to 1. Older lands rely more on classic media, younger ones
## on platforms (rechenmodell.md 3.2).
static func reach_factor(defs: GameDefs, land: LandDef, party: PartyState, classic_reach: float) -> float:
	var floor_share := defs.params.value("reach_floor")
	var age := land.age_index / 100.0
	var reach := (1.0 - age) * party.reach_platform + age * classic_reach
	return floor_share + (1.0 - floor_share) * reach / 100.0


## Returns the crisis term of the polling target (Krisenbonus_l, rechenmodell.md section 11).
## The party is in opposition in the MVP, so crises are an opportunity after the first turn.
static func crisis_bonus(
	state: GameState, defs: GameDefs, land: LandDef, salience_by_topic: Dictionary[String, float]
) -> float:
	var bonus := 0.0
	for crisis in state.crises:
		if crisis.elapsed_turns == 0:
			bonus += RALLY_EFFECT
		else:
			var crisis_topics := PackedStringArray(defs.crises[crisis.crisis_id].salience.keys())
			var fit := topic_fit(defs, land, state.party, salience_by_topic, crisis_topics)
			bonus += defs.params.value("crisis_bonus") * fit
	return bonus


## Returns the polling target of a land (Ziel_l, rechenmodell.md 3.4).
static func target(state: GameState, defs: GameDefs, land_id: String, ctx: Context) -> float:
	var params := defs.params
	var party := state.party
	var land := defs.lands[land_id]
	var land_state := state.lands[land_id]
	var f_reach := reach_factor(defs, land, party, land_state.classic_reach)
	var f_credibility := CREDIBILITY_FLOOR + party.credibility / 200.0
	var leaders := PersonSystem.leadership(state, land.region)
	var leadership: float = params.value("leadership_weight") * (leaders["persuasion"] - 50.0) / 50.0 * f_reach
	if leaders["ideologue"]:
		leadership *= POLARIZATION_FACTOR
	var support := params.value("topic_weight") * topic_fit(defs, land, party, ctx.salience) * f_reach * f_credibility \
		+ params.value("anchoring_weight") * state.regions[land.region].anchoring / 100.0 \
		+ leadership \
		+ crisis_bonus(state, defs, land, ctx.salience)
	var competition := RivalSystem.pressure(defs, land_id, ctx.ideology)
	# Mobilized non-voters are not contested by the established parties: no competition factor.
	# Like every message, mobilization only works as far as the party is heard (f_reach).
	var value := params.value("polling_base") \
		+ support * (1.0 - competition) * (1.0 + params.value("media_climate_effect") * land_state.media_climate) \
		+ RepresentationSystem.mobilization(defs, land, party, ctx.salience) * f_reach \
		- params.value("stigma_per_level") * party.vs_level * state.resilience / 100.0
	if leaders["ideologue"] and state.resilience > POLARIZATION_RESILIENCE:
		value -= params.value("polarization_penalty")
	value += ModifierSystem.total_add(state, "polling_target")
	value += ModifierSystem.total_add(state, "polling_target." + land_id)
	return value


## Returns the national polling value (U_Bund), weighted by population.
static func national(state: GameState, defs: GameDefs) -> float:
	var total := 0.0
	for land_id: String in defs.lands:
		total += defs.lands[land_id].population_share * state.lands[land_id].polling
	return total


## Builds the values shared by all lands for one polling update.
static func make_context(state: GameState, defs: GameDefs) -> Context:
	var ctx := Context.new()
	ctx.ideology = IdeologySystem.profile(state.party, defs)
	ctx.salience = salience(state, defs)
	ctx.tones = MediaSystem.tones(state, defs, ctx.ideology)
	ctx.attention = MediaSystem.attention(national(state, defs))
	return ctx


## Updates media reach and climate per land, moves polling towards the targets and advances
## the media houses (rechenmodell.md 3.5, 5.6). Records the national value in the history.
static func step(state: GameState, defs: GameDefs) -> void:
	var params := defs.params
	var ctx := make_context(state, defs)
	var national_climate := 0.0
	for land_id: String in defs.lands:
		var land := defs.lands[land_id]
		var land_state := state.lands[land_id]
		land_state.classic_reach = MediaSystem.classic_reach(state, defs, land_id, ctx.attention)
		land_state.media_climate = MediaSystem.climate(state, defs, land_id, ctx.tones)
		national_climate += land.population_share * land_state.media_climate
		land_state.representation_gap = RepresentationSystem.gap(defs, land, ctx.salience)
		land_state.turnout = RepresentationSystem.turnout(
			defs, land_state.representation_gap,
			RepresentationSystem.mobilization(defs, land, state.party, ctx.salience)
		)
	state.media_climate = clampf(national_climate, -1.0, 1.0)
	for land_id: String in defs.lands:
		var loyalty := defs.lands[land_id].party_loyalty / 100.0
		var alpha := params.value("polling_alpha") * (1.0 - LOYALTY_DAMPING * loyalty)
		var land_state := state.lands[land_id]
		var noise := state.rng.randfn(0.0, params.value("polling_noise") * (1.0 - loyalty))
		land_state.polling = clampf(
			SimMath.approach(land_state.polling, target(state, defs, land_id, ctx), alpha) + noise,
			0.0, params.value("polling_max")
		)
	MediaSystem.step(state, defs, ctx.ideology)
	state.national_polling_history.append(national(state, defs))
	while state.national_polling_history.size() > GameState.POLLING_HISTORY_LENGTH:
		state.national_polling_history.pop_front()
