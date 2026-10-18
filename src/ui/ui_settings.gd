class_name UiSettings
extends RefCounted
## Settings of the player that are not part of a game, stored in user://settings.cfg.

const PATH := "user://settings.cfg"
const SECTION := "display"
## Selectable sizes of the user interface, in percent.
const SCALES: Array[int] = [80, 100, 125, 150, 175, 200]
const DEFAULT_SCALE := 100

## Size of the user interface in percent; scales text, buttons and spacing alike.
var ui_scale: int = DEFAULT_SCALE


## Loads the settings; missing or invalid values fall back to the defaults.
static func load_from(path: String = PATH) -> UiSettings:
	var settings := UiSettings.new()
	var file := ConfigFile.new()
	if file.load(path) == OK:
		var value: Variant = file.get_value(SECTION, "ui_scale", DEFAULT_SCALE)
		if typeof(value) == TYPE_INT and SCALES.has(value):
			settings.ui_scale = value
	return settings


## Saves the settings.
func save_to(path: String = PATH) -> Error:
	var file := ConfigFile.new()
	file.set_value(SECTION, "ui_scale", ui_scale)
	return file.save(path)


## Applies the interface size to a window. The project stretches the interface with the
## window's pixel size (high-resolution screens); this factor comes on top.
func apply(window: Window) -> void:
	window.content_scale_factor = ui_scale / 100.0
