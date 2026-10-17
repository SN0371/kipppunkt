class_name ModifierState
extends RefCounted
## A temporary or permanent change to a value of the simulation (game-design.md section 13).
##
## Targets are dotted names such as "salience.topic.taxes", "polling_target.land.by"
## or "election_bonus.land.by". A modifier adds a value and multiplies by a factor.

## Remaining turns until the modifier expires; -1 means permanent.
const PERMANENT := -1

var source: String = ""
var target: String = ""
var add: float = 0.0
var factor: float = 1.0
var remaining_turns: int = PERMANENT


## Serializes the modifier to plain JSON-compatible data.
func to_dict() -> Dictionary:
	return {
		"source": source,
		"target": target,
		"add": add,
		"factor": factor,
		"remaining_turns": remaining_turns,
	}


## Restores a modifier from data written by to_dict().
static func from_dict(d: Dictionary, reader: JsonReader, ctx: String) -> ModifierState:
	var modifier := ModifierState.new()
	modifier.source = reader.read_string(d, "source", ctx)
	modifier.target = reader.read_string(d, "target", ctx)
	modifier.add = reader.read_float(d, "add", ctx)
	modifier.factor = reader.read_float(d, "factor", ctx)
	modifier.remaining_turns = reader.read_int(d, "remaining_turns", ctx, PERMANENT)
	return modifier
