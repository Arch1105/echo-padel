extends Control
## LAN matchmaking screen: no more auto-discovery broadcast (see
## NetworkSession.gd's class doc comment for why) - one player presses
## Create Room (becomes host immediately, and is shown/spoken their device's
## own network address as the "room code" to read out to the other player)
## and the other presses Join Room and types that code in - a direct
## connection, not a broadcast.
##
## Reached from OnlineModeSelect.tscn, which stages NetworkSession.quick_mode
## before navigating here - this screen just displays whichever mode was
## picked, it doesn't choose it.

@onready var title_label: Label = $VBoxContainer/Title
@onready var name_prompt_label: Label = $VBoxContainer/NamePrompt
@onready var name_input: LineEdit = $VBoxContainer/NameInput
@onready var create_button: Button = $VBoxContainer/CreateRoomButton
@onready var join_button: Button = $VBoxContainer/JoinRoomButton
@onready var room_code_prompt_label: Label = $VBoxContainer/RoomCodePrompt
@onready var room_code_input: LineEdit = $VBoxContainer/RoomCodeInput
@onready var connect_button: Button = $VBoxContainer/ConnectButton
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var copy_code_button: Button = $VBoxContainer/CopyCodeButton
@onready var cancel_button: Button = $VBoxContainer/CancelButton

const REASSURANCE_INTERVAL := 20.0

var _connecting: bool = false
var _joining: bool = false
var _waiting_for_opponent: bool = false
var _reassurance_timer: Timer
var _hosted_room_code: String = ""

func _ready() -> void:
	get_tree().paused = false
	Music.stop_music()
	_apply_text()
	name_input.text = GameSettings.online_player_name if GameSettings.online_player_name != "" else _fallback_player_name()
	create_button.pressed.connect(_on_create_pressed)
	join_button.pressed.connect(_on_join_pressed)
	connect_button.pressed.connect(_on_connect_pressed)
	room_code_input.text_submitted.connect(func(_t: String) -> void: _on_connect_pressed())
	copy_code_button.pressed.connect(_on_copy_code_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	NetworkSession.opponent_connected.connect(_on_opponent_connected)
	NetworkSession.connection_failed.connect(_on_connection_failed)
	name_input.grab_focus()

	_reassurance_timer = Timer.new()
	_reassurance_timer.wait_time = REASSURANCE_INTERVAL
	_reassurance_timer.timeout.connect(func() -> void:
		if _waiting_for_opponent and not _connecting:
			var key: String = "lan_still_joining_message" if _joining else "lan_still_hosting_message"
			Voice.say_dynamic(Loc.t(key))
	)
	add_child(_reassurance_timer)

func _fallback_player_name() -> String:
	var os_name: String = OS.get_environment("USERNAME")
	return os_name if os_name != "" else "Player"

func _apply_text() -> void:
	var title: String = Loc.t("quick_online_mode_button") if NetworkSession.quick_mode else Loc.t("lan_title")
	title_label.text = title
	title_label.accessibility_name = title
	name_prompt_label.text = Loc.t("lan_name_prompt")
	name_prompt_label.accessibility_name = Loc.t("lan_name_prompt")
	name_input.placeholder_text = Loc.t("name_input_placeholder")
	name_input.accessibility_name = Loc.t("name_input_placeholder")
	name_input.accessibility_description = Loc.t("lan_name_input_desc")
	create_button.text = Loc.t("lan_create_button")
	create_button.accessibility_name = Loc.t("lan_create_button")
	create_button.accessibility_description = Loc.t("lan_create_desc")
	join_button.text = Loc.t("lan_join_button")
	join_button.accessibility_name = Loc.t("lan_join_button")
	join_button.accessibility_description = Loc.t("lan_join_desc")
	room_code_prompt_label.text = Loc.t("lan_join_code_prompt")
	room_code_prompt_label.accessibility_name = Loc.t("lan_join_code_prompt")
	room_code_input.placeholder_text = Loc.t("lan_room_code_placeholder")
	room_code_input.accessibility_name = Loc.t("lan_room_code_placeholder")
	room_code_input.accessibility_description = Loc.t("lan_join_code_input_desc")
	connect_button.text = Loc.t("lan_connect_button")
	connect_button.accessibility_name = Loc.t("lan_connect_button")
	connect_button.accessibility_description = Loc.t("lan_connect_desc")
	copy_code_button.text = Loc.t("lan_copy_code_button")
	copy_code_button.accessibility_name = Loc.t("lan_copy_code_button")
	copy_code_button.accessibility_description = Loc.t("lan_copy_code_desc")
	cancel_button.text = Loc.t("back_button")
	cancel_button.accessibility_name = Loc.t("back_button")
	cancel_button.accessibility_description = Loc.t("lan_cancel_desc")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()

func _set_status(text: String) -> void:
	status_label.visible = true
	status_label.text = text
	status_label.accessibility_name = text

func _lock_in_name() -> String:
	var player_name: String = name_input.text.strip_edges()
	if player_name == "":
		player_name = "Player"
	GameSettings.set_online_player_name(player_name)
	return player_name

func _hide_choice_step() -> void:
	name_prompt_label.visible = false
	name_input.visible = false
	create_button.visible = false
	join_button.visible = false

func _on_create_pressed() -> void:
	if _connecting:
		return
	var player_name: String = _lock_in_name()
	var code: String = NetworkSession.local_room_code()
	_hide_choice_step()
	if code == "":
		cancel_button.grab_focus()
		_set_status(Loc.t("lan_no_address_message"))
		Voice.say_dynamic(Loc.t("lan_no_address_message"))
		return
	_hosted_room_code = code
	copy_code_button.visible = true
	copy_code_button.grab_focus()
	var key: String = "lan_hosting_quick_message" if NetworkSession.quick_mode else "lan_hosting_message"
	var message: String = Loc.t(key) % code
	_set_status(message)
	Voice.say_dynamic(message)
	NetworkSession.create_room(player_name)
	_waiting_for_opponent = true
	_reassurance_timer.start()

func _on_copy_code_pressed() -> void:
	DisplayServer.clipboard_set(_hosted_room_code)
	Voice.say_dynamic(Loc.t("lan_copy_code_confirm") % _hosted_room_code)

func _on_join_pressed() -> void:
	if _connecting:
		return
	_joining = true
	_hide_choice_step()
	room_code_prompt_label.visible = true
	room_code_input.visible = true
	connect_button.visible = true
	room_code_input.grab_focus()

func _on_connect_pressed() -> void:
	if _connecting:
		return
	var player_name: String = _lock_in_name()
	var code: String = room_code_input.text.strip_edges()
	if code == "":
		return
	room_code_prompt_label.visible = false
	room_code_input.visible = false
	connect_button.visible = false
	cancel_button.grab_focus()
	var message: String = Loc.t("lan_connecting_message") % code
	_set_status(message)
	Voice.say_dynamic(message)
	NetworkSession.join_room(player_name, code)
	_waiting_for_opponent = true
	_reassurance_timer.start()

func _on_opponent_connected() -> void:
	if _connecting:
		return
	_connecting = true
	_waiting_for_opponent = false
	_reassurance_timer.stop()
	var message: String = Loc.t("lan_connected_message") % NetworkSession.opponent_name
	_set_status(message)
	Voice.say_dynamic(message)
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/Match.tscn")

func _on_connection_failed(reason: String) -> void:
	_waiting_for_opponent = false
	_reassurance_timer.stop()
	copy_code_button.visible = false
	var message: String
	if reason == "invalid_code":
		message = Loc.t("lan_invalid_code_message")
	elif reason == "server_failed" or reason == "client_failed":
		message = Loc.t("lan_failed_message")
	elif _joining:
		message = Loc.t("lan_failed_join_message")
	else:
		message = Loc.t("lan_failed_host_message")
	_set_status(message)
	Voice.say_dynamic(message)
	cancel_button.grab_focus()

func _on_cancel_pressed() -> void:
	NetworkSession.cancel_search()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
