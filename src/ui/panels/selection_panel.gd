class_name SelectionPanel
extends SidePanel
## Details of the land or institution selected on the map, with the actions available
## there (game-design.md section 3.3).

## Selected land id or place id; empty shows a hint.
var selection: String = ""


## Shows a land or a place.
func select(id: String) -> void:
	selection = id
	refresh()


## Fills the content.
func build() -> void:
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
	content.add_child(UiKit.grid([
		[tr("ui.land.polling"), UiKit.percent(land.polling)],
		[tr("ui.land.turnout"), UiKit.percent(land.turnout)],
		[tr("ui.land.gap"), UiKit.percent(land.representation_gap * 100.0)],
		[tr("ui.land.media_climate"), "%+.2f" % land.media_climate],
		[tr("ui.land.classic_reach"), UiKit.score(land.classic_reach)],
		[tr("ui.land.landtag"), tr("ui.yes") if land.in_landtag else tr("ui.no")],
		[tr("ui.land.last_state_result"), UiKit.percent(land.last_state_result)],
		[tr("ui.land.last_municipal_result"), UiKit.percent(land.last_municipal_result)],
		[tr("ui.land.anchoring"), UiKit.score(session.state.regions[land_def.region].anchoring)],
	]))
	content.add_child(UiKit.heading(tr("ui.land.topics")))
	var topic_rows := []
	for topic_id: String in defs.topics:
		topic_rows.append([
			tr(topic_id + ".name"),
			tr("ui.land.topic_value") % [land_def.topic_weights[topic_id], UiKit.position(land_def.topic_preferences[topic_id])],
		])
	content.add_child(UiKit.grid(topic_rows))
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
	var topic_choice := UiKit.choice(_topic_entries())
	var value_choice := UiKit.choice(_value_entries())
	content.add_child(UiKit.row([topic_choice, value_choice]))
	content.add_child(UiKit.button(
		tr("action.regional_message.name") + " (" + tr("ui.cost.action_points") % 1 + ")",
		func() -> void: plan("action.regional_message", region, {
			"topic": UiKit.chosen(topic_choice), "value": UiKit.chosen(value_choice),
		}),
		tr("action.regional_message.description")
	))


func _build_media(media_id: String) -> void:
	var house := session.state.media[media_id]
	var ideology := IdeologySystem.profile(session.state.party, session.defs)
	var tone: float = MediaSystem.tones(session.state, session.defs, ideology)[media_id]
	content.add_child(UiKit.heading(tr(media_id + ".name")))
	content.add_child(UiKit.grid([
		[tr("ui.media.reach"), UiKit.score(house.reach)],
		[tr("ui.media.credibility"), UiKit.score(house.credibility)],
		[tr("ui.media.independence"), UiKit.score(house.independence)],
		[tr("ui.media.tone"), "%+.2f" % tone],
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
			]))
		"institution.domestic_intelligence":
			content.add_child(UiKit.grid([
				[tr("ui.party.vs_level"), tr("vs_level.%d" % party.vs_level)],
				[tr("ui.party.scrutiny"), UiKit.score(party.scrutiny)],
			]))
	content.add_child(UiKit.hint(tr(place_id + ".description")))


func _topic_entries() -> Array:
	var entries := []
	for topic_id: String in session.defs.topics:
		entries.append([tr(topic_id + ".name"), topic_id])
	return entries


func _value_entries() -> Array:
	var entries := []
	for value in [2, 1, 0, -1, -2]:
		entries.append([tr("position.%d" % value), value])
	return entries
