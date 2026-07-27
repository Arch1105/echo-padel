extends Control
class_name UpdatePrompt
## Accessible overlay for the auto-updater: "Update available - download now?"
## with Yes/No, then a downloading state, then (on failure) a dismissible
## error message. MainMenu.gd owns the actual Updater.gd calls; this scene
## only reports what the player chose.

signal update_confirmed
signal dismissed

@onready var message_label: Label = $Panel/VBoxContainer/MessageLabel
@onready var button_row: HBoxContainer = $Panel/VBoxContainer/ButtonRow
@onready var update_button: Button = $Panel/VBoxContainer/ButtonRow/UpdateButton
@onready var later_button: Button = $Panel/VBoxContainer/ButtonRow/LaterButton
@onready var ok_button: Button = $Panel/VBoxContainer/OkButton

func _ready() -> void:
	update_button.pressed.connect(func() -> void: update_confirmed.emit())
	later_button.pressed.connect(func() -> void: dismissed.emit())
	ok_button.pressed.connect(func() -> void: dismissed.emit())

func show_available(version: String) -> void:
	var text: String = Loc.t("update_available_message") % version
	message_label.text = text
	message_label.accessibility_name = text
	update_button.text = Loc.t("update_now_button")
	update_button.accessibility_name = Loc.t("update_now_button")
	later_button.text = Loc.t("not_now_button")
	later_button.accessibility_name = Loc.t("not_now_button")
	button_row.visible = true
	ok_button.visible = false
	update_button.grab_focus()

func show_downloading() -> void:
	set_progress(0.0)
	button_row.visible = false
	ok_button.visible = false

func set_progress(fraction: float) -> void:
	var percent: int = clampi(roundi(fraction * 100.0), 0, 100)
	var text: String = Loc.t("update_downloading_message") % percent
	message_label.text = text
	message_label.accessibility_name = text

func show_failed(reason_key: String) -> void:
	var text: String = Loc.t(reason_key)
	message_label.text = text
	message_label.accessibility_name = text
	button_row.visible = false
	ok_button.visible = true
	ok_button.text = Loc.t("ok_button")
	ok_button.accessibility_name = Loc.t("ok_button")
	ok_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and button_row.visible:
		dismissed.emit()
