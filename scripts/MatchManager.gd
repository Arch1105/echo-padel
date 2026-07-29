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
## In a LAN match (see NetworkSession.gd), only the *host's* MatchManager
## actually runs this scoring state machine - it's the single source of
## truth, exactly as for a local bot match, just with the "Bot" node driven
## by a remote human's input instead of AI. Every _speak()/_speak_sequence()/
## _speak_tally() call additionally relays to the client (with "you"/"bot"
## keys flipped, since the client's own "you" is the host's "bot" slot - see
## NetworkSession.flip_you_bot_key()), and _sync_network_score() mirrors the
## raw score fields the same way, so the client's own local MatchManager -
## which never independently computes anything - can still answer its own
## Check Score button correctly using the exact same _announce_current_score
## code, unmodified, just fed mirrored numbers. Whenever an announcement is
## about the opponent, both devices substitute the opponent's typed name in
## place of the generic "Bot" wording (see NetworkSession.speak_local_keys())
## - the name itself never crosses the network, since each device already
## knows its own opponent's name from the discovery handshake; only the
## relay's existing timing cue does.
##
## LAN matches can also opt into "Quick Online Mode" (see NetworkSession.
## quick_mode, OnlineModeSelect.tscn) - the whole match becomes a single
## race to 7 points, win by 2, with no games or sets at all. This reuses
## _award_tiebreak_point()'s existing win condition unchanged (a regular
## match's own 6-6 tiebreak uses the exact same rule); quick_mode (set from
## _ready()) just decides whether reaching it ends the match outright instead
## of starting a new set - see _start_quick_race().
##
## Every serve (including the very first) waits for a "ready" press (Enter/
## Xbox B/PS5 Circle - the same button as a smash, just contextually never
## live at the same time) rather than firing right after the score
## announcement - per feedback, without this the ball was already inbound
## while the screen reader was still finishing the score, so the first
## bounce could get missed entirely. In a LAN match both players confirm
## ready independently before every point, not just whoever's serving.

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

## LAN-only (see NetworkSession.quick_mode) - "Quick Online Mode": the whole
## match is a single race to 7 points, win by 2, no games/sets at all - the
## exact same win condition a *regular* match's 6-6 tiebreak already uses
## (see _award_tiebreak_point()), just run from the very first point instead
## of only at 6 games all. Set from NetworkSession.quick_mode in _ready() -
## the client reads it too (not just the host), purely so its own local
## announce_score() knows to skip the irrelevant games/sets tallies.
var quick_mode: bool = false

var _awaiting_serve_confirm: bool = false
var _host_ready_confirmed: bool = false
var _client_ready_confirmed: bool = false
var _client_awaiting_ready: bool = false

func _process(_delta: float) -> void:
	var is_network_client: bool = NetworkSession.is_networked and not NetworkSession.is_host
	if is_network_client:
		if _client_awaiting_ready and Input.is_action_just_pressed("smash"):
			_client_awaiting_ready = false
			NetworkSession.submit_ready.rpc()
		return

	if not _awaiting_serve_confirm:
		return
	if Input.is_action_just_pressed("smash"):
		_host_ready_confirmed = true
	if NetworkSession.is_networked and NetworkSession.consume_remote_ready():
		_client_ready_confirmed = true
	if _host_ready_confirmed and _client_ready_confirmed:
		_awaiting_serve_confirm = false
		_serve()

func _await_ready_then_serve() -> void:
	_awaiting_serve_confirm = true
	_host_ready_confirmed = false
	_client_ready_confirmed = not NetworkSession.is_networked
	Sfx3D.play_ui("ready_chime")
	Voice.say("ready_prompt")
	if NetworkSession.is_networked:
		NetworkSession.relay_await_ready()

## Called by NetworkSession's net_await_ready RPC on the client - the local
## mirror of _await_ready_then_serve() above, for the player who isn't
## serving this point (or is, from their own perspective - either way, both
## players see this every point).
func client_show_ready_prompt() -> void:
	_client_awaiting_ready = true
	Sfx3D.play_ui("ready_chime")
	Voice.say("ready_prompt")

func _ready() -> void:
	get_tree().paused = false
	Music.stop_music()
	player.match_manager = self

	if NetworkSession.is_networked:
		quick_mode = NetworkSession.quick_mode

	var is_network_client: bool = NetworkSession.is_networked and not NetworkSession.is_host
	if is_network_client:
		# The client never runs this scoring state machine itself - see the
		# class doc comment. It just waits for the host's relayed events.
		return

	player.ball = ball
	bot.ball = ball
	ball.is_puppet = false
	if NetworkSession.is_networked:
		# LAN match: no AI, no Career - the "Bot" node is driven by the
		# remote player's real input (see BotAI.gd/NetworkSession.gd).
		_speak("quick_match_start" if quick_mode else "match_start")
	elif CareerRun.active:
		bot.strength_override = CareerRun.current_strength()
		Voice.say_dynamic("%s. %s. Your opponent: %s." %
				[CareerRun.tournament_label(), CareerRun.current_round_name(), CareerRun.opponent_name])
		ball.bounced.connect(bot._on_ball_bounced)
		_speak("match_start")
	else:
		bot.difficulty = GameSettings.difficulty
		ball.bounced.connect(bot._on_ball_bounced)
		_speak("match_start")
	ball.point_resolved.connect(_on_point_resolved)
	if quick_mode:
		_start_quick_race()
	else:
		_start_set()

## --- Speak-and-relay wrappers - see class doc comment. ---

func _speak(key: String) -> void:
	if NetworkSession.is_networked:
		NetworkSession.speak_local_keys([key])
	else:
		Voice.say(key)
	if NetworkSession.is_networked and NetworkSession.is_host:
		NetworkSession.relay_speak([key])

func _speak_sequence(keys: Array) -> void:
	if NetworkSession.is_networked:
		NetworkSession.speak_local_keys(keys)
	else:
		Voice.say_sequence(keys)
	if NetworkSession.is_networked and NetworkSession.is_host:
		NetworkSession.relay_speak(keys)

func _speak_tally(prefix_key: String, count: int, singular_key: String, plural_key: String) -> void:
	var keys: Array[String] = Voice.tally_keys(prefix_key, count, singular_key, plural_key)
	if NetworkSession.is_networked:
		NetworkSession.speak_local_keys(keys)
	else:
		Voice.say_tally(prefix_key, count, singular_key, plural_key)
	if NetworkSession.is_networked and NetworkSession.is_host:
		NetworkSession.relay_speak(keys)

## Composes "[prefix] [Surname]" (e.g. point_prefix + "Mercer") in Career
## mode; otherwise speaks the normal fixed "..._bot" phrase.
func _say_bot_prefixed(fixed_key: String, prefix_key: String) -> void:
	if CareerRun.active:
		Voice.say_sequence([prefix_key, OpponentNames.name_key(CareerRun.opponent_surname)])
	else:
		_speak(fixed_key)

## Composes "[Surname] serves." in Career mode; otherwise "Bot serves."
func _say_bot_serve() -> void:
	if CareerRun.active:
		Voice.say_sequence([OpponentNames.name_key(CareerRun.opponent_surname), "serves_suffix"])
	else:
		_speak("bot_serve")

func announce_score() -> void:
	if in_tiebreak:
		_speak_sequence(["num_%d" % tiebreak_you, "num_%d" % tiebreak_bot])
	else:
		_announce_current_score()
	if quick_mode:
		return  # no games/sets in Quick Online Mode - the race score above is the whole story
	_speak_tally("you_prefix", sets_you, "sets_singular", "sets_plural")
	_speak_tally("you_prefix", games_you, "games_singular", "games_plural")
	if CareerRun.active:
		var name_key: String = OpponentNames.name_key(CareerRun.opponent_surname)
		Voice.say_tally(name_key, sets_bot, "sets_singular", "sets_plural")
		Voice.say_tally(name_key, games_bot, "games_singular", "games_plural")
	else:
		_speak_tally("bot_prefix", sets_bot, "sets_singular", "sets_plural")
		_speak_tally("bot_prefix", games_bot, "games_singular", "games_plural")

## Quick Online Mode's entire match, in place of _start_set()/_start_game() -
## goes straight into the same race-to-7-win-by-2 scoring _award_tiebreak_
## point() already implements for a regular match's 6-6 tiebreak, just from
## the very first point and ending the match outright on a win (see
## _award_tiebreak_point()'s quick_mode branch) instead of starting a new set.
func _start_quick_race() -> void:
	in_tiebreak = true
	tiebreak_you = 0
	tiebreak_bot = 0
	if server_is_you:
		_speak("your_serve")
	else:
		_say_bot_serve()
	_sync_network_score()
	_await_ready_then_serve()

func _start_set() -> void:
	games_you = 0
	games_bot = 0
	_start_game()

func _start_game() -> void:
	points_you = 0
	points_bot = 0
	in_tiebreak = false
	if server_is_you:
		_speak("your_serve")
	else:
		_say_bot_serve()
	_await_ready_then_serve()

func _serve() -> void:
	player.cancel_charge()
	player.reset_position()
	bot.reset_position()
	if NetworkSession.is_networked and NetworkSession.is_host:
		NetworkSession.relay_paddle_position(bot.current_col, bot.current_row_local)
	var server: PaddleCharacter = player if server_is_you else bot
	ball.start_serve(server_is_you, server.current_col, server.current_row_local)

func _on_point_resolved(winner: String, reason: String) -> void:
	if match_over:
		return
	_speak(reason)
	await get_tree().create_timer(0.6).timeout
	_award_point(winner)

func _award_point(winner: String) -> void:
	Sfx3D.play_ui("cheer" if winner == "you" else "boo")
	if NetworkSession.is_networked and NetworkSession.is_host:
		NetworkSession.relay_cheer_or_boo(winner == "you")
	if winner == "you":
		Sfx3D.rumble(0.5, 0.8, 0.12)
		if NetworkSession.is_networked and NetworkSession.is_host:
			NetworkSession.relay_rumble(0.6, 0.15, 0.35)  # the client just lost this point
	else:
		Sfx3D.rumble(0.6, 0.15, 0.35)
		if NetworkSession.is_networked and NetworkSession.is_host:
			NetworkSession.relay_rumble(0.5, 0.8, 0.12)  # the client just won this point
	if winner == "you":
		_speak("point_you")
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
		_sync_network_score()
		_await_ready_then_serve()

func _would_win_game(p: int, o: int) -> bool:
	return p >= 4 and p - o >= 2

func _announce_current_score() -> void:
	var server_points: int = points_you if server_is_you else points_bot
	var receiver_points: int = points_bot if server_is_you else points_you
	if server_points >= 3 and receiver_points >= 3:
		if server_points == receiver_points:
			_speak("deuce")
		else:
			var leader_is_you: bool = (points_you > points_bot)
			if leader_is_you:
				_speak("advantage_you")
			else:
				_say_bot_prefixed("advantage_bot", "advantage_prefix")
	else:
		if server_points == receiver_points:
			_speak_sequence([POINT_WORDS[server_points], "all"])
		else:
			_speak_sequence([POINT_WORDS[server_points], POINT_WORDS[receiver_points]])

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
		_speak("match_point_you" if is_match_point else "set_point_you")
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
		_speak("game_you")
	else:
		_say_bot_prefixed("game_bot", "game_prefix")
	if winner == "you":
		games_you += 1
	else:
		games_bot += 1
	server_is_you = not server_is_you
	_sync_network_score()
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
	_speak_sequence(["num_%d" % tiebreak_you, "num_%d" % tiebreak_bot])
	if (tiebreak_you >= 7 and tiebreak_you - tiebreak_bot >= 2) or (tiebreak_bot >= 7 and tiebreak_bot - tiebreak_you >= 2):
		var set_winner: String = "you" if tiebreak_you > tiebreak_bot else "bot"
		in_tiebreak = false
		if quick_mode:
			_win_match(set_winner)
			return
		if set_winner == "you":
			games_you = 7
		else:
			games_bot = 7
		_win_set(set_winner)
	else:
		server_is_you = not server_is_you
		_sync_network_score()
		_await_ready_then_serve()

func _win_set(winner: String) -> void:
	if winner == "you":
		_speak("set_you")
	else:
		_say_bot_prefixed("set_bot", "set_prefix")
	if winner == "you":
		sets_you += 1
	else:
		sets_bot += 1
	_sync_network_score()
	if sets_you >= 2 or sets_bot >= 2:
		_win_match(winner)
	else:
		_start_set()

func _win_match(winner: String) -> void:
	match_over = true
	if CareerRun.active:
		_handle_career_result(winner)
		return
	_speak("you_win_match" if winner == "you" else "bot_wins_match")
	if NetworkSession.is_networked:
		# Coins are LAN-only (see OnlineData.gd) - only the winner's own
		# device awards them, and only once, right here on the host's
		# authoritative copy of the result; the client's own award happens
		# symmetrically in NetworkSession.net_match_over().
		if winner == "you":
			var coins: int = OnlineData.COINS_PER_QUICK_WIN if quick_mode else OnlineData.COINS_PER_WIN
			OnlineData.add_coins(coins)
		if NetworkSession.is_host:
			NetworkSession.relay_match_over(winner == "you")
	await get_tree().create_timer(4.0).timeout
	if NetworkSession.is_networked:
		NetworkSession.end_session()
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

## Mirrors the raw score fields to the client, with "you"/"bot" swapped -
## the client's own local MatchManager (which never independently computes
## any of this - see the class doc comment) just stores whatever it's told,
## so its own unmodified _announce_current_score()/announce_score() reads
## correctly from its own perspective.
func _sync_network_score() -> void:
	if NetworkSession.is_networked and NetworkSession.is_host:
		NetworkSession.relay_score_sync(points_bot, points_you, games_bot, games_you,
				sets_bot, sets_you, not server_is_you, in_tiebreak, tiebreak_bot, tiebreak_you)

## Called by NetworkSession's net_score_sync RPC on the client.
func client_apply_score_sync(p_you: int, p_bot: int, g_you: int, g_bot: int, s_you: int, s_bot: int,
		serve_you: bool, tiebreak: bool, tb_you: int, tb_bot: int) -> void:
	points_you = p_you
	points_bot = p_bot
	games_you = g_you
	games_bot = g_bot
	sets_you = s_you
	sets_bot = s_bot
	server_is_you = serve_you
	in_tiebreak = tiebreak
	tiebreak_you = tb_you
	tiebreak_bot = tb_bot
