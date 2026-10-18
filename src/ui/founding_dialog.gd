class_name FoundingDialog
extends AcceptDialog
## Founding assistant before the first turn: party name, chair and founding programme of two
## positions (rechenmodell.md 5.8). It cannot be dismissed without founding the party.

## Emitted once the party is founded and the first turn has started.
signal founded

const STEPS := 4
const SIZE_RATIO := 0.7

var session: GameSession
var _suggestions := NameSuggestions.new()
var _content: VBoxContainer
var _step := 0
var _party_name := ""
var _abbreviation := ""
var _chair_name := ""
var _programme := {}


## Prepares the dialog.
func setup(game_session: GameSession) -> void:
	session = game_session
	title = tr("ui.founding.title")
	get_ok_button().visible = false
	dialog_close_on_escape = false
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)
	add_child(scroll)
	# Closing via the title bar would leave the game without a party: show it again.
	canceled.connect(func() -> void: popup_centered_ratio.call_deferred(SIZE_RATIO))


## Starts the assistant with fresh suggestions.
func open() -> void:
	var party := _suggestions.party()
	_party_name = party[0]
	_abbreviation = party[1]
	_chair_name = _suggestions.person()
	_programme = {}
	_step = 0
	_rebuild()
	popup_centered_ratio(SIZE_RATIO)


func _rebuild() -> void:
	UiKit.clear(_content)
	_content.add_child(UiKit.hint(tr("ui.founding.step") % [_step + 1, STEPS]))
	match _step:
		0:
			_build_party()
		1:
			_build_chair()
		2:
			_build_programme()
		3:
			_build_summary()
	_content.add_child(_navigation())


func _build_party() -> void:
	_content.add_child(UiKit.heading(tr("ui.founding.party")))
	_content.add_child(UiKit.label(tr("ui.founding.party_hint")))
	var name_edit := _line_edit(_party_name, tr("ui.founding.party_name"), func(text: String) -> void: _party_name = text)
	var abbreviation_edit := _line_edit(_abbreviation, tr("ui.founding.abbreviation"), func(text: String) -> void: _abbreviation = text)
	abbreviation_edit.max_length = FoundingSystem.MAX_ABBREVIATION_LENGTH
	_content.add_child(UiKit.row([UiKit.label(tr("ui.founding.party_name")), name_edit]))
	_content.add_child(UiKit.row([UiKit.label(tr("ui.founding.abbreviation")), abbreviation_edit]))
	_content.add_child(UiKit.button(tr("ui.founding.suggest"), func() -> void:
		var party := _suggestions.party()
		_party_name = party[0]
		_abbreviation = party[1]
		_rebuild()))


func _build_chair() -> void:
	var chair := PersonSystem.by_role(session.state, "chair")
	_content.add_child(UiKit.heading(tr("ui.founding.chair")))
	_content.add_child(UiKit.label(tr("ui.founding.chair_hint")))
	_content.add_child(UiKit.row([
		UiKit.label(tr("ui.founding.chair_name")),
		_line_edit(_chair_name, tr("ui.founding.chair_name"), func(text: String) -> void: _chair_name = text),
	]))
	_content.add_child(UiKit.button(tr("ui.founding.suggest"), func() -> void:
		_chair_name = _suggestions.person()
		_rebuild()))
	_content.add_child(UiKit.grid([
		[tr("ui.staff.loyalty"), str(roundi(chair.loyalty))],
		[tr("ui.staff.persuasion"), str(roundi(chair.persuasion))],
		[tr("ui.staff.network"), str(roundi(chair.network))],
		[tr("ui.staff.competence"), str(roundi(chair.competence))],
	]))


func _build_programme() -> void:
	var defs := session.defs
	_content.add_child(UiKit.heading(tr("ui.founding.programme")))
	_content.add_child(UiKit.label(tr("ui.founding.programme_hint") % FoundingSystem.FOUNDING_POSITIONS))
	_content.add_child(UiKit.label(tr("ui.founding.chosen") % [_programme.size(), FoundingSystem.FOUNDING_POSITIONS]))
	var south := VoterPreferences.average(defs, PackedStringArray(["region.south"]))
	var north := VoterPreferences.average(defs, PackedStringArray(["region.north"]))
	for topic_id: String in defs.topics:
		var value: int = _programme.get(topic_id, 0)
		var text := tr(topic_id + ".name") + ": " + (tr("position.%d" % value) if value != 0 else tr("ui.founding.not_chosen"))
		_content.add_child(UiKit.label(text))
		_content.add_child(UiKit.hint(tr("ui.founding.regional_mood") % [_mood(south[topic_id]), _mood(north[topic_id])]))
		var full := _programme.size() >= FoundingSystem.FOUNDING_POSITIONS and value == 0
		var slider := UiKit.position_slider(value, func(new_value: int) -> void:
			if new_value == 0:
				_programme.erase(topic_id)
			else:
				_programme[topic_id] = new_value
			_rebuild.call_deferred())
		if full:
			slider.editable = false
			slider.modulate = Color(1, 1, 1, 0.4)
			slider.tooltip_text = tr("ui.founding.full")
		_content.add_child(slider)


func _build_summary() -> void:
	_content.add_child(UiKit.heading(tr("ui.founding.summary")))
	var lines := [
		[tr("ui.founding.party_name"), "%s (%s)" % [_party_name, _abbreviation]],
		[tr("ui.founding.chair_name"), _chair_name],
	]
	for topic_id: String in _programme:
		lines.append([tr(topic_id + ".name"), tr("position.%d" % int(_programme[topic_id]))])
	_content.add_child(UiKit.grid(lines))
	_content.add_child(UiKit.label(tr("ui.founding.summary_hint")))


func _navigation() -> HBoxContainer:
	var buttons: Array = []
	if _step > 0:
		buttons.append(UiKit.button(tr("ui.founding.back"), func() -> void:
			_step -= 1
			_rebuild()))
	var problem := _step_problem()
	var next: Button
	if _step < STEPS - 1:
		next = UiKit.button(tr("ui.founding.next"), func() -> void:
			_step += 1
			_rebuild())
	else:
		next = UiKit.button(tr("ui.founding.found"), _found)
	next.disabled = not problem.is_empty()
	next.tooltip_text = problem
	buttons.append(next)
	return UiKit.row(buttons)


## Returns why the current step cannot be left yet, or an empty string.
func _step_problem() -> String:
	match _step:
		0:
			if _party_name.strip_edges().is_empty() or _abbreviation.strip_edges().is_empty():
				return tr("ui.founding.missing_name")
		1:
			if _chair_name.strip_edges().is_empty():
				return tr("ui.founding.missing_chair")
		2:
			if _programme.size() != FoundingSystem.FOUNDING_POSITIONS:
				return tr("ui.founding.chosen") % [_programme.size(), FoundingSystem.FOUNDING_POSITIONS]
	return ""


func _found() -> void:
	var reason := session.found(_party_name, _abbreviation, _chair_name, _programme)
	if reason.is_empty():
		hide()
		founded.emit()


func _mood(preference: float) -> String:
	if preference >= 1.0:
		return tr("ui.mood.strongly_for")
	if preference >= 0.25:
		return tr("ui.mood.for")
	if preference <= -1.0:
		return tr("ui.mood.strongly_against")
	if preference <= -0.25:
		return tr("ui.mood.against")
	return tr("ui.mood.undecided")


func _line_edit(text: String, placeholder: String, on_change: Callable) -> LineEdit:
	var edit := LineEdit.new()
	edit.text = text
	edit.placeholder_text = placeholder
	edit.max_length = FoundingSystem.MAX_NAME_LENGTH
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(func(new_text: String) -> void:
		on_change.call(new_text)
		_refresh_navigation())
	return edit


## Updates only the navigation buttons while typing, so the text field keeps its focus.
func _refresh_navigation() -> void:
	var last := _content.get_child(_content.get_child_count() - 1)
	_content.remove_child(last)
	last.queue_free()
	_content.add_child(_navigation())
