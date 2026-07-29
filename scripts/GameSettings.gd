extends Node
## Tiny cross-scene autoload: carries the difficulty chosen on the main menu
## into the Match scene (Godot discards regular node state on scene change),
## and the chosen UI/voice language (see Loc.gd, Voice.gd). Language is
## persisted (unlike difficulty, which is picked fresh each time you start a
## match) since nobody wants to re-pick their language every launch.

const SAVE_PATH := "user://settings.json"
const SUPPORTED_LANGUAGES := ["en", "es"]

var difficulty: String = "medium"
var language: String = "en"
var online_player_name: String = ""
var vibration_enabled: bool = true

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var lang: String = parsed.get("language", "en")
	if lang in SUPPORTED_LANGUAGES:
		language = lang
	online_player_name = parsed.get("online_player_name", "")
	vibration_enabled = bool(parsed.get("vibration_enabled", true))

func save_settings() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("GameSettings: could not write settings file")
		return
	file.store_string(JSON.stringify({
		"language": language,
		"online_player_name": online_player_name,
		"vibration_enabled": vibration_enabled,
	}, "\t"))
	file.close()

func set_language(lang: String) -> void:
	if lang in SUPPORTED_LANGUAGES:
		language = lang
		save_settings()

func set_online_player_name(player_name: String) -> void:
	online_player_name = player_name
	save_settings()

func set_vibration_enabled(enabled: bool) -> void:
	vibration_enabled = enabled
	save_settings()
