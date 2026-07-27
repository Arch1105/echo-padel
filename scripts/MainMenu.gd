extends Control
## Main menu. Buttons/OptionButton carry accessibility_name/description
## (Godot 4.5+ AccessKit integration) so any running screen reader - NVDA,
## Narrator, JAWS - announces them automatically on focus; no custom
## accessibility plugin needed. Text is applied in code via Loc.t() rather
## than hardcoded in the scene file, so it reflects GameSettings.language.

const DIFFICULTIES := ["easy", "medium", "hard", "pro"]
const DIFFICULTY_KEYS := ["difficulty_easy", "difficulty_medium", "difficulty_hard", "difficulty_pro"]

@onready var title_label: Label = $VBoxContainer/Title
@onready var difficulty_label: Label = $VBoxContainer/DifficultyLabel
@onready var difficulty_option: OptionButton = $VBoxContainer/DifficultyOption
@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var training_button: Button = $VBoxContainer/TrainingButton
@onready var career_button: Button = $VBoxContainer/CareerButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

func _ready() -> void:
	get_tree().paused = false
	Music.play_music()
	_apply_text()
	difficulty_option.selected = maxi(DIFFICULTIES.find(GameSettings.difficulty), 0)
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	play_button.pressed.connect(_on_play_pressed)
	training_button.pressed.connect(_on_training_pressed)
	career_button.pressed.connect(_on_career_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	play_button.grab_focus()

func _apply_text() -> void:
	title_label.text = "Echo Padel"
	title_label.accessibility_name = Loc.t("main_title_access")

	difficulty_label.text = Loc.t("difficulty_label")
	difficulty_label.accessibility_name = Loc.t("difficulty_label")

	difficulty_option.clear()
	for key in DIFFICULTY_KEYS:
		difficulty_option.add_item(Loc.t(key))
	difficulty_option.accessibility_name = Loc.t("difficulty_selector_access")
	difficulty_option.accessibility_description = Loc.t("difficulty_selector_desc")

	play_button.text = Loc.t("play_button")
	play_button.accessibility_name = Loc.t("play_button")
	play_button.accessibility_description = Loc.t("play_desc")

	training_button.text = Loc.t("training_button")
	training_button.accessibility_name = Loc.t("training_button")
	training_button.accessibility_description = Loc.t("training_desc")

	career_button.text = Loc.t("career_button")
	career_button.accessibility_name = Loc.t("career_button")
	career_button.accessibility_description = Loc.t("career_desc")

	settings_button.text = Loc.t("settings_button")
	settings_button.accessibility_name = Loc.t("settings_button")
	settings_button.accessibility_description = Loc.t("settings_desc")

	exit_button.text = Loc.t("exit_button")
	exit_button.accessibility_name = Loc.t("exit_button")
	exit_button.accessibility_description = Loc.t("exit_desc")

func _on_difficulty_selected(index: int) -> void:
	GameSettings.difficulty = DIFFICULTIES[index]

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Match.tscn")

func _on_training_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Training.tscn")

func _on_career_pressed() -> void:
	if CareerData.has_save:
		get_tree().change_scene_to_file("res://scenes/CareerHub.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/CareerMenu.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
