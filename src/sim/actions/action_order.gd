class_name ActionOrder
extends RefCounted
## An order of the player or a bot for one action in the current turn (prototyp-plan.md section 2).

var action_id: String = ""
## Id of the target (region, land, topic, person or donor); empty for actions without target.
var target: String = ""
## Topic for actions with the parameter "topic".
var topic: String = ""
## Position -2..+2 for actions with the parameter "value".
var value: int = 0
## Party function for actions with the parameter "role".
var role: String = ""
## Id of the staff member who carries out the action; empty means the chair.
var performer: String = ""


## Creates an order. Optional fields are given as a dictionary, for example {"value": 2}.
static func create(action_id: String, target: String = "", fields: Dictionary = {}) -> ActionOrder:
	var order := ActionOrder.new()
	order.action_id = action_id
	order.target = target
	order.topic = fields.get("topic", "")
	order.value = fields.get("value", 0)
	order.role = fields.get("role", "")
	order.performer = fields.get("performer", "")
	return order


## Serializes the order for the protocol.
func to_dict() -> Dictionary:
	return {
		"action": action_id,
		"target": target,
		"topic": topic,
		"value": value,
		"role": role,
		"performer": performer,
	}
