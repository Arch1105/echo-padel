extends Control
## LAN matchmaking screen: no manual IP entry (see NetworkSession.gd) - just
## broadcasts and listens on the local network until another Echo Padel copy
## shows up, then connects and drops both players into Match.tscn. Purely
## regular (non-Career) scoring for now - see NetworkSession.gd's class doc
## comment for why Career mode and LAN matches don't currently mix.

const REASSURANCE_INTERVAL := 12.0

@onready var title_label: Label = $VBoxContainer/Title
@onready var name_prompt_label: Label = $VBoxContainer/NamePrompt
@onready var name_input: LineEdit = $VBoxContainer/NameInput
@onready var search_button: Button = $VBoxContainer/SearchButton
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var cancel_button: Button = $VBoxContainer/CancelButton

var _connecting: bool = false
var _searching: bool = false
var _reassurance_timer: Timer

func _ready() -> void:
	get_tree().paused = false
	Music.stop_music()
	_apply_text()
	name_input.text = GameSettings.online_player_name if GameSettings.online_player_name != "" else _fallback_player_name()
	search_button.pressed.connect(_on_search_pressed)
	name_input.text_submitted.connect(_on_name_submitted)
	cancel_button.pressed.connect(_on_cancel_pressed)
	NetworkSession.opponent_connected.connect(_on_opponent_connected)
	NetworkSession.connection_failed.connect(_on_connection_failed)
	name_input.grab_focus()

	_reassurance_timer = Timer.new()
	_reassurance_timer.wait_time = REASSURANCE_INTERVAL
	_reassurance_timer.timeout.connect(func() -> void:
		if _searching and not _connecting:
			Voice.say_dynamic(Loc.t("lan_still_searching_message"))
	)
	add_child(_reassurance_timer)

func _fallback_player_name() -> String:
	var os_name: String = OS.get_environment("USERNAME")
	return os_name if os_name != "" else "Player"

func _on_name_submitted(_text: String) -> void:
	_begin_search()

func _on_search_pressed() -> void:
	_begin_search()

func _begin_search() -> void:
	if _searching:
		return
	_searching = true
	var player_name: String = name_input.text.strip_edges()
	if player_name == "":
		player_name = "Player"
	GameSettings.set_online_player_name(player_name)

	name_prompt_label.visible = false
	name_input.visible = false
	search_button.visible = false
	status_label.visible = true
	cancel_button.grab_focus()

	var message: String = Loc.t("lan_searching_message")
	_set_status(message)
	Voice.say_dynamic(message)
	NetworkSession.begin_search(player_name)
	_reassurance_timer.start()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()

func _apply_text() -> void:
	title_label.text = Loc.t("lan_title")
	title_label.accessibility_name = Loc.t("lan_title")
	name_prompt_label.text = Loc.t("lan_name_prompt")
	name_prompt_label.accessibility_name = Loc.t("lan_name_prompt")
	name_input.placeholder_text = Loc.t("name_input_placeholder")
	name_input.accessibility_name = Loc.t("name_input_placeholder")
	name_input.accessibility_description = Loc.t("lan_name_input_desc")
	search_button.text = Loc.t("lan_search_button")
	search_button.accessibility_name = Loc.t("lan_search_button")
	search_button.accessibility_description = Loc.t("lan_search_desc")
	cancel_button.text = Loc.t("back_button")
	cancel_button.accessibility_name = Loc.t("back_button")
	cancel_button.accessibility_description = Loc.t("lan_cancel_desc")

func _set_status(text: String) -> void:
	status_label.text = text
	status_label.accessibility_name = text

func _on_opponent_connected() -> void:
	if _connecting:
		return
	_connecting = true
	_reassurance_timer.stop()
	var message: String = Loc.t("lan_connected_message") % NetworkSession.opponent_name
	_set_status(message)
	Voice.say_dynamic(message)
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/Match.tscn")

func _on_connection_failed(_reason: String) -> void:
	_reassurance_timer.stop()
	var message: String = Loc.t("lan_failed_message")
	_set_status(message)
	Voice.say_dynamic(message)

func _on_cancel_pressed() -> void:
	NetworkSession.cancel_search()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
