class_name RandomBot
extends Bot
## Random: picks random actions with random but well-formed targets. Without a plan
## the party should hardly ever succeed.

const ATTEMPTS_PER_TURN := 6


## Returns the short name used on the command line and in reports.
func id() -> String:
	return "random"


## Founds the party on two random topics with random directions.
func founding_programme(_state: GameState, defs: GameDefs) -> Dictionary:
	var topics: Array = defs.topics.keys()
	var first: String = _pick(topics)
	var second: String = first
	while second == first:
		second = _pick(topics)
	return {first: _random_direction(), second: _random_direction()}


## Answers events at random, sometimes with silence.
func respond(_state: GameState, _defs: GameDefs, _event: EventDef) -> Variant:
	var roll := rng.randi_range(-3, 2)
	return null if roll == -3 else roll


## Returns the orders for the current turn.
func orders(state: GameState, defs: GameDefs) -> Array[ActionOrder]:
	var result: Array[ActionOrder] = []
	var action_ids: Array = defs.actions.keys()
	for i in ATTEMPTS_PER_TURN:
		var def: ActionDef = defs.actions[_pick(action_ids)]
		var fields := {
			"topic": _pick(defs.topics.keys()),
			"value": rng.randi_range(-2, 2),
			"role": _pick(Array(PersonSystem.STAFF_FUNCTIONS)),
		}
		result.append(ActionOrder.create(def.id, _random_target(state, defs, def.target), fields))
	return result


func _random_target(state: GameState, defs: GameDefs, target_type: String) -> String:
	match target_type:
		"region":
			return _pick(Array(playable_regions(state, defs)))
		"land":
			return _pick(Array(CAMPAIGN_PRIORITY))
		"topic":
			return _pick(defs.topics.keys())
		"person":
			return _pick(state.persons.map(func(p: PersonState) -> String: return p.id))
		"donor":
			return _pick(defs.donors.keys())
	return ""


func _random_direction() -> int:
	return [-2, -1, 1, 2][rng.randi_range(0, 3)]


func _pick(items: Array) -> Variant:
	return items[rng.randi_range(0, items.size() - 1)] if not items.is_empty() else ""
