extends Control
## Main menu. Buttons/OptionButton carry accessibility_name/description
## (Godot 4.5+ AccessKit integration) so any running screen reader - NVDA,
## Narrator, JAWS - announces them automatically on focus; no custom
## accessibility plugin needed. Text is applied in code via Loc.t() rather
## than hardcoded in the scene file, so it reflects GameSettings.language.

const DIFFICULTIES := ["easy", "medium", "hard", "pro", "elite", "legendary"]
const DIFFICULTY_KEYS := ["difficulty_easy", "difficulty_medium", "difficulty_hard", "difficulty_pro",
		"difficulty_elite", "difficulty_legendary"]

@onready var title_label: Label = $VBoxContainer/Title
@onready var difficulty_label: Label = $VBoxContainer/DifficultyLabel
@onready var difficulty_option: OptionButton = $VBoxContainer/DifficultyOption
@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var training_button: Button = $VBoxContainer/TrainingButton
@onready var career_button: Button = $VBoxContainer/CareerButton
@onready var play_online_button: Button = $VBoxContainer/PlayOnlineButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var help_button: Button = $VBoxContainer/HelpButton
@onready var check_updates_button: Button = $VBoxContainer/CheckUpdatesButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var version_label: Label = $VersionLabel

## True only while a Check for Updates *button press* is in flight - the
## silent auto-check on launch shouldn't pop up "you're up to date"/"couldn't
## check" noise, only an actually-available update. A manual check always
## gets some feedback either way, since the player asked for it.
var _manual_check_pending: bool = false
var _prompt: UpdatePrompt = null

func _ready() -> void:
	get_tree().paused = false
	Music.play_music()
	_apply_text()
	difficulty_option.selected = maxi(DIFFICULTIES.find(GameSettings.difficulty), 0)
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	play_button.pressed.connect(_on_play_pressed)
	training_button.pressed.connect(_on_training_pressed)
	career_button.pressed.connect(_on_career_pressed)
	play_online_button.pressed.connect(_on_play_online_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	help_button.pressed.connect(_on_help_pressed)
	check_updates_button.pressed.connect(_on_check_updates_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	play_button.grab_focus()

	Updater.update_check_finished.connect(_on_update_check_finished)
	Updater.update_check_failed.connect(_on_update_check_failed)
	Updater.update_download_progress.connect(_on_update_download_progress)
	Updater.update_failed.connect(_on_update_failed)
	Updater.check_for_update()

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

	play_online_button.text = Loc.t("play_online_button")
	play_online_button.accessibility_name = Loc.t("play_online_button")
	play_online_button.accessibility_description = Loc.t("play_online_desc")

	settings_button.text = Loc.t("settings_button")
	settings_button.accessibility_name = Loc.t("settings_button")
	settings_button.accessibility_description = Loc.t("settings_desc")

	help_button.text = Loc.t("help_button")
	help_button.accessibility_name = Loc.t("help_button")
	help_button.accessibility_description = Loc.t("help_desc")

	check_updates_button.text = Loc.t("check_updates_button")
	check_updates_button.accessibility_name = Loc.t("check_updates_button")
	check_updates_button.accessibility_description = Loc.t("check_updates_desc")

	exit_button.text = Loc.t("exit_button")
	exit_button.accessibility_name = Loc.t("exit_button")
	exit_button.accessibility_description = Loc.t("exit_desc")

	version_label.text = "v%s" % AppVersion.CURRENT
	version_label.accessibility_name = Loc.t("version_label_access") % AppVersion.CURRENT

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

func _on_play_online_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/OnlineLan.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_help_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/HelpScreen.tscn")

func _on_check_updates_pressed() -> void:
	_manual_check_pending = true
	Updater.check_for_update()

func _on_update_check_finished(available: bool, version: String, download_url: String) -> void:
	if available:
		_show_prompt()
		_prompt.show_available(version)
		_prompt.update_confirmed.connect(func() -> void:
			_prompt.show_downloading()
			Updater.begin_update(download_url)
		, CONNECT_ONE_SHOT)
		_prompt.dismissed.connect(_close_prompt, CONNECT_ONE_SHOT)
	elif _manual_check_pending:
		_show_prompt()
		_prompt.show_failed("update_up_to_date_message")
		_prompt.dismissed.connect(_close_prompt, CONNECT_ONE_SHOT)
	_manual_check_pending = false

func _on_update_check_failed(_reason: String) -> void:
	if _manual_check_pending:
		_show_prompt()
		_prompt.show_failed("update_check_failed_message")
		_prompt.dismissed.connect(_close_prompt, CONNECT_ONE_SHOT)
	_manual_check_pending = false

func _on_update_download_progress(fraction: float) -> void:
	if _prompt:
		_prompt.set_progress(fraction)

func _on_update_failed(_reason: String) -> void:
	_show_prompt()
	_prompt.show_failed("update_download_failed_message")
	_prompt.dismissed.connect(_close_prompt, CONNECT_ONE_SHOT)

func _show_prompt() -> void:
	if _prompt:
		return
	_prompt = preload("res://scenes/UpdatePrompt.tscn").instantiate()
	add_child(_prompt)

func _close_prompt() -> void:
	if _prompt:
		_prompt.queue_free()
		_prompt = null
