class_name ModifierSystem
extends RefCounted
## Collects and applies modifiers; the single mechanism for rule exceptions (prototyp-plan.md 2).


## Adds a modifier to the state.
static func add(
	state: GameState, source: String, target: String, add_value: float,
	turns: int = ModifierState.PERMANENT, factor: float = 1.0
) -> void:
	var modifier := ModifierState.new()
	modifier.source = source
	modifier.target = target
	modifier.add = add_value
	modifier.factor = factor
	modifier.remaining_turns = turns
	state.modifiers.append(modifier)


## Returns the base value multiplied by all factors and increased by all additions for a target.
static func apply(state: GameState, target: String, base: float) -> float:
	var factor := 1.0
	var sum := 0.0
	for modifier in state.modifiers:
		if modifier.target == target:
			factor *= modifier.factor
			sum += modifier.add
	return base * factor + sum


## Returns the sum of all additions for a target.
static func total_add(state: GameState, target: String) -> float:
	return apply(state, target, 0.0)


## Counts down temporary modifiers and removes expired ones. Called once at the end of a turn.
static func tick(state: GameState) -> void:
	var kept: Array[ModifierState] = []
	for modifier in state.modifiers:
		if modifier.remaining_turns == ModifierState.PERMANENT:
			kept.append(modifier)
		elif modifier.remaining_turns > 1:
			modifier.remaining_turns -= 1
			kept.append(modifier)
	state.modifiers = kept
