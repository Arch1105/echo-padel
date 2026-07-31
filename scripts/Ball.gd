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
## Wall Mode (NetworkSession.wall_mode, a third LAN-only online option
## alongside Online/Quick Online - see OnlineModeSelect.gd) turns the side
## walls (already-existing visual geometry, see Court.gd's _build_side_
## walls()) from decorative into interactive: a shot whose curve would
## otherwise sail out to the side instead reflects off that wall and lands
## on the *opposite* side of the court, still in play. Uses the exact same
## "aim past the boundary, let the per-frame integration reflect it there"
## trick as the back-wall case above, just mirrored across the court's
## center rather than back toward the same side - see attempt_hit()'s
## side_wall_x/final_x math and _integrate()'s _hop_allow_side_wall_bank
## check. Every other mode (Online, Quick Online, Play, Career, Training)
## is untouched - a wide curve still simply goes out for all of them.
##
## Per playtest feedback the soundscape is kept deliberately sparse: just
## racket hits and bounces, plus a single cheer/boo on point outcomes (see
## Sfx3D.gd) - no continuous ball-tracking tone, no charge tone. Voice still
## speaks fault reasons/score (MatchManager.gd) exactly once per point, via
## the point_resolved signal below.
##
## Four shot types: a smash (its own dedicated button, see
## PlayerController.gd/BotAI.gd - not just "hold the normal swing longer")
## is a forced, guaranteed-max, extra-fast/flat blast whose bounces on the
## *receiving* side are also fast and give a tight, hard-but-not-impossible
## hit window - genuinely difficult to return, by design, for whichever
## side receives it (player or bot); a drop shot (also its own dedicated
## button - see PlayerController.gd) always lands in the front row near the
## net regardless of held direction, with its own noticeably higher net-fault
## floor than a normal shot (a real dink is meant to risk clipping the net) -
## a brief tap above that floor still dollies up into a weak sitter exactly
## like a weak normal shot would, only a real charge produces a genuine,
## poised drop shot with its own distinct sound; a mishit (any hit - normal
## or drop shot - below a low-power floor) "dollies" up into a weak, high,
## slow ball instead - both of its bounces on the receiving side are
## elongated to match, a real sitter that's easy to attack; anything else is
## a normal hit, exactly as before.

signal bounced(side_is_player: bool, col: int, row_local: int, bounce_number: int)
signal returned(by: String)
## won_via_smash: true only when reason is "missed" (a return failure) and
## the shot the receiver failed to return was itself a smash - see
## _last_hit_was_smash below. Only meaningful to Wall Mode's win condition
## (see MatchManager.gd's _award_wall_point()) - every other mode ignores it.
signal point_resolved(winner: String, reason: String, won_via_smash: bool)

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
## A Super Smash's receiving bounce is tighter still than a regular smash's -
## genuinely very difficult, but never zero/impossible, per feedback.
const SUPER_SMASH_SECOND_BOUNCE_HEIGHT := 0.14
const SUPER_SMASH_SECOND_BOUNCE_DURATION := 0.15
const SUPER_SMASH_HIT_WINDOW_GRACE := 0.1
const SERVE_DURATION := 0.9
const SERVE_PEAK := 1.4
const MIN_DURATION := 0.45
const MAX_DURATION := 1.1
const MIN_PEAK := 0.6
const MAX_PEAK := 1.8
## A smash is faster and flatter than even a normal full-power hit.
const SMASH_DURATION := 0.32
const SMASH_PEAK := 0.45
## Wall Mode's one-per-game Super Smash (see PlayerController.gd's class doc
## comment) - noticeably faster/flatter still than a regular smash.
const SUPER_SMASH_DURATION := 0.18
const SUPER_SMASH_PEAK := 0.3
## How long attempt_hit() waits after speaking "Super Smash!" before the
## ball actually gets hit - covers the longer of the two pre-rendered
## fallback clips (English ~1.78s, Spanish ~2.02s) with a small buffer, so
## the announcement is always heard in full before the (much faster) ball
## arrives, giving the opponent a real chance to react.
const SUPER_SMASH_ANNOUNCE_DELAY := 2.2
const NET_MIN_POWER := 0.08
## A drop shot risks the net on purpose - a genuine dink barely clears it, so
## this floor sits above the normal-shot one, widening how brief a tap has to
## be before it's an outright fault. Above that floor but still below
## MISHIT_MAX_POWER, a weak drop shot dollies up into an easy sitter exactly
## like a weak *normal* shot would (see attempt_hit) - only a real charge
## clears MISHIT_MAX_POWER and produces a genuine, poised drop shot with its
## own distinct sound.
const DROP_SHOT_NET_MIN_POWER := 0.12
const MISHIT_MAX_POWER := 0.25
const CURVE_SHIFT := Court.TILE_SIZE * 0.9
## Career-mode Racket upgrade: added to the player's own receiving grace
## window per level (see _handle_bounce()) - up to +0.3s at MAX_UPGRADE_LEVEL
## (50, see CareerData.gd). A wider window still only helps *timing* - it
## doesn't move the player to the right tile or tell them where the ball
## is - so even fully maxed this stays a real edge, not a guarantee.
const RACKET_UPGRADE_GRACE_BONUS := 0.3 / 50.0

var _hop_state: int = HopState.NONE
var _vx: float = 0.0
var _vy: float = 0.0
var _vz: float = 0.0
var _gravity: float = 0.0
var _hop_target_side_is_player: bool = false
var _hop_allow_wall_bank: bool = false
var _hop_bank_side_is_player: bool = false
var _hop_allow_side_wall_bank: bool = false
var _hop_side_wall_x: float = 0.0
var hop_is_dolly: bool = false
var _hop_is_smash: bool = false
var _hop_is_super_smash: bool = false
var _continuation_elapsed: float = 0.0
var _continuation_duration: float = SECOND_BOUNCE_DURATION
var _grace_duration: float = HIT_WINDOW_GRACE
var _grace_elapsed: float = 0.0

var _last_hitter: String = ""
var _last_hit_was_smash: bool = false
var _bounce_count_this_side: int = 0

var target_col: int = -1
var target_row_local: int = -1
var hit_window_open: bool = false

## True only on the client's own Ball node in a LAN match (see
## NetworkSession.gd) - a puppet never runs its own physics/hop-state
## machine, it just displays whatever the host's authoritative Ball tells it
## via puppet_apply_transform()/puppet_play_visual_effect() (see those, and
## _play_and_relay() below, for how the host keeps it in sync).
var is_puppet: bool = false

## Sighted-player visuals only (see PaddleCharacter.gd's racket-glow and the
## dolly highlight below) - the audio-first design needs none of this, so it
## stays purely cosmetic and never gates gameplay.
const BALL_NORMAL_COLOR := Color(0.8, 0.95, 0.2)
const BALL_DOLLY_COLOR := Color(1.0, 0.55, 0.05)
const FIREWORKS_LIFETIME := 1.2
const BOUNCE_FLASH_LIFETIME := 0.5

## A flat, dark "contact shadow" tracking the ball's XZ position at all
## times, sized and faded by height (see _update_shadow()) - a real tennis
## broadcast trick for reading how high/far a ball is off a 2D-ish camera
## angle without needing full HRTF-quality depth cues, purely a sighted-
## player aid (per feedback asking for the ball to be easier to judge).
const SHADOW_MAX_HEIGHT := 1.8
const SHADOW_MIN_SCALE := 0.3
const SHADOW_MAX_ALPHA := 0.45
const SHADOW_MIN_ALPHA := 0.12

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _shadow: MeshInstance3D = $Shadow
var _ball_mat: StandardMaterial3D
var _shadow_mat: StandardMaterial3D

func _ready() -> void:
	_ball_mat = StandardMaterial3D.new()
	_ball_mat.albedo_color = BALL_NORMAL_COLOR
	# A real tennis ball is felted, not glossy - roughness near 1 keeps
	# specular highlights soft/diffuse instead of a shiny plastic look.
	_ball_mat.roughness = 0.92
	_ball_mat.metallic = 0.0
	_mesh.material_override = _ball_mat

	_shadow_mat = StandardMaterial3D.new()
	_shadow_mat.albedo_color = Color(0.0, 0.0, 0.0, SHADOW_MAX_ALPHA)
	_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = _shadow_mat

## Keeps the ground shadow blob under the ball's current XZ position at all
## times, shrinking and fading it the higher the ball currently is - runs
## for both the host's real ball and the client's puppet copy, since both
## have a valid, up-to-date global_position to read from.
func _update_shadow() -> void:
	var height_frac: float = clampf(global_position.y / SHADOW_MAX_HEIGHT, 0.0, 1.0)
	var scale_amount: float = lerp(1.0, SHADOW_MIN_SCALE, height_frac)
	_shadow.scale = Vector3(scale_amount, 1.0, scale_amount)
	_shadow.global_position = Vector3(global_position.x, 0.01, global_position.z)
	_shadow_mat.albedo_color.a = lerp(SHADOW_MAX_ALPHA, SHADOW_MIN_ALPHA, height_frac)

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
	if is_puppet:
		return  # the client's puppet Ball only ever displays what the host broadcasts
	var from: Vector3 = Court.cell_center(server_side_is_player, server_col, server_row_local) + Vector3(0, 1.0, 0)
	var target_side_is_player: bool = not server_side_is_player
	var land_row: int = target_row_override if target_row_override >= 0 else 1
	var land_col: int = target_col_override if target_col_override >= 0 else server_col
	var to: Vector3 = Court.cell_center(target_side_is_player, land_col, land_row)
	_last_hitter = "you" if server_side_is_player else "bot"
	_last_hit_was_smash = false
	_bounce_count_this_side = 0
	_launch_flight(from, to, SERVE_DURATION, SERVE_PEAK, target_side_is_player, false)

## by: "you"/"bot". shape: {power: 0..1, curve: -1/0/1, depth: -1/0/1,
## is_smash: bool, is_drop_shot: bool} (curve: -1 left, 1 right - depth: -1
## back/deep bank, 1 forward/short, 0 flat - either is_drop_shot=true or
## depth=1 alone is enough to be treated as a drop shot, see
## PlayerController.gd's dedicated drop shot button vs. its older Forward-
## shape technique). hitter_col/hitter_row_local: the hitter's own current tile
## (shot origin).
func attempt_hit(by: String, hitter_col: int, hitter_row_local: int, shape: Dictionary) -> bool:
	if is_puppet:
		return false  # the client's puppet Ball never resolves hits itself - see NetworkSession.submit_hit
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

	# Wall Mode's one-per-game Super Smash - validated against wall_mode
	# itself here (not just trusted from the shape dict) since this is the
	# one place that actually resolves a hit; PlayerController.gd already
	# only ever sets this flag inside Wall Mode, but the host - the only
	# device that ever reaches this code - shouldn't honor it if it somehow
	# arrived any other way. No spin allowed on one, also enforced here
	# rather than just trusting the client already zeroed it.
	var is_super_smash: bool = is_smash and NetworkSession.wall_mode and shape.get("is_super_smash", false)

	hit_window_open = false
	_hop_state = HopState.NONE

	# Super Smash: announce first, then actually wait for it to finish
	# speaking before the ball gets hit - the whole point is a warning the
	# opponent has time to react to, not something that lands at the same
	# instant as the (much faster) ball itself. Deliberately as early as
	# possible in this function - the rest of the shot's math below doesn't
	# depend on real time passing, so delaying here (rather than delaying
	# just before the eventual _launch_flight() call) keeps this the one
	# and only place attempt_hit() ever waits.
	if is_super_smash:
		NetworkSession.speak_local_keys(["super_smash"])
		if NetworkSession.is_networked and NetworkSession.is_host:
			NetworkSession.relay_speak(["super_smash"])
		await get_tree().create_timer(SUPER_SMASH_ANNOUNCE_DELAY).timeout

	var power: float = clampf(shape.get("power", 0.5), 0.0, 1.0)
	var curve: int = 0 if is_super_smash else clampi(shape.get("curve", 0), -1, 1)
	var depth: int = clampi(shape.get("depth", 0), -1, 1)
	# Any shot landing short (depth > 0) reads as a drop shot, whether it came
	# from the dedicated drop-shot button (which always sets depth to 1
	# itself) or from holding Forward while releasing a normal swing - the
	# older, easier-to-miss way to shape a short shot (see PlayerController.
	# gd's class doc comment; the bot uses this path too, via BotAI._swing()'s
	# random depth choice). Both land in the same tile, so both should sound
	# and risk the same way - previously only the dedicated button did.
	var is_drop_shot: bool = shape.get("is_drop_shot", false) or depth > 0
	if is_drop_shot:
		depth = 1
	var from: Vector3 = Court.cell_center(hitter_side_is_player, hitter_col, hitter_row_local) + Vector3(0, 0.9, 0)
	var target_side_is_player: bool = not hitter_side_is_player

	var net_min_power: float = DROP_SHOT_NET_MIN_POWER if is_drop_shot else NET_MIN_POWER
	if not is_smash and power < net_min_power:
		_play_and_relay("net_hit", from, 2.0, 1.0, Sfx3D.NEAR_BUS if hitter_side_is_player else Sfx3D.DISTANT_BUS)
		_resolve_fault("into_net", _opponent_of(by))
		return true

	var sound_name: String
	var is_dolly: bool = false
	var duration: float
	var peak_height: float
	if is_smash:
		sound_name = "super_smash_hit" if is_super_smash else "smash"
		duration = SUPER_SMASH_DURATION if is_super_smash else SMASH_DURATION
		peak_height = SUPER_SMASH_PEAK if is_super_smash else SMASH_PEAK
	elif is_drop_shot and power < MISHIT_MAX_POWER:
		# A brief-but-not-instant tap dollies up into an easy sitter, same as
		# a weak normal shot would (per feedback: a tap shouldn't *always*
		# fault into the net, just risk it more than a normal shot does).
		sound_name = "mishit"
		is_dolly = true
		duration = lerp(MAX_DURATION, MIN_DURATION, power)
		peak_height = lerp(MAX_PEAK, MIN_PEAK, power)
	elif is_drop_shot:
		# A real charge - genuine, poised drop shot with its own distinct
		# sound, never classified as a mishit/dolly.
		sound_name = "drop_shot"
		duration = lerp(MAX_DURATION, MIN_DURATION, power)
		peak_height = lerp(MAX_PEAK, MIN_PEAK, power)
	elif power < MISHIT_MAX_POWER:
		sound_name = "mishit"
		is_dolly = true
		duration = lerp(MAX_DURATION, MIN_DURATION, power)
		peak_height = lerp(MAX_PEAK, MIN_PEAK, power)
	else:
		sound_name = "hit"
		duration = lerp(MAX_DURATION, MIN_DURATION, power)
		peak_height = lerp(MAX_PEAK, MIN_PEAK, power)
	# curve_shift_mult: Career-mode IQ upgrade bonus (see PlayerController.gd) -
	# shaped shots land further from center, harder for the bot to reach in
	# time. Defaults to 1.0 (no change) for the bot's own shots and outside
	# Career mode - baseline curve behavior (including its existing risk of
	# sailing out on a hard curve) is untouched. When it *is* upgraded
	# (mult > 1.0), the extra reach is clamped back to just inside the court
	# line - IQ always means placing it right at the edge, never an
	# upgrade that backfires by curving a shot out that would've landed.
	var curve_shift_mult: float = shape.get("curve_shift_mult", 1.0)
	var base_x: float = Court.cell_center(target_side_is_player, hitter_col, 0).x + curve * CURVE_SHIFT * curve_shift_mult
	if curve != 0 and curve_shift_mult > 1.0:
		var edge: float = Court.COURT_HALF_WIDTH - 0.15
		base_x = clampf(base_x, -edge, edge)

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

	# Wall Mode: a shot whose curve would otherwise sail out to the side
	# instead bounces off that wall and redirects to the opposite side - see
	# the class doc comment. Applies uniformly regardless of which depth
	# branch above produced `to`, since curve/base_x is computed the same
	# way for all three. final_x sits on the *opposite* side of center, at a
	# distance scaled by how far past the wall the original curve would have
	# carried it (clamped so it can never touch either wall exactly) - a
	# shot that barely goes out only just crosses center; a hard curve lands
	# deep on the far side. to.x is then aimed *past* the real wall by the
	# same amount final_x sits *inside* it, so the single in-flight
	# reflection in _integrate() below lands it exactly on final_x.
	var side_wall_x: float = 0.0
	var allow_side_wall_bank: bool = false
	if NetworkSession.wall_mode and absf(to.x) > Court.COURT_HALF_WIDTH:
		side_wall_x = signf(to.x) * Court.COURT_HALF_WIDTH
		var overshoot: float = absf(to.x) - Court.COURT_HALF_WIDTH
		var final_x: float = -signf(to.x) * clampf(overshoot, 0.15, Court.COURT_HALF_WIDTH - 0.15)
		to.x = 2.0 * side_wall_x - final_x
		allow_side_wall_bank = true

	_last_hitter = by
	_last_hit_was_smash = is_smash
	_bounce_count_this_side = 0
	if hitter_side_is_player:
		var volume_db: float = -2.0 if sound_name == "mishit" else 4.0
		_play_and_relay(sound_name, from, volume_db, 1.0, Sfx3D.NEAR_BUS)
		if is_smash:
			Sfx3D.rumble_smash()
		else:
			var m: PackedFloat32Array = _hit_rumble_magnitudes(sound_name)
			Sfx3D.rumble(m[0], m[1], m[2])
	else:
		_play_and_relay(sound_name, from, 0.0, 1.0, Sfx3D.DISTANT_BUS)
		# The host itself doesn't rumble for the opponent's own hit (correct -
		# that's not the host's action to feel) - but the client needs to feel
		# THEIR OWN hit on their OWN controller, which only a relay can do.
		if NetworkSession.is_networked and NetworkSession.is_host:
			if is_smash:
				NetworkSession.relay_rumble_smash()
			else:
				var m: PackedFloat32Array = _hit_rumble_magnitudes(sound_name)
				NetworkSession.relay_rumble(m[0], m[1], m[2])
	if is_smash:
		_spawn_smash_fireworks(from)
	_launch_flight(from, to, duration, peak_height, target_side_is_player, allow_bank, hitter_side_is_player,
			is_dolly, is_smash, allow_side_wall_bank, side_wall_x, is_super_smash)
	returned.emit(by)
	return true

## Relays to the client in a LAN match (see puppet_play_visual_effect(), the
## client-side receiver) so both players see the burst, not just the host.
func _spawn_smash_fireworks(pos: Vector3) -> void:
	_spawn_smash_fireworks_local(pos)
	if NetworkSession.is_networked and NetworkSession.is_host:
		NetworkSession.relay_visual_effect("fireworks", pos)

## Sighted-player visual only - a one-shot particle burst at the hit point
## when a smash actually connects. CPUParticles3D (not GPUParticles3D) since
## the project runs the gl_compatibility renderer, which CPU particles work
## on without needing shader support.
func _spawn_smash_fireworks_local(pos: Vector3) -> void:
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

## Relays to the client in a LAN match, same reasoning as the fireworks above.
func _spawn_bounce_flash(pos: Vector3) -> void:
	_spawn_bounce_flash_local(pos)
	if NetworkSession.is_networked and NetworkSession.is_host:
		NetworkSession.relay_visual_effect("bounce_flash", pos)

## Sighted-player visual only - a small flat burst of dust at ground level on
## every bounce (both the first "locate" bounce and the second), so a bounce
## reads as a distinct visible event rather than only being inferable from
## the ball mesh's continuous arc.
func _spawn_bounce_flash_local(pos: Vector3) -> void:
	var particles := CPUParticles3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.025
	mesh.height = 0.05
	particles.mesh = mesh
	particles.amount = 10
	particles.lifetime = 0.28
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 65.0
	particles.gravity = Vector3(0, -6.0, 0)
	particles.initial_velocity_min = 0.6
	particles.initial_velocity_max = 1.3
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.0
	particles.color = Color(1.0, 1.0, 1.0, 0.85)
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 0.85))
	grad.add_point(1.0, Color(1.0, 1.0, 1.0, 0.0))
	particles.color_ramp = grad
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos + Vector3(0, 0.02, 0)
	particles.emitting = true
	var t: SceneTreeTimer = get_tree().create_timer(BOUNCE_FLASH_LIFETIME)
	t.timeout.connect(particles.queue_free)

func _launch_flight(from: Vector3, to: Vector3, duration: float, peak_height: float,
		target_side_is_player: bool, allow_wall_bank: bool, bank_side_is_player: bool = false,
		is_dolly: bool = false, is_smash: bool = false,
		allow_side_wall_bank: bool = false, side_wall_x: float = 0.0, is_super_smash: bool = false) -> void:
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
	_hop_is_super_smash = is_super_smash
	_hop_allow_side_wall_bank = allow_side_wall_bank
	_hop_side_wall_x = side_wall_x
	_hop_state = HopState.FLIGHT

func _physics_process(delta: float) -> void:
	if _ball_mat:
		_ball_mat.albedo_color = BALL_DOLLY_COLOR if hop_is_dolly else BALL_NORMAL_COLOR
	_update_shadow()
	if is_puppet:
		return
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
	if NetworkSession.is_networked and NetworkSession.is_host:
		NetworkSession.relay_ball_transform(global_position, hop_is_dolly, hit_window_open, _hop_target_side_is_player)

## Applied by the client's puppet Ball each tick from the host's broadcast
## (see NetworkSession.gd's net_ball_transform RPC) - already mirrored for
## this device's own perspective before it arrives, so no translation needed
## here, just apply it directly.
func puppet_apply_transform(pos: Vector3, is_dolly: bool, window_open: bool, target_side_is_player: bool) -> void:
	global_position = pos
	hop_is_dolly = is_dolly
	hit_window_open = window_open
	_hop_target_side_is_player = target_side_is_player

## Every ball sound (bounces, hit/smash/mishit/drop_shot, net_hit, wall_bank)
## routes through here, and only these do - a single place to apply a small
## uniform boost per feedback that they read as a touch too quiet, without
## touching every individual call site's carefully-tuned relative level.
const BALL_SOUND_BOOST_DB := 2.5

## Host-only equivalent of Sfx3D.play_at() that also relays the sound to a
## connected LAN client (mirrored for their perspective - see
## NetworkSession.relay_sound()). A no-op relay outside a networked host, so
## every call site can use this unconditionally without branching.
func _play_and_relay(sound_name: String, pos: Vector3, volume_db: float, pitch: float, bus: String) -> void:
	var boosted_db: float = volume_db + BALL_SOUND_BOOST_DB
	Sfx3D.play_at(sound_name, pos, boosted_db, pitch, bus)
	if NetworkSession.is_networked and NetworkSession.is_host:
		NetworkSession.relay_sound(sound_name, pos, boosted_db, pitch, bus)

## [weak, strong, duration] rumble magnitudes for a given hit sound_name
## (smash uses the separate multi-stage rumble_smash() pattern instead - see
## call sites). Shared by both the host's own local rumble and the relayed
## copy sent to the client for their own hit, so the two can never drift.
func _hit_rumble_magnitudes(sound_name: String) -> PackedFloat32Array:
	match sound_name:
		"mishit":
			return PackedFloat32Array([0.15, 0.1, 0.06])
		"drop_shot":
			return PackedFloat32Array([0.2, 0.15, 0.08])
		_:
			return PackedFloat32Array([0.3, 0.9, 0.15])

## The client's puppet Ball never runs _handle_bounce()/attempt_hit() itself
## (is_puppet skips all of that) - this is the receiving half, called from
## NetworkSession's net_visual_effect RPC.
func puppet_play_visual_effect(effect_name: String, pos: Vector3) -> void:
	if effect_name == "fireworks":
		_spawn_smash_fireworks_local(pos)
	elif effect_name == "bounce_flash":
		_spawn_bounce_flash_local(pos)

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
			var bank_bus: String = Sfx3D.NEAR_BUS if _hop_bank_side_is_player else Sfx3D.DISTANT_BUS
			var bank_volume_db: float = 2.0 if _hop_bank_side_is_player else 0.0
			_play_and_relay("wall_bank", global_position, bank_volume_db, 1.0, bank_bus)

	if _hop_allow_side_wall_bank:
		if (_hop_side_wall_x > 0.0 and global_position.x >= _hop_side_wall_x) or \
				(_hop_side_wall_x < 0.0 and global_position.x <= _hop_side_wall_x):
			global_position.x = 2.0 * _hop_side_wall_x - global_position.x
			_vx = -_vx
			_hop_allow_side_wall_bank = false
			var side_bus: String = Sfx3D.NEAR_BUS if _hop_target_side_is_player else Sfx3D.DISTANT_BUS
			var side_volume_db: float = 2.0 if _hop_target_side_is_player else 0.0
			_play_and_relay("wall_bank", global_position, side_volume_db, 1.0, side_bus)

	if global_position.y <= 0.0 and _vy < 0.0:
		_handle_bounce()

func _handle_bounce() -> void:
	global_position.y = 0.0
	_vy = 0.0

	if absf(global_position.x) > Court.COURT_HALF_WIDTH:
		_resolve_fault("out", _opponent_of(_last_hitter))
		return

	_spawn_bounce_flash(global_position)

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
		_play_and_relay("bounce_locate", global_position, volume_db, pitch, bus)
		if landed_side_is_player:
			Sfx3D.rumble(0.15, 0.3, 0.08)
		elif NetworkSession.is_networked and NetworkSession.is_host:
			NetworkSession.relay_rumble(0.15, 0.3, 0.08)
		var cont_height: float
		if hop_is_dolly:
			cont_height = DOLLY_SECOND_BOUNCE_HEIGHT
			_continuation_duration = DOLLY_SECOND_BOUNCE_DURATION
			_grace_duration = HIT_WINDOW_GRACE
		elif _hop_is_super_smash:
			cont_height = SUPER_SMASH_SECOND_BOUNCE_HEIGHT
			_continuation_duration = SUPER_SMASH_SECOND_BOUNCE_DURATION
			_grace_duration = SUPER_SMASH_HIT_WINDOW_GRACE
		elif _hop_is_smash:
			cont_height = SMASH_SECOND_BOUNCE_HEIGHT
			_continuation_duration = SMASH_SECOND_BOUNCE_DURATION
			_grace_duration = SMASH_HIT_WINDOW_GRACE
		else:
			cont_height = SECOND_BOUNCE_HEIGHT
			_continuation_duration = SECOND_BOUNCE_DURATION
			_grace_duration = HIT_WINDOW_GRACE
		# Racket upgrade (Career mode only, player's own side only) - a
		# bigger sweet spot means a bit more forgiving timing, not a
		# shorter/harder-to-read rally, so this only ever widens the window.
		if landed_side_is_player and CareerRun.active:
			_grace_duration += CareerData.upgrade_racket * RACKET_UPGRADE_GRACE_BONUS
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
		_play_and_relay("bounce_second", global_position, volume_db, pitch, bus)
		if landed_side_is_player:
			Sfx3D.rumble(0.25, 0.5, 0.1)
		elif NetworkSession.is_networked and NetworkSession.is_host:
			NetworkSession.relay_rumble(0.25, 0.5, 0.1)
		_grace_elapsed = 0.0
		_hop_state = HopState.FROZEN_AWAITING_HIT
		# hit_window_open should already be true by now (opened pre-emptively
		# during CONTINUATION); force it open in case timing landed exactly here.
		hit_window_open = true

func _resolve_fault(reason: String, winner: String) -> void:
	_hop_state = HopState.NONE
	hit_window_open = false
	# "missed" means the receiver failed to return the last successful hit -
	# won_via_smash is only ever true for that case, and only if that hit was
	# itself a smash (a netted/out smash attempt loses the point instead, not
	# "won by smash" for the opponent who did nothing but receive it).
	var won_via_smash: bool = reason == "missed" and _last_hit_was_smash
	point_resolved.emit(winner, reason, won_via_smash)
