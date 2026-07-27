extends Node
## Transient "we're currently mid-bracket in career mode" state - bridges
## CareerHub -> Match.tscn (reloaded fresh once per round) -> CareerHub, the
## same role GameSettings plays for carrying the chosen difficulty into a
## regular match. Mirrored into CareerData's save on every start/advance so
## closing the app mid-tournament resumes at the right round instead of
## losing that progress (see CareerData.run_* fields).

var active: bool = false
var tier: int = 1
var tournament_name: String = ""  # "" for tiers 1-6; a Grand Slam name for tier 7
var round_names: Array = []
var round_index: int = 0
var is_grand_slam: bool = false
## A fresh random name each round (see OpponentNames.gd) - purely cosmetic,
## so it isn't persisted to CareerData's save; resuming just picks a new one.
## opponent_name (full) is spoken once at round start; opponent_surname is
## used for frequent in-match announcements (see MatchManager.gd), since
## only the surname has pre-rendered clips in every language.
var opponent_name: String = ""
var opponent_surname: String = ""

func _roll_opponent() -> void:
	var first: String = OpponentNames.random_first()
	opponent_surname = OpponentNames.random_last()
	opponent_name = "%s %s" % [first, opponent_surname]

func start(tier_index: int, slam_name: String = "") -> void:
	active = true
	tier = tier_index
	is_grand_slam = tier_index >= CareerTiers.MAX_TIER
	tournament_name = slam_name if is_grand_slam else ""
	round_names = CareerTiers.rounds_for(tier_index)
	round_index = 0
	_roll_opponent()
	CareerData.save_run(tier, tournament_name, round_index, is_grand_slam)

## Restores state from CareerData's persisted run_* fields (a previous
## session left a tournament in progress). Returns false if there's nothing
## to resume.
func resume_from_save() -> bool:
	if not CareerData.run_active:
		return false
	active = true
	tier = CareerData.run_tier
	is_grand_slam = CareerData.run_is_grand_slam
	tournament_name = CareerData.run_tournament_name
	round_names = CareerTiers.rounds_for(tier)
	round_index = clampi(CareerData.run_round_index, 0, round_names.size() - 1)
	_roll_opponent()
	return true

## Grand Slam names are deliberately not translated (see Loc.gd); the
## fictional tier names are.
func tournament_label() -> String:
	return tournament_name if is_grand_slam else Loc.tier_name(tier)

func current_round_name() -> String:
	return Loc.round_name(round_names[round_index])

func current_strength() -> float:
	return CareerTiers.strength_for(tier, round_index, round_names.size())

func is_final_round() -> bool:
	return round_index >= round_names.size() - 1

func advance_round() -> void:
	round_index += 1
	_roll_opponent()
	CareerData.save_run(tier, tournament_name, round_index, is_grand_slam)

func finish(won_it: bool) -> void:
	active = false
	CareerData.clear_run()
	if won_it:
		CareerData.record_win(is_grand_slam, tournament_name)
	else:
		CareerData.record_loss()
