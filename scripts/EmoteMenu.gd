extends Control
class_name EmoteMenu
## Accessible in-match overlay (LAN only - see EmoteMenuHandler.gd, which
## owns pausing the tree and instantiating this) listing the player's owned
## emotes (see OnlineData.gd/Emotes.gd). Picking one plays it immediately -
## locally right away, and relayed to the opponent (see NetworkSession.
## play_emote()) - and closes the menu. Same dynamically-built-button-list
## pattern as EmoteStore.gd, since the owned set varies player to player.
##
## Keyboard/screen-reader users navigate with the native Up/Down focus chain
## and ui_accept, same as every other menu here. On a controller, Left/Right
## bumper instead cycle the highlighted emote (see _cycle()) and A/Cross
## activates it via the same native focus system - ui_accept already
## triggers a focused Button's pressed signal for free. Left Shift/bumper
## doubles as this overlay's *open* trigger (see EmoteMenuHandler.gd) and,
## once open, "cycle previous" here; Right Shift/bumper ("emote_next") reuses
## the same physical key as PlayerController's drop-shot button, safely,
## since gameplay input is fully suspended (tree paused) while this is open.
## ui_cancel (or the Close button) is the only way out now - emote_menu no
## longer closes the menu, so it's free to mean "previous" instead.

signal closed

@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var emote_list: VBoxContainer = $Panel/VBoxContainer/EmoteList
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_label.text = Loc.t("emote_menu_title")
	title_label.accessibility_name = Loc.t("emote_menu_title")
	close_button.text = Loc.t("back_button")
	close_button.accessibility_name = Loc.t("back_button")
	close_button.pressed.connect(_close)

	if Emotes.CATALOG.is_empty() or OnlineData.owned_emotes.is_empty():
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_label.custom_minimum_size = Vector2(360, 0)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.text = Loc.t("emote_menu_empty")
		empty_label.accessibility_name = Loc.t("emote_menu_empty")
		emote_list.add_child(empty_label)
		close_button.grab_focus()
		return

	for entry in Emotes.CATALOG:
		var emote_id: String = entry["id"]
		if not OnlineData.owns_emote(emote_id):
			continue
		var emote_name: String = Loc.t(entry["name_key"])
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(320, 48)
		btn.focus_mode = Control.FOCUS_ALL
		btn.text = emote_name
		btn.accessibility_name = emote_name
		btn.accessibility_description = Loc.t("emote_menu_play_desc")
		btn.pressed.connect(_on_emote_pressed.bind(emote_id))
		emote_list.add_child(btn)

	if emote_list.get_child_count() > 0:
		emote_list.get_child(0).grab_focus()
	else:
		close_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("emote_menu"):
		_cycle(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("emote_next"):
		_cycle(1)
		get_viewport().set_input_as_handled()

## Moves focus to the previous/next emote button, wrapping around - the
## controller-friendly alternative to Up/Down. A no-op on the empty state
## (a Label, not a button list).
func _cycle(direction: int) -> void:
	var buttons: Array = emote_list.get_children()
	if buttons.is_empty():
		return
	var current: Control = get_viewport().gui_get_focus_owner()
	var idx: int = buttons.find(current)
	idx = 0 if idx == -1 else (idx + direction + buttons.size()) % buttons.size()
	buttons[idx].grab_focus()

func _on_emote_pressed(emote_id: String) -> void:
	NetworkSession.play_emote(emote_id)
	_close()

func _close() -> void:
	closed.emit()
