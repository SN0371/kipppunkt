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


## Returns a two-column grid for [name, value] or [name, value, tooltip] entries.
static func grid(pairs: Array) -> GridContainer:
	var result := GridContainer.new()
	result.columns = 2
	for pair: Array in pairs:
		var tooltip: String = pair[2] if pair.size() > 2 else ""
		var name_label := Label.new()
		name_label.text = pair[0] + (" (?)" if not tooltip.is_empty() else "")
		name_label.modulate = Color(1, 1, 1, 0.75)
		var value_label := Label.new()
		value_label.text = pair[1]
		for item: Label in [name_label, value_label]:
			if not tooltip.is_empty():
				item.tooltip_text = tooltip
				item.mouse_filter = Control.MOUSE_FILTER_PASS
			result.add_child(item)
	return result


## Returns a slider for a position -2..+2; the middle means "no position". The track turns
## green for "for" and red for "against". The callback receives the new value once the
## player lets go (or clicks).
static func position_slider(value: int, on_change: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = -2
	slider.max_value = 2
	slider.step = 1
	slider.tick_count = 5
	slider.ticks_on_borders = true
	slider.value = value
	slider.custom_minimum_size = Vector2(200, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_color_slider(slider, value)
	var dragging := [false]
	slider.drag_started.connect(func() -> void: dragging[0] = true)
	slider.drag_ended.connect(func(changed: bool) -> void:
		dragging[0] = false
		if changed:
			on_change.call(int(slider.value)))
	slider.value_changed.connect(func(new_value: float) -> void:
		_color_slider(slider, int(new_value))
		if not dragging[0]:
			on_change.call(int(new_value)))
	return slider


static func _color_slider(slider: HSlider, value: int) -> void:
	var color := Color(0.45, 0.45, 0.48)
	if value > 0:
		color = Color(0.2, 0.65, 0.3)
	elif value < 0:
		color = Color(0.8, 0.25, 0.25)
	var track := StyleBoxFlat.new()
	track.bg_color = color
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	track.set_corner_radius_all(3)
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", track)
	slider.add_theme_stylebox_override("grabber_area_highlight", track)


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


## Formats a value on a 0..100 scale together with its maximum, for example "20 / 100".
static func score(value: float) -> String:
	return "%d / 100" % roundi(value)


## Formats a turn as "Q3/2042".
static func quarter_label(date: Array[int]) -> String:
	return "Q%d/%d" % [date[1], date[0]]


## Formats a position -2..+2 with sign.
static func position(value: int) -> String:
	return "%+d" % value if value != 0 else "0"
