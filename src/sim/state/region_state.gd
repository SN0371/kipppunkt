class_name RegionState
extends RefCounted
## Dynamic state of the party in one region (rechenmodell.md section 1.3).

## Local branches, municipal mandates and presence in associations (V_r), 0..100.
var anchoring: float = 0.0


## Serializes the region state to plain JSON-compatible data.
func to_dict() -> Dictionary:
	return {"anchoring": anchoring}


## Restores a region state from data written by to_dict().
static func from_dict(d: Dictionary, reader: JsonReader, ctx: String) -> RegionState:
	var region := RegionState.new()
	region.anchoring = reader.read_float(d, "anchoring", ctx, 0.0, 100.0)
	return region
