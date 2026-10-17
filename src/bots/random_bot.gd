class_name RandomBot
extends Bot
## Random: picks random actions with random but well-formed targets. Without a plan
## the party should hardly ever succeed.

const ATTEMPTS_PER_TURN := 6


## Returns the short name used on the command line and in reports.
func id() -> String:
	return "random"


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


func _pick(items: Array) -> Variant:
	return items[rng.randi_range(0, items.size() - 1)] if not items.is_empty() else ""
