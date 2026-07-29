extends Control
## Reached from the main menu before searching for a LAN opponent - picks
## which scoring rules the match will use. The choice is staged directly on
## NetworkSession (quick_mode) rather than passed as a scene parameter, since
## Godot's change_scene_to_file() can't carry arguments - see NetworkSession.
## quick_mode's own doc comment for how this gets resolved once two devices
## actually connect (the host's choice always wins).

@onready var title_label: Label = $VBoxContainer/Title
@onready var online_button: Button = $VBoxContainer/OnlineModeButton
@onready var quick_button: Button = $VBoxContainer/QuickModeButton
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	get_tree().paused = false
	_apply_text()
	online_button.pressed.connect(_on_online_pressed)
	quick_button.pressed.connect(_on_quick_pressed)
	back_button.pressed.connect(_on_back_pressed)
	online_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _apply_text() -> void:
	title_label.text = Loc.t("online_mode_select_title")
	title_label.accessibility_name = Loc.t("online_mode_select_title")

	online_button.text = Loc.t("online_mode_button")
	online_button.accessibility_name = Loc.t("online_mode_button")
	online_button.accessibility_description = Loc.t("online_mode_desc")

	quick_button.text = Loc.t("quick_online_mode_button")
	quick_button.accessibility_name = Loc.t("quick_online_mode_button")
	quick_button.accessibility_description = Loc.t("quick_online_mode_desc")

	back_button.text = Loc.t("back_button")
	back_button.accessibility_name = Loc.t("back_button")

func _on_online_pressed() -> void:
	NetworkSession.quick_mode = false
	get_tree().change_scene_to_file("res://scenes/OnlineLan.tscn")

func _on_quick_pressed() -> void:
	NetworkSession.quick_mode = true
	get_tree().change_scene_to_file("res://scenes/OnlineLan.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
