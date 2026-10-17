class_name UiKit
extends RefCounted
## Small helpers to build the code-defined user interface consistently.

const HEADING_SIZE := 18
const SMALL_SIZE := 13


## Returns a wrapping label.
static func label(text: String) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result


## Returns a section heading.
static func heading(text: String) -> Label:
	var result := label(text)
	result.add_theme_font_size_override("font_size", HEADING_SIZE)
	return result


## Returns a small, muted explanation text.
static func hint(text: String) -> Label:
	var result := label(text)
	result.add_theme_font_size_override("font_size", SMALL_SIZE)
	result.modulate = Color(1, 1, 1, 0.7)
	return result


## Returns a button that calls the callback when pressed.
static func button(text: String, callback: Callable, tooltip: String = "") -> Button:
	var result := Button.new()
	result.text = text
	result.tooltip_text = tooltip
	result.pressed.connect(callback)
	return result


## Returns a horizontal row of controls.
static func row(children: Array) -> HBoxContainer:
	var result := HBoxContainer.new()
	for child: Control in children:
		result.add_child(child)
	return result


## Returns a two-column grid for "name: value" pairs.
static func grid(pairs: Array) -> GridContainer:
	var result := GridContainer.new()
	result.columns = 2
	for pair: Array in pairs:
		var name_label := Label.new()
		name_label.text = pair[0]
		name_label.modulate = Color(1, 1, 1, 0.75)
		result.add_child(name_label)
		var value_label := Label.new()
		value_label.text = pair[1]
		result.add_child(value_label)
	return result


## Returns a drop-down with the given entries [[text, metadata], ...].
static func choice(entries: Array) -> OptionButton:
	var result := OptionButton.new()
	for i in entries.size():
		result.add_item(entries[i][0], i)
		result.set_item_metadata(i, entries[i][1])
	return result


## Returns the metadata of the selected drop-down entry, or null.
static func chosen(option: OptionButton) -> Variant:
	return option.get_item_metadata(option.selected) if option.selected >= 0 else null


## Removes and frees all children of a node.
static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


## Formats a percentage value.
static func percent(value: float) -> String:
	return "%.1f %%" % value


## Formats an amount in thousand euros.
static func money(value: float) -> String:
	return "%d T€" % roundi(value)


## Formats a value on a 0..100 scale.
static func score(value: float) -> String:
	return "%d" % roundi(value)


## Formats a position -2..+2 with sign.
static func position(value: int) -> String:
	return "%+d" % value if value != 0 else "0"
