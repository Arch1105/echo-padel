extends Control
## Career home screen: shows the player's current tier and how close they
## are to a demotion, and lists the tournament(s) available at that tier -
## one for tiers 1-6 and tier 8 (Hall of Champions), the four Grand Slams
## (with title counts) at tier 7. Tournament buttons are built in code since
## their number/labels depend on save data, not something worth hand-
## authoring per tier in the scene file. Text goes through
## Loc.t()/Loc.tier_name()/Loc.round_name() throughout so it reflects
## GameSettings.language.

const RESET_ARM_SECONDS := 5.0

@onready var title_label: Label = $VBoxContainer/Title
@onready var tier_label: Label = $VBoxContainer/TierLabel
@onready var losses_label: Label = $VBoxContainer/LossesLabel
@onready var tournament_buttons: VBoxContainer = $VBoxContainer/TournamentButtons
@onready var upgrades_button: Button = $VBoxContainer/UpgradesButton
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var reset_button: Button = $VBoxContainer/ResetButton

var _reset_armed: bool = false

func _ready() -> void:
	get_tree().paused = false
	Music.stop_music()
	upgrades_button.pressed.connect(_on_upgrades_pressed)
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _refresh() -> void:
	title_label.text = Loc.t("career_hub_title")
	title_label.accessibility_name = Loc.t("career_hub_title")

	var tier: int = CareerData.current_tier
	tier_label.text = Loc.t("career_hub_status") % [CareerData.player_name, Loc.tier_name(tier)]
	tier_label.accessibility_name = tier_label.text

	if tier <= 1:
		losses_label.text = Loc.t("career_hub_unlimited")
	else:
		losses_label.text = Loc.t("career_hub_losses") % [CareerData.losses_at_tier, CareerData.LOSSES_TO_DEMOTE]
	losses_label.accessibility_name = losses_label.text

	upgrades_button.text = Loc.t("upgrades_button") % CareerData.upgrade_points
	upgrades_button.accessibility_name = upgrades_button.text
	upgrades_button.accessibility_description = Loc.t("upgrades_desc")

	back_button.text = Loc.t("back_to_menu_button")
	back_button.accessibility_name = Loc.t("back_to_menu_button")

	reset_button.text = Loc.t("reset_confirm_button") if _reset_armed else Loc.t("reset_career_button")
	reset_button.accessibility_name = reset_button.text
	reset_button.accessibility_description = Loc.t("reset_career_desc")

	for child in tournament_buttons.get_children():
		child.queue_free()

	if CareerData.run_active:
		var label: String = CareerData.run_tournament_name if CareerData.run_is_grand_slam \
				else Loc.tier_name(CareerData.run_tier)
		var round_name: String = Loc.round_name(CareerTiers.rounds_for(CareerData.run_tier)[CareerData.run_round_index])
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(300, 52)
		btn.text = Loc.t("resume_button") % [label, round_name]
		btn.accessibility_name = btn.text
		btn.accessibility_description = Loc.t("resume_desc")
		btn.pressed.connect(_on_resume_pressed)
		tournament_buttons.add_child(btn)
		return

	if tier == CareerTiers.SLAM_TIER:
		for slam in CareerTiers.GRAND_SLAMS:
			var count: int = CareerData.slam_title_count(slam)
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(300, 52)
			btn.text = slam
			btn.accessibility_name = slam
			var time_word: String = Loc.t("time_singular") if count == 1 else Loc.t("time_plural")
			btn.accessibility_description = Loc.t("slam_desc_template") % [count, time_word]
			btn.pressed.connect(_on_enter_slam.bind(slam))
			tournament_buttons.add_child(btn)
	else:
		var tier_name: String = Loc.tier_name(tier)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(300, 52)
		btn.text = Loc.t("enter_tier_button") % tier_name
		btn.accessibility_name = btn.text
		btn.accessibility_description = Loc.t("enter_tier_desc") % tier_name
		btn.pressed.connect(_on_enter_tier.bind(tier))
		tournament_buttons.add_child(btn)

func _on_resume_pressed() -> void:
	CareerRun.resume_from_save()
	get_tree().change_scene_to_file("res://scenes/Match.tscn")

func _on_enter_tier(tier: int) -> void:
	CareerRun.start(tier)
	get_tree().change_scene_to_file("res://scenes/Match.tscn")

func _on_enter_slam(slam_name: String) -> void:
	CareerRun.start(CareerTiers.SLAM_TIER, slam_name)
	get_tree().change_scene_to_file("res://scenes/Match.tscn")

func _on_upgrades_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CareerUpgrades.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_reset_pressed() -> void:
	if _reset_armed:
		CareerData.erase_career()
		get_tree().change_scene_to_file("res://scenes/CareerMenu.tscn")
		return
	_reset_armed = true
	reset_button.text = Loc.t("reset_confirm_button")
	reset_button.accessibility_name = reset_button.text
	Voice.say("career_reset_confirm")
	await get_tree().create_timer(RESET_ARM_SECONDS).timeout
	if is_instance_valid(reset_button) and _reset_armed:
		_reset_armed = false
		reset_button.text = Loc.t("reset_career_button")
		reset_button.accessibility_name = reset_button.text
