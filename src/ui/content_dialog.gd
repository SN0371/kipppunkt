class_name ContentDialog
extends ConfirmationDialog
## Overlay whose content is built by a callback and rebuilt whenever the session changes,
## so it always shows the current budget and plan. Used for actions, donors, regional
## messages and the end of a turn.

## Share of the window the dialog takes.
const SIZE_RATIO := 0.6

var session: GameSession
var content: VBoxContainer
## Last message, for example why an order could not be planned.
var info: Label
var _builder: Callable


## Prepares the dialog. The builder receives the content container and fills it.
func setup(game_session: GameSession, dialog_title: String, builder: Callable) -> void:
	session = game_session
	title = dialog_title
	_builder = builder
	var root := VBoxContainer.new()
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	root.add_child(scroll)
	info = UiKit.hint("")
	root.add_child(info)
	add_child(root)
	session.changed.connect(_on_changed, CONNECT_DEFERRED)


## Builds the content and shows the dialog.
func open() -> void:
	info.text = ""
	rebuild()
	popup_centered_ratio(SIZE_RATIO)


## Rebuilds the content from the current state.
func rebuild() -> void:
	UiKit.clear(content)
	_builder.call(content)


## Shows a message below the content.
func show_message(text: String) -> void:
	info.text = text


func _on_changed() -> void:
	if visible:
		rebuild()
