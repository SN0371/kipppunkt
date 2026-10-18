class_name StaffPanel
extends SidePanel
## Party functions and the candidate pool (game-design.md section 3.6). Hidden agendas
## stay hidden until revealed: finding out should surprise the player.


## Fills the content.
func build() -> void:
	var state := session.state
	content.add_child(UiKit.heading(tr("ui.staff.functions")))
	content.add_child(UiKit.hint(tr("ui.staff.scale_hint")))
	content.add_child(_person_block(tr("role.chair"), PersonSystem.by_role(state, "chair")))
	var open_roles: Array = []
	for role in PersonSystem.STAFF_FUNCTIONS:
		var person := PersonSystem.by_role(state, role)
		if person == null:
			content.add_child(UiKit.label(tr("role." + role) + ": " + tr("ui.staff.vacant")))
			if _planned_appointment_for_role(role) == null:
				open_roles.append([tr("role." + role), role])
			continue
		content.add_child(_person_block(tr("role." + role), person))
		content.add_child(UiKit.row([
			action_button("action.vet_person", person.id),
			action_button("action.dismiss", person.id),
		]))
	content.add_child(UiKit.heading(tr("ui.staff.candidates")))
	content.add_child(UiKit.hint(tr("ui.staff.candidates_hint")))
	for person in state.persons:
		if not person.role.is_empty():
			continue
		content.add_child(_person_block(tr("ui.staff.candidate"), person))
		var planned := _planned_appointment_for_person(person.id)
		if planned != null:
			content.add_child(UiKit.label("✓ " + tr("ui.staff.appointment_planned") % tr("role." + planned.role)))
		elif not open_roles.is_empty():
			var role_choice := UiKit.choice(open_roles)
			content.add_child(UiKit.row([
				role_choice,
				UiKit.button(tr("action.appoint.name"), func() -> void:
					plan("action.appoint", person.id, {"role": UiKit.chosen(role_choice)})),
			]))


## Returns a title line with the person's attributes as a small table below it.
func _person_block(title: String, person: PersonState) -> VBoxContainer:
	var block := VBoxContainer.new()
	var heading := title
	if person.agenda_revealed and person.agenda != "none":
		heading += " – " + tr("agenda." + person.agenda)
	var title_label := UiKit.label(heading)
	title_label.add_theme_font_size_override("font_size", UiKit.HEADING_SIZE - 2)
	block.add_child(title_label)
	var table := UiKit.grid([
		[tr("ui.staff.loyalty"), str(roundi(person.loyalty))],
		[tr("ui.staff.persuasion"), str(roundi(person.persuasion))],
		[tr("ui.staff.network"), str(roundi(person.network))],
		[tr("ui.staff.competence"), str(roundi(person.competence))],
	])
	var indent := MarginContainer.new()
	indent.add_theme_constant_override("margin_left", 16)
	indent.add_child(table)
	block.add_child(indent)
	return block


func _planned_appointment_for_role(role: String) -> ActionOrder:
	for order in session.planned:
		if order.action_id == "action.appoint" and order.role == role:
			return order
	return null


func _planned_appointment_for_person(person_id: String) -> ActionOrder:
	for order in session.planned:
		if order.action_id == "action.appoint" and order.target == person_id:
			return order
	return null
