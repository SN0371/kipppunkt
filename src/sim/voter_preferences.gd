class_name VoterPreferences
extends RefCounted
## Average voter preferences over regions, used by bots and by the player's previews.


## Returns the population- and weight-averaged preference per topic in the given regions (-2..+2).
static func average(defs: GameDefs, regions: PackedStringArray) -> Dictionary[String, float]:
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
