class_name PlanningPanel
extends SidePanel
## Orders planned for the current turn and the remaining budget. Responsible staff carry out
## their tasks; the chair can take a task over personally for one extra action point.


## Fills the content.
func build() -> void:
	var budget := session.remaining()
	content.add_child(UiKit.heading(tr("ui.planning.budget")))
	content.add_child(UiKit.grid([
		[tr("ui.planning.action_points"), str(budget["action_points"])],
		[tr("ui.planning.money"), UiKit.money(budget["money"])],
		[tr("ui.planning.activists"), str(budget["activists"])],
	]))
	content.add_child(UiKit.heading(tr("ui.planning.orders")))
	content.add_child(UiKit.hint(tr("ui.planning.delegation_hint") % ActionResolver.PERSONAL_SURCHARGE))
	if session.planned.is_empty():
		content.add_child(UiKit.hint(tr("ui.planning.no_orders")))
	for i in session.planned.size():
		var order := session.planned[i]
		content.add_child(UiKit.row([
			UiKit.label(order_text(order)),
			UiKit.button("✕", session.unplan.bind(i), tr("ui.planning.remove")),
		]))
		var responsible := ActionResolver.responsible(session.state, session.defs, order)
		var performer := ActionResolver.performer(session.state, session.defs, order)
		content.add_child(UiKit.hint(tr("ui.planning.carried_out_by") % tr("role." + performer.role)))
		if responsible != null:
			var personal := CheckBox.new()
			personal.text = tr("ui.planning.personal") % ActionResolver.PERSONAL_SURCHARGE
			personal.button_pressed = ActionResolver.is_personal_override(session.state, session.defs, order)
			personal.toggled.connect(func(on: bool) -> void:
				var reason := session.set_personal(i, on)
				if not reason.is_empty():
					report(order.action_id, reason))
			content.add_child(personal)


## Returns a readable description of a planned order, for example
## "Position beziehen – Steuern senken: +1 dafür".
static func order_text(order: ActionOrder) -> String:
	var server := TranslationServer
	var text := String(server.translate(order.action_id + ".name"))
	match order.action_id:
		"action.set_position":
			var value := server.translate("position.%d" % order.value) if order.value != 0 \
				else server.translate("ui.party.no_position")
			return "%s – %s: %s" % [text, server.translate(order.target + ".name"), value]
		"action.regional_message":
			return "%s – %s, %s: %s" % [text, server.translate(order.target + ".name"),
				server.translate(order.topic + ".name"), server.translate("position.%d" % order.value)]
		"action.appoint":
			return "%s – %s" % [text, server.translate("role." + order.role)]
	if not order.target.is_empty() and not order.target.begins_with("person."):
		text += " – " + server.translate(order.target + ".name")
	return text
