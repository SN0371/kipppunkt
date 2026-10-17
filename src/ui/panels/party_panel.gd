class_name PartyPanel
extends SidePanel
## The party: indicators, ideology, positions, donors, rivals and party-wide actions.


## Fills the content.
func build() -> void:
	var state := session.state
	var defs := session.defs
	var party := state.party
	var ideology := IdeologySystem.profile(party, defs)
	content.add_child(UiKit.heading(tr("ui.party.indicators")))
	content.add_child(UiKit.grid([
		[tr("ui.party.credibility"), UiKit.score(party.credibility)],
		[tr("ui.party.radicalism"), UiKit.score(party.radicalism)],
		[tr("ui.party.unity"), UiKit.score(party.unity)],
		[tr("ui.party.scrutiny"), UiKit.score(party.scrutiny)],
		[tr("ui.party.vs_level"), tr("vs_level.%d" % party.vs_level)],
		[tr("ui.party.reach_platform"), UiKit.score(party.reach_platform)],
		[tr("ui.party.contradiction_risk"), UiKit.score(party.contradiction_risk)],
		[tr("ui.party.resilience"), UiKit.score(state.resilience)],
		[tr("ui.party.ideology"), tr("ui.party.ideology_value") % [ideology.x, ideology.y]],
	]))
	content.add_child(UiKit.heading(tr("ui.party.positions")))
	content.add_child(UiKit.hint(tr("ui.party.positions_hint")))
	for topic_id: String in defs.topics:
		var current: Variant = party.positions.get(topic_id)
		var text := tr(topic_id + ".name") + ": " + (UiKit.position(current) if current != null else tr("ui.party.no_position"))
		var buttons: Array = [UiKit.label(text)]
		for value in [-2, -1, 0, 1, 2]:
			if current != null and int(current) == value:
				continue
			var cost := IdeologySystem.change_cost(state, defs, topic_id, value)
			var tooltip := tr("ui.party.change_cost") % cost if cost > 0.0 else ""
			buttons.append(UiKit.button(UiKit.position(value), plan.bind("action.set_position", topic_id, {"value": value}), tooltip))
		content.add_child(UiKit.row(buttons))
	if not party.regional_messages.is_empty():
		content.add_child(UiKit.heading(tr("ui.party.regional_messages")))
		for region_id: String in party.regional_messages:
			for topic_id: String in party.regional_messages[region_id]:
				content.add_child(UiKit.label("%s – %s: %s" % [
					tr(region_id + ".name"), tr(topic_id + ".name"),
					UiKit.position(party.regional_messages[region_id][topic_id]),
				]))
	content.add_child(UiKit.heading(tr("ui.actions")))
	for action_id in [
		"action.social_media_campaign", "action.press_conference", "action.win_influencer",
		"action.discredit_opponents", "action.party_congress", "action.purge",
	]:
		content.add_child(action_button(action_id))
	var topic_choice := UiKit.choice(_topic_entries())
	content.add_child(UiKit.row([
		topic_choice,
		UiKit.button(tr("action.outrage_wave.name"), func() -> void:
			plan("action.outrage_wave", UiKit.chosen(topic_choice)), tr("action.outrage_wave.description")),
	]))
	content.add_child(UiKit.heading(tr("ui.party.donors")))
	for donor_id: String in defs.donors:
		var donor := state.donors[donor_id]
		var status := tr("ui.party.donor_status") % [
			UiKit.score(donor.satisfaction), UiKit.money(DonorSystem.payment(state, defs, donor_id)),
		]
		if not donor.active:
			status = tr("ui.party.donor_withdrawn")
		content.add_child(UiKit.label(tr(donor_id + ".name") + ": " + status))
		if donor.active:
			content.add_child(UiKit.row([
				action_button("action.court_donor", donor_id),
				action_button("action.accept_large_donation", donor_id),
				action_button("action.third_party_funding", donor_id),
			]))
	content.add_child(UiKit.heading(tr("ui.party.rivals")))
	for rival: RivalPartyDef in defs.rivals.values():
		content.add_child(UiKit.label(tr("ui.party.rival_status") % [
			tr(rival.id + ".name"), RivalSystem.national_strength(defs, rival),
			RivalSystem.attitude(defs, rival, ideology, party),
		]))


func _topic_entries() -> Array:
	var entries := []
	for topic_id: String in session.defs.topics:
		entries.append([tr(topic_id + ".name"), topic_id])
	return entries
