class_name SaveGame
extends RefCounted
## Writes game states as JSON and reads them back (prototyp-plan.md section 3).
##
## Save files are plain data and never execute code when loaded, so they can be
## shared safely.

## Increase when the save format changes incompatibly.
const FORMAT_VERSION := 2


## Serializes a game state to JSON. Floats are written with full precision; Godot's float
## parsing may still differ in the last binary digit (about 1e-16 relative) when loading.
## Integers, strings, the seed and the generator state round-trip exactly.
static func to_json(state: GameState) -> String:
	var data := {"format_version": FORMAT_VERSION, "state": state.to_dict()}
	return JSON.stringify(data, "\t", true, true)


## Parses JSON written by to_json() and checks it against the definitions.
## Returns null and records the reasons in the reader if the data is not usable.
static func from_json(text: String, defs: GameDefs, reader: JsonReader) -> GameState:
	var json := JSON.new()
	if json.parse(text) != OK:
		reader.error("save", "invalid JSON in line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return null
	if typeof(json.data) != TYPE_DICTIONARY:
		reader.error("save", "must be an object")
		return null
	var data: Dictionary = json.data
	var version := reader.read_int(data, "format_version", "save")
	if reader.is_ok() and version != FORMAT_VERSION:
		reader.error("save", "unsupported format version %d, expected %d" % [version, FORMAT_VERSION])
	var state_raw := reader.read_dict(data, "state", "save")
	if not reader.is_ok():
		return null
	var state := GameState.from_dict(state_raw, reader)
	if reader.is_ok():
		state.validate_against(defs, reader)
	return state if reader.is_ok() else null


## Writes a game state to a file.
static func save_to_file(state: GameState, path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(to_json(state))
	return file.get_error()


## Reads a game state from a file. Returns null and records the reasons in the reader on failure.
static func load_from_file(path: String, defs: GameDefs, reader: JsonReader) -> GameState:
	if not FileAccess.file_exists(path):
		reader.error(path, "file not found")
		return null
	return from_json(FileAccess.get_file_as_string(path), defs, reader)
