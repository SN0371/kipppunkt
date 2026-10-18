class_name SidePanel
extends ScrollContainer
## Base class of the tabs in the side bar. A panel rebuilds its content from the session
## on every change; the amount of content is small enough for that.

## Emitted with a translated message for the status line.
signal message(text: String)

## Tint of buttons whose action is already planned this turn.
const PLANNED_TINT := Color(0.75, 1.0, 0.8)

var session: GameSession
## Content container that refresh() fills.
var content: VBoxContainer
var _dialogs: Array[ContentDialog] = []
## Feedback on the last planning attempt in this panel, shown at the top until the turn ends.
var _notice: String = ""
var _notice_ok: bool = true


## Prepares the panel; call before it enters the tree.
func setup(game_session: GameSession) -> void:
	session = game_session
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	add_child(content)
	# Deferred: a slider or drop-down that triggered the change must not be freed while
	# its signal is still being handled; several changes in one frame rebuild only once.
	session.changed.connect(refresh, CONNECT_DEFERRED)
	session.turn_finished.connect(func(_report: Array[Dictionary]) -> void: _notice = "")


## Rebuilds the content.
func refresh() -> void:
	UiKit.clear(content)
	if not session.has_game():
		return
	if not _notice.is_empty():
		var notice := UiKit.label(_notice)
		notice.add_theme_color_override("font_color", Color(0.55, 0.9, 0.6) if _notice_ok else Color(1.0, 0.55, 0.5))
		content.add_child(notice)
	build()


## Fills the content; overridden by each panel.
func build() -> void:
	pass


## Plans an order and reports the result in the status line. The responsible staff member
## carries it out; the planning panel lets the chair take it over.
func plan(action_id: String, target: String = "", fields: Dictionary = {}) -> void:
	report(action_id, session.plan(ActionOrder.create(action_id, target, fields)))


## Reports the result of planning an action in the status line and in open overlays.
func report(action_id: String, reason: String) -> void:
	var text := tr("ui.planned") % tr(action_id + ".name")
	if not reason.is_empty():
		text = tr("ui.not_planned") % [tr(action_id + ".name"), LogFormatter.reason_text(reason)]
	message.emit(text)
	_notice = text
	_notice_ok = reason.is_empty()
	if not _notice_ok:
		refresh.call_deferred()
	for dialog in _dialogs:
		if dialog.visible:
			dialog.show_message(text)


## Creates an overlay owned by this panel; the builder fills its content.
func make_dialog(title_key: String, builder: Callable) -> ContentDialog:
	var dialog := ContentDialog.new()
	dialog.setup(session, tr(title_key), builder)
	dialog.get_cancel_button().visible = false
	dialog.ok_button_text = tr("ui.close")
	add_child(dialog)
	_dialogs.append(dialog)
	return dialog


## Returns a button that plans an action, labelled with its name and costs. It shows how often
## the action is already planned and is disabled, with the reason as tooltip, if the action
## cannot be planned now. An optional callback replaces the default "plan this order", for
## example when the target comes from a drop-down at the time of the click.
func action_button(
	action_id: String, target: String = "", fields: Dictionary = {}, on_press: Callable = Callable()
) -> Button:
	var def := session.defs.actions[action_id]
	var costs := PackedStringArray()
	if def.cost_action_points > 0:
		costs.append(tr("ui.cost.action_points") % def.cost_action_points)
	if def.cost_money > 0.0:
		costs.append(UiKit.money(def.cost_money))
	if def.cost_activists > 0:
		costs.append(tr("ui.cost.activists") % def.cost_activists)
	var text := tr(action_id + ".name")
	if not costs.is_empty():
		text += " (" + ", ".join(costs) + ")"
	var count := session.planned_count(action_id, target)
	if count > 0:
		text += "  ✓ " + tr("ui.planned_count") % count
	var callback := on_press if on_press.is_valid() else plan.bind(action_id, target, fields)
	var button := UiKit.button(text, callback, tr(action_id + ".description"))
	if count > 0:
		button.modulate = PLANNED_TINT
	var reason := session.check(ActionOrder.create(action_id, target, fields))
	if not reason.is_empty():
		button.disabled = true
		button.tooltip_text = tr("ui.not_possible") % LogFormatter.reason_text(reason)
	return button
