extends Control
## Reached from the main menu before searching for a LAN opponent - picks
## which scoring rules the match will use. The choice is staged directly on
## NetworkSession (quick_mode) rather than passed as a scene parameter, since
## Godot's change_scene_to_file() can't carry arguments - see NetworkSession.
## quick_mode's own doc comment for how this gets resolved once two devices
## actually connect (the host's choice always wins).

@onready var title_label: Label = $VBoxContainer/Title
@onready var coins_button: Button = $VBoxContainer/CoinsButton
@onready var online_button: Button = $VBoxContainer/OnlineModeButton
@onready var quick_button: Button = $VBoxContainer/QuickModeButton
@onready var wall_button: Button = $VBoxContainer/WallModeButton
@onready var store_button: Button = $VBoxContainer/StoreButton
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	get_tree().paused = false
	Music.play_online_music()
	_apply_text()
	coins_button.pressed.connect(_on_coins_pressed)
	online_button.pressed.connect(_on_online_pressed)
	quick_button.pressed.connect(_on_quick_pressed)
	wall_button.pressed.connect(_on_wall_pressed)
	store_button.pressed.connect(_on_store_pressed)
	back_button.pressed.connect(_on_back_pressed)
	online_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _apply_text() -> void:
	title_label.text = Loc.t("online_mode_select_title")
	title_label.accessibility_name = Loc.t("online_mode_select_title")

	var coin_text: String = Loc.t("online_coin_balance") % OnlineData.coins
	coins_button.text = coin_text
	coins_button.accessibility_name = coin_text
	coins_button.accessibility_description = Loc.t("online_coin_balance_desc")

	online_button.text = Loc.t("online_mode_button")
	online_button.accessibility_name = Loc.t("online_mode_button")
	online_button.accessibility_description = Loc.t("online_mode_desc")

	quick_button.text = Loc.t("quick_online_mode_button")
	quick_button.accessibility_name = Loc.t("quick_online_mode_button")
	quick_button.accessibility_description = Loc.t("quick_online_mode_desc")

	wall_button.text = Loc.t("wall_online_mode_button")
	wall_button.accessibility_name = Loc.t("wall_online_mode_button")
	wall_button.accessibility_description = Loc.t("wall_online_mode_desc")

	store_button.text = Loc.t("store_button")
	store_button.accessibility_name = Loc.t("store_button")
	store_button.accessibility_description = Loc.t("store_desc")

	back_button.text = Loc.t("back_button")
	back_button.accessibility_name = Loc.t("back_button")

## A focused Button's own text/accessibility_name is already read on focus -
## this explicit spoken confirmation on press is extra certainty (same
## reasoning as CareerUpgrades.gd's spend confirmations), not the only way
## to hear the balance.
func _on_coins_pressed() -> void:
	Voice.say_dynamic(Loc.t("online_coin_balance") % OnlineData.coins)

func _on_store_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/EmoteStore.tscn")

func _on_online_pressed() -> void:
	NetworkSession.quick_mode = false
	NetworkSession.wall_mode = false
	get_tree().change_scene_to_file("res://scenes/OnlineLan.tscn")

func _on_quick_pressed() -> void:
	NetworkSession.quick_mode = true
	NetworkSession.wall_mode = false
	get_tree().change_scene_to_file("res://scenes/OnlineLan.tscn")

func _on_wall_pressed() -> void:
	NetworkSession.quick_mode = false
	NetworkSession.wall_mode = true
	get_tree().change_scene_to_file("res://scenes/OnlineLan.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
