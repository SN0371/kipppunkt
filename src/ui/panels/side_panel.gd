class_name SidePanel
extends ScrollContainer
## Base class of the tabs in the side bar. A panel rebuilds its content from the session
## on every change; the amount of content is small enough for that.

## Emitted with a translated message for the status line.
signal message(text: String)

var session: GameSession
## Content container that refresh() fills.
var content: VBoxContainer
var _dialogs: Array[ContentDialog] = []


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


## Rebuilds the content.
func refresh() -> void:
	UiKit.clear(content)
	if session.has_game():
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


## Returns a button that plans an action, labelled with its name and costs.
func action_button(action_id: String, target: String = "", fields: Dictionary = {}) -> Button:
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
	return UiKit.button(text, plan.bind(action_id, target, fields), tr(action_id + ".description"))
