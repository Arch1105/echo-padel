extends Control
class_name EmoteMenu
## Accessible in-match overlay (LAN only - see EmoteMenuHandler.gd, which
## owns pausing the tree and instantiating this) listing the player's owned
## emotes (see OnlineData.gd/Emotes.gd). Picking one plays it immediately -
## locally right away, and relayed to the opponent (see NetworkSession.
## play_emote()) - and closes the menu. Same dynamically-built-button-list
## pattern as EmoteStore.gd, since the owned set varies player to player.

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
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("emote_menu"):
		_close()
		get_viewport().set_input_as_handled()

func _on_emote_pressed(emote_id: String) -> void:
	NetworkSession.play_emote(emote_id)
	_close()

func _close() -> void:
	closed.emit()
