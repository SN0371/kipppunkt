class_name PlanningPanel
extends SidePanel
## Orders planned for the current turn, the remaining budget and who carries out
## delegable actions.


## Fills the content.
func build() -> void:
	var budget := session.remaining()
	content.add_child(UiKit.heading(tr("ui.planning.budget")))
	content.add_child(UiKit.grid([
		[tr("ui.planning.action_points"), str(budget["action_points"])],
		[tr("ui.planning.money"), UiKit.money(budget["money"])],
		[tr("ui.planning.activists"), str(budget["activists"])],
	]))
	content.add_child(UiKit.heading(tr("ui.planning.performer")))
	content.add_child(UiKit.hint(tr("ui.planning.performer_hint")))
	var entries := [[tr("role.chair"), ""]]
	for person in PersonSystem.staff(session.state):
		if person.role != "chair":
			entries.append([tr("role." + person.role), person.id])
	var performer_choice := UiKit.choice(entries)
	for i in entries.size():
		if entries[i][1] == session.performer:
			performer_choice.selected = i
	performer_choice.item_selected.connect(func(index: int) -> void:
		session.performer = performer_choice.get_item_metadata(index))
	content.add_child(performer_choice)
	content.add_child(UiKit.heading(tr("ui.planning.orders")))
	if session.planned.is_empty():
		content.add_child(UiKit.hint(tr("ui.planning.no_orders")))
	for i in session.planned.size():
		var order := session.planned[i]
		var text := tr(order.action_id + ".name")
		if not order.target.is_empty() and not order.target.begins_with("person."):
			text += " – " + tr(order.target + ".name")
		content.add_child(UiKit.row([UiKit.label(text), UiKit.button("✕", session.unplan.bind(i), tr("ui.planning.remove"))]))
