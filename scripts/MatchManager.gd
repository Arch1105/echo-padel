extends Node3D
class_name MatchManager
## Root of a match: standard tennis/padel scoring - Love/15/30/40, deuce and
## advantage past 40-40, first to 6 games (win by 2) per set with a 7-point
## (win by 2) tiebreak at 6 games all, best of three sets. Wires the Ball's
## point_resolved signal to the scoring state machine and reads every score
## change aloud through Voice.
##
## In Career mode, every announcement that would otherwise say generic "bot"
## instead composes the opponent's actual surname in (see CareerRun.gd/
## OpponentNames.gd/Voice.gd's name_* clips) - "Mercer serves." instead of
## "Bot serves." Regular (non-Career) matches are unaffected, since there's
## no persistent named-opponent concept there.
##
## Every serve (including the very first) waits for a "ready" press (Enter/
## Xbox B/PS5 Circle - the same button as a smash, just contextually never
## live at the same time) rather than firing right after the score
## announcement - per feedback, without this the ball was already inbound
## while the screen reader was still finishing the score, so the first
## bounce could get missed entirely.

const POINT_WORDS := ["love", "fifteen", "thirty", "forty"]

@onready var ball: Ball = $Ball
@onready var player: PlayerController = $Player
@onready var bot: BotAI = $Bot

var points_you: int = 0
var points_bot: int = 0
var games_you: int = 0
var games_bot: int = 0
var sets_you: int = 0
var sets_bot: int = 0
var server_is_you: bool = true
var in_tiebreak: bool = false
var tiebreak_you: int = 0
var tiebreak_bot: int = 0
var match_over: bool = false
var _awaiting_serve_confirm: bool = false

func _process(_delta: float) -> void:
	if _awaiting_serve_confirm and Input.is_action_just_pressed("smash"):
		_awaiting_serve_confirm = false
		_serve()

func _await_ready_then_serve() -> void:
	_awaiting_serve_confirm = true
	Sfx3D.play_ui("ready_chime")
	Voice.say("ready_prompt")

func _ready() -> void:
	get_tree().paused = false
	Music.stop_music()
	player.ball = ball
	bot.ball = ball
	player.match_manager = self
	if CareerRun.active:
		bot.strength_override = CareerRun.current_strength()
		Voice.say_dynamic("%s. %s. Your opponent: %s." %
				[CareerRun.tournament_label(), CareerRun.current_round_name(), CareerRun.opponent_name])
	else:
		bot.difficulty = GameSettings.difficulty
	ball.bounced.connect(bot._on_ball_bounced)
	ball.point_resolved.connect(_on_point_resolved)
	Voice.say("match_start")
	_start_set()

## Composes "[prefix] [Surname]" (e.g. point_prefix + "Mercer") in Career
## mode; otherwise speaks the normal fixed "..._bot" phrase.
func _say_bot_prefixed(fixed_key: String, prefix_key: String) -> void:
	if CareerRun.active:
		Voice.say_sequence([prefix_key, OpponentNames.name_key(CareerRun.opponent_surname)])
	else:
		Voice.say(fixed_key)

## Composes "[Surname] serves." in Career mode; otherwise "Bot serves."
func _say_bot_serve() -> void:
	if CareerRun.active:
		Voice.say_sequence([OpponentNames.name_key(CareerRun.opponent_surname), "serves_suffix"])
	else:
		Voice.say("bot_serve")

func announce_score() -> void:
	if in_tiebreak:
		Voice.say_sequence(["num_%d" % tiebreak_you, "num_%d" % tiebreak_bot])
	else:
		_announce_current_score()
	Voice.say_tally("you_prefix", sets_you, "sets_singular", "sets_plural")
	Voice.say_tally("you_prefix", games_you, "games_singular", "games_plural")
	if CareerRun.active:
		var name_key: String = OpponentNames.name_key(CareerRun.opponent_surname)
		Voice.say_tally(name_key, sets_bot, "sets_singular", "sets_plural")
		Voice.say_tally(name_key, games_bot, "games_singular", "games_plural")
	else:
		Voice.say_tally("bot_prefix", sets_bot, "sets_singular", "sets_plural")
		Voice.say_tally("bot_prefix", games_bot, "games_singular", "games_plural")

func _start_set() -> void:
	games_you = 0
	games_bot = 0
	_start_game()

func _start_game() -> void:
	points_you = 0
	points_bot = 0
	in_tiebreak = false
	if server_is_you:
		Voice.say("your_serve")
	else:
		_say_bot_serve()
	_await_ready_then_serve()

func _serve() -> void:
	player.cancel_charge()
	player.reset_position()
	bot.reset_position()
	var server: PaddleCharacter = player if server_is_you else bot
	ball.start_serve(server_is_you, server.current_col, server.current_row_local)

func _on_point_resolved(winner: String, reason: String) -> void:
	if match_over:
		return
	Voice.say(reason)
	await get_tree().create_timer(0.6).timeout
	_award_point(winner)

func _award_point(winner: String) -> void:
	Sfx3D.play_ui("cheer" if winner == "you" else "boo")
	if winner == "you":
		Sfx3D.rumble(0.5, 0.8, 0.12)
	else:
		Sfx3D.rumble(0.6, 0.15, 0.35)
	if winner == "you":
		Voice.say("point_you")
	else:
		_say_bot_prefixed("point_bot", "point_prefix")
	if in_tiebreak:
		_award_tiebreak_point(winner)
		return
	if winner == "you":
		points_you += 1
	else:
		points_bot += 1
	if _would_win_game(points_you, points_bot):
		_win_game("you")
	elif _would_win_game(points_bot, points_you):
		_win_game("bot")
	else:
		_announce_current_score()
		_announce_stakes_before_serve()
		_await_ready_then_serve()

func _would_win_game(p: int, o: int) -> bool:
	return p >= 4 and p - o >= 2

func _announce_current_score() -> void:
	var server_points: int = points_you if server_is_you else points_bot
	var receiver_points: int = points_bot if server_is_you else points_you
	if server_points >= 3 and receiver_points >= 3:
		if server_points == receiver_points:
			Voice.say("deuce")
		else:
			var leader_is_you: bool = (points_you > points_bot)
			if leader_is_you:
				Voice.say("advantage_you")
			else:
				_say_bot_prefixed("advantage_bot", "advantage_prefix")
	else:
		if server_points == receiver_points:
			Voice.say_sequence([POINT_WORDS[server_points], "all"])
		else:
			Voice.say_sequence([POINT_WORDS[server_points], POINT_WORDS[receiver_points]])

func _announce_stakes_before_serve() -> void:
	if _would_win_game(points_you + 1, points_bot):
		_announce_stakes_for("you", games_you + 1, games_bot, sets_you + 1)
	elif _would_win_game(points_bot + 1, points_you):
		_announce_stakes_for("bot", games_bot + 1, games_you, sets_bot + 1)

func _announce_stakes_for(who: String, games_after: int, opp_games: int, sets_after: int) -> void:
	if not (games_after >= 6 and games_after - opp_games >= 2):
		return
	var is_match_point: bool = sets_after >= 2
	if who == "you":
		Voice.say("match_point_you" if is_match_point else "set_point_you")
	elif is_match_point:
		_say_bot_prefixed("match_point_bot", "match_point_prefix")
	else:
		_say_bot_prefixed("set_point_bot", "set_point_prefix")

func _win_game(winner: String) -> void:
	# A love game (won without the bot scoring a single point) earns a
	# Career-mode upgrade point - points_bot/points_you still hold this
	# game's final tally here, since _start_game()/_start_set() (further
	# down) are what reset them for the next game.
	if winner == "you" and points_bot == 0 and CareerRun.active:
		CareerData.add_upgrade_points(1)
		Voice.say_dynamic(Loc.t("upgrade_point_earned_announcement"))
	if winner == "you":
		Voice.say("game_you")
	else:
		_say_bot_prefixed("game_bot", "game_prefix")
	if winner == "you":
		games_you += 1
	else:
		games_bot += 1
	server_is_you = not server_is_you
	if games_you == 6 and games_bot == 6:
		in_tiebreak = true
		tiebreak_you = 0
		tiebreak_bot = 0
		_await_ready_then_serve()
	elif (games_you >= 6 and games_you - games_bot >= 2) or (games_bot >= 6 and games_bot - games_you >= 2):
		_win_set(winner)
	else:
		_start_game()

func _award_tiebreak_point(winner: String) -> void:
	if winner == "you":
		tiebreak_you += 1
	else:
		tiebreak_bot += 1
	Voice.say_sequence(["num_%d" % tiebreak_you, "num_%d" % tiebreak_bot])
	if (tiebreak_you >= 7 and tiebreak_you - tiebreak_bot >= 2) or (tiebreak_bot >= 7 and tiebreak_bot - tiebreak_you >= 2):
		var set_winner: String = "you" if tiebreak_you > tiebreak_bot else "bot"
		if set_winner == "you":
			games_you = 7
		else:
			games_bot = 7
		in_tiebreak = false
		_win_set(set_winner)
	else:
		server_is_you = not server_is_you
		_await_ready_then_serve()

func _win_set(winner: String) -> void:
	if winner == "you":
		Voice.say("set_you")
	else:
		_say_bot_prefixed("set_bot", "set_prefix")
	if winner == "you":
		sets_you += 1
	else:
		sets_bot += 1
	if sets_you >= 2 or sets_bot >= 2:
		_win_match(winner)
	else:
		_start_set()

func _win_match(winner: String) -> void:
	match_over = true
	if CareerRun.active:
		_handle_career_result(winner)
		return
	Voice.say("you_win_match" if winner == "you" else "bot_wins_match")
	await get_tree().create_timer(4.0).timeout
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _handle_career_result(winner: String) -> void:
	if winner == "you":
		if CareerRun.is_final_round():
			var was_grand_slam: bool = CareerRun.is_grand_slam
			Voice.say("career_champion")
			CareerRun.finish(true)
			if not was_grand_slam:
				await get_tree().create_timer(2.0).timeout
				Voice.say("career_promoted")
			await get_tree().create_timer(3.0).timeout
			get_tree().change_scene_to_file("res://scenes/CareerHub.tscn")
		else:
			Voice.say("career_round_won")
			CareerRun.advance_round()
			await get_tree().create_timer(2.5).timeout
			get_tree().change_scene_to_file("res://scenes/Match.tscn")
	else:
		Voice.say("career_round_lost")
		var tier_before: int = CareerRun.tier
		CareerRun.finish(false)
		if CareerData.current_tier < tier_before:
			await get_tree().create_timer(0.8).timeout
			Voice.say("career_demoted")
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://scenes/CareerHub.tscn")
