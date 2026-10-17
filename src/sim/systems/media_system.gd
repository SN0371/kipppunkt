class_name MediaSystem
extends RefCounted
## Media houses: reach, credibility and tone towards the party (rechenmodell.md section 5.6).

## Credibility a house tends towards at independence 0.
const CREDIBILITY_FLOOR := 20.0
## Credibility gained per point of newsroom independence.
const CREDIBILITY_PER_INDEPENDENCE := 0.7
## Ideology distance at which an owner's sympathy turns from positive to negative.
const OWNER_SYMPATHY_RANGE := 50.0
## Newsroom judgement of a moderate, average party.
const NEWSROOM_BASE := 0.3
const NEWSROOM_RADICALISM_DIVISOR := 80.0
const NEWSROOM_PENALTY_PER_VS_LEVEL := 0.25
## National polling in percent at which the party gets full media attention.
const FULL_ATTENTION_POLLING := 10.0
## Rate at which reach and credibility approach their targets per turn.
const DYNAMICS_RATE := 0.1
## Difference between owner and newsroom judgement that can trigger a conflict.
const CONFLICT_THRESHOLD := 1.0
const CONFLICT_PROBABILITY := 0.2
const OWNER_WIN_INDEPENDENCE_LOSS := 10.0
const NEWSROOM_WIN_INDEPENDENCE_GAIN := 5.0
const RESIGNATION_PROBABILITY := 0.3
const RESIGNATION_CREDIBILITY_LOSS := 10.0
const CONFLICT_RESILIENCE_LOSS := 0.5
const INHERITANCE_PROBABILITY := 0.01
## Share of politics in the supervisory boards of public broadcasting (at most one third).
const BOARDS_POLITICS_SHARE := 1.0 / 3.0


## Returns the credibility a house converges to for a given newsroom independence (Ziel_Glaub_m).
static func target_credibility(independence: float) -> float:
	return CREDIBILITY_FLOOR + CREDIBILITY_PER_INDEPENDENCE * independence


## Returns the reach of a house without sensationalism (Grundreichweite_m).
static func base_reach(defs: GameDefs, def: MediaDef) -> float:
	return def.reach - _sensationalism(defs, def.independence)


## Returns the reach a house converges to for its current independence (Ziel_Reach_m).
static func target_reach(defs: GameDefs, def: MediaDef, house: MediaState) -> float:
	return base_reach(defs, def) + _sensationalism(defs, house.independence)


## Returns the ideology of the supervisory boards of public broadcasting (I_Gremien).
## Politics is represented by the rival parties weighted by national strength; society sits at the centre.
static func board_ideology(defs: GameDefs) -> Vector2:
	var weighted := Vector2.ZERO
	var total := 0.0
	for rival: RivalPartyDef in defs.rivals.values():
		var strength := RivalSystem.national_strength(defs, rival)
		weighted += rival.ideology * strength
		total += strength
	var politics := weighted / total if total > 0.0 else Vector2.ZERO
	return politics * BOARDS_POLITICS_SHARE


## Returns the owner's (or boards') sympathy for the party (Eigentümer_m), -1..+1.
static func owner_sympathy(defs: GameDefs, def: MediaDef, house: MediaState, ideology: Vector2) -> float:
	var owner_position := board_ideology(defs) if def.owner == "boards" else house.owner_ideology
	return clampf(1.0 - ideology.distance_to(owner_position) / OWNER_SYMPATHY_RANGE, -1.0, 1.0)


## Returns the journalistic judgement of the party (Redaktion_m), -1..+1.
static func newsroom_judgement(party: PartyState) -> float:
	return clampf(
		NEWSROOM_BASE + (party.credibility - 50.0) / 100.0
			- party.radicalism / NEWSROOM_RADICALISM_DIVISOR
			- NEWSROOM_PENALTY_PER_VS_LEVEL * party.vs_level,
		-1.0, 1.0
	)


## Returns the tone of every house towards the party (Ton_m), keyed by media id.
static func tones(state: GameState, defs: GameDefs, ideology: Vector2) -> Dictionary[String, float]:
	var result: Dictionary[String, float] = {}
	var newsroom := newsroom_judgement(state.party)
	for media_id: String in defs.media:
		var house := state.media[media_id]
		var independence := house.independence / 100.0
		var owner := owner_sympathy(defs, defs.media[media_id], house, ideology)
		result[media_id] = (1.0 - independence) * owner + independence * newsroom
	return result


## Returns how much attention media pay to the party (Aufm), 0..1.
static func attention(national_polling: float) -> float:
	return minf(1.0, national_polling / FULL_ATTENTION_POLLING)


## Returns true if a house is read in a land.
static func reaches_land(defs: GameDefs, def: MediaDef, land_id: String) -> bool:
	return def.area == GameDefs.NATIONAL or def.area == defs.lands[land_id].region


## Returns the party's reach in classic media in a land (RK_l), 0..100.
static func classic_reach(state: GameState, defs: GameDefs, land_id: String, attention_share: float) -> float:
	var total := 0.0
	for media_id: String in defs.media:
		if reaches_land(defs, defs.media[media_id], land_id):
			total += state.media[media_id].reach * attention_share
	return minf(100.0, total + state.party.reach_classic_bonus)


## Returns the media climate towards the party in a land (MK_l), -1..+1.
## Credible houses with large reach weigh most.
static func climate(state: GameState, defs: GameDefs, land_id: String, tone_by_media: Dictionary[String, float]) -> float:
	var weighted := 0.0
	var weight := 0.0
	for media_id: String in defs.media:
		if reaches_land(defs, defs.media[media_id], land_id):
			var house := state.media[media_id]
			var influence := house.reach * house.credibility
			weighted += influence * tone_by_media[media_id]
			weight += influence
	return weighted / weight if weight > 0.0 else 0.0


## Advances every house by one turn: reach and credibility dynamics, conflicts between
## owner and newsroom, and changes of ownership (rechenmodell.md 5.6).
static func step(state: GameState, defs: GameDefs, ideology: Vector2) -> void:
	var newsroom := newsroom_judgement(state.party)
	var radius: float = defs.scenarios[state.scenario_id].media_owner_ideology_radius
	for media_id: String in defs.media:
		var def := defs.media[media_id]
		var house := state.media[media_id]
		if not def.independence_fixed:
			var owner := owner_sympathy(defs, def, house, ideology)
			if absf(owner - newsroom) > CONFLICT_THRESHOLD and state.rng.randf() < CONFLICT_PROBABILITY:
				_resolve_conflict(state, media_id, house)
		house.reach = SimMath.clamp100(SimMath.approach(house.reach, target_reach(defs, def, house), DYNAMICS_RATE))
		house.credibility = SimMath.clamp100(
			SimMath.approach(house.credibility, target_credibility(house.independence), DYNAMICS_RATE)
		)
		if def.owner == "family" and state.rng.randf() < INHERITANCE_PROBABILITY:
			house.owner_ideology = SimMath.random_point_in_disc(radius, state.rng)
			SimLog.add(state, "media_new_owner", {"media": media_id})


static func _resolve_conflict(state: GameState, media_id: String, house: MediaState) -> void:
	if state.rng.randf() < 1.0 - house.independence / 100.0:
		house.independence = SimMath.clamp100(house.independence - OWNER_WIN_INDEPENDENCE_LOSS)
		var resignations := state.rng.randf() < RESIGNATION_PROBABILITY
		if resignations:
			house.credibility = SimMath.clamp100(house.credibility - RESIGNATION_CREDIBILITY_LOSS)
		state.resilience = SimMath.clamp100(state.resilience - CONFLICT_RESILIENCE_LOSS)
		SimLog.add(state, "media_conflict", {"media": media_id, "winner": "owner", "resignations": resignations})
	else:
		house.independence = SimMath.clamp100(house.independence + NEWSROOM_WIN_INDEPENDENCE_GAIN)
		SimLog.add(state, "media_conflict", {"media": media_id, "winner": "newsroom"})


static func _sensationalism(defs: GameDefs, independence: float) -> float:
	return defs.params.value("media_sensationalism_reach") * (1.0 - independence / 100.0)
