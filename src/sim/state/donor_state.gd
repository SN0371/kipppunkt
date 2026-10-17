class_name DonorState
extends RefCounted
## Dynamic state of one donor (rechenmodell.md section 5.4).

## Satisfaction with the party (Z_u), 0..100.
var satisfaction: float = 0.0
## False after the donor withdrew.
var active: bool = true
## Consecutive turns with satisfaction below the withdrawal threshold.
var low_turns: int = 0
## Earliest turn a withdrawn donor may return; 0 if not withdrawn.
var return_turn: int = 0
## Current maximum payment per turn in thousand euros (Zmax_u); halved after a return.
var max_payment: float = 0.0


## Serializes the donor state to plain JSON-compatible data.
func to_dict() -> Dictionary:
	return {
		"satisfaction": satisfaction,
		"active": active,
		"low_turns": low_turns,
		"return_turn": return_turn,
		"max_payment": max_payment,
	}


## Restores a donor state from data written by to_dict().
static func from_dict(d: Dictionary, reader: JsonReader, ctx: String) -> DonorState:
	var donor := DonorState.new()
	donor.satisfaction = reader.read_float(d, "satisfaction", ctx, 0.0, 100.0)
	donor.active = reader.read_bool(d, "active", ctx)
	donor.low_turns = reader.read_int(d, "low_turns", ctx, 0)
	donor.return_turn = reader.read_int(d, "return_turn", ctx, 0)
	donor.max_payment = reader.read_float(d, "max_payment", ctx, 0.0)
	return donor
