class_name RepresentationSystem
extends RefCounted
## Representation gap, turnout and mobilization (rechenmodell.md section 3.8).
##
## Established parties are moderate. Voters who feel strongly about an urgent topic
## (preference +-2) find no matching offer there. The more of these unserved concerns a
## land has, the more people stay home. A party that answers exactly these concerns can
## mobilize them; radical methods amplify that, in any ideological direction.
## The gap depends on topics and salience, never on a property of the people in a region.

## Preference strength that established, moderate parties do not serve.
const UNSERVED_PREFERENCE := 2
## Mobilization factor of a party without radicalism; rises to 1.5 at radicalism 100.
const RADICALISM_FACTOR_BASE := 0.5


## Returns the representation gap of a land (Lücke_l), 0..1: the salience- and
## weight-adjusted share of concerns that no established party serves.
static func gap(defs: GameDefs, land: LandDef, salience: Dictionary[String, float]) -> float:
	var unserved := 0.0
	var total := 0.0
	for topic_id: String in defs.topics:
		var weight := salience[topic_id] * land.topic_weights[topic_id]
		total += weight
		if absi(land.topic_preferences[topic_id]) >= UNSERVED_PREFERENCE:
			unserved += weight
	return unserved / total if total > 0.0 else 0.0


## Returns the polling points the party wins by answering unserved concerns (Mobilisierung_l).
## Only positions in the direction of the unserved concern count: a strong one fully,
## a moderate one half.
static func mobilization(
	defs: GameDefs, land: LandDef, party: PartyState, salience: Dictionary[String, float]
) -> float:
	var answered := 0.0
	var total := 0.0
	for topic_id: String in defs.topics:
		var weight := salience[topic_id] * land.topic_weights[topic_id]
		total += weight
		var preference := land.topic_preferences[topic_id]
		var position: Variant = PollingSystem.effective_position(party, land, topic_id)
		if absi(preference) >= UNSERVED_PREFERENCE and position != null:
			answered += weight * maxf(0.0, int(position) * preference / 4.0)
	if total == 0.0:
		return 0.0
	return defs.params.value("mobilization_weight") * answered / total \
		* (RADICALISM_FACTOR_BASE + party.radicalism / 100.0)


## Returns the expected turnout of a land in percent: unserved concerns keep people at home,
## mobilization brings some of them back.
static func turnout(defs: GameDefs, gap_share: float, mobilized: float) -> float:
	var params := defs.params
	return clampf(params.value("turnout_base") - params.value("turnout_gap_effect") * gap_share + mobilized, 0.0, 100.0)
