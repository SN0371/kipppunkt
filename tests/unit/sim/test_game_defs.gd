extends GutTest
## Tests loading and validation of the content definitions.

const DATA_DIR := "res://data"


func test_shipped_data_loads_without_errors() -> void:
	var defs := GameDefs.load_from_dir(DATA_DIR)
	assert_eq(defs.errors, PackedStringArray(), "Shipped data must be valid")
	assert_eq(defs.lands.size(), 16, "16 lands")
	assert_eq(defs.regions.size(), 6, "6 regions")
	assert_eq(defs.topics.size(), 8, "8 MVP topics")
	assert_eq(defs.contradictions.size(), 5, "5 contradictions")
	assert_eq(defs.rivals.size(), 3, "3 rival parties")
	assert_eq(defs.media.size(), 5, "5 media houses")
	assert_eq(defs.crises.size(), 2, "2 MVP crises")
	assert_true(defs.scenarios.has("scenario.new_party"), "Scenario 'new party' exists")


func test_regions_get_their_lands_from_land_definitions() -> void:
	var defs := GameDefs.load_from_dir(DATA_DIR)
	assert_eq(defs.regions["region.south"].lands, PackedStringArray(["land.bw", "land.by"]))
	assert_eq(defs.regions["region.east"].lands.size(), 5)


func test_rivals_are_spread_evenly_around_the_centre() -> void:
	var defs := GameDefs.load_from_dir(DATA_DIR)
	for rival: RivalPartyDef in defs.rivals.values():
		assert_almost_eq(rival.ideology.length(), 35.0, 0.5, "%s radius" % rival.id)


func test_parameters_match_the_data_file() -> void:
	var defs := GameDefs.load_from_dir(DATA_DIR)
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_DIR.path_join("params.json")))
	for name: String in raw:
		assert_eq(defs.params.value(name), float(raw[name]["value"]), name)


func test_missing_topic_in_land_is_reported() -> void:
	var raw := _raw_data()
	raw["lands"][0]["topics"].erase("topic.welfare")
	var defs := GameDefs.from_raw(raw)
	assert_true(_has_error(defs, "lands[land.bw].topics", "missing id 'topic.welfare'"))


func test_unknown_region_reference_is_reported() -> void:
	var raw := _raw_data()
	raw["lands"][0]["region"] = "region.atlantis"
	var defs := GameDefs.from_raw(raw)
	assert_true(_has_error(defs, "lands[land.bw]", "unknown region 'region.atlantis'"))


func test_out_of_range_value_is_reported() -> void:
	var raw := _raw_data()
	raw["lands"][0]["topics"]["topic.taxes"]["weight"] = 7
	var defs := GameDefs.from_raw(raw)
	assert_true(_has_error(defs, "topic.taxes.weight", "must be within [0, 3]"))


func test_non_integer_is_reported() -> void:
	var raw := _raw_data()
	raw["lands"][0]["topics"]["topic.taxes"]["preference"] = 1.5
	var defs := GameDefs.from_raw(raw)
	assert_true(_has_error(defs, "topic.taxes.preference", "must be an integer"))


func test_duplicate_id_is_reported() -> void:
	var raw := _raw_data()
	raw["topics"].append(raw["topics"][0].duplicate(true))
	var defs := GameDefs.from_raw(raw)
	assert_true(_has_error(defs, "topics", "duplicate id 'topic.wind_power'"))


func test_population_shares_must_add_up_to_one() -> void:
	var raw := _raw_data()
	raw["lands"][0]["population_share"] = 0.5
	var defs := GameDefs.from_raw(raw)
	assert_true(_has_error(defs, "lands", "population shares add up to"))


func test_unknown_parameter_is_reported() -> void:
	var raw := _raw_data()
	raw["params"]["topic_wieght"] = {"symbol": "P_T", "value": 1.0}
	var defs := GameDefs.from_raw(raw)
	assert_true(_has_error(defs, "params.topic_wieght", "unknown parameter"))


func test_missing_parameter_is_reported() -> void:
	var raw := _raw_data()
	raw["params"].erase("topic_weight")
	var defs := GameDefs.from_raw(raw)
	assert_true(_has_error(defs, "params", "missing parameter 'topic_weight'"))


func test_election_in_unknown_land_is_reported() -> void:
	var raw := _raw_data()
	raw["scenarios"][0]["elections"][0]["land"] = "land.xx"
	var defs := GameDefs.from_raw(raw)
	assert_true(_has_error(defs, "elections[0]", "unknown land 'land.xx'"))


func test_contradiction_with_unknown_topic_is_reported() -> void:
	var raw := _raw_data()
	raw["contradictions"][0]["topics"]["topic.unknown"] = 1
	var defs := GameDefs.from_raw(raw)
	assert_true(_has_error(defs, "contradictions[contradiction.tax_cuts_and_welfare].topics", "unknown id 'topic.unknown'"))


func test_missing_directory_is_reported() -> void:
	var defs := GameDefs.load_from_dir("res://does_not_exist")
	assert_false(defs.is_valid())
	assert_true(_has_error(defs, "params.json", "file not found"))


func _raw_data() -> Dictionary:
	var reader := JsonReader.new()
	var raw := GameDefs.read_raw_dir(DATA_DIR, reader)
	assert_true(reader.is_ok(), "Raw data must be readable")
	return raw


func _has_error(defs: GameDefs, ctx_part: String, message_part: String) -> bool:
	for e in defs.errors:
		if e.contains(ctx_part) and e.contains(message_part):
			return true
	gut.p("Errors were: %s" % [defs.errors])
	return false
