class_name RivalSystem
extends RefCounted
## Established rival parties: competition for voters and attitude (rechenmodell.md 3.3, 5.5).

## Upper limit of the competition pressure in a land (Konk_l).
const MAX_PRESSURE := 0.8


## Returns how close the party's profile is to a rival (Nähe_j), 0..1.
static func proximity(defs: GameDefs, rival: RivalPartyDef, ideology: Vector2) -> float:
	return maxf(0.0, 1.0 - ideology.distance_to(rival.ideology) / defs.params.value("rival_proximity_range"))


## Returns the competition pressure in a land (Konk_l), 0..MAX_PRESSURE.
static func pressure(defs: GameDefs, land_id: String, ideology: Vector2) -> float:
	var total := 0.0
	for rival: RivalPartyDef in defs.rivals.values():
		total += rival.strength[land_id] / 100.0 * proximity(defs, rival, ideology)
	return minf(MAX_PRESSURE, defs.params.value("rival_pressure") * total)


## Returns a rival's willingness to cooperate with the party (Haltung_j), 0..100.
static func attitude(defs: GameDefs, rival: RivalPartyDef, ideology: Vector2, party: PartyState) -> float:
	return SimMath.clamp100(
		100.0 * proximity(defs, rival, ideology) - 0.5 * party.radicalism - 20.0 * party.vs_level
	)


## Returns a rival's vote share in the whole federation, weighted by population.
static func national_strength(defs: GameDefs, rival: RivalPartyDef) -> float:
	var total := 0.0
	for land_id: String in defs.lands:
		total += defs.lands[land_id].population_share * rival.strength[land_id]
	return total
