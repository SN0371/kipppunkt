class_name JsonReader
extends RefCounted
## Reads typed values from parsed JSON data and collects validation errors.
##
## Every accessor returns a safe default when a value is missing or invalid and
## records an error instead of failing, so a whole file is checked in one pass.
## JSON numbers arrive as floats; integer accessors verify that they are integral.

var errors: PackedStringArray = PackedStringArray()


## Returns true if no errors have been recorded.
func is_ok() -> bool:
	return errors.is_empty()


## Records an error message for the given context (file, id or field path).
func error(ctx: String, message: String) -> void:
	errors.append("%s: %s" % [ctx, message])


## Reads a required string field.
func read_string(d: Dictionary, key: String, ctx: String) -> String:
	if not _require(d, key, ctx):
		return ""
	if typeof(d[key]) != TYPE_STRING:
		error(ctx, "field '%s' must be a string" % key)
		return ""
	return d[key]


## Reads a required string field whose value must be one of the allowed values.
func read_enum(d: Dictionary, key: String, ctx: String, allowed: PackedStringArray) -> String:
	var value := read_string(d, key, ctx)
	if not d.has(key) or typeof(d[key]) != TYPE_STRING:
		return value
	if not allowed.has(value):
		error(ctx, "field '%s' must be one of %s, got '%s'" % [key, allowed, value])
	return value


## Reads a required boolean field.
func read_bool(d: Dictionary, key: String, ctx: String) -> bool:
	if not _require(d, key, ctx):
		return false
	if typeof(d[key]) != TYPE_BOOL:
		error(ctx, "field '%s' must be true or false" % key)
		return false
	return d[key]


## Reads an optional boolean field, returning the default if it is missing.
func read_optional_bool(d: Dictionary, key: String, ctx: String, default: bool) -> bool:
	return read_bool(d, key, ctx) if d.has(key) else default


## Reads an optional string field, returning the default if it is missing.
func read_optional_string(d: Dictionary, key: String, ctx: String, default: String) -> String:
	return read_string(d, key, ctx) if d.has(key) else default


## Reads a required number field within an inclusive range.
func read_float(
	d: Dictionary, key: String, ctx: String, min_value: float = -INF, max_value: float = INF
) -> float:
	if not _require(d, key, ctx):
		return 0.0
	return check_float(d[key], "%s.%s" % [ctx, key], min_value, max_value)


## Reads a required integer field within an inclusive range.
func read_int(
	d: Dictionary, key: String, ctx: String, min_value: int = -2147483648, max_value: int = 2147483647
) -> int:
	if not _require(d, key, ctx):
		return 0
	return check_int(d[key], "%s.%s" % [ctx, key], min_value, max_value)


## Reads a required 64-bit integer stored as a decimal string.
## Used for seeds and generator states, which JSON numbers cannot hold exactly.
func read_int64_string(d: Dictionary, key: String, ctx: String) -> int:
	var text := read_string(d, key, ctx)
	if not d.has(key) or typeof(d[key]) != TYPE_STRING:
		return 0
	if not text.is_valid_int():
		error(ctx, "field '%s' must be an integer string, got '%s'" % [key, text])
		return 0
	return text.to_int()


## Reads a required two-element number array as a vector, each component within [-max_abs, max_abs].
func read_vector2(d: Dictionary, key: String, ctx: String, max_abs: float = INF) -> Vector2:
	if not _require(d, key, ctx):
		return Vector2.ZERO
	var value: Variant = d[key]
	if typeof(value) != TYPE_ARRAY or (value as Array).size() != 2:
		error(ctx, "field '%s' must be an array of two numbers" % key)
		return Vector2.ZERO
	var path := "%s.%s" % [ctx, key]
	var x := check_float(value[0], path + "[0]", -max_abs, max_abs)
	var y := check_float(value[1], path + "[1]", -max_abs, max_abs)
	return Vector2(x, y)


## Reads a required object field.
func read_dict(d: Dictionary, key: String, ctx: String) -> Dictionary:
	if not _require(d, key, ctx):
		return {}
	if typeof(d[key]) != TYPE_DICTIONARY:
		error(ctx, "field '%s' must be an object" % key)
		return {}
	return d[key]


## Reads a required array field.
func read_array(d: Dictionary, key: String, ctx: String) -> Array:
	if not _require(d, key, ctx):
		return []
	if typeof(d[key]) != TYPE_ARRAY:
		error(ctx, "field '%s' must be an array" % key)
		return []
	return d[key]


## Reads a required array of strings.
func read_string_array(d: Dictionary, key: String, ctx: String) -> PackedStringArray:
	var result := PackedStringArray()
	for i in read_array(d, key, ctx).size():
		var item: Variant = d[key][i]
		if typeof(item) != TYPE_STRING:
			error(ctx, "field '%s[%d]' must be a string" % [key, i])
		else:
			result.append(item)
	return result


## Reads a required object mapping ids to numbers within an inclusive range.
func read_float_map(
	d: Dictionary, key: String, ctx: String, min_value: float = -INF, max_value: float = INF
) -> Dictionary[String, float]:
	var result: Dictionary[String, float] = {}
	var raw := read_dict(d, key, ctx)
	for id: String in raw:
		result[id] = check_float(raw[id], "%s.%s.%s" % [ctx, key, id], min_value, max_value)
	return result


## Reads a required object mapping ids to integers within an inclusive range.
func read_int_map(
	d: Dictionary, key: String, ctx: String, min_value: int, max_value: int
) -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	var raw := read_dict(d, key, ctx)
	for id: String in raw:
		result[id] = check_int(raw[id], "%s.%s.%s" % [ctx, key, id], min_value, max_value)
	return result


## Validates that a value is a number within an inclusive range.
func check_float(value: Variant, ctx: String, min_value: float = -INF, max_value: float = INF) -> float:
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		error(ctx, "must be a number")
		return 0.0
	var number := float(value)
	if number < min_value or number > max_value:
		error(ctx, "must be within [%s, %s], got %s" % [min_value, max_value, number])
	return number


## Validates that a value is an integral number within an inclusive range.
func check_int(value: Variant, ctx: String, min_value: int, max_value: int) -> int:
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		error(ctx, "must be an integer")
		return 0
	var number := float(value)
	if number != floorf(number):
		error(ctx, "must be an integer, got %s" % number)
		return 0
	if number < min_value or number > max_value:
		error(ctx, "must be within [%d, %d], got %d" % [min_value, max_value, int(number)])
	return int(number)


func _require(d: Dictionary, key: String, ctx: String) -> bool:
	if not d.has(key):
		error(ctx, "missing field '%s'" % key)
		return false
	return true
