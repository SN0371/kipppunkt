class_name GameDefs
extends RefCounted
## Content definitions loaded from the JSON data directory (prototyp-plan.md section 3).
##
## Load with load_from_dir() and check is_valid() before use. Definitions are
## read-only after loading; dynamic values live in GameState.

## Area or region value meaning "the whole federation".
const NATIONAL := "national"
## List files in the data directory, keyed by their name in the raw data.
const LIST_FILES: Dictionary = {
	"topics": "topics.json",
	"regions": "regions.json",
	"lands": "lands.json",
	"rivals": "parties.json",
	"media": "media.json",
	"donors": "donors.json",
	"crises": "crises.json",
}
const PARAMS_FILE := "params.json"
const SCENARIO_DIR := "scenarios"
## Allowed deviation of the summed population shares from 1.
const POPULATION_TOLERANCE := 0.01

var errors: PackedStringArray = PackedStringArray()
var params: ParamSet = ParamSet.new()
var topics: Dictionary[String, TopicDef] = {}
var regions: Dictionary[String, RegionDef] = {}
var lands: Dictionary[String, LandDef] = {}
var rivals: Dictionary[String, RivalPartyDef] = {}
var media: Dictionary[String, MediaDef] = {}
var donors: Dictionary[String, DonorDef] = {}
var crises: Dictionary[String, CrisisDef] = {}
var scenarios: Dictionary[String, ScenarioDef] = {}


## Returns true if all definitions loaded without errors.
func is_valid() -> bool:
	return errors.is_empty()


## Loads and validates all data files from a directory such as "res://data".
static func load_from_dir(dir_path: String) -> GameDefs:
	var reader := JsonReader.new()
	var raw := read_raw_dir(dir_path, reader)
	return from_raw(raw, reader)


## Reads all data files of a directory into plain parsed JSON without validating the content.
## File and syntax errors are recorded in the reader.
static func read_raw_dir(dir_path: String, reader: JsonReader) -> Dictionary:
	var raw: Dictionary = {}
	raw["params"] = _read_json_file(dir_path.path_join(PARAMS_FILE), reader)
	for key: String in LIST_FILES:
		raw[key] = _read_json_file(dir_path.path_join(LIST_FILES[key]), reader)
	var scenario_dir := dir_path.path_join(SCENARIO_DIR)
	var scenarios_raw: Array = []
	raw["scenarios"] = scenarios_raw
	if not DirAccess.dir_exists_absolute(scenario_dir):
		reader.error(scenario_dir, "directory not found")
		return raw
	var file_names := DirAccess.get_files_at(scenario_dir)
	file_names.sort()
	for file_name in file_names:
		if file_name.get_extension() == "json":
			scenarios_raw.append(_read_json_file(scenario_dir.path_join(file_name), reader))
	return raw


## Builds and validates definitions from parsed JSON as returned by read_raw_dir().
## Errors already recorded in the given reader are kept.
static func from_raw(raw: Dictionary, reader: JsonReader = null) -> GameDefs:
	if reader == null:
		reader = JsonReader.new()
	var defs := GameDefs.new()
	if typeof(raw.get("params")) == TYPE_DICTIONARY:
		defs.params = ParamSet.from_dict(raw["params"], reader)
	else:
		reader.error("params", "must be an object")
	for item in _items(raw, "topics", reader):
		_add_unique(defs.topics, TopicDef.from_dict(item, reader), "topics", reader)
	for item in _items(raw, "regions", reader):
		_add_unique(defs.regions, RegionDef.from_dict(item, reader), "regions", reader)
	for item in _items(raw, "lands", reader):
		_add_unique(defs.lands, LandDef.from_dict(item, reader), "lands", reader)
	for item in _items(raw, "rivals", reader):
		_add_unique(defs.rivals, RivalPartyDef.from_dict(item, reader), "parties", reader)
	for item in _items(raw, "media", reader):
		_add_unique(defs.media, MediaDef.from_dict(item, reader), "media", reader)
	for item in _items(raw, "donors", reader):
		_add_unique(defs.donors, DonorDef.from_dict(item, reader), "donors", reader)
	for item in _items(raw, "crises", reader):
		_add_unique(defs.crises, CrisisDef.from_dict(item, reader), "crises", reader)
	for item in _items(raw, "scenarios", reader):
		_add_unique(defs.scenarios, ScenarioDef.from_dict(item, reader), "scenarios", reader)
	defs._validate_references(reader)
	defs.errors = reader.errors
	return defs


## Returns true if the value is "national" or a known region id.
func is_area(value: String) -> bool:
	return value == NATIONAL or regions.has(value)


func _validate_references(reader: JsonReader) -> void:
	_validate_lands(reader)
	for region: RegionDef in regions.values():
		if region.lands.is_empty():
			reader.error("regions[%s]" % region.id, "has no lands")
	for rival: RivalPartyDef in rivals.values():
		check_same_ids(rival.strength.keys(), lands.keys(), "parties[%s].strength" % rival.id, reader)
	for land_id: String in lands:
		var total := 0.0
		for rival: RivalPartyDef in rivals.values():
			total += rival.strength.get(land_id, 0.0)
		if total >= 100.0:
			reader.error("parties", "rival strengths in %s add up to %s, must stay below 100" % [land_id, total])
	for house: MediaDef in media.values():
		if not is_area(house.area):
			reader.error("media[%s]" % house.id, "unknown area '%s'" % house.area)
	for donor: DonorDef in donors.values():
		var ctx := "donors[%s]" % donor.id
		if not is_area(donor.region):
			reader.error(ctx, "unknown region '%s'" % donor.region)
		_check_known_ids(donor.topic_preferences.keys(), topics, ctx + ".topic_preferences", reader)
	for crisis: CrisisDef in crises.values():
		_check_known_ids(crisis.salience.keys(), topics, "crises[%s].salience" % crisis.id, reader)
	for scenario: ScenarioDef in scenarios.values():
		_validate_scenario(scenario, reader)


func _validate_lands(reader: JsonReader) -> void:
	var population_sum := 0.0
	for land: LandDef in lands.values():
		var ctx := "lands[%s]" % land.id
		if regions.has(land.region):
			regions[land.region].lands.append(land.id)
		else:
			reader.error(ctx, "unknown region '%s'" % land.region)
		check_same_ids(land.topic_weights.keys(), topics.keys(), ctx + ".topics", reader)
		population_sum += land.population_share
	if not lands.is_empty() and absf(population_sum - 1.0) > POPULATION_TOLERANCE:
		reader.error("lands", "population shares add up to %s, expected 1" % population_sum)


func _validate_scenario(scenario: ScenarioDef, reader: JsonReader) -> void:
	var ctx := "scenarios[%s]" % scenario.id
	_check_known_ids(Array(scenario.playable_regions), regions, ctx + ".playable_regions", reader)
	_check_known_ids(scenario.anchoring.keys(), regions, ctx + ".anchoring", reader)
	for i in scenario.elections.size():
		var election := scenario.elections[i]
		if election.type != "federal" and not lands.has(election.land):
			reader.error("%s.elections[%d]" % [ctx, i], "unknown land '%s'" % election.land)


## Records an error for every id that is not a key of the known dictionary.
static func _check_known_ids(ids: Array, known: Dictionary, ctx: String, reader: JsonReader) -> void:
	for id: String in ids:
		if not known.has(id):
			reader.error(ctx, "unknown id '%s'" % id)


## Records errors for unknown and missing ids, so a set of ids matches the expected one exactly.
static func check_same_ids(ids: Array, expected: Array, ctx: String, reader: JsonReader) -> void:
	for id: String in ids:
		if not expected.has(id):
			reader.error(ctx, "unknown id '%s'" % id)
	for id: String in expected:
		if not ids.has(id):
			reader.error(ctx, "missing id '%s'" % id)


static func _add_unique(target: Dictionary, def: Variant, file: String, reader: JsonReader) -> void:
	var id: String = def.id
	if id.is_empty():
		return
	if target.has(id):
		reader.error(file, "duplicate id '%s'" % id)
		return
	target[id] = def


## Returns the objects of a raw list, recording errors for anything that is not an object.
static func _items(raw: Dictionary, key: String, reader: JsonReader) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var value: Variant = raw.get(key)
	if typeof(value) != TYPE_ARRAY:
		reader.error(key, "must be an array")
		return result
	for i in (value as Array).size():
		if typeof(value[i]) == TYPE_DICTIONARY:
			result.append(value[i])
		else:
			reader.error("%s[%d]" % [key, i], "must be an object")
	return result


static func _read_json_file(path: String, reader: JsonReader) -> Variant:
	if not FileAccess.file_exists(path):
		reader.error(path, "file not found")
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		reader.error(path, "invalid JSON in line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return null
	return json.data
