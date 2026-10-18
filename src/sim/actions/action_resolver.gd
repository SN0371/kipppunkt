class_name ActionResolver
extends RefCounted
## Checks and carries out action orders (rechenmodell.md sections 4 and 10.3).

## Extra action points when the chair takes over a task whose responsible function is filled.
const PERSONAL_SURCHARGE := 1
const CHANCE_MIN := 0.05
const CHANCE_MAX := 0.95
## Competence above average adds this much success chance per point (1/200).
const COMPETENCE_DIVISOR := 200.0
## Extra radicalism when an ideologue carries out an action more radically than ordered.
const IDEOLOGUE_EXTRA_RADICALISM := 5.0
## Material an undercover journalist gains by documenting instead of sabotaging.
const JOURNALIST_DOCUMENTATION := 20.0
## Scrutiny an informant's report adds.
const INFORMANT_SCRUTINY := 5.0


## Checks and carries out all orders of a turn in the given order (step 4 of the turn).
## Invalid orders are skipped and logged with the reason.
static func resolve(state: GameState, defs: GameDefs, orders: Array[ActionOrder]) -> void:
	for order in orders:
		var reason := check(state, defs, order)
		if reason.is_empty():
			execute(state, defs, order)
		else:
			SimLog.add(state, "order_rejected", {"order": order.to_dict(), "reason": reason})


## Returns why an order cannot be carried out, or an empty string if it can.
## The optional budget {"action_points", "money", "activists"} replaces the party's current
## resources, so the planning view can check an order against what earlier orders leave.
static func check(state: GameState, defs: GameDefs, order: ActionOrder, budget: Dictionary = {}) -> String:
	if not defs.actions.has(order.action_id):
		return "unknown action"
	var def := defs.actions[order.action_id]
	var target_problem := _check_target(state, defs, def, order)
	if not target_problem.is_empty():
		return target_problem
	if def.needs("topic") and not defs.topics.has(order.topic):
		return "unknown topic"
	if def.requires.get("addressed_topic", false):
		var topic_id := order.topic if def.needs("topic") else order.target
		if not state.party.positions.has(topic_id):
			return "topic not addressed yet"
		if def.action_points_per_step and order.value == state.party.positions[topic_id]:
			return "position unchanged"
	if def.needs("value") and (order.value < -2 or order.value > 2):
		return "value out of range"
	if def.needs("role"):
		if not PersonSystem.STAFF_FUNCTIONS.has(order.role):
			return "unknown role"
		if PersonSystem.by_role(state, order.role) != null:
			return "role already filled"
	if not order.performer.is_empty():
		var assigned := PersonSystem.by_id(state, order.performer)
		if assigned == null or assigned.role.is_empty():
			return "performer is not on the staff"
		if not def.is_delegable() and assigned.role != "chair":
			return "action cannot be delegated"
	var party := state.party
	if action_point_cost(state, defs, order) > budget.get("action_points", party.action_points):
		return "not enough action points"
	if def.cost_money > 0.0 and def.cost_money > budget.get("money", party.money):
		return "not enough money"
	if def.cost_activists > budget.get("activists", party.activists):
		return "not enough activists"
	return ""


## Returns the action points an order costs. Delegation costs nothing extra, but the chair
## taking over a task whose responsible function is filled costs PERSONAL_SURCHARGE more.
static func action_point_cost(state: GameState, defs: GameDefs, order: ActionOrder) -> int:
	var def := defs.actions[order.action_id]
	var cost := def.cost_action_points
	if def.action_points_per_step:
		cost *= absi(order.value - state.party.positions.get(order.target, 0))
	return cost + PERSONAL_SURCHARGE if is_personal_override(state, defs, order) else cost


## Returns the staff member responsible for an order's action, or null if the function is
## vacant or the chair is always responsible (rechenmodell.md 4.1).
static func responsible(state: GameState, defs: GameDefs, order: ActionOrder) -> PersonState:
	var def := defs.actions[order.action_id]
	match def.delegate:
		"treasurer", "general_secretary":
			return PersonSystem.by_role(state, def.delegate)
		"regional":
			var region := order.target
			if defs.lands.has(order.target):
				region = defs.lands[order.target].region
			if PersonSystem.REGION_CHAIRS.has(region):
				return PersonSystem.by_role(state, PersonSystem.REGION_CHAIRS[region])
	return null


## Returns true if the order explicitly assigns the chair although a responsible staff
## member exists.
static func is_personal_override(state: GameState, defs: GameDefs, order: ActionOrder) -> bool:
	if order.performer.is_empty():
		return false
	var chair := PersonSystem.by_role(state, "chair")
	return chair != null and order.performer == chair.id and responsible(state, defs, order) != null


## Returns who carries out an order: the explicitly assigned person, otherwise the responsible
## staff member, otherwise the chair.
static func performer(state: GameState, defs: GameDefs, order: ActionOrder) -> PersonState:
	if not order.performer.is_empty():
		return PersonSystem.by_id(state, order.performer)
	var person := responsible(state, defs, order)
	return person if person != null else PersonSystem.by_role(state, "chair")


## Returns the success chance of an order (rechenmodell.md 4.1).
static func success_chance(state: GameState, defs: GameDefs, order: ActionOrder) -> float:
	var def := defs.actions[order.action_id]
	if def.base_chance >= 1.0:
		return 1.0
	var competence := performer(state, defs, order).competence
	var chance := def.base_chance + (competence - 50.0) / COMPETENCE_DIVISOR
	chance = ModifierSystem.apply(state, "action_chance." + def.id, chance)
	return clampf(chance, CHANCE_MIN, CHANCE_MAX)


## Carries out a valid order: pays the costs, runs the loyalty check of a delegated
## performer, rolls for success and applies the effects.
static func execute(state: GameState, defs: GameDefs, order: ActionOrder) -> void:
	var def := defs.actions[order.action_id]
	var party := state.party
	party.action_points -= action_point_cost(state, defs, order)
	party.money -= def.cost_money
	party.activists -= def.cost_activists
	var person := performer(state, defs, order)
	var extra_radicalism := 0.0
	if person.role != "chair" and _has_conflict(state, def, person, order) \
			and not PersonSystem.loyalty_check(state, person):
		match person.agenda:
			"careerist":
				state.persons.erase(person)
				SimLog.add(state, "action_abandoned", {"order": order.to_dict(), "person": person.id})
				return
			"ideologue":
				extra_radicalism = IDEOLOGUE_EXTRA_RADICALISM
			"journalist":
				person.material += JOURNALIST_DOCUMENTATION
			"informant":
				party.scrutiny = SimMath.clamp100(party.scrutiny + INFORMANT_SCRUTINY)
	var success := state.rng.randf() < success_chance(state, defs, order)
	for op in (def.effects if success else def.failure_effects):
		_apply(state, defs, def, order, op)
	for op in def.side_effects:
		_apply(state, defs, def, order, op)
	if extra_radicalism > 0.0:
		party.radicalism = SimMath.clamp100(party.radicalism + extra_radicalism)
		party.radical_action_this_turn = true
	SimLog.add(state, "action", {"order": order.to_dict(), "success": success, "performer": person.role})


static func _check_target(state: GameState, defs: GameDefs, def: ActionDef, order: ActionOrder) -> String:
	var playable := defs.scenarios[state.scenario_id].playable_regions
	match def.target:
		"none":
			if not order.target.is_empty():
				return "action has no target"
		"region":
			if not defs.regions.has(order.target):
				return "unknown region"
			if not playable.has(order.target):
				return "region is not playable"
			if def.requires.get("municipal_level", false) and not defs.regions[order.target].has_municipal_level:
				return "region has no municipal level"
		"land":
			if not defs.lands.has(order.target):
				return "unknown land"
			if not playable.has(defs.lands[order.target].region):
				return "land is not playable"
			if def.requires.get("campaign", false) and not ElectionSystem.land_votes(state, defs, order.target):
				return "no election in this land"
		"topic":
			if not defs.topics.has(order.target):
				return "unknown topic"
		"person":
			var person := PersonSystem.by_id(state, order.target)
			if person == null:
				return "unknown person"
			if def.requires.get("candidate", false) and not person.role.is_empty():
				return "person is not a candidate"
			if def.requires.get("staff", false) and (person.role.is_empty() or person.role == "chair"):
				return "person is not on the staff"
		"donor":
			if not defs.donors.has(order.target):
				return "unknown donor"
			var donor := state.donors[order.target]
			if not donor.active:
				return "donor has withdrawn"
			if donor.satisfaction < float(def.requires.get("min_target_satisfaction", 0.0)):
				return "donor is not satisfied enough"
	return ""


## Returns true if an action goes against the hidden agenda of the person carrying it out.
static func _has_conflict(state: GameState, def: ActionDef, person: PersonState, order: ActionOrder) -> bool:
	match person.agenda:
		"none":
			return false
		"ideologue":
			var current: int = state.party.positions.get(order.target, 0)
			var weakens_position := def.id == "action.set_position" and absi(order.value) < absi(current)
			return weakens_position or def.agenda_conflicts.has("ideologue")
		"informant":
			return def.raises("party.scrutiny") or def.agenda_conflicts.has("informant")
		"journalist":
			return def.raises("party.intransparency") or def.agenda_conflicts.has("journalist")
	return def.agenda_conflicts.has(person.agenda)


static func _apply(state: GameState, defs: GameDefs, def: ActionDef, order: ActionOrder, op: Dictionary) -> void:
	var party := state.party
	match op["op"]:
		"add":
			_add(state, defs, order, op["stat"], float(op["value"]))
		"scale":
			party.members = maxi(0, roundi(party.members * float(op["value"])))
		"modifier":
			var target: String = String(op["target"]).replace("{target}", order.target).replace("{topic}", order.topic)
			ModifierSystem.add(state, def.id, target, float(op["value"]), int(op["turns"]))
		"set_position":
			IdeologySystem.set_position(state, defs, order.target, order.value)
		"set_regional_message":
			IdeologySystem.set_regional_message(state, order.target, order.topic, order.value)
		"donor_payment":
			party.money += float(op["factor"]) * state.donors[order.target].max_payment
		"reveal_agenda":
			var person := PersonSystem.by_id(state, order.target)
			person.agenda_revealed = true
			SimLog.add(state, "agenda_revealed", {"person": person.id, "agenda": person.agenda})
		"purge":
			_purge(state, float(op["loyalty_below"]), float(op["competence_loss"]))
		"appoint":
			PersonSystem.by_id(state, order.target).role = order.role
		"dismiss":
			state.persons.erase(PersonSystem.by_id(state, order.target))


static func _add(state: GameState, defs: GameDefs, order: ActionOrder, stat: String, amount: float) -> void:
	var party := state.party
	match stat:
		"party.money":
			party.money += amount
		"resilience":
			state.resilience = SimMath.clamp100(state.resilience + amount)
		"lands.polling":
			var maximum := defs.params.value("polling_max")
			for land: LandState in state.lands.values():
				land.polling = clampf(land.polling + amount, 0.0, maximum)
		"target.anchoring":
			var region := state.regions[order.target]
			region.anchoring = SimMath.clamp100(region.anchoring + amount)
		"target.satisfaction":
			var donor := state.donors[order.target]
			donor.satisfaction = SimMath.clamp100(donor.satisfaction + amount)
		_:
			var field := stat.trim_prefix("party.")
			party.set(field, SimMath.clamp100(float(party.get(field)) + amount))
			if field == "radicalism" and amount > 0.0:
				party.radical_action_this_turn = true


static func _purge(state: GameState, loyalty_below: float, competence_loss: float) -> void:
	var removed: Array[String] = []
	for person in PersonSystem.staff(state):
		if person.role == "chair":
			continue
		if person.loyalty < loyalty_below:
			state.persons.erase(person)
			removed.append(person.id)
		else:
			person.competence = SimMath.clamp100(person.competence - competence_loss)
	SimLog.add(state, "purge", {"removed": removed})
