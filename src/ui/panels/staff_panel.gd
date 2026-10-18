class_name StaffPanel
extends SidePanel
## Party functions and the candidate pool (game-design.md section 3.6). Hidden agendas
## stay hidden until revealed.


## Fills the content.
func build() -> void:
	var state := session.state
	content.add_child(UiKit.heading(tr("ui.staff.functions")))
	content.add_child(UiKit.hint(tr("ui.staff.scale_hint")))
	var chair := PersonSystem.by_role(state, "chair")
	content.add_child(_person_line(tr("role.chair"), chair))
	var vacant: Array = []
	for role in PersonSystem.STAFF_FUNCTIONS:
		var person := PersonSystem.by_role(state, role)
		if person == null:
			vacant.append([tr("role." + role), role])
			content.add_child(UiKit.label(tr("role." + role) + ": " + tr("ui.staff.vacant")))
			continue
		content.add_child(_person_line(tr("role." + role), person))
		content.add_child(UiKit.row([
			action_button("action.vet_person", person.id),
			action_button("action.dismiss", person.id),
		]))
	content.add_child(UiKit.heading(tr("ui.staff.candidates")))
	content.add_child(UiKit.hint(tr("ui.staff.candidates_hint")))
	for person in state.persons:
		if not person.role.is_empty():
			continue
		content.add_child(_person_line(tr("ui.staff.candidate"), person))
		if not vacant.is_empty():
			var role_choice := UiKit.choice(vacant)
			content.add_child(UiKit.row([
				role_choice,
				UiKit.button(tr("action.appoint.name"), func() -> void:
					plan("action.appoint", person.id, {"role": UiKit.chosen(role_choice)})),
			]))


func _person_line(title: String, person: PersonState) -> Label:
	var text := tr("ui.staff.person") % [
		title, roundi(person.loyalty), roundi(person.persuasion), roundi(person.network), roundi(person.competence),
	]
	if person.agenda_revealed:
		text += " – " + tr("agenda." + person.agenda)
	return UiKit.label(text)
