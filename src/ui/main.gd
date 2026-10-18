extends Control
## Main screen: top bar, map and side bar with tabs (prototyp-plan.md section 9).
## The layout is built in code so it stays readable in diffs.

const SIDE_BAR_WIDTH := 460
## Share of the usable screen the window takes at start.
const WINDOW_SCREEN_SHARE := 0.85
const ZOOM_REGIONS: PackedStringArray = ["", "region.south", "region.north"]

var session: GameSession
var map_view: MapView
var tabs: TabContainer
var selection_panel: SelectionPanel
var report_panel: ReportPanel
var status_label: Label
var top_bar_label: Label
var legend_label: Label
var save_dialog: ConfirmationDialog
var save_name: LineEdit
var load_dialog: ConfirmationDialog
var load_list: ItemList
var info_dialog: AcceptDialog
var turn_dialog: ContentDialog
## True while the turn dialog shows the results of the resolved turn.
var _showing_results: bool = false
var settings: UiSettings


func _ready() -> void:
	_fit_window_to_screen()
	settings = UiSettings.load_from()
	settings.apply(get_window())
	var defs := GameDefs.load_from_dir("res://data")
	if not defs.is_valid():
		add_child(UiKit.label("Invalid data:\n" + "\n".join(defs.errors)))
		return
	var map := MapData.load_default()
	if map == null:
		add_child(UiKit.label("Map data missing"))
		return
	session = GameSession.new(defs)
	_build(map)
	session.changed.connect(_refresh)
	session.turn_finished.connect(_on_turn_finished)
	new_game()


## Sizes the window to most of the screen in physical pixels. The interface stretches with the
## window (project setting "canvas_items"), so on high-resolution screens it grows with the
## pixel density instead of appearing tiny.
func _fit_window_to_screen() -> void:
	var window := get_window()
	if DisplayServer.get_name() == "headless" or window.is_embedded():
		return
	var screen := DisplayServer.screen_get_usable_rect(window.current_screen)
	var base := Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"),
	)
	var factor := minf(screen.size.x / base.x, screen.size.y / base.y) * WINDOW_SCREEN_SHARE
	window.size = Vector2i(base * factor)
	window.position = screen.position + (screen.size - window.size) / 2


## Starts a new game with a random seed; the seed is shown so a game can be reproduced.
func new_game() -> void:
	var game_seed := randi()
	session.new_game(game_seed)
	selection_panel.select("")
	_set_status(tr("ui.status.new_game") % game_seed)


func _build(map: MapData) -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	top_bar_label = UiKit.label("")
	root.add_child(UiKit.row([
		top_bar_label,
		_build_scale_choice(),
		UiKit.button(tr("ui.new_game"), new_game),
		UiKit.button(tr("ui.save"), _open_save_dialog),
		UiKit.button(tr("ui.load"), _open_load_dialog),
		UiKit.button(tr("ui.end_turn"), _open_turn_dialog),
	]))
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(split)
	split.add_child(_build_map_area(map))
	split.add_child(_build_side_bar())
	status_label = UiKit.label("")
	root.add_child(status_label)
	_build_dialogs()


func _build_scale_choice() -> OptionButton:
	var entries := []
	for scale in UiSettings.SCALES:
		entries.append([tr("ui.settings.ui_scale") % scale, scale])
	var choice := UiKit.choice(entries)
	choice.selected = UiSettings.SCALES.find(settings.ui_scale)
	choice.tooltip_text = tr("ui.settings.ui_scale_hint")
	choice.item_selected.connect(func(index: int) -> void:
		settings.ui_scale = choice.get_item_metadata(index)
		settings.apply(get_window())
		settings.save_to())
	return choice


func _build_map_area(map: MapData) -> Control:
	var area := VBoxContainer.new()
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var overlay_entries := []
	for overlay in MapView.OVERLAYS:
		overlay_entries.append([tr("ui.map.overlay." + overlay), overlay])
	var overlay_choice := UiKit.choice(overlay_entries)
	overlay_choice.item_selected.connect(func(index: int) -> void:
		map_view.set_overlay(overlay_choice.get_item_metadata(index))
		legend_label.text = map_view.legend())
	var controls: Array = [overlay_choice]
	for region_id in ZOOM_REGIONS:
		var text := tr("ui.map.federation") if region_id.is_empty() else tr(region_id + ".name")
		controls.append(UiKit.button(text, func() -> void: map_view.zoom_to(region_id)))
	area.add_child(UiKit.row(controls))
	legend_label = UiKit.hint("")
	area.add_child(legend_label)
	map_view = MapView.new()
	map_view.setup(session, map)
	map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_view.land_selected.connect(_select)
	map_view.place_selected.connect(_select)
	area.add_child(map_view)
	legend_label.text = map_view.legend()
	return area


func _build_side_bar() -> TabContainer:
	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(SIDE_BAR_WIDTH, 0)
	selection_panel = SelectionPanel.new()
	report_panel = ReportPanel.new()
	var entries := [
		["ui.tab.selection", selection_panel],
		["ui.tab.party", PartyPanel.new()],
		["ui.tab.staff", StaffPanel.new()],
		["ui.tab.media", MediaPanel.new()],
		["ui.tab.planning", PlanningPanel.new()],
		["ui.tab.report", report_panel],
	]
	for i in entries.size():
		var panel: SidePanel = entries[i][1]
		panel.setup(session)
		panel.message.connect(_set_status)
		tabs.add_child(panel)
		tabs.set_tab_title(i, tr(entries[i][0]))
	return tabs


func _build_dialogs() -> void:
	save_dialog = ConfirmationDialog.new()
	save_dialog.title = tr("ui.save")
	save_name = LineEdit.new()
	save_name.placeholder_text = tr("ui.save.name")
	save_dialog.add_child(save_name)
	save_dialog.confirmed.connect(_save)
	add_child(save_dialog)
	load_dialog = ConfirmationDialog.new()
	load_dialog.title = tr("ui.load")
	load_list = ItemList.new()
	load_list.custom_minimum_size = Vector2(320, 240)
	load_dialog.add_child(load_list)
	load_dialog.confirmed.connect(_load)
	add_child(load_dialog)
	info_dialog = AcceptDialog.new()
	add_child(info_dialog)
	turn_dialog = ContentDialog.new()
	turn_dialog.setup(session, tr("ui.end_turn"), _build_turn_dialog)
	turn_dialog.confirmed.connect(_on_turn_dialog_confirmed)
	add_child(turn_dialog)


func _refresh() -> void:
	var state := session.state
	var party := state.party
	var budget := session.remaining()
	top_bar_label.text = tr("ui.top_bar") % [
		session.quarter(), session.year(), UiKit.money(budget["money"]),
		budget["action_points"], party.action_points, budget["activists"],
	]


func _select(id: String) -> void:
	selection_panel.select(id)
	tabs.current_tab = 0


## Opens the end-of-turn overlay with the planned orders.
func _open_turn_dialog() -> void:
	if session.state.is_over():
		_set_status(tr("ui.status.game_over"))
		return
	_showing_results = false
	turn_dialog.get_cancel_button().visible = true
	turn_dialog.ok_button_text = tr("ui.end_turn")
	turn_dialog.open()


## Resolves the turn without the overlay (also used by tests).
func _end_turn() -> void:
	if not session.state.is_over():
		session.end_turn()


func _on_turn_dialog_confirmed() -> void:
	if _showing_results:
		return
	_end_turn()
	_showing_results = true
	turn_dialog.get_cancel_button().visible = false
	turn_dialog.ok_button_text = tr("ui.close")
	turn_dialog.rebuild()
	turn_dialog.popup_centered_ratio(ContentDialog.SIZE_RATIO)


## First the planned orders, after confirming the results of the turn.
func _build_turn_dialog(box: VBoxContainer) -> void:
	if _showing_results:
		box.add_child(UiKit.heading(tr("ui.turn.results")))
		for entry in session.last_report:
			var text := LogFormatter.format(entry, session.defs)
			if not text.is_empty():
				box.add_child(UiKit.label("• " + text))
		if session.state.is_over():
			box.add_child(UiKit.heading(tr("outcome." + session.state.outcome)))
			box.add_child(UiKit.label(tr("outcome." + session.state.outcome + ".description")))
		return
	box.add_child(UiKit.heading(tr("ui.turn.planned") % [session.quarter(), session.year()]))
	if session.planned.is_empty():
		box.add_child(UiKit.hint(tr("ui.planning.no_orders")))
	for order in session.planned:
		box.add_child(UiKit.label("• " + PlanningPanel.order_text(order)))
	var budget := session.remaining()
	box.add_child(UiKit.hint(tr("ui.turn.unused") % [budget["action_points"], UiKit.money(budget["money"])]))


func _on_turn_finished(_report: Array[Dictionary]) -> void:
	tabs.current_tab = tabs.get_tab_idx_from_control(report_panel)


func _open_save_dialog() -> void:
	save_name.text = "%d-Q%d" % [session.year(), session.quarter()]
	save_dialog.popup_centered(Vector2i(360, 120))


func _save() -> void:
	var error := session.save(save_name.text)
	_set_status(tr("ui.status.saved") % save_name.text if error == OK else tr("ui.status.save_failed") % error_string(error))


func _open_load_dialog() -> void:
	load_list.clear()
	for slot in GameSession.save_slots():
		load_list.add_item(slot)
	load_dialog.popup_centered(Vector2i(360, 320))


func _load() -> void:
	var selected := load_list.get_selected_items()
	if selected.is_empty():
		return
	var slot := load_list.get_item_text(selected[0])
	var problem := session.load_game(slot)
	if problem.is_empty():
		selection_panel.select("")
		_set_status(tr("ui.status.loaded") % slot)
	else:
		info_dialog.title = tr("ui.load")
		info_dialog.dialog_text = tr("ui.status.load_failed") + "\n" + problem
		info_dialog.popup_centered()


func _set_status(text: String) -> void:
	status_label.text = text
