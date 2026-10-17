class_name StateCompare
extends RefCounted
## Compares serialized game states, allowing tiny float differences.
##
## Godot's float parsing is not exact in the last binary digit, so a state loaded
## from JSON can differ from the saved one by about 1e-16 relative. Everything
## else (integers, strings, structure) must match exactly.

const RELATIVE_TOLERANCE := 1e-9


## Returns the paths at which two serialized states differ beyond the tolerance.
static func differences(a: Variant, b: Variant, path: String = "") -> PackedStringArray:
	var result := PackedStringArray()
	_compare(a, b, path, result)
	return result


static func _compare(a: Variant, b: Variant, path: String, result: PackedStringArray) -> void:
	if _is_number(a) and _is_number(b):
		var scale := maxf(1.0, maxf(absf(float(a)), absf(float(b))))
		if absf(float(a) - float(b)) > RELATIVE_TOLERANCE * scale:
			result.append("%s: %s != %s" % [path, a, b])
		return
	if typeof(a) != typeof(b):
		result.append("%s: type %s != %s" % [path, type_string(typeof(a)), type_string(typeof(b))])
		return
	match typeof(a):
		TYPE_DICTIONARY:
			for key: Variant in a:
				if not (b as Dictionary).has(key):
					result.append("%s.%s: missing" % [path, key])
				else:
					_compare(a[key], b[key], "%s.%s" % [path, key], result)
			for key: Variant in b:
				if not (a as Dictionary).has(key):
					result.append("%s.%s: unexpected" % [path, key])
		TYPE_ARRAY:
			if (a as Array).size() != (b as Array).size():
				result.append("%s: size %d != %d" % [path, a.size(), b.size()])
				return
			for i in (a as Array).size():
				_compare(a[i], b[i], "%s[%d]" % [path, i], result)
		_:
			if a != b:
				result.append("%s: %s != %s" % [path, a, b])


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT
