extends GutTest
## Starts the main screen without graphics and plays a turn through it.

const MAIN_SCENE := preload("res://src/ui/main.tscn")

var _main: Control


func before_each() -> void:
	TranslationServer.set_locale("de")
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(2)


func test_main_screen_starts_a_game() -> void:
	assert_not_null(_main.session)
	assert_true(_main.session.has_game())
	assert_true(_main.top_bar_label.text.begins_with("Q1/2041"), _main.top_bar_label.text)


func test_every_panel_and_overlay_renders() -> void:
	_main.session.plan(ActionOrder.create("action.social_media_campaign"))
	for overlay in MapView.OVERLAYS:
		_main.map_view.set_overlay(overlay)
		_main.map_view.queue_redraw()
		await wait_process_frames(1)
	for region in ["region.south", "region.north", ""]:
		_main.map_view.zoom_to(region)
	for id in ["land.by", "land.be", "institution.bundestag", "institution.domestic_intelligence", "media.public"]:
		_main._select(id)
		await wait_process_frames(1)
		assert_gt(_main.selection_panel.content.get_child_count(), 0, id)
	for i in _main.tabs.get_tab_count():
		_main.tabs.current_tab = i
		await wait_process_frames(1)
		assert_gt((_main.tabs.get_tab_control(i) as SidePanel).content.get_child_count(), 0, "Tab %d" % i)


func test_end_turn_fills_the_report() -> void:
	_main.session.plan(ActionOrder.create("action.set_position", "topic.organic_farming", {"value": -2}))
	_main._end_turn()
	await wait_process_frames(1)
	assert_eq(_main.session.state.turn, 2)
	assert_eq(_main.tabs.get_current_tab_control(), _main.report_panel)
	assert_gt(_main.report_panel.content.get_child_count(), 0)


func test_buttons_show_planned_actions_and_disable_without_budget() -> void:
	_main._select("land.by")
	await wait_process_frames(2)
	var branch := _find_button(_main.selection_panel.content, "action.found_local_branch")
	assert_not_null(branch)
	branch.pressed.emit()
	await wait_process_frames(2)
	branch = _find_button(_main.selection_panel.content, "action.found_local_branch")
	assert_true(branch.text.contains("✓"), branch.text)
	branch.pressed.emit()
	await wait_process_frames(2)
	branch = _find_button(_main.selection_panel.content, "action.found_local_branch")
	assert_true(branch.disabled, "No action points left")
	assert_ne(branch.tooltip_text, "")


func _find_button(node: Node, action_id: String) -> Button:
	var name_text := tr(action_id + ".name")
	for child in node.get_children():
		if child is Button and (child as Button).text.begins_with(name_text):
			return child
		var found := _find_button(child, action_id)
		if found != null:
			return found
	return null
