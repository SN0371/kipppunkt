class_name EventDialog
extends AcceptDialog
## Overlay for an event before the turn is planned (rechenmodell.md 5.8): the party takes a
## stand, stays silent, keeps its position or rethinks it. It cannot be dismissed without a
## decision.

## Emitted after the response was given.
signal resolved

## Size of the dialog in interface units; it scales with the window like everything else.
const DIALOG_SIZE := Vector2i(900, 460)

var session: GameSession
var _content: VBoxContainer
var _choice := 0


## Prepares the dialog.
func setup(game_session: GameSession) -> void:
	session = game_session
	get_ok_button().visible = false
	dialog_close_on_escape = false
	# Growing with the content would use the height measured before the labels know their
	# width (one word per line); the dialog has a fixed size instead.
	wrap_controls = false
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	# Wrapping labels need a known width, otherwise they measure themselves one word per line.
	_content.custom_minimum_size = Vector2(DIALOG_SIZE.x - 40, 0)
	add_child(_content)
	canceled.connect(func() -> void: popup_centered.call_deferred(DIALOG_SIZE))


## Shows the pending event, if there is one. Returns true if the dialog opened.
func open_pending() -> bool:
	var event := session.pending_event()
	if event == null:
		return false
	_choice = session.state.party.positions.get(event.topic, 0)
	title = tr("ui.event.title")
	_rebuild()
	popup_centered(DIALOG_SIZE)
	return true


func _rebuild() -> void:
	UiKit.clear(_content)
	var event := session.pending_event()
	if event == null:
		return
	var party := session.state.party
	var addressed := party.positions.has(event.topic)
	_content.add_child(UiKit.heading(tr(event.name_key)))
	var area := tr("ui.map.federation") if event.area == GameDefs.NATIONAL else tr(event.area + ".name")
	_content.add_child(UiKit.hint(area))
	_content.add_child(UiKit.label(tr(event.text_key)))
	_content.add_child(UiKit.heading(tr(event.topic + ".name")))
	if addressed:
		_content.add_child(UiKit.label(tr("ui.event.current") % tr("position.%d" % party.positions[event.topic])))
		_content.add_child(UiKit.hint(tr("ui.event.rethink_hint")))
	else:
		_content.add_child(UiKit.label(tr("ui.event.first_stand")))
	var choice_label := UiKit.label(tr("ui.event.choice") % tr("position.%d" % _choice))
	_content.add_child(choice_label)
	_content.add_child(UiKit.position_slider(_choice, func(value: int) -> void:
		_choice = value
		_rebuild.call_deferred()))
	var buttons: Array = []
	if addressed:
		buttons.append(UiKit.button(tr("ui.event.keep"), _respond.bind(null)))
		var rethink := UiKit.button(tr("ui.event.rethink"), func() -> void: _respond(_choice))
		var cost := IdeologySystem.change_cost(session.state, session.defs, event.topic, _choice)
		rethink.disabled = _choice == party.positions[event.topic]
		rethink.tooltip_text = tr("ui.event.rethink_cost") % cost
		if not rethink.disabled:
			rethink.text += " (" + tr("ui.event.rethink_cost") % cost + ")"
		buttons.append(rethink)
	else:
		buttons.append(UiKit.button(tr("ui.event.take_stand"), func() -> void: _respond(_choice)))
		buttons.append(UiKit.button(
			tr("ui.event.silence") % session.defs.params.value("silence_credibility_cost"), _respond.bind(null)))
	_content.add_child(UiKit.row(buttons))


func _respond(choice: Variant) -> void:
	session.respond_to_event(choice)
	hide()
	resolved.emit()
