class_name PartyPanel
extends SidePanel
## The party: indicators, positions as sliders, contradictions and rivals. Party-wide
## actions and donors open as overlays.

const PARTY_ACTIONS: PackedStringArray = [
	"action.social_media_campaign", "action.press_conference", "action.win_influencer",
	"action.discredit_opponents", "action.party_congress", "action.purge",
]

var _actions_dialog: ContentDialog
var _donors_dialog: ContentDialog
var _outrage_topic: String = ""
## Folded state per section; open by default are indicators, positions and contradictions.
var _folded: Dictionary = {"indicators": false, "positions": false, "contradictions": false}


## Fills the content. Sections can be folded; the folded state survives rebuilds.
func build() -> void:
	if _actions_dialog == null:
		_actions_dialog = make_dialog("ui.party.actions", _build_actions)
		_donors_dialog = make_dialog("ui.party.donors", _build_donors)
	var state := session.state
	var defs := session.defs
	var party := state.party
	content.add_child(UiKit.row([
		UiKit.button(tr("ui.party.actions") + " …", _actions_dialog.open),
		UiKit.button(tr("ui.party.donors") + " …", _donors_dialog.open),
	]))
	var ideology := IdeologySystem.profile(party, defs)
	var indicators := _section("indicators", tr("ui.party.indicators"))
	indicators.add_child(UiKit.grid([
		[tr("ui.party.credibility"), UiKit.score(party.credibility), tr("ui.party.credibility_hint")],
		[tr("ui.party.radicalism"), UiKit.score(party.radicalism)],
		[tr("ui.party.unity"), UiKit.score(party.unity)],
		[tr("ui.party.scrutiny"), UiKit.score(party.scrutiny)],
		[tr("ui.party.vs_level"), tr("vs_level.%d" % party.vs_level)],
		[tr("ui.party.reach_platform"), UiKit.score(party.reach_platform)],
		[tr("ui.party.contradiction_risk"), UiKit.score(party.contradiction_risk), tr("ui.party.contradiction_risk_hint")],
		[tr("ui.party.members"), str(party.members)],
		[tr("ui.party.resilience"), UiKit.score(state.resilience)],
		[tr("ui.party.ideology"), tr("ui.party.ideology_value") % [ideology.x, ideology.y]],
	]))
	var positions := _section("positions", tr("ui.party.positions"))
	positions.add_child(UiKit.hint(tr("ui.party.positions_hint")))
	for topic_id: String in defs.topics:
		_add_position_row(positions, topic_id)
	var contradictions := IdeologySystem.active_contradictions(party, defs)
	if not contradictions.is_empty():
		var box := _section("contradictions", tr("ui.party.contradictions"))
		for id: String in contradictions:
			box.add_child(UiKit.label("• " + tr(id + ".name")))
		box.add_child(UiKit.hint(tr("ui.party.contradictions_hint") % (
			defs.params.value("inconsistency_penalty") * IdeologySystem.inconsistency(party, defs))))
	if not party.regional_messages.is_empty():
		var box := _section("messages", tr("ui.party.regional_messages"))
		for region_id: String in party.regional_messages:
			for topic_id: String in party.regional_messages[region_id]:
				box.add_child(UiKit.label("%s – %s: %s" % [
					tr(region_id + ".name"), tr(topic_id + ".name"),
					tr("position.%d" % int(party.regional_messages[region_id][topic_id])),
				]))
	var rivals := _section("rivals", tr("ui.party.rivals"))
	for rival: RivalPartyDef in defs.rivals.values():
		rivals.add_child(UiKit.label(tr("ui.party.rival_status") % [
			tr(rival.id + ".name"), RivalSystem.national_strength(defs, rival),
			RivalSystem.attitude(defs, rival, ideology, party),
		]))


func _section(key: String, title: String) -> VBoxContainer:
	return UiKit.section(content, title, _folded.get(key, true), func(folded: bool) -> void: _folded[key] = folded)


func _add_position_row(box: VBoxContainer, topic_id: String) -> void:
	var intended := session.intended_position(topic_id)
	var text := tr(topic_id + ".name") + ": " + (tr("position.%d" % intended) if intended != 0 else tr("ui.party.no_position"))
	if session.is_position_planned(topic_id):
		text += " " + tr("ui.party.planned_marker")
	box.add_child(UiKit.label(text))
	var slider := UiKit.position_slider(intended, func(value: int) -> void:
		report("action.set_position", session.plan_position(topic_id, value)))
	var reason := ""
	if not session.is_position_planned(topic_id):
		# Probe with any other value: what blocks a change is the budget, not the value.
		var probe := 1 if intended != 1 else -1
		reason = session.check(ActionOrder.create("action.set_position", topic_id, {"value": probe}))
	if not reason.is_empty():
		slider.editable = false
		slider.modulate = Color(1, 1, 1, 0.5)
	var cost_hints := PackedStringArray()
	for value in [-2, -1, 0, 1, 2]:
		var cost := IdeologySystem.change_cost(session.state, session.defs, topic_id, value)
		if cost > 0.0:
			cost_hints.append("%s: −%.1f" % [UiKit.position(value), cost])
	slider.tooltip_text = tr("ui.party.slider_hint")
	if not cost_hints.is_empty():
		slider.tooltip_text += "\n" + tr("ui.party.change_costs") + " " + ", ".join(cost_hints)
	if not reason.is_empty():
		slider.tooltip_text = tr("ui.not_possible") % LogFormatter.reason_text(reason)
	box.add_child(slider)


## Overlay with the party-wide actions.
func _build_actions(box: VBoxContainer) -> void:
	_add_budget(box)
	for action_id in PARTY_ACTIONS:
		box.add_child(action_button(action_id))
		box.add_child(UiKit.hint(tr(action_id + ".description")))
	if _outrage_topic.is_empty():
		_outrage_topic = session.defs.topics.keys()[0]
	var entries := []
	for topic_id: String in session.defs.topics:
		entries.append([tr(topic_id + ".name"), topic_id])
	var topic_choice := UiKit.choice(entries)
	topic_choice.selected = session.defs.topics.keys().find(_outrage_topic)
	topic_choice.item_selected.connect(func(index: int) -> void: _outrage_topic = topic_choice.get_item_metadata(index))
	box.add_child(UiKit.row([topic_choice, _outrage_button()]))
	box.add_child(UiKit.hint(tr("action.outrage_wave.description")))


## Returns the outrage button; the topic comes from the drop-down at the time of the click.
func _outrage_button() -> Button:
	return action_button("action.outrage_wave", _outrage_topic, {}, func() -> void:
		plan("action.outrage_wave", _outrage_topic))


## Overlay with the donors and the funding actions.
func _build_donors(box: VBoxContainer) -> void:
	var state := session.state
	var defs := session.defs
	_add_budget(box)
	box.add_child(UiKit.hint(tr("ui.party.donors_hint")))
	for donor_id: String in defs.donors:
		var donor := state.donors[donor_id]
		box.add_child(UiKit.heading(tr(donor_id + ".name")))
		if not donor.active:
			box.add_child(UiKit.label(tr("ui.party.donor_withdrawn")))
			continue
		var wishes := PackedStringArray()
		var preferences := defs.donors[donor_id].topic_preferences
		for topic_id: String in preferences:
			wishes.append("%s %s" % [tr(topic_id + ".name"), UiKit.position(preferences[topic_id])])
		box.add_child(UiKit.grid([
			[tr("ui.party.donor_satisfaction"), UiKit.score(donor.satisfaction)],
			[tr("ui.party.donor_payment"), UiKit.money(DonorSystem.payment(state, defs, donor_id))],
			[tr("ui.party.donor_wishes"), ", ".join(wishes)],
		]))
		box.add_child(UiKit.row([
			action_button("action.court_donor", donor_id),
			action_button("action.accept_large_donation", donor_id),
			action_button("action.third_party_funding", donor_id),
		]))


func _add_budget(box: VBoxContainer) -> void:
	var budget := session.remaining()
	box.add_child(UiKit.label(tr("ui.budget_line") % [budget["action_points"], UiKit.money(budget["money"]), budget["activists"]]))
