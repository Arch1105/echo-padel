extends Node
## Persistent career-mode save: player name, current tier, how many losses
## at that tier (demotes at 3), a title count per Grand Slam, upgrade points
## and the 4 stat levels they've been spent on, and - so a closed app or an
## early exit doesn't lose bracket progress - which tournament/round was in
## progress, if any. Saved as plain JSON to user://career_save.json - no
## engine-specific resource formats, so it stays easy to read/reset by hand
## if ever needed. Written after every result, so "closed the app" and
## "explicitly went back to the menu" behave identically - there's never an
## unsaved window.

const SAVE_PATH := "user://career_save.json"
const LOSSES_TO_DEMOTE := 3
const MAX_UPGRADE_LEVEL := 5
const UPGRADE_STATS := ["strength", "iq", "speed", "racket"]

var player_name: String = ""
var current_tier: int = 1
var losses_at_tier: int = 0
var slam_titles: Dictionary = {}
var has_save: bool = false

## Spent on the player's character between tournaments, from CareerUpgrades -
## see PlayerController.gd/Ball.gd/PaddleCharacter.gd for what each stat
## actually does in a match. Career-mode only; regular Play/Training never
## read these.
var upgrade_points: int = 0
var upgrade_strength: int = 0
var upgrade_iq: int = 0
var upgrade_speed: int = 0
var upgrade_racket: int = 0

## In-progress bracket, if any - see CareerRun.gd, which is the thing that
## actually reads/writes these during a run.
var run_active: bool = false
var run_tier: int = 1
var run_tournament_name: String = ""
var run_round_index: int = 0
var run_is_grand_slam: bool = false

func _ready() -> void:
	load_career()

func load_career() -> void:
	has_save = false
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
	player_name = parsed.get("player_name", "")
	current_tier = clampi(int(parsed.get("current_tier", 1)), 1, CareerTiers.MAX_TIER)
	losses_at_tier = int(parsed.get("losses_at_tier", 0))
	slam_titles = parsed.get("slam_titles", {})
	upgrade_points = int(parsed.get("upgrade_points", 0))
	upgrade_strength = int(parsed.get("upgrade_strength", 0))
	upgrade_iq = int(parsed.get("upgrade_iq", 0))
	upgrade_speed = int(parsed.get("upgrade_speed", 0))
	upgrade_racket = int(parsed.get("upgrade_racket", 0))
	run_active = bool(parsed.get("run_active", false))
	run_tier = int(parsed.get("run_tier", 1))
	run_tournament_name = parsed.get("run_tournament_name", "")
	run_round_index = int(parsed.get("run_round_index", 0))
	run_is_grand_slam = bool(parsed.get("run_is_grand_slam", false))
	has_save = player_name != ""

	# Migration for saves from before Hall of Champions (tier 8) existed: a
	# player already sitting at tier 7 with at least one Grand Slam title has
	# already proven themselves at that level, so promote them once on load
	# rather than requiring a brand new Grand Slam win to unlock it.
	if has_save and current_tier == CareerTiers.SLAM_TIER and total_slam_titles() > 0:
		current_tier = CareerTiers.HALL_TIER
		save_career()

func save_career() -> void:
	var data := {
		"player_name": player_name,
		"current_tier": current_tier,
		"losses_at_tier": losses_at_tier,
		"slam_titles": slam_titles,
		"upgrade_points": upgrade_points,
		"upgrade_strength": upgrade_strength,
		"upgrade_iq": upgrade_iq,
		"upgrade_speed": upgrade_speed,
		"upgrade_racket": upgrade_racket,
		"run_active": run_active,
		"run_tier": run_tier,
		"run_tournament_name": run_tournament_name,
		"run_round_index": run_round_index,
		"run_is_grand_slam": run_is_grand_slam,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("CareerData: could not write save file")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

## Called by CareerRun whenever a bracket starts or advances a round, so
## quitting mid-tournament resumes at the right spot instead of losing it.
func save_run(tier: int, tournament_name: String, round_index: int, is_grand_slam: bool) -> void:
	run_active = true
	run_tier = tier
	run_tournament_name = tournament_name
	run_round_index = round_index
	run_is_grand_slam = is_grand_slam
	save_career()

## Called by CareerRun once a tournament resolves (won or lost) - nothing
## left to resume.
func clear_run() -> void:
	run_active = false
	save_career()

## Permanently erases the save file and resets to a blank slate.
func erase_career() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	player_name = ""
	current_tier = 1
	losses_at_tier = 0
	slam_titles = {}
	upgrade_points = 0
	upgrade_strength = 0
	upgrade_iq = 0
	upgrade_speed = 0
	upgrade_racket = 0
	run_active = false
	run_tier = 1
	run_tournament_name = ""
	run_round_index = 0
	run_is_grand_slam = false
	has_save = false

func start_new_career(name: String) -> void:
	player_name = name
	current_tier = 1
	losses_at_tier = 0
	slam_titles = {}
	for slam in CareerTiers.GRAND_SLAMS:
		slam_titles[slam] = 0
	upgrade_points = 0
	upgrade_strength = 0
	upgrade_iq = 0
	upgrade_speed = 0
	upgrade_racket = 0
	run_active = false
	has_save = true
	save_career()

func slam_title_count(slam_name: String) -> int:
	return int(slam_titles.get(slam_name, 0))

func total_slam_titles() -> int:
	var total := 0
	for v in slam_titles.values():
		total += int(v)
	return total

## is_grand_slam + slam_name only matter when current_tier is already 7 -
## winning a lower tier's tournament instead advances current_tier by one.
## The very first Grand Slam title ever won additionally unlocks tier 8
## (Hall of Champions) - see CareerTiers.gd's doc comment for why that's the
## chosen unlock condition.
func record_win(is_grand_slam: bool, slam_name: String = "") -> void:
	losses_at_tier = 0
	if is_grand_slam:
		var was_first_slam_title: bool = total_slam_titles() == 0
		slam_titles[slam_name] = slam_title_count(slam_name) + 1
		if was_first_slam_title and current_tier == CareerTiers.SLAM_TIER:
			current_tier = CareerTiers.HALL_TIER
	elif current_tier < CareerTiers.MAX_TIER:
		current_tier += 1
	save_career()

## Tier 1 has unlimited tries (nowhere lower to demote to). Everywhere else,
## three tournament losses at the same tier demotes one tier down and resets
## the counter - the same rule applies even at the Grand Slams and Hall of
## Champions.
func record_loss() -> void:
	if current_tier > 1:
		losses_at_tier += 1
		if losses_at_tier >= LOSSES_TO_DEMOTE:
			current_tier -= 1
			losses_at_tier = 0
	save_career()

## +1 upgrade point, per love game won - see MatchManager.gd's _win_game().
func add_upgrade_points(amount: int) -> void:
	upgrade_points += amount
	save_career()

func get_upgrade_level(stat: String) -> int:
	match stat:
		"strength": return upgrade_strength
		"iq": return upgrade_iq
		"speed": return upgrade_speed
		"racket": return upgrade_racket
	return 0

## Returns false (no-op) if there are no points left or the stat's already
## at MAX_UPGRADE_LEVEL - callers should check that before offering the
## button, this is just the authoritative guard.
func spend_upgrade_point(stat: String) -> bool:
	if not UPGRADE_STATS.has(stat):
		return false
	if upgrade_points <= 0 or get_upgrade_level(stat) >= MAX_UPGRADE_LEVEL:
		return false
	upgrade_points -= 1
	match stat:
		"strength": upgrade_strength += 1
		"iq": upgrade_iq += 1
		"speed": upgrade_speed += 1
		"racket": upgrade_racket += 1
	save_career()
	return true
