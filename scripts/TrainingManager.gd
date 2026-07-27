extends Node3D
class_name TrainingManager
## Practice mode: no bot, no scoring - just a steady stream of serves to
## random tiles on the player's own side, so reaching the right tile and
## timing the hit window can be drilled in isolation. Reports a spoken
## streak count instead of a full scoreboard. Escape returns to the menu.
##
## Same "press ready" gate as MatchManager.gd before every serve - without
## it the next ball could already be inbound while the streak count was
## still being read out.

const SERVE_DELAY_AFTER_HIT := 0.8
const SERVE_DELAY_AFTER_FAULT := 1.2

@onready var ball: Ball = $Ball
@onready var player: PlayerController = $Player

var streak: int = 0
var best_streak: int = 0
var attempts: int = 0
var _awaiting_serve_confirm: bool = false

func _ready() -> void:
	get_tree().paused = false
	Music.stop_music()
	player.ball = ball
	ball.returned.connect(_on_returned)
	ball.point_resolved.connect(_on_point_resolved)
	Voice.say("training_intro")
	await get_tree().create_timer(2.0).timeout
	_await_ready_then_serve()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause_menu"):
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	elif Input.is_action_just_pressed("check_score"):
		Voice.say_sequence(["best_streak_prefix", "num_%d" % mini(best_streak, 20)])
	elif _awaiting_serve_confirm and Input.is_action_just_pressed("smash"):
		_awaiting_serve_confirm = false
		_serve()

func _await_ready_then_serve() -> void:
	_awaiting_serve_confirm = true
	Sfx3D.play_ui("ready_chime")
	Voice.say("ready_prompt")

func _serve() -> void:
	player.cancel_charge()
	player.reset_position()
	var target_col: int = randi() % Court.GRID
	var target_row: int = randi() % Court.GRID
	ball.start_serve(false, 1, 1, target_col, target_row)

func _on_returned(by: String) -> void:
	if by != "you":
		return
	attempts += 1
	streak += 1
	best_streak = maxi(best_streak, streak)
	Voice.say("num_%d" % mini(streak, 20))
	await get_tree().create_timer(SERVE_DELAY_AFTER_HIT).timeout
	_await_ready_then_serve()

func _on_point_resolved(_winner: String, reason: String) -> void:
	attempts += 1
	streak = 0
	Voice.say(reason)
	await get_tree().create_timer(SERVE_DELAY_AFTER_FAULT).timeout
	_await_ready_then_serve()
