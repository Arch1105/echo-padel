extends Node3D
class_name PaddleCharacter
## Shared base for the human player and the bot: both live on a Court.GRID x
## Court.GRID grid on their own side of the net and move in discrete
## one-tile steps rather than continuously, so there's no physics body here -
## just grid coordinates mapped to world position via Court.cell_center().

@export var is_player_side: bool = true

## Sighted-player visuals only - blind play never depends on any of this.
## Body/racket color mirrors Court.gd's floor tint per side (blue = player,
## red = bot) so a sighted spectator can tell them apart at a glance. The
## racket glows red whenever *this* character specifically has a smash
## available (its turn to hit, and the ball is currently dollied) - smash is
## gated on that same condition in Ball.gd/BotAI.gd, so the glow always
## matches what's actually legal.
const RACKET_NORMAL_COLOR := Color(0.12, 0.1, 0.09)
const RACKET_SMASH_COLOR := Color(1.0, 0.15, 0.1)

var side_label: String = "you"
var current_col: int = (Court.GRID - 1) / 2
var current_row_local: int = (Court.GRID - 1) / 2
var ball: Ball

var _racket_mat: StandardMaterial3D

func _ready() -> void:
	side_label = "you" if is_player_side else "bot"
	_snap_to_current_cell()
	_build_visuals()

func _process(_delta: float) -> void:
	if ball == null:
		return
	var smash_ready: bool = ball.hit_window_open and ball.hop_is_dolly \
			and ball.expected_hitter_is_player() == is_player_side
	_racket_mat.albedo_color = RACKET_SMASH_COLOR if smash_ready else RACKET_NORMAL_COLOR

func _build_visuals() -> void:
	var body_color: Color = Color(0.2, 0.45, 0.75) if is_player_side else Color(0.75, 0.25, 0.25)

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.28
	body_mesh.height = 1.6
	body.mesh = body_mesh
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = body_color
	body.material_override = body_mat
	# Character origin sits at Court.HEAD_HEIGHT (ear height, for the
	# AudioListener3D) - offset the capsule down so it reads as a standing
	# figure with its head near that height, not a floating blob.
	body.position = Vector3(0.0, -0.8, 0.0)
	body.name = "BodyMesh"
	add_child(body)

	var racket := MeshInstance3D.new()
	var racket_mesh := CylinderMesh.new()
	racket_mesh.top_radius = 0.22
	racket_mesh.bottom_radius = 0.22
	racket_mesh.height = 0.04
	racket.mesh = racket_mesh
	_racket_mat = StandardMaterial3D.new()
	_racket_mat.albedo_color = RACKET_NORMAL_COLOR
	racket.material_override = _racket_mat
	# Stand the disc up facing the net instead of lying flat, so it reads as
	# a held racket from the overhead-angled camera.
	racket.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	var facing_z: float = -0.35 if is_player_side else 0.35
	racket.position = Vector3(0.45, -0.35, facing_z)
	racket.name = "RacketMesh"
	add_child(racket)

func _snap_to_current_cell() -> void:
	var pos: Vector3 = Court.cell_center(is_player_side, current_col, current_row_local)
	pos.y = Court.HEAD_HEIGHT
	global_position = pos

## Steps exactly one tile per call (delta_col/delta_row should be -1/0/1).
## Returns false if already at that edge of the grid.
func move(delta_col: int, delta_row: int) -> bool:
	var new_col: int = clampi(current_col + delta_col, 0, Court.GRID - 1)
	var new_row: int = clampi(current_row_local + delta_row, 0, Court.GRID - 1)
	if new_col == current_col and new_row == current_row_local:
		return false
	current_col = new_col
	current_row_local = new_row
	_snap_to_current_cell()
	return true

## Puts the character back at the standard starting tile - the closest
## thing to a center on a grid that may not have an exact middle cell.
func reset_position() -> void:
	current_col = (Court.GRID - 1) / 2
	current_row_local = (Court.GRID - 1) / 2
	_snap_to_current_cell()
