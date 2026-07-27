extends Control
## Spend Career-mode upgrade points (earned from love-game wins, see
## MatchManager.gd) on the player's character. Four fixed stats, each capped
## at CareerData.MAX_UPGRADE_LEVEL - buttons are pre-built in the scene since
## there's always exactly four, unlike CareerHub's tournament list.
##
## Changing a *focused* button's own text isn't reliably re-announced by a
## screen reader on its own, so every successful spend also speaks an
## explicit confirmation through Voice - the same reason CareerHub's reset
## button does the same for its armed state.

const STATS := ["strength", "iq", "speed", "racket"]

@onready var title_label: Label = $VBoxContainer/Title
@onready var points_label: Label = $VBoxContainer/PointsLabel
@onready var back_button: Button = $VBoxContainer/BackButton

var stat_buttons: Dictionary = {}

func _ready() -> void:
	get_tree().paused = false
	Music.stop_music()
	stat_buttons = {
		"strength": $VBoxContainer/StrengthButton,
		"iq": $VBoxContainer/IqButton,
		"speed": $VBoxContainer/SpeedButton,
		"racket": $VBoxContainer/RacketButton,
	}
	for stat in STATS:
		stat_buttons[stat].pressed.connect(_on_stat_pressed.bind(stat))
	back_button.pressed.connect(_on_back_pressed)
	_refresh()
	stat_buttons["strength"].grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _refresh() -> void:
	title_label.text = Loc.t("upgrades_title")
	title_label.accessibility_name = Loc.t("upgrades_title")

	points_label.text = Loc.t("upgrades_points_label") % CareerData.upgrade_points
	points_label.accessibility_name = points_label.text

	for stat in STATS:
		var btn: Button = stat_buttons[stat]
		var level: int = CareerData.get_upgrade_level(stat)
		var name_key: String = "upgrade_stat_%s" % stat
		var stat_name: String = Loc.t(name_key)
		var text: String
		if level >= CareerData.MAX_UPGRADE_LEVEL:
			text = Loc.t("upgrade_row_maxed") % [stat_name, level, CareerData.MAX_UPGRADE_LEVEL]
			btn.disabled = true
		elif CareerData.upgrade_points <= 0:
			text = Loc.t("upgrade_row_no_points") % [stat_name, level, CareerData.MAX_UPGRADE_LEVEL]
			btn.disabled = true
		else:
			text = Loc.t("upgrade_row_button") % [stat_name, level, CareerData.MAX_UPGRADE_LEVEL]
			btn.disabled = false
		btn.text = text
		btn.accessibility_name = text
		btn.accessibility_description = Loc.t("%s_desc" % name_key)

	back_button.text = Loc.t("back_button")
	back_button.accessibility_name = Loc.t("back_button")

func _on_stat_pressed(stat: String) -> void:
	if not CareerData.spend_upgrade_point(stat):
		return
	var stat_name: String = Loc.t("upgrade_stat_%s" % stat)
	var new_level: int = CareerData.get_upgrade_level(stat)
	var maxed: bool = new_level >= CareerData.MAX_UPGRADE_LEVEL
	var key: String = "upgrade_row_maxed" if maxed else "upgrade_row_button"
	Voice.say_dynamic(Loc.t(key) % [stat_name, new_level, CareerData.MAX_UPGRADE_LEVEL])
	_refresh()
	if stat_buttons[stat].disabled:
		back_button.grab_focus()
	else:
		stat_buttons[stat].grab_focus()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CareerHub.tscn")
