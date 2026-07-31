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
## Right Shift (or a controller's right trigger) is a third, separate
## dedicated drop shot - always lands in the front row near the net, no
## matter what direction is held, unlike the Forward-shape short shot below
## (added because that one turned out too easy to never discover/use by
## accident). Same hold-to-charge power curve as a normal shot - a short tap
## is a genuine soft dink (more likely to clatter into the net, since it's
## barely clearing it on purpose), a longer hold is a firmer short ball that's
## still returnable but with less margin for the returner to get there in
## time. Spin (Left/Right) still applies while charging one. Charging a drop
## shot and charging a normal shot are mutually exclusive - starting either
## one cancels the other, same as smash already cancels a normal charge.
##
## Either way, whichever direction is held *at release/press* shapes a normal
## shot or smash: Left/Right = spin, Back = played off your own back wall
## first (real padel technique) then carried over the net, Forward = short
## drop shot near the net, none = flat straight shot. On a controller, shot
## shaping instead reads the *right* stick (shape_left/right/forward/back) so
## it's independent of the left stick's movement, matching the keyboard's
## arrow keys doing double duty only because there's nothing else to hold.
##
## Movement is suppressed while Space or the drop-shot button is held -
## arrow keys are read as shot shaping during a charge, not as movement, so
## charging a curved shot doesn't also shuffle the player sideways.
##
## No audio feedback plays during a normal charge (per playtest feedback,
## the soundscape is kept to just hits/bounces/point outcomes) - you gauge
## power by how long you held it, same as you would in real life.
##
## Two more moves exist, but only in LAN Wall Mode (NetworkSession.wall_mode -
## see Ball.gd's class doc comment for the wall-bounce mechanic they're built
## around):
##
## Side dash - D-pad Left/Right on a controller, or hold F and press the
## Left/Right arrow key - jumps straight to that side's edge tile, skipping
## the middle column entirely, so you can actually get across in time to
## return a shot that just bounced off a side wall to the opposite side.
## Same move-suppression-while-charging rule as normal movement. The
## keyboard version is deliberately a held-modifier + arrow combo rather
## than its own dedicated key, since the arrow keys are already this
## overloaded (movement/shaping) - F is otherwise unused.
##
## Super Smash - a one-per-game power move. Just press the left trigger (or
## J on keyboard) alone - no combo with the smash button - any time the ball
## is dollied on your side, exactly the same timing as a regular smash (no
## extra "must be between bounces" restriction - per feedback that was one
## puzzle too many stacked on top of the once-per-game limit). Press it on a
## ball that isn't dollied and it's simply ignored (the left trigger has no
## other meaning during a match), so there's no risk of it misfiring into a
## regular smash. No spin - holding a
## shape-stick direction does nothing on a Super Smash specifically, unlike
## every other shot including a regular smash. Landing it speaks a distinct
## "Super Smash!" announcement and *waits for it to finish* before the ball
## actually gets hit (see Ball.gd's SUPER_SMASH_ANNOUNCE_DELAY) - the whole
## point is a warning the opponent has time to hear and react to, not
## something that arrives at the same instant as the ball itself, which
## would defeat the purpose for a screen-reader player. It also has its own
## more powerful-sounding impact, and the ball crosses much faster than a
## normal smash and is noticeably harder (though never impossible) to
## return - see Ball.gd's other SUPER_SMASH_* constants. "Per game" is
## tracked via the running games_you+games_bot total, which MatchManager
## already keeps identical on both host and client via score sync - no
## extra network message needed to reset it each new game.

const MAX_CHARGE := 1.2

## Career-mode upgrade effects (see CareerUpgrades.gd for spending points,
## CareerData.gd for the persisted levels, MAX_UPGRADE_LEVEL=50 there) - only
## ever applied when CareerRun.active, so regular Play/Training are
## untouched. Each rate is small per point on purpose - the total at 50
## points (fully maxed, a serious grind) is meant to feel like a real edge,
## not a guaranteed win: +0.4 power is a lot but still shy of an automatic
## max-power shot from a weak charge, and the bot's own difficulty keeps
## scaling independently with Career tier (see BotAI.gd/CareerTiers.gd), so
## even a fully maxed character still has a real opponent at the top tiers.
const STRENGTH_UPGRADE_POWER_BONUS := 0.4 / 50.0
const IQ_UPGRADE_CURVE_MULT_PER_LEVEL := 1.5 / 50.0
const SPEED_UPGRADE_VISUAL_DURATION_CUT := 0.1 / 50.0
const BASE_MOVE_VISUAL_DURATION := 0.12
const MIN_MOVE_VISUAL_DURATION := 0.02

var match_manager: MatchManager

var _charging: bool = false
var _charge_elapsed: float = 0.0
var _drop_charging: bool = false
var _drop_charge_elapsed: float = 0.0
## Wall Mode only - see the class doc comment.
var _super_smash_used_in_game: int = -1
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
	var drop_shot_held: bool = Input.is_action_pressed("drop_shot")

	if not swinging_held and not drop_shot_held:
		# Wall Mode only (see class doc comment) - F is otherwise a complete
		# no-op, so a plain arrow press outside Wall Mode always behaves as a
		# normal one-tile move regardless of whether F happens to be held.
		var dash_left: bool = NetworkSession.wall_mode and (Input.is_action_just_pressed("dash_left") or
				(Input.is_key_pressed(KEY_F) and Input.is_action_just_pressed("move_left")))
		var dash_right: bool = NetworkSession.wall_mode and (Input.is_action_just_pressed("dash_right") or
				(Input.is_key_pressed(KEY_F) and Input.is_action_just_pressed("move_right")))
		if dash_left:
			_do_side_dash(-1)
		elif dash_right:
			_do_side_dash(1)
		elif Input.is_action_just_pressed("move_left"):
			_do_move(-1, 0)
		elif Input.is_action_just_pressed("move_right"):
			_do_move(1, 0)
		elif Input.is_action_just_pressed("move_forward"):
			_do_move(0, -1)
		elif Input.is_action_just_pressed("move_back"):
			_do_move(0, 1)

	if Input.is_action_just_pressed("swing"):
		_drop_charging = false
		_charging = true
		_charge_elapsed = 0.0
	elif _charging and swinging_held:
		_charge_elapsed += delta
	elif Input.is_action_just_released("swing") and _charging:
		_release_swing()

	if Input.is_action_just_pressed("drop_shot"):
		_charging = false
		_drop_charging = true
		_drop_charge_elapsed = 0.0
	elif _drop_charging and drop_shot_held:
		_drop_charge_elapsed += delta
	elif Input.is_action_just_released("drop_shot") and _drop_charging:
		_release_drop_shot()

	if Input.is_action_just_pressed("smash"):
		_drop_charging = false
		_attempt_smash()

	# Wall Mode only - a single press of the left trigger (or J) is the
	# whole Super Smash input. Same timing window as a regular smash (any
	# dollied ball heading to this player, first bounce or second - no extra
	# timing puzzle on top of the once-per-game limit). Only does anything at
	# all when every condition is already met right now - otherwise it's a
	# complete no-op, not a fallback regular smash, since the left trigger
	# has no other meaning in a match.
	if Input.is_action_just_pressed("super_smash_arm") and NetworkSession.wall_mode and ball \
			and _can_use_super_smash() and ball.hop_is_dolly \
			and ball._hop_target_side_is_player == is_player_side:
		_charging = false
		_drop_charging = false
		_attempt_smash(true)

	if Input.is_action_just_pressed("check_score") and match_manager:
		match_manager.announce_score()

	if Input.is_action_just_pressed("check_coordinates"):
		_announce_coordinates()

func cancel_charge() -> void:
	_charging = false
	_drop_charging = false

## Speaks your own current tile as a left/middle/right, front/back pair -
## purely local (this device's own PlayerController already knows its own
## current_col/current_row_local directly, host or client, LAN or offline),
## so it works identically in every mode without any network relay. Returns
## the key list spoken, so tests can check the mapping without depending on
## Voice's own playback state.
func _announce_coordinates() -> Array[String]:
	var col_key: String
	if current_col == 0:
		col_key = "coord_left"
	elif current_col == Court.COLS - 1:
		col_key = "coord_right"
	else:
		col_key = "coord_middle"
	var row_key: String = "coord_front" if current_row_local == 0 else "coord_back"
	var keys: Array[String] = ["coord_prefix", col_key, row_key]
	Voice.say_sequence(keys)
	return keys

## In a LAN match (see NetworkSession.gd), applies locally right away for
## responsiveness (move() always succeeds within the grid, so there's no
## real risk of ever disagreeing with the host's own authoritative copy of
## this same call) *and* tells the host, so its Bot-slot puppet of this
## player stays in sync. Outside a networked client, this is exactly the
## plain local move() it replaced.
func _do_move(delta_col: int, delta_row: int) -> void:
	move(delta_col, delta_row)
	if NetworkSession.is_networked and not NetworkSession.is_host:
		NetworkSession.submit_move.rpc(delta_col, delta_row)

## Wall Mode only - jumps straight to the near/far edge column, skipping
## whatever's in between, by computing the delta move() needs to land
## exactly there - reuses _do_move()'s existing clamping/relay unchanged,
## since an oversized delta already clamps to a legal edge column on its own.
func _do_side_dash(direction: int) -> void:
	var target_col: int = 0 if direction < 0 else Court.COLS - 1
	_do_move(target_col - current_col, 0)

## Wall Mode only - see class doc comment. games_you/games_bot are already
## kept identical on host and client via score sync, so their running total
## doubles as a "which game are we in" number with no extra network message
## needed just to reset this every new game.
func _current_game_number() -> int:
	return match_manager.games_you + match_manager.games_bot if match_manager else 0

func _can_use_super_smash() -> bool:
	return NetworkSession.wall_mode and _super_smash_used_in_game != _current_game_number()

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
	_submit_hit(shape)

## want_super: true when the caller (see _physics_process()'s dedicated
## super_smash_arm branch) already believes the left trigger/J press landed
## inside a valid Super Smash window. Still re-checked here against the live
## ball state (dolly, heading to this player) and the once-per-game flag
## before actually flagging the shape as a Super Smash - this call is the
## single source of truth, so a stale or racy caller can never sneak one
## through.
func _attempt_smash(want_super: bool = false) -> void:
	_charging = false
	var shape: Dictionary = _current_shape()
	shape["power"] = 1.0
	shape["is_smash"] = true
	if want_super and _can_use_super_smash() and ball and ball.hop_is_dolly \
			and ball._hop_target_side_is_player == is_player_side:
		shape["is_super_smash"] = true
		shape["curve"] = 0  # no spin on a Super Smash - see class doc comment
		_super_smash_used_in_game = _current_game_number()
	_apply_career_upgrades(shape)
	_submit_hit(shape)

## Always lands in the front row (depth forced to 1, overriding whatever
## _current_shape() read for depth) regardless of held direction - spin
## (curve) still applies. Power still comes from hold duration same as a
## normal shot; Ball.gd is what turns "less power" into "more of a genuine
## dink, but more net risk" for this shot type specifically.
func _release_drop_shot() -> void:
	_drop_charging = false
	var power: float = clampf(_drop_charge_elapsed / MAX_CHARGE, 0.0, 1.0)
	var shape: Dictionary = _current_shape()
	shape["power"] = power
	shape["is_smash"] = false
	shape["depth"] = 1
	shape["is_drop_shot"] = true
	_apply_career_upgrades(shape)
	_submit_hit(shape)

## The client's own Ball is a puppet (attempt_hit() is a no-op on one, see
## Ball.gd) - only the host resolves hits, so a networked client sends the
## shape to the host instead and waits for whatever the host broadcasts back
## (sound/score/etc.) through the usual relayed channels. On the host - or
## outside a networked match entirely - this is exactly the direct local
## call it replaced.
func _submit_hit(shape: Dictionary) -> void:
	if NetworkSession.is_networked and not NetworkSession.is_host:
		NetworkSession.submit_hit.rpc(shape)
	else:
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
