extends Control
## Spend LAN-match coins (see OnlineData.gd) on emotes (see Emotes.gd's
## static catalog) - buttons are built dynamically from the catalog, same
## pattern CareerHub.gd uses for its tier list, since the list itself isn't
## a small fixed set of named slots the way CareerUpgrades.gd's four stats
## are.

@onready var title_label: Label = $VBoxContainer/Title
@onready var coins_label: Label = $VBoxContainer/CoinsLabel
@onready var hint_label: Label = $VBoxContainer/HintLabel
@onready var emote_list: VBoxContainer = $VBoxContainer/EmoteList
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	get_tree().paused = false
	back_button.pressed.connect(_on_back_pressed)
	_refresh()
	if emote_list.get_child_count() > 0:
		emote_list.get_child(0).grab_focus()
	else:
		back_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _refresh() -> void:
	title_label.text = Loc.t("store_title")
	title_label.accessibility_name = Loc.t("store_title")

	var balance_text: String = Loc.t("store_coin_balance") % OnlineData.coins
	coins_label.text = balance_text
	coins_label.accessibility_name = balance_text

	hint_label.text = Loc.t("store_earn_hint")
	hint_label.accessibility_name = Loc.t("store_earn_hint")

	for child in emote_list.get_children():
		child.queue_free()

	for entry in Emotes.CATALOG:
		var emote_id: String = entry["id"]
		var price: int = entry["price"]
		var emote_name: String = Loc.t(entry["name_key"])
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(360, 52)
		btn.focus_mode = Control.FOCUS_ALL
		if OnlineData.owns_emote(emote_id):
			btn.text = "%s - %s" % [emote_name, Loc.t("store_owned_label")]
			btn.accessibility_name = btn.text
			btn.disabled = true
		else:
			btn.text = "%s - %s" % [emote_name, Loc.t("store_buy_button") % price]
			btn.accessibility_name = btn.text
			btn.accessibility_description = Loc.t("store_buy_desc") % price
			btn.pressed.connect(_on_buy_pressed.bind(emote_id, price))
		emote_list.add_child(btn)

	back_button.text = Loc.t("back_button")
	back_button.accessibility_name = Loc.t("back_button")

func _on_buy_pressed(emote_id: String, price: int) -> void:
	if OnlineData.buy_emote(emote_id, price):
		Voice.say_dynamic(Loc.t("store_bought_message"))
	else:
		Voice.say_dynamic(Loc.t("store_cant_afford_message"))
	_refresh()
	if emote_list.get_child_count() > 0:
		emote_list.get_child(0).grab_focus()
	else:
		back_button.grab_focus()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/OnlineModeSelect.tscn")
