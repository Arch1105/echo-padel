extends Node3D
class_name Ball
## Scripted ball flight - no physics engine involved, since the whole game
## turns on precise, predictable bounce timing. A "hop" is one parabolic arc
## computed from a start point, a straight-line horizontal velocity, and a
## gravity value solved to hit a given peak height at the midpoint and
## return to y=0 exactly at the end of the duration.
##
## Rally flow per side: first bounce is a pure locator cue (bounce_locate
## sfx, no voice callout - the player locates it by ear, not by being told
## a tile name) - no action possible/needed yet. That immediately launches a
## short in-place "continuation" bounce; a hit window opens just before it
## lands and stays open briefly after, and a Space press from the correct
## tile during that window returns the ball. Missing the window (or wrong
## tile) faults the point to whoever hit the good shot.
##
## Both bounces play the same real tennis-ball recording (see Sfx3D.gd) - a
## ball doesn't sound different on its 2nd bounce - but on the *player's own*
## side the 2nd bounce plays a touch louder, since that one's the deadline
## they actually need to react to; the opponent's side doesn't need that
## emphasis.
##
## Off-your-own-wall shots (Down/Back+Space, the real padel technique) are a
## single reflection off the *hitter's own* back wall, not the opponent's:
## the raw straight-line target is aimed *past* that wall (its mirror point),
## so the per-frame integration naturally reflects it there first, then
## carries it forward across the net to land in the opponent's court.
##
## Per playtest feedback the soundscape is kept deliberately sparse: just
## racket hits and bounces, plus a single cheer/boo on point outcomes (see
## Sfx3D.gd) - no continuous ball-tracking tone, no charge tone. Voice still
## speaks fault reasons/score (MatchManager.gd) exactly once per point, via
## the point_resolved signal below.
##
## Three shot types: a smash (its own dedicated button, see
## PlayerController.gd/BotAI.gd - not just "hold the normal swing longer")
## is a forced, guaranteed-max, extra-fast/flat blast whose bounces on the
## *receiving* side are also fast and give a tight, hard-but-not-impossible
## hit window - genuinely difficult to return, by design, for whichever
## side receives it (player or bot); a mishit (any hit below a low-power
## floor, whether under-charged or the bot rolled one) "dollies" up into a
## weak, high, slow ball instead - both of its bounces on the receiving side
## are elongated to match, a real sitter that's easy to attack; anything
## else is a normal hit, exactly as before.

signal bounced(side_is_player: bool, col: int, row_local: int, bounce_number: int)
signal returned(by: String)
signal point_resolved(winner: String, reason: String)

enum HopState { NONE, FLIGHT, CONTINUATION, FROZEN_AWAITING_HIT }

const HIT_WINDOW_PRE := 0.15
const HIT_WINDOW_GRACE := 0.4
const SECOND_BOUNCE_HEIGHT := 0.35
const SECOND_BOUNCE_DURATION := 0.5
## A mishit's "dolly" - both its bounces (see start_serve/_handle_bounce)
## arc higher and take far longer, an easy, slow sitter ball.
const DOLLY_SECOND_BOUNCE_HEIGHT := 0.6
const DOLLY_SECOND_BOUNCE_DURATION := 1.4
## A smash's bounces on the receiving side are low, fast, and give a much
## tighter grace window - hard to return on purpose, not impossible.
const SMASH_SECOND_BOUNCE_HEIGHT := 0.18
const SMASH_SECOND_BOUNCE_DURATION := 0.2
const SMASH_HIT_WINDOW_GRACE := 0.15
const SERVE_DURATION := 0.9
const SERVE_PEAK := 1.4
const MIN_DURATION := 0.45
const MAX_DURATION := 1.1
const MIN_PEAK := 0.6
const MAX_PEAK := 1.8
## A smash is faster and flatter than even a normal full-power hit.
const SMASH_DURATION := 0.32
const SMASH_PEAK := 0.45
const NET_MIN_POWER := 0.08
const MISHIT_MAX_POWER := 0.25
const CURVE_SHIFT := Court.TILE_SIZE * 0.9

var _hop_state: int = HopState.NONE
var _vx: float = 0.0
var _vy: float = 0.0
var _vz: float = 0.0
var _gravity: float = 0.0
var _hop_target_side_is_player: bool = false
var _hop_allow_wall_bank: bool = false
var _hop_bank_side_is_player: bool = false
var hop_is_dolly: bool = false
var _hop_is_smash: bool = false
var _continuation_elapsed: float = 0.0
var _continuation_duration: float = SECOND_BOUNCE_DURATION
var _grace_duration: float = HIT_WINDOW_GRACE
var _grace_elapsed: float = 0.0

var _last_hitter: String = ""
var _bounce_count_this_side: int = 0

var target_col: int = -1
var target_row_local: int = -1
var hit_window_open: bool = false

## Sighted-player visuals only (see PaddleCharacter.gd's racket-glow and the
## dolly highlight below) - the audio-first design needs none of this, so it
## stays purely cosmetic and never gates gameplay.
const BALL_NORMAL_COLOR := Color(0.8, 0.95, 0.2)
const BALL_DOLLY_COLOR := Color(1.0, 0.55, 0.05)
const FIREWORKS_LIFETIME := 1.2

@onready var _mesh: MeshInstance3D = $MeshInstance3D
var _ball_mat: StandardMaterial3D

func _ready() -> void:
	_ball_mat = StandardMaterial3D.new()
	_ball_mat.albedo_color = BALL_NORMAL_COLOR
	_mesh.material_override = _ball_mat

func _opponent_of(side: String) -> String:
	return "bot" if side == "you" else "you"

## Which side is expected to hit next - lets PaddleCharacter.gd know, for
## purely visual purposes, whether *it* is the one with a smash available
## right now (see the racket-glow logic there).
func expected_hitter_is_player() -> bool:
	return _hop_target_side_is_player

## target_col_override/target_row_override let a caller (e.g. training mode)
## aim the serve at a specific tile instead of the default mirrored-medium
## landing spot; pass -1 (the default) to keep the normal match-serve target.
func start_serve(server_side_is_player: bool, server_col: int, server_row_local: int,
		target_col_override: int = -1, target_row_override: int = -1) -> void:
	var from: Vector3 = Court.cell_center(server_side_is_player, server_col, server_row_local) + Vector3(0, 1.0, 0)
	var target_side_is_player: bool = not server_side_is_player
	var land_row: int = target_row_override if target_row_override >= 0 else 1
	var land_col: int = target_col_override if target_col_override >= 0 else server_col
	var to: Vector3 = Court.cell_center(target_side_is_player, land_col, land_row)
	_last_hitter = "you" if server_side_is_player else "bot"
	_bounce_count_this_side = 0
	_launch_flight(from, to, SERVE_DURATION, SERVE_PEAK, target_side_is_player, false)

## by: "you"/"bot". shape: {power: 0..1, curve: -1/0/1, depth: -1/0/1,
## is_smash: bool} (curve: -1 left, 1 right - depth: -1 back/deep bank,
## 1 forward/short, 0 flat). hitter_col/hitter_row_local: the hitter's own
## current tile (shot origin).
func attempt_hit(by: String, hitter_col: int, hitter_row_local: int, shape: Dictionary) -> bool:
	if not hit_window_open:
		return false
	var hitter_side_is_player: bool = (by == "you")
	if hitter_side_is_player != _hop_target_side_is_player:
		return false
	if hitter_col != target_col or hitter_row_local != target_row_local:
		return false

	var is_smash: bool = shape.get("is_smash", false)
	# Smash is only available off a dolly (a weak, floaty mishit) - not a
	# free "always hit hardest" option on every ball, on purpose. Rejecting
	# here leaves the hit window open so a normal Space hit can still be
	# used instead - it's a no-op, not a fault.
	if is_smash and not hop_is_dolly:
		return false

	hit_window_open = false
	_hop_state = HopState.NONE

	var power: float = clampf(shape.get("power", 0.5), 0.0, 1.0)
	var curve: int = clampi(shape.get("curve", 0), -1, 1)
	var depth: int = clampi(shape.get("depth", 0), -1, 1)
	var from: Vector3 = Court.cell_center(hitter_side_is_player, hitter_col, hitter_row_local) + Vector3(0, 0.9, 0)
	var target_side_is_player: bool = not hitter_side_is_player

	if not is_smash and power < NET_MIN_POWER:
		Sfx3D.play_at("net_hit", from, 2.0, 1.0, Sfx3D.NEAR_BUS if hitter_side_is_player else Sfx3D.DISTANT_BUS)
		_resolve_fault("into_net", _opponent_of(by))
		return true

	var sound_name: String
	var is_dolly: bool = false
	var duration: float
	var peak_height: float
	if is_smash:
		sound_name = "smash"
		duration = SMASH_DURATION
		peak_height = SMASH_PEAK
	elif power < MISHIT_MAX_POWER:
		sound_name = "mishit"
		is_dolly = true
		duration = lerp(MAX_DURATION, MIN_DURATION, power)
		peak_height = lerp(MAX_PEAK, MIN_PEAK, power)
	else:
		sound_name = "hit"
		duration = lerp(MAX_DURATION, MIN_DURATION, power)
		peak_height = lerp(MAX_PEAK, MIN_PEAK, power)
	var base_x: float = Court.cell_center(target_side_is_player, hitter_col, 0).x + curve * CURVE_SHIFT

	var land_row: int
	var allow_bank: bool
	var to: Vector3
	if depth < 0:
		# Off-your-own-wall shot (real padel technique): the shot first
		# travels *backward* into the hitter's own back wall, banks off it,
		# then carries forward across the net to land on the opponent's
		# side - not a shot that banks off the opponent's wall.
		land_row = 1
		allow_bank = true
		var own_boundary: float = Court.BACK_WALL_DISTANCE if hitter_side_is_player else -Court.BACK_WALL_DISTANCE
		var land_z: float = Court.cell_center(target_side_is_player, hitter_col, land_row).z
		var raw_z: float = 2.0 * own_boundary - land_z
		to = Vector3(base_x, 0.0, raw_z)
	elif depth > 0:
		land_row = 0
		allow_bank = false
		to = Vector3(base_x, 0.0, Court.cell_center(target_side_is_player, hitter_col, land_row).z)
	else:
		land_row = 1
		allow_bank = false
		to = Vector3(base_x, 0.0, Court.cell_center(target_side_is_player, hitter_col, land_row).z)

	_last_hitter = by
	_bounce_count_this_side = 0
	if hitter_side_is_player:
		var volume_db: float = -2.0 if sound_name == "mishit" else 4.0
		Sfx3D.play_at(sound_name, from, volume_db, 1.0, Sfx3D.NEAR_BUS)
		if sound_name == "smash":
			Sfx3D.rumble_smash()
		elif sound_name == "mishit":
			Sfx3D.rumble(0.15, 0.1, 0.06)
		else:
			Sfx3D.rumble(0.3, 0.9, 0.15)
	else:
		Sfx3D.play_at(sound_name, from, 0.0, 1.0, Sfx3D.DISTANT_BUS)
	if sound_name == "smash":
		_spawn_smash_fireworks(from)
	_launch_flight(from, to, duration, peak_height, target_side_is_player, allow_bank, hitter_side_is_player,
			is_dolly, is_smash)
	returned.emit(by)
	return true

## Sighted-player visual only - a one-shot particle burst at the hit point
## when a smash actually connects. CPUParticles3D (not GPUParticles3D) since
## the project runs the gl_compatibility renderer, which CPU particles work
## on without needing shader support.
func _spawn_smash_fireworks(pos: Vector3) -> void:
	var particles := CPUParticles3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	particles.mesh = mesh
	particles.amount = 36
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 180.0
	particles.gravity = Vector3(0, -4.5, 0)
	particles.initial_velocity_min = 2.5
	particles.initial_velocity_max = 4.5
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.2
	particles.color = Color(1.0, 0.75, 0.1)
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.95, 0.4))
	grad.add_point(0.55, Color(1.0, 0.45, 0.05))
	grad.add_point(1.0, Color(1.0, 0.1, 0.05, 0.0))
	particles.color_ramp = grad
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos + Vector3(0, 0.3, 0)
	particles.emitting = true
	var t: SceneTreeTimer = get_tree().create_timer(FIREWORKS_LIFETIME)
	t.timeout.connect(particles.queue_free)

func _launch_flight(from: Vector3, to: Vector3, duration: float, peak_height: float,
		target_side_is_player: bool, allow_wall_bank: bool, bank_side_is_player: bool = false,
		is_dolly: bool = false, is_smash: bool = false) -> void:
	global_position = from
	_vx = (to.x - from.x) / duration
	_vz = (to.z - from.z) / duration
	_vy = 4.0 * peak_height / duration
	_gravity = 8.0 * peak_height / (duration * duration)
	_hop_target_side_is_player = target_side_is_player
	_hop_allow_wall_bank = allow_wall_bank
	_hop_bank_side_is_player = bank_side_is_player
	hop_is_dolly = is_dolly
	_hop_is_smash = is_smash
	_hop_state = HopState.FLIGHT

func _physics_process(delta: float) -> void:
	if _ball_mat:
		_ball_mat.albedo_color = BALL_DOLLY_COLOR if hop_is_dolly else BALL_NORMAL_COLOR
	match _hop_state:
		HopState.FLIGHT, HopState.CONTINUATION:
			_integrate(delta)
			if _hop_state == HopState.CONTINUATION:
				_continuation_elapsed += delta
				if not hit_window_open and _continuation_elapsed >= _continuation_duration - HIT_WINDOW_PRE:
					hit_window_open = true
		HopState.FROZEN_AWAITING_HIT:
			_grace_elapsed += delta
			if _grace_elapsed >= _grace_duration:
				hit_window_open = false
				_hop_state = HopState.NONE
				_resolve_fault("missed", _last_hitter)

func _integrate(delta: float) -> void:
	_vy -= _gravity * delta
	global_position.y += _vy * delta
	global_position.x += _vx * delta
	global_position.z += _vz * delta

	if _hop_allow_wall_bank:
		var boundary: float = Court.BACK_WALL_DISTANCE if _hop_bank_side_is_player else -Court.BACK_WALL_DISTANCE
		if (_hop_bank_side_is_player and global_position.z >= boundary) or \
				(not _hop_bank_side_is_player and global_position.z <= boundary):
			global_position.z = 2.0 * boundary - global_position.z
			_vz = -_vz

	if global_position.y <= 0.0 and _vy < 0.0:
		_handle_bounce()

func _handle_bounce() -> void:
	global_position.y = 0.0
	_vy = 0.0

	if absf(global_position.x) > Court.COURT_HALF_WIDTH:
		_resolve_fault("out", _opponent_of(_last_hitter))
		return

	var landed_side_is_player: bool = global_position.z > 0.0
	var col: int = Court.x_to_col(global_position.x)
	var row_local: int = Court.z_to_row_local(absf(global_position.z))
	_bounce_count_this_side += 1
	bounced.emit(landed_side_is_player, col, row_local, _bounce_count_this_side)

	# Which side a bounce is on is carried by the bus (clear+near vs
	# muffled+distant, see Sfx3D.gd), not by relying on distance/panning
	# alone - those turned out ambiguous on a court this small.
	var bus: String = Sfx3D.NEAR_BUS if landed_side_is_player else Sfx3D.DISTANT_BUS
	var pitch: float = Sfx3D.row_pitch_multiplier(row_local)

	if _bounce_count_this_side == 1:
		target_col = col
		target_row_local = row_local
		var volume_db: float = 6.0 if landed_side_is_player else 0.0
		Sfx3D.play_at("bounce_locate", global_position, volume_db, pitch, bus)
		if landed_side_is_player:
			Sfx3D.rumble(0.15, 0.3, 0.08)
		var cont_height: float
		if hop_is_dolly:
			cont_height = DOLLY_SECOND_BOUNCE_HEIGHT
			_continuation_duration = DOLLY_SECOND_BOUNCE_DURATION
			_grace_duration = HIT_WINDOW_GRACE
		elif _hop_is_smash:
			cont_height = SMASH_SECOND_BOUNCE_HEIGHT
			_continuation_duration = SMASH_SECOND_BOUNCE_DURATION
			_grace_duration = SMASH_HIT_WINDOW_GRACE
		else:
			cont_height = SECOND_BOUNCE_HEIGHT
			_continuation_duration = SECOND_BOUNCE_DURATION
			_grace_duration = HIT_WINDOW_GRACE
		_vx = 0.0
		_vz = 0.0
		_vy = 4.0 * cont_height / _continuation_duration
		_gravity = 8.0 * cont_height / (_continuation_duration * _continuation_duration)
		_continuation_elapsed = 0.0
		_hop_state = HopState.CONTINUATION
	else:
		# Same real bounce recording both times (a ball doesn't sound
		# different on its 2nd bounce) - but the player's own side gets it
		# louder still since that's the deadline they need to react to.
		var volume_db: float = 10.0 if landed_side_is_player else 2.0
		Sfx3D.play_at("bounce_second", global_position, volume_db, pitch, bus)
		if landed_side_is_player:
			Sfx3D.rumble(0.25, 0.5, 0.1)
		_grace_elapsed = 0.0
		_hop_state = HopState.FROZEN_AWAITING_HIT
		# hit_window_open should already be true by now (opened pre-emptively
		# during CONTINUATION); force it open in case timing landed exactly here.
		hit_window_open = true

func _resolve_fault(reason: String, winner: String) -> void:
	_hop_state = HopState.NONE
	hit_window_open = false
	point_resolved.emit(winner, reason)
