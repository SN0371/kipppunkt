class_name NameSuggestions
extends RefCounted
## Random fictional names for the founding assistant, from data/names/suggestions.json.
## The combinations are invented; any similarity to real parties or persons is unintended.

const PATH := "res://data/names/suggestions.json"

var _data: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(raw) == TYPE_DICTIONARY:
		_data = raw
	_rng.randomize()


## Returns a random person name like "Jana Keller".
func person() -> String:
	return "%s %s" % [_pick("first_names"), _pick("last_names")]


## Returns a random party name and its abbreviation, for example ["Allianz Zukunft", "AZ"].
func party() -> Array[String]:
	var parts: Array = _pick("party_names")
	if parts.is_empty():
		return ["", ""]
	var party_name := "%s %s" % [parts[0], parts[1]]
	return [party_name, abbreviation(party_name)]


## Returns the initials of the capitalized words of a name, at most four letters.
static func abbreviation(party_name: String) -> String:
	var letters := ""
	for word in party_name.split(" ", false):
		if word[0] == word[0].to_upper() and word[0] != word[0].to_lower():
			letters += word[0]
	return letters.left(4)


func _pick(key: String) -> Variant:
	var items: Array = _data.get(key, [])
	return items[_rng.randi_range(0, items.size() - 1)] if not items.is_empty() else ""
