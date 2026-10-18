class_name SelectionPanel
extends SidePanel
## Details of the land or institution selected on the map, with the actions available
## there (game-design.md section 3.3). The representation gap stays internal: players
## infer it from the turnout.

## Selected land id or place id; empty shows a hint.
var selection: String = ""
var _message_dialog: ContentDialog
var _message_topic: String = ""
var _message_value: int = 2


## Shows a land or a place.
func select(id: String) -> void:
	selection = id
	refresh()


## Fills the content.
func build() -> void:
	if _message_dialog == null:
		_message_dialog = make_dialog("action.regional_message.name", _build_message_dialog)
	if selection.is_empty():
		content.add_child(UiKit.hint(tr("ui.selection.hint")))
	elif session.defs.lands.has(selection):
		_build_land(selection)
	elif session.defs.media.has(selection):
		_build_media(selection)
	else:
		_build_institution(selection)


func _build_land(land_id: String) -> void:
	var defs := session.defs
	var land_def := defs.lands[land_id]
	var land := session.state.lands[land_id]
	content.add_child(UiKit.heading(tr(land_id + ".name")))
	content.add_child(UiKit.hint(tr(land_def.region + ".name")))
	content.add_child(UiKit.label(tr(land_id + ".description")))
	content.add_child(UiKit.grid([
		[tr("ui.land.polling"), UiKit.percent(land.polling)],
		[tr("ui.land.turnout"), UiKit.percent(land.turnout), tr("ui.land.turnout_hint")],
		[tr("ui.land.media_climate"), "%+.2f" % land.media_climate, tr("ui.land.media_climate_hint")],
		[tr("ui.land.classic_reach"), UiKit.score(land.classic_reach), tr("ui.land.classic_reach_hint")],
		[tr("ui.land.anchoring"), UiKit.score(session.state.regions[land_def.region].anchoring), tr("ui.land.anchoring_hint")],
		[tr("ui.land.landtag"), tr("ui.yes") if land.in_landtag else tr("ui.no")],
		[tr("ui.land.last_state_result"), UiKit.percent(land.last_state_result)],
		[tr("ui.land.last_municipal_result"), UiKit.percent(land.last_municipal_result)],
	]))
	content.add_child(UiKit.heading(tr("ui.land.elections")))
	content.add_child(UiKit.grid([
		[tr("ui.land.next_municipal"), _election_text("municipal", land_id)],
		[tr("ui.land.next_state"), _election_text("state", land_id)],
		[tr("ui.land.next_federal"), _election_text("federal", land_id)],
	]))
	content.add_child(UiKit.heading(tr("ui.land.rivals")))
	var rival_rows := []
	for rival: RivalPartyDef in defs.rivals.values():
		rival_rows.append([tr(rival.id + ".name"), UiKit.percent(rival.strength[land_id])])
	content.add_child(UiKit.grid(rival_rows))
	var region := land_def.region
	if not defs.scenarios[session.state.scenario_id].playable_regions.has(region):
		content.add_child(UiKit.hint(tr("ui.land.not_playable")))
		return
	content.add_child(UiKit.heading(tr("ui.actions")))
	if ElectionSystem.land_votes(session.state, defs, land_id):
		content.add_child(action_button("action.campaign", land_id))
	content.add_child(action_button("action.found_local_branch", region))
	content.add_child(action_button("action.club_presence", region))
	content.add_child(UiKit.button(tr("action.regional_message.name") + " …", _open_message_dialog,
		tr("action.regional_message.description")))


func _election_text(type: String, land_id: String) -> String:
	var turn := ElectionSystem.next_turn(session.state, session.defs, type, land_id)
	if turn < 0:
		return tr("ui.land.no_election")
	var turns := turn - session.state.turn
	var when := tr("ui.land.this_turn") if turns == 0 else tr("ui.land.in_turns") % turns
	return "%s (%s)" % [when, UiKit.quarter_label(session.date_of(turn))]


func _open_message_dialog() -> void:
	var addressed := session.state.party.positions.keys()
	if not addressed.has(_message_topic):
		_message_topic = addressed[0] if not addressed.is_empty() else ""
	_message_dialog.open()


## Overlay for a regional message: explanation, topic and position.
func _build_message_dialog(box: VBoxContainer) -> void:
	var region := session.defs.lands[selection].region if session.defs.lands.has(selection) else ""
	if region.is_empty():
		return
	box.add_child(UiKit.heading(tr("ui.message.title") % tr(region + ".name")))
	box.add_child(UiKit.label(tr("ui.message.explanation")))
	var entries := []
	var addressed: Array = session.state.party.positions.keys()
	for topic_id: String in session.defs.topics:
		if addressed.has(topic_id):
			entries.append([tr(topic_id + ".name"), topic_id])
	if entries.is_empty() or _message_topic.is_empty():
		box.add_child(UiKit.hint(tr("ui.message.no_topics")))
		return
	var topic_choice := UiKit.choice(entries)
	for i in entries.size():
		if entries[i][1] == _message_topic:
			topic_choice.selected = i
	topic_choice.item_selected.connect(func(index: int) -> void:
		_message_topic = topic_choice.get_item_metadata(index)
		_message_dialog.rebuild.call_deferred())
	box.add_child(topic_choice)
	var federal: int = session.state.party.positions.get(_message_topic, 0)
	var current: Variant = session.state.party.regional_messages.get(region, {}).get(_message_topic)
	box.add_child(UiKit.grid([
		[tr("ui.message.federal"), tr("position.%d" % federal)],
		[tr("ui.message.current"), tr("position.%d" % int(current)) if current != null else tr("ui.message.none")],
	]))
	var value_label := UiKit.label(tr("ui.message.choose") + " " + tr("position.%d" % _message_value))
	box.add_child(value_label)
	box.add_child(UiKit.position_slider(_message_value, func(value: int) -> void:
		_message_value = value
		value_label.text = tr("ui.message.choose") + " " + tr("position.%d" % value)))
	box.add_child(UiKit.hint(tr("ui.message.risk")))
	var plan_button := UiKit.button(tr("ui.message.plan"), func() -> void:
		plan("action.regional_message", region, {"topic": _message_topic, "value": _message_value}))
	var reason := session.check(ActionOrder.create("action.regional_message", region, {"topic": _message_topic, "value": 2}))
	if not reason.is_empty():
		plan_button.disabled = true
		plan_button.tooltip_text = tr("ui.not_possible") % LogFormatter.reason_text(reason)
	var count := session.planned_count("action.regional_message", region)
	if count > 0:
		box.add_child(UiKit.label("✓ " + tr("ui.planned_count") % count))
	box.add_child(plan_button)


func _build_media(media_id: String) -> void:
	var house := session.state.media[media_id]
	var ideology := IdeologySystem.profile(session.state.party, session.defs)
	var tone: float = MediaSystem.tones(session.state, session.defs, ideology)[media_id]
	content.add_child(UiKit.heading(tr(media_id + ".name")))
	content.add_child(UiKit.grid([
		[tr("ui.media.reach"), UiKit.score(house.reach)],
		[tr("ui.media.credibility"), UiKit.score(house.credibility)],
		[tr("ui.media.independence"), UiKit.score(house.independence)],
		[tr("ui.media.tone"), "%+.2f" % tone, tr("ui.media.tone_hint")],
	]))
	content.add_child(UiKit.hint(tr("ui.media.not_playable")))


func _build_institution(place_id: String) -> void:
	var party := session.state.party
	content.add_child(UiKit.heading(tr(place_id + ".name")))
	match place_id:
		"institution.bundestag":
			content.add_child(UiKit.grid([
				[tr("ui.bundestag.member"), tr("ui.yes") if party.in_bundestag else tr("ui.no")],
				[tr("ui.bundestag.last_result"), UiKit.percent(party.last_federal_result)],
				[tr("ui.bundestag.national_polling"), UiKit.percent(PollingSystem.national(session.state, session.defs))],
				[tr("ui.land.next_federal"), _election_text("federal", "")],
			]))
		"institution.domestic_intelligence":
			content.add_child(UiKit.grid([
				[tr("ui.party.vs_level"), tr("vs_level.%d" % party.vs_level)],
				[tr("ui.party.scrutiny"), UiKit.score(party.scrutiny)],
			]))
	content.add_child(UiKit.hint(tr(place_id + ".description")))
