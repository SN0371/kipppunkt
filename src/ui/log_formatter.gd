class_name LogFormatter
extends RefCounted
## Turns protocol entries (SimLog) into readable, translated sentences for the report.

## Protocol kinds shown in the report; each has a translation key "log.<kind>".
const SHOWN_KINDS: PackedStringArray = [
	"action", "order_rejected", "action_abandoned", "position_set", "regional_message_set",
	"income", "crisis_omen", "crisis_started", "crisis_ended", "crisis_false_alarm",
	"election", "surveillance_level", "press_exposed_contradiction", "press_exposed_funding",
	"press_exposed_insider", "media_conflict", "media_new_owner", "donor_withdrew",
	"donor_returned", "person_left", "agenda_revealed", "purge", "phase", "game_over",
]
## Actions whose effect has its own, more precise report line.
const SELF_REPORTING_ACTIONS: PackedStringArray = ["action.set_position", "action.regional_message"]


## Returns the sentence for an entry, or an empty string for entries not shown in the report.
static func format(entry: Dictionary, defs: GameDefs) -> String:
	var kind: String = entry["kind"]
	if not SHOWN_KINDS.has(kind):
		return ""
	var data: Dictionary = entry["data"]
	var server := TranslationServer
	match kind:
		"action":
			var order: Dictionary = data["order"]
			if data["success"] and SELF_REPORTING_ACTIONS.has(order["action"]):
				return ""
			var key := "log.action" if data["success"] else "log.action_failed"
			return server.translate(key) % [server.translate(order["action"] + ".name"), _target(order, defs)]
		"order_rejected":
			var order: Dictionary = data["order"]
			return server.translate("log.order_rejected") % [
				server.translate(order["action"] + ".name"), reason_text(data["reason"]),
			]
		"action_abandoned":
			return server.translate("log.action_abandoned") % server.translate(data["order"]["action"] + ".name")
		"position_set":
			var topic := server.translate(data["topic"] + ".name")
			var value := server.translate("position.%d" % int(data["value"]))
			if float(data["credibility_cost"]) <= 0.0:
				return server.translate("log.position_set_free") % [topic, value]
			return server.translate("log.position_set") % [topic, value, data["credibility_cost"]]
		"regional_message_set":
			return server.translate("log.regional_message_set") % [
				server.translate(data["region"] + ".name"), server.translate(data["topic"] + ".name"),
				server.translate("position.%d" % int(data["value"])),
			]
		"income":
			return server.translate("log.income") % [
				UiKit.money(data["fees"]), UiKit.money(data["donations"]),
				UiKit.money(data["state_funding"]), UiKit.money(data["costs"]),
			]
		"crisis_omen", "crisis_started", "crisis_ended", "crisis_false_alarm":
			return server.translate("log." + kind) % server.translate(data["crisis"] + ".name")
		"election":
			return _election(data)
		"surveillance_level":
			var key := "log.surveillance_raised" if data["raised"] else "log.surveillance_lowered"
			return server.translate(key) % server.translate("vs_level.%d" % int(data["level"]))
		"media_conflict":
			var key := "log.media_conflict_owner" if data["winner"] == "owner" else "log.media_conflict_newsroom"
			return server.translate(key) % server.translate(data["media"] + ".name")
		"media_new_owner":
			return server.translate("log.media_new_owner") % server.translate(data["media"] + ".name")
		"donor_withdrew", "donor_returned":
			return server.translate("log." + kind) % server.translate(data["donor"] + ".name")
		"person_left":
			return server.translate("log.person_left") % server.translate("role." + String(data["role"]))
		"agenda_revealed":
			return server.translate("log.agenda_revealed") % server.translate("agenda." + String(data["agenda"]))
		"purge":
			return server.translate("log.purge") % (data["removed"] as Array).size()
		"phase":
			return server.translate("log.phase") % int(data["phase"])
		"game_over":
			return server.translate("log.game_over") % server.translate("outcome." + String(data["outcome"]))
	return server.translate("log." + kind)


## Returns the translated text of a rejection reason from ActionResolver.check().
static func reason_text(reason: String) -> String:
	return TranslationServer.translate("reason." + reason.replace(" ", "_"))


static func _election(data: Dictionary) -> String:
	var server := TranslationServer
	var result: float = data["result"]
	var turnout: float = data["turnout"]
	match data["type"]:
		"municipal":
			return server.translate("log.election_municipal") % [server.translate(data["land"] + ".name"), result, turnout]
		"state":
			var key := "log.election_state_seats" if data["seats"] else "log.election_state"
			return server.translate(key) % [server.translate(data["land"] + ".name"), result, turnout]
	var federal_key := "log.election_federal_seats" if data["seats"] else "log.election_federal"
	return server.translate(federal_key) % [result, turnout]


static func _target(order: Dictionary, defs: GameDefs) -> String:
	var target: String = order["target"]
	if target.is_empty() or target.begins_with("person."):
		return ""
	if defs.lands.has(target) or defs.regions.has(target) or defs.topics.has(target) or defs.donors.has(target):
		return " (" + TranslationServer.translate(target + ".name") + ")"
	return ""
