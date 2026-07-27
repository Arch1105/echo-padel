extends PaddleCharacter
class_name PlayerController
## The human player. Left/Right/Forward/Back (arrow keys, WASD, or a
## controller's left stick) step one tile each press.
##
## Space (or Xbox A / PS5 Cross) charges a normal shot - the longer it's
## held (up to MAX_CHARGE seconds), the harder it's hit. Enter (or Xbox B /
## PS5 Circle) is a separate, dedicated smash - always maximum power and
## always immediate, no charging - a proper hard-to-return blast (see
## Ball.gd for how much harder it is to return than a normal hit). Only
## available off a dolly (a weak mishit lofted ball) - Ball.gd rejects it
## otherwise, so it's not just a free "always hit hardest" option. Pressing
## smash cancels any in-progress normal charge.
##
## Either way, whichever direction is held *at release/press* shapes the
## shot: Left/Right = spin, Back = played off your own back wall first (real
## padel technique) then carried over the net, Forward = short drop shot near
## the net, none = flat straight shot. On a controller, shot shaping instead
## reads the *right* stick (shape_left/right/forward/back) so it's
## independent of the left stick's movement, matching the keyboard's arrow
## keys doing double duty only because there's nothing else to hold.
##
## Movement is suppressed while Space is held - arrow keys are read as shot
## shaping during a charge, not as movement, so charging a curved shot
## doesn't also shuffle the player sideways.
##
## No audio feedback plays during a normal charge (per playtest feedback,
## the soundscape is kept to just hits/bounces/point outcomes) - you gauge
## power by how long you held it, same as you would in real life.

const MAX_CHARGE := 1.2

## Career-mode upgrade effects (see CareerUpgrades.gd for spending points,
## CareerData.gd for the persisted levels) - only ever applied when
## CareerRun.active, so regular Play/Training are untouched.
const STRENGTH_UPGRADE_POWER_BONUS := 0.04
const IQ_UPGRADE_CURVE_MULT_PER_LEVEL := 0.08
const SPEED_UPGRADE_VISUAL_DURATION_CUT := 0.02
const BASE_MOVE_VISUAL_DURATION := 0.12
const MIN_MOVE_VISUAL_DURATION := 0.02

var match_manager: MatchManager

var _charging: bool = false
var _charge_elapsed: float = 0.0
@onready var _listener: AudioListener3D = AudioListener3D.new()

func _ready() -> void:
	is_player_side = true
	super._ready()
	add_child(_listener)
	_listener.current = true
	# Player stands at +Z looking toward the net at Z=0, i.e. toward -Z -
	# that's the default Node3D/AudioListener3D forward, so no rotation needed.
	if CareerRun.active:
		move_visual_duration = maxf(BASE_MOVE_VISUAL_DURATION -
				CareerData.upgrade_speed * SPEED_UPGRADE_VISUAL_DURATION_CUT, MIN_MOVE_VISUAL_DURATION)

func _physics_process(delta: float) -> void:
	var swinging_held: bool = Input.is_action_pressed("swing")

	if not swinging_held:
		if Input.is_action_just_pressed("move_left"):
			move(-1, 0)
		elif Input.is_action_just_pressed("move_right"):
			move(1, 0)
		elif Input.is_action_just_pressed("move_forward"):
			move(0, -1)
		elif Input.is_action_just_pressed("move_back"):
			move(0, 1)

	if Input.is_action_just_pressed("swing"):
		_charging = true
		_charge_elapsed = 0.0
	elif _charging and swinging_held:
		_charge_elapsed += delta
	elif Input.is_action_just_released("swing") and _charging:
		_release_swing()

	if Input.is_action_just_pressed("smash"):
		_attempt_smash()

	if Input.is_action_just_pressed("check_score") and match_manager:
		match_manager.announce_score()

func cancel_charge() -> void:
	_charging = false

func _current_shape() -> Dictionary:
	var curve := 0
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("shape_left"):
		curve = -1
	elif Input.is_action_pressed("move_right") or Input.is_action_pressed("shape_right"):
		curve = 1
	var depth := 0
	if Input.is_action_pressed("move_back") or Input.is_action_pressed("shape_back"):
		depth = -1
	elif Input.is_action_pressed("move_forward") or Input.is_action_pressed("shape_forward"):
		depth = 1
	return {"curve": curve, "depth": depth}

func _release_swing() -> void:
	_charging = false
	var power: float = clampf(_charge_elapsed / MAX_CHARGE, 0.0, 1.0)
	var shape: Dictionary = _current_shape()
	shape["power"] = power
	shape["is_smash"] = false
	_apply_career_upgrades(shape)
	ball.attempt_hit("you", current_col, current_row_local, shape)

func _attempt_smash() -> void:
	_charging = false
	var shape: Dictionary = _current_shape()
	shape["power"] = 1.0
	shape["is_smash"] = true
	_apply_career_upgrades(shape)
	ball.attempt_hit("you", current_col, current_row_local, shape)

## Strength adds a flat bonus to normal-hit power (harmless no-op on a smash,
## which is already max power) - IQ widens how far a shaped shot lands from
## center (Ball.gd clamps this back to a legal in-bounds edge, so it's never
## a downside). Both no-ops outside Career mode.
func _apply_career_upgrades(shape: Dictionary) -> void:
	if not CareerRun.active:
		return
	var power: float = shape.get("power", 0.5)
	shape["power"] = clampf(power + CareerData.upgrade_strength * STRENGTH_UPGRADE_POWER_BONUS, 0.0, 1.0)
	shape["curve_shift_mult"] = 1.0 + CareerData.upgrade_iq * IQ_UPGRADE_CURVE_MULT_PER_LEVEL
