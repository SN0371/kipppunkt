extends GutTest
## Tests loading, saving and applying the player's display settings.

const PATH := "user://test_settings.cfg"


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func test_defaults_without_file() -> void:
	assert_eq(UiSettings.load_from(PATH).ui_scale, UiSettings.DEFAULT_SCALE)


func test_round_trip() -> void:
	var settings := UiSettings.new()
	settings.ui_scale = 150
	assert_eq(settings.save_to(PATH), OK)
	assert_eq(UiSettings.load_from(PATH).ui_scale, 150)


func test_unknown_scale_falls_back_to_default() -> void:
	var file := ConfigFile.new()
	file.set_value(UiSettings.SECTION, "ui_scale", 333)
	file.save(PATH)
	assert_eq(UiSettings.load_from(PATH).ui_scale, UiSettings.DEFAULT_SCALE)


func test_apply_sets_window_scale() -> void:
	var window := Window.new()
	var settings := UiSettings.new()
	settings.ui_scale = 175
	settings.apply(window)
	assert_almost_eq(window.content_scale_factor, 1.75, 0.0001)
	window.free()
