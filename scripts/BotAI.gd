extends PaddleCharacter
class_name BotAI
## Opponent. Reacts to the ball's first bounce on its own side after a
## human-like reaction delay (difficulty-tuned), steps toward the landing
## tile at a difficulty-tuned cadence, and swings once it's in position and
## the hit window is open. A per-rally coin flip (miss_chance) can commit the
## bot to an unforced error up front - it simply never moves/swings that
## rally, exactly as if a weaker player misjudged the ball entirely.
##
## Difficulty is a single continuous "strength" float rather than 4 fixed
## presets, so Career mode can scale it smoothly across 7 tiers x up to 5
## rounds each - including going tougher than "pro" for a Grand Slam final.
## The named easy/medium/hard/pro presets are just anchor points on that same
## scale (0.0 / 1/3 / 2/3 / 1.0); regular Play/Training still uses them
## exactly as before via `difficulty`. Career mode instead sets
## `strength_override` directly (any value, including beyond 1.0), which
## takes priority when set (>= 0.0).

@export_enum("easy", "medium", "hard", "pro", "elite", "legendary") var difficulty: String = "medium"
var strength_override: float = -1.0

const DIFFICULTY_STRENGTH := {
	"easy": 0.0, "medium": 1.0 / 3.0, "hard": 2.0 / 3.0, "pro": 1.0,
	"elite": 1.5, "legendary": 2.0,
}

## Anchor points on the strength scale - easy/medium/hard/pro are 0.0-1.0 as
## before; elite/legendary extend it further for players who've mastered pro,
## and give Career's Hall of Champions tier (strength ~1.25-1.6, see
## CareerTiers.gd) something real to interpolate between instead of raw
## extrapolation past pro. Any strength interpolates between the two
## surrounding anchors, or extrapolates past the last segment's slope beyond
## legendary (shouldn't normally happen - legendary is meant to be the top).
const ANCHORS: Array[Dictionary] = [
	{"s": 0.0, "reaction": Vector2(0.35, 0.6), "step_interval": 0.28, "miss_chance": 0.35,
			"shape_skill": 0.15, "power_min": 0.15, "power_max": 0.6, "smash_chance": 0.0},
	{"s": 1.0 / 3.0, "reaction": Vector2(0.2, 0.4), "step_interval": 0.2, "miss_chance": 0.18,
			"shape_skill": 0.4, "power_min": 0.35, "power_max": 0.8, "smash_chance": 0.05},
	{"s": 2.0 / 3.0, "reaction": Vector2(0.1, 0.22), "step_interval": 0.14, "miss_chance": 0.07,
			"shape_skill": 0.7, "power_min": 0.5, "power_max": 0.95, "smash_chance": 0.15},
	{"s": 1.0, "reaction": Vector2(0.03, 0.1), "step_interval": 0.09, "miss_chance": 0.02,
			"shape_skill": 0.95, "power_min": 0.6, "power_max": 1.0, "smash_chance": 0.3},
	{"s": 1.5, "reaction": Vector2(0.02, 0.06), "step_interval": 0.07, "miss_chance": 0.0,
			"shape_skill": 1.0, "power_min": 0.7, "power_max": 1.0, "smash_chance": 0.4},
	{"s": 2.0, "reaction": Vector2(0.02, 0.04), "step_interval": 0.05, "miss_chance": 0.0,
			"shape_skill": 1.0, "power_min": 0.85, "power_max": 1.0, "smash_chance": 0.55},
]

var _reacting: bool = false
var _react_timer: float = 0.0
var _step_timer: float = 0.0
var _target_col: int = -1
var _target_row: int = -1
var _committed_miss: bool = false

func _ready() -> void:
	is_player_side = false
	super._ready()
	# ball is assigned by MatchManager after this node's _ready() runs (child
	# nodes ready before their parent), so the bounced signal is wired up
	# from MatchManager once ball/bot are both in place - see MatchManager.gd.

func _current_strength() -> float:
	if strength_override >= 0.0:
		return strength_override
	return DIFFICULTY_STRENGTH.get(difficulty, 1.0 / 3.0)

static func _lerp_field(a, b, t: float):
	if a is Vector2:
		return a.lerp(b, t)
	return lerpf(a, b, t)

func _tuning() -> Dictionary:
	var s: float = maxf(_current_strength(), 0.0)
	var last: int = ANCHORS.size() - 1
	var idx: int = 0
	while idx < last - 1 and s > ANCHORS[idx + 1]["s"]:
		idx += 1
	var a: Dictionary = ANCHORS[idx]
	var b: Dictionary = ANCHORS[idx + 1]
	var span: float = b["s"] - a["s"]
	var t: float = (s - a["s"]) / span if span > 0.0 else 0.0

	var result := {}
	for key in a.keys():
		if key == "s":
			continue
		result[key] = _lerp_field(a[key], b[key], t)

	result["miss_chance"] = clampf(result["miss_chance"], 0.0, 1.0)
	result["shape_skill"] = clampf(result["shape_skill"], 0.0, 1.0)
	result["smash_chance"] = clampf(result["smash_chance"], 0.0, 1.0)
	result["power_min"] = clampf(result["power_min"], 0.0, 1.0)
	result["power_max"] = clampf(result["power_max"], result["power_min"], 1.0)
	result["step_interval"] = maxf(result["step_interval"], 0.05)
	var reaction: Vector2 = result["reaction"]
	result["reaction"] = Vector2(maxf(reaction.x, 0.02), maxf(reaction.y, maxf(reaction.x, 0.02) + 0.01))
	return result

func _on_ball_bounced(side_is_player: bool, col: int, row_local: int, bounce_number: int) -> void:
	if side_is_player or bounce_number != 1:
		return
	var t: Dictionary = _tuning()
	_target_col = col
	_target_row = row_local
	_committed_miss = randf() < t["miss_chance"]
	_react_timer = randf_range(t["reaction"].x, t["reaction"].y)
	_step_timer = 0.0
	_reacting = true

func _physics_process(delta: float) -> void:
	if not _reacting or _committed_miss:
		return
	if _react_timer > 0.0:
		_react_timer -= delta
		return
	var t: Dictionary = _tuning()
	_step_timer -= delta
	if _step_timer > 0.0:
		return
	_step_timer = t["step_interval"]
	if current_col != _target_col:
		move(int(sign(_target_col - current_col)), 0)
	elif current_row_local != _target_row:
		move(0, int(sign(_target_row - current_row_local)))
	elif ball.hit_window_open:
		_swing(t)

func _swing(t: Dictionary) -> void:
	_reacting = false
	# Smash is only available off a dolly - see Ball.gd's attempt_hit, which
	# would reject it anyway, but there's no reason to even try.
	var is_smash: bool = ball.hop_is_dolly and randf() < t["smash_chance"]
	var curve := 0
	var depth := 0
	if is_smash or randf() < t["shape_skill"]:
		var options: Array = [-1, 0, 1]
		curve = options[randi() % options.size()]
		depth = options[randi() % options.size()]
	var power: float = 1.0 if is_smash else randf_range(t["power_min"], t["power_max"])
	ball.attempt_hit("bot", current_col, current_row_local,
			{"power": power, "curve": curve, "depth": depth, "is_smash": is_smash})
