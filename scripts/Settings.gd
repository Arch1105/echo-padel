extends Control

const MASTER_BUS := "Master"
const LANGUAGES := ["en", "es"]
const LANGUAGE_KEYS := ["lang_english", "lang_spanish"]

@onready var title_label: Label = $VBoxContainer/Title
@onready var volume_label: Label = $VBoxContainer/VolumeLabel
@onready var volume_slider: HSlider = $VBoxContainer/VolumeSlider
@onready var language_label: Label = $VBoxContainer/LanguageLabel
@onready var language_option: OptionButton = $VBoxContainer/LanguageOption
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	get_tree().paused = false
	Music.stop_music()
	var bus_idx := AudioServer.get_bus_index(MASTER_BUS)
	volume_slider.value = clamp(db_to_linear(AudioServer.get_bus_volume_db(bus_idx)) * 100.0, 0.0, 100.0)
	volume_slider.value_changed.connect(_on_volume_changed)

	_apply_text()
	language_option.selected = maxi(LANGUAGES.find(GameSettings.language), 0)
	language_option.item_selected.connect(_on_language_selected)

	back_button.pressed.connect(_on_back_pressed)
	volume_slider.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _apply_text() -> void:
	title_label.text = Loc.t("settings_title")
	title_label.accessibility_name = Loc.t("settings_title")

	volume_label.text = Loc.t("volume_label")
	volume_label.accessibility_name = Loc.t("volume_label")
	volume_slider.accessibility_name = Loc.t("volume_slider_access")
	volume_slider.accessibility_description = Loc.t("volume_slider_desc")

	language_label.text = Loc.t("language_label")
	language_label.accessibility_name = Loc.t("language_label")
	language_option.clear()
	for key in LANGUAGE_KEYS:
		language_option.add_item(Loc.t(key))
	language_option.accessibility_name = Loc.t("language_selector_access")
	language_option.accessibility_description = Loc.t("language_selector_desc")

	back_button.text = Loc.t("back_button")
	back_button.accessibility_name = Loc.t("back_button")
	back_button.accessibility_description = Loc.t("back_desc")

func _on_volume_changed(value: float) -> void:
	var bus_idx := AudioServer.get_bus_index(MASTER_BUS)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(max(value, 0.001) / 100.0))

func _on_language_selected(index: int) -> void:
	GameSettings.set_language(LANGUAGES[index])
	_apply_text()
	language_option.selected = index

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
