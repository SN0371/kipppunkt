class_name EconomySystem
extends RefCounted
## Money, members, activists, action points and the slow recovery of indicators
## (rechenmodell.md section 6).

const BASE_ACTION_POINTS := 4
const MAX_ACTION_POINTS := 10
const CAMPAIGN_ACTION_POINT_FACTOR := 1.5
const ACTIVIST_BASE_QUOTA := 0.05
const ACTIVIST_UNITY_QUOTA := 0.10
const ACTIVIST_RADICALISM_QUOTA := 0.10
## Share of the gap to the member target closed per turn while support attracts members.
const MEMBER_ATTRACTION_RATE := 0.05
## Share of the gap closed per turn while members drift away after support fell.
const MEMBER_DRIFT_RATE := 0.02
const EXIT_RATE := 0.03
const EXIT_UNITY_THRESHOLD := 40.0
## Total anchoring at which the fixed costs have doubled.
const ANCHORING_COST_DIVISOR := 50.0
## [Vereinfachung] Votes cast in a federal election; land shares follow the population.
const VOTES_CAST := 45000000.0
## Minimum results for state funding (rechenmodell.md section 6).
const STATE_FUNDING_MIN_STATE_RESULT := 1.0
const STATE_FUNDING_MIN_FEDERAL_RESULT := 0.5
const CLASSIC_BONUS_DECAY := 0.3
const CREDIBILITY_RATE := 0.05
const CREDIBILITY_REST := 60.0
const UNITY_RATE := 0.1
const UNITY_REST := 60.0
## Not quantified in the model ("sinkt langsam").
const INTRANSPARENCY_DECAY := 1.0
const RADICALISM_DECAY := 0.5
## Not quantified in the model: resilience slowly returns to the scenario's start value.
const RESILIENCE_RECOVERY_RATE := 0.02


## Returns the votes the party won in the last elections that qualify for state funding.
static func funded_votes(state: GameState, defs: GameDefs) -> float:
	var votes := 0.0
	for land_id: String in defs.lands:
		var result := state.lands[land_id].last_state_result
		if result >= STATE_FUNDING_MIN_STATE_RESULT:
			votes += defs.lands[land_id].population_share * VOTES_CAST * result / 100.0
	if state.party.last_federal_result >= STATE_FUNDING_MIN_FEDERAL_RESULT:
		votes += VOTES_CAST * state.party.last_federal_result / 100.0
	return votes


## Returns the fixed costs of the party per turn; they grow with its anchoring.
static func fixed_costs(state: GameState, defs: GameDefs) -> float:
	var anchoring := 0.0
	for region: RegionState in state.regions.values():
		anchoring += region.anchoring
	return defs.params.value("fixed_costs") * (1.0 + anchoring / ANCHORING_COST_DIVISOR)


## Returns the action points of a turn: base, filled functions and state parliament groups,
## more in a campaign quarter.
static func action_points(state: GameState, defs: GameDefs) -> int:
	var landtag_groups := 0
	for land: LandState in state.lands.values():
		if land.in_landtag:
			landtag_groups += 1
	var points := mini(MAX_ACTION_POINTS, BASE_ACTION_POINTS + PersonSystem.filled_functions(state) + landtag_groups)
	if ElectionSystem.is_campaign_turn(state, defs):
		points = int(points * CAMPAIGN_ACTION_POINT_FACTOR)
	return points


## Returns the member count of the next turn (rechenmodell.md section 6).
## A very small party grows by itself (start boost, fading out with size); beyond that,
## members follow the party's support: they approach a target proportional to national polling.
static func next_members(state: GameState, defs: GameDefs) -> int:
	var party := state.party
	var params := defs.params
	var crisis_factor := CrisisSystem.member_growth_factor(state, defs)
	var start_boost := params.value("member_growth") * crisis_factor \
		* maxf(0.0, 1.0 - party.members / params.value("member_small_party"))
	var exit := EXIT_RATE * maxf(0.0, (EXIT_UNITY_THRESHOLD - party.unity) / EXIT_UNITY_THRESHOLD)
	var target := params.value("members_per_polling_point") * PollingSystem.national(state, defs)
	var gap := target - party.members
	var inflow := MEMBER_ATTRACTION_RATE * crisis_factor * gap if gap > 0.0 else MEMBER_DRIFT_RATE * gap
	return maxi(0, roundi(party.members * (1.0 + start_boost - exit) + inflow))


## Books the income and costs of a turn and renews members, activists and action points
## (step 1 of the turn).
static func income(state: GameState, defs: GameDefs) -> void:
	var party := state.party
	var params := defs.params
	var fees := party.members * params.value("member_fee")
	var donations := 0.0
	for donor_id: String in defs.donors:
		donations += DonorSystem.payment(state, defs, donor_id)
	var funding := params.value("state_funding_per_vote") * funded_votes(state, defs)
	var costs := fixed_costs(state, defs)
	party.money += fees + donations + funding - costs
	SimLog.add(state, "income", {"fees": fees, "donations": donations, "state_funding": funding, "costs": costs})
	party.members = next_members(state, defs)
	var quota := ACTIVIST_BASE_QUOTA + ACTIVIST_UNITY_QUOTA * party.unity / 100.0 \
		+ ACTIVIST_RADICALISM_QUOTA * party.radicalism / 100.0
	party.activists = int(party.members * quota)
	party.action_points = action_points(state, defs)


## Lets indicators decay or recover at the end of a turn (step 9 of the turn).
static func decay(state: GameState, defs: GameDefs, salience: Dictionary[String, float]) -> void:
	var party := state.party
	var params := defs.params
	party.reach_platform = SimMath.clamp100(
		party.reach_platform * (1.0 - params.value("platform_reach_decay"))
			+ ModifierSystem.total_add(state, "reach_platform_per_turn")
	)
	party.reach_classic_bonus *= 1.0 - CLASSIC_BONUS_DECAY
	party.credibility = SimMath.clamp100(SimMath.approach(
		party.credibility, CREDIBILITY_REST + params.value("media_climate_credibility_shift") * state.media_climate,
		CREDIBILITY_RATE
	))
	party.unity = SimMath.clamp100(SimMath.approach(party.unity, UNITY_REST, UNITY_RATE))
	party.intransparency = SimMath.clamp100(party.intransparency - INTRANSPARENCY_DECAY)
	if not party.radical_action_this_turn:
		party.radicalism = SimMath.clamp100(party.radicalism - RADICALISM_DECAY)
	party.radical_action_this_turn = false
	var start_resilience: float = defs.scenarios[state.scenario_id].resilience
	state.resilience = SimMath.clamp100(SimMath.approach(state.resilience, start_resilience, RESILIENCE_RECOVERY_RATE))
	IdeologySystem.update_contradiction(state, defs, salience)
	IdeologySystem.age_positions(party)
