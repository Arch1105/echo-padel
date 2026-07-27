extends Control
## Name entry, only reached when there's no existing career save. Starts a
## brand-new career at tier 1 (School League) and goes to the Hub.

@onready var title_label: Label = $VBoxContainer/Title
@onready var instructions_label: Label = $VBoxContainer/Instructions
@onready var name_input: LineEdit = $VBoxContainer/NameInput
@onready var start_button: Button = $VBoxContainer/StartButton

func _ready() -> void:
	get_tree().paused = false
	Music.stop_music()
	_apply_text()
	start_button.pressed.connect(_on_start_pressed)
	name_input.text_submitted.connect(_on_name_submitted)
	name_input.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _apply_text() -> void:
	title_label.text = Loc.t("career_menu_title")
	title_label.accessibility_name = Loc.t("career_menu_title")

	instructions_label.text = Loc.t("career_menu_instructions")
	instructions_label.accessibility_name = Loc.t("career_menu_instructions")

	name_input.placeholder_text = Loc.t("name_input_placeholder")
	name_input.accessibility_name = Loc.t("name_input_placeholder")
	name_input.accessibility_description = Loc.t("name_input_desc")

	start_button.text = Loc.t("start_career_button")
	start_button.accessibility_name = Loc.t("start_career_button")
	start_button.accessibility_description = Loc.t("start_career_desc")

func _on_name_submitted(_text: String) -> void:
	_start_career()

func _on_start_pressed() -> void:
	_start_career()

func _start_career() -> void:
	var player_name: String = name_input.text.strip_edges()
	if player_name == "":
		player_name = "Player"
	CareerData.start_new_career(player_name)
	get_tree().change_scene_to_file("res://scenes/CareerHub.tscn")
