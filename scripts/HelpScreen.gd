extends Control
## Detailed how-to-play guide, reachable from the main menu. Each section is
## built as a Button (not a plain read-only Label) purely so it's actually
## reachable via Tab/Up/Down and gets announced by a screen reader on focus -
## Labels alone aren't part of the normal keyboard focus chain, so a wall of
## Labels would be invisible to anyone navigating by keyboard/screen reader,
## exactly the audience this whole game is built for. The buttons don't
## *do* anything when pressed; their accessibility_name carries the full
## heading + body text (that's what actually gets read, not the visual
## label - see _wrap_text() for why the button's on-screen text also gets
## manually wrapped rather than relying on Button auto-wrap, which Godot
## doesn't reliably provide for multi-line button text).

const WRAP_WIDTH := 58

const SECTIONS := [
	["help_goal_heading", "help_goal_body"],
	["help_movement_heading", "help_movement_body"],
	["help_hitting_heading", "help_hitting_body"],
	["help_smash_heading", "help_smash_body"],
	["help_drop_shot_heading", "help_drop_shot_body"],
	["help_shaping_heading", "help_shaping_body"],
	["help_sounds_heading", "help_sounds_body"],
	["help_serving_heading", "help_serving_body"],
	["help_training_heading", "help_training_body"],
	["help_career_heading", "help_career_body"],
	["help_online_extras_heading", "help_online_extras_body"],
	["help_wall_mode_heading", "help_wall_mode_body"],
	["help_settings_heading", "help_settings_body"],
]

@onready var title_label: Label = $Title
@onready var section_list: VBoxContainer = $ScrollContainer/SectionList

var _back_button: Button

func _ready() -> void:
	get_tree().paused = false
	Music.stop_music()
	_build_sections()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _build_sections() -> void:
	title_label.text = Loc.t("help_title")
	title_label.accessibility_name = Loc.t("help_title")

	for child in section_list.get_children():
		child.queue_free()

	for pair in SECTIONS:
		var heading: String = Loc.t(pair[0])
		var body: String = Loc.t(pair[1])
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(560, 0)
		btn.text = "%s\n%s" % [heading, _wrap_text(body, WRAP_WIDTH)]
		btn.accessibility_name = "%s. %s" % [heading, body]
		btn.focus_mode = Control.FOCUS_ALL
		section_list.add_child(btn)

	_back_button = Button.new()
	_back_button.custom_minimum_size = Vector2(260, 52)
	_back_button.text = Loc.t("back_button")
	_back_button.accessibility_name = Loc.t("back_button")
	_back_button.pressed.connect(_on_back_pressed)
	section_list.add_child(_back_button)
	section_list.get_child(0).grab_focus()

## Buttons don't reliably auto-wrap long text the way Label does with
## autowrap_mode, so this breaks it into explicit lines at word boundaries -
## purely cosmetic, doesn't affect what's actually spoken (accessibility_name
## carries the unwrapped original text).
func _wrap_text(text: String, width: int) -> String:
	var words: PackedStringArray = text.split(" ")
	var lines: PackedStringArray = []
	var current := ""
	for word in words:
		var candidate: String = word if current == "" else "%s %s" % [current, word]
		if candidate.length() > width and current != "":
			lines.append(current)
			current = word
		else:
			current = candidate
	if current != "":
		lines.append(current)
	return "\n".join(lines)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
