extends GutTest
## Every translation key the game uses exists in German and English (prototyp-plan.md 6).

const LANGUAGES := ["de", "en"]

var _keys: Dictionary = {}


func before_all() -> void:
	for language in LANGUAGES:
		_keys[language] = _read_po_keys("res://i18n/%s.po" % language)


func after_all() -> void:
	TranslationServer.set_locale("de")


func test_languages_have_the_same_keys() -> void:
	var german: Array = _keys["de"].keys()
	var english: Array = _keys["en"].keys()
	german.sort()
	english.sort()
	assert_eq(german, english)


func test_literal_keys_in_ui_code_exist() -> void:
	var pattern := RegEx.create_from_string("tr\\(\"([a-z0-9_.]+)\"\\)")
	for path in _gd_files("res://src/ui"):
		for found in pattern.search_all(FileAccess.get_file_as_string(path)):
			_assert_key(found.get_string(1), path)


func test_content_names_exist() -> void:
	var defs := SimFixture.defs()
	for group in [defs.lands, defs.regions, defs.topics, defs.rivals, defs.media, defs.donors, defs.crises, defs.actions, defs.scenarios]:
		for def: Variant in (group as Dictionary).values():
			_assert_key(def.name_key, "data")
	for action_id: String in defs.actions:
		_assert_key(action_id + ".description", "data")
	for event: EventDef in defs.events.values():
		_assert_key(event.name_key, "events")
		_assert_key(event.text_key, "events")
	for place_id: String in MapData.load_default().places:
		_assert_key(place_id + ".name", "map")


func test_dynamic_keys_exist() -> void:
	for role in PersonState.ROLES:
		if not role.is_empty():
			_assert_key("role." + role, "roles")
	for agenda in PersonState.AGENDAS:
		_assert_key("agenda." + agenda, "agendas")
	for level in 4:
		_assert_key("vs_level.%d" % level, "levels")
	for value in range(-2, 3):
		_assert_key("position.%d" % value, "positions")
	for outcome in GameState.OUTCOMES:
		if not outcome.is_empty():
			_assert_key("outcome." + outcome, "outcomes")
			_assert_key("outcome." + outcome + ".description", "outcomes")
	for overlay in MapView.OVERLAYS:
		_assert_key("ui.map.overlay." + overlay, "overlays")
		_assert_key("ui.map.legend." + overlay, "overlays")


func test_every_rejection_reason_is_translated() -> void:
	var pattern := RegEx.create_from_string("return \"([a-z ]+)\"")
	for path in ["res://src/sim/actions/action_resolver.gd", "res://src/ui/game_session.gd"]:
		for found in pattern.search_all(FileAccess.get_file_as_string(path)):
			_assert_key("reason." + found.get_string(1).replace(" ", "_"), path)


func test_every_report_line_is_translated() -> void:
	var defs := SimFixture.defs()
	var order := {"action": "action.found_local_branch", "target": "region.south"}
	var entries := {
		"action": {"order": order, "success": false},
		"order_rejected": {"order": order, "reason": "not enough money"},
		"action_abandoned": {"order": order},
		"position_set": {"topic": "topic.taxes", "value": 1.0, "credibility_cost": 2.5},
		"regional_message_set": {"region": "region.south", "topic": "topic.taxes", "value": -2.0},
		"income": {"fees": 1.0, "donations": 2.0, "state_funding": 3.0, "costs": 4.0},
		"crisis_omen": {"crisis": "crisis.energy"},
		"crisis_started": {"crisis": "crisis.energy"},
		"crisis_ended": {"crisis": "crisis.energy"},
		"crisis_false_alarm": {"crisis": "crisis.energy"},
		"election": {"type": "state", "land": "land.by", "result": 6.0, "seats": true, "turnout": 70.0},
		"surveillance_level": {"level": 2.0, "raised": true},
		"press_exposed_contradiction": {},
		"press_exposed_funding": {},
		"press_exposed_insider": {"person": "person.3"},
		"media_conflict": {"media": "media.tabloid", "winner": "owner"},
		"media_new_owner": {"media": "media.tabloid"},
		"donor_withdrew": {"donor": "donor.real_estate"},
		"donor_returned": {"donor": "donor.real_estate"},
		"person_left": {"role": "treasurer"},
		"agenda_revealed": {"agenda": "informant"},
		"purge": {"removed": ["person.1"]},
		"phase": {"phase": 2.0},
		"game_over": {"outcome": "won"},
	}
	assert_eq(entries.keys().size(), LogFormatter.SHOWN_KINDS.size(), "Every shown kind has a sample")
	for language in LANGUAGES:
		TranslationServer.set_locale(language)
		for kind: String in entries:
			var text := LogFormatter.format({"turn": 1.0, "kind": kind, "data": entries[kind]}, defs)
			assert_false(text.is_empty(), kind)
			assert_false(text.contains("log.") or text.contains(".name") or text.contains("reason."),
				"%s/%s untranslated: %s" % [language, kind, text])


func _assert_key(key: String, source: String) -> void:
	for language in LANGUAGES:
		assert_true(_keys[language].has(key), "%s: missing '%s' (%s)" % [language, key, source])


func _read_po_keys(path: String) -> Dictionary:
	var keys := {}
	for line in FileAccess.get_file_as_string(path).split("\n"):
		if line.begins_with("msgid \"") and line != "msgid \"\"":
			keys[line.trim_prefix("msgid \"").trim_suffix("\"")] = true
	return keys


func _gd_files(dir: String) -> PackedStringArray:
	var files := PackedStringArray()
	for file_name in DirAccess.get_files_at(dir):
		if file_name.get_extension() == "gd":
			files.append(dir.path_join(file_name))
	for sub in DirAccess.get_directories_at(dir):
		files.append_array(_gd_files(dir.path_join(sub)))
	return files
