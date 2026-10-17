class_name SidePanel
extends ScrollContainer
## Base class of the tabs in the side bar. A panel rebuilds its content from the session
## on every change; the amount of content is small enough for that.

## Emitted with a translated message for the status line.
signal message(text: String)

var session: GameSession
## Content container that refresh() fills.
var content: VBoxContainer


## Prepares the panel; call before it enters the tree.
func setup(game_session: GameSession) -> void:
	session = game_session
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	add_child(content)
	session.changed.connect(refresh)


## Rebuilds the content.
func refresh() -> void:
	UiKit.clear(content)
	if session.has_game():
		build()


## Fills the content; overridden by each panel.
func build() -> void:
	pass


## Plans an order and reports the result in the status line.
## Delegable actions are carried out by the performer chosen in the planning panel.
func plan(action_id: String, target: String = "", fields: Dictionary = {}) -> void:
	var def := session.defs.actions[action_id]
	var order_fields := fields.duplicate()
	if def.delegable and not session.performer.is_empty() and not order_fields.has("performer"):
		order_fields["performer"] = session.performer
	var reason := session.plan(ActionOrder.create(action_id, target, order_fields))
	if reason.is_empty():
		message.emit(tr("ui.planned") % tr(action_id + ".name"))
	else:
		message.emit(tr("ui.not_planned") % [tr(action_id + ".name"), LogFormatter.reason_text(reason)])


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
