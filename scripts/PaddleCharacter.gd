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

## How long a tile-to-tile step's *visual* glide takes - purely cosmetic,
## gameplay (current_col/current_row_local, hit-tile matching) updates
## instantly regardless, so this can never affect timing/fairness, only how
## it looks. PlayerController.gd lowers this in Career mode via the Speed
## upgrade; the bot always uses the default.
var move_visual_duration: float = 0.12

var _racket_mat: StandardMaterial3D
var _visual_rig: Node3D
var _visual_tween: Tween

func _ready() -> void:
	side_label = "you" if is_player_side else "bot"
	_visual_rig = Node3D.new()
	_visual_rig.name = "VisualRig"
	add_child(_visual_rig)
	_snap_to_current_cell()
	_build_visuals()

func _process(_delta: float) -> void:
	if ball == null:
		return
	var smash_ready: bool = ball.hit_window_open and ball.hop_is_dolly \
			and ball.expected_hitter_is_player() == is_player_side
	_racket_mat.albedo_color = RACKET_SMASH_COLOR if smash_ready else RACKET_NORMAL_COLOR

## Built as separate head/torso/legs/arm pieces (not one blob capsule) so the
## silhouette actually reads as a standing figure in athletic stance from the
## overhead-angled camera - still deliberately low-poly/stylized, not a
## realistic rigged character model, which is out of scope for primitives
## built in code. Everything's parented under _visual_rig (see
## _snap_to_current_cell()) so the whole figure glides together when moving.
func _build_visuals() -> void:
	var skin_color: Color = Color(0.85, 0.68, 0.55)
	var kit_color: Color = Color(0.2, 0.45, 0.75) if is_player_side else Color(0.75, 0.25, 0.25)
	var facing_z: float = -0.35 if is_player_side else 0.35

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.13
	head_mesh.height = 0.26
	head.mesh = head_mesh
	head.material_override = _solid_material(skin_color)
	# Character origin sits at Court.HEAD_HEIGHT (ear height, for the
	# AudioListener3D) - the head sits just above that, torso/legs below.
	head.position = Vector3(0.0, 0.1, 0.0)
	head.name = "HeadMesh"
	_visual_rig.add_child(head)

	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.2
	torso_mesh.height = 0.68
	torso.mesh = torso_mesh
	torso.material_override = _solid_material(kit_color)
	torso.position = Vector3(0.0, -0.35, 0.0)
	torso.name = "TorsoMesh"
	_visual_rig.add_child(torso)

	# Two legs in a slight athletic stance (one a touch forward, one back)
	# rather than standing dead straight.
	for leg_i in range(2):
		var leg := MeshInstance3D.new()
		var leg_mesh := CylinderMesh.new()
		leg_mesh.top_radius = 0.075
		leg_mesh.bottom_radius = 0.06
		leg_mesh.height = 0.8
		leg.mesh = leg_mesh
		leg.material_override = _solid_material(kit_color.darkened(0.5))
		var side: float = -1.0 if leg_i == 0 else 1.0
		leg.position = Vector3(side * 0.12, -1.05, side * 0.1)
		leg.name = "Leg%d" % leg_i
		_visual_rig.add_child(leg)

	var arm := MeshInstance3D.new()
	var arm_mesh := CylinderMesh.new()
	arm_mesh.top_radius = 0.055
	arm_mesh.bottom_radius = 0.06
	arm_mesh.height = 0.5
	arm.mesh = arm_mesh
	arm.material_override = _solid_material(skin_color)
	# Angled out and down from the shoulder toward the racket grip - a fixed
	# approximate pose (no inverse kinematics here) rather than dynamically
	# aimed at the racket's exact position.
	arm.rotation_degrees = Vector3(0.0, 0.0, -55.0)
	arm.position = Vector3(0.28, -0.15, 0.0)
	arm.name = "ArmMesh"
	_visual_rig.add_child(arm)

	var racket := Node3D.new()
	racket.name = "RacketMesh"
	racket.position = Vector3(0.5, -0.45, facing_z)
	racket.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_visual_rig.add_child(racket)

	var frame := MeshInstance3D.new()
	var frame_mesh := TorusMesh.new()
	frame_mesh.inner_radius = 0.15
	frame_mesh.outer_radius = 0.21
	frame.mesh = frame_mesh
	_racket_mat = StandardMaterial3D.new()
	_racket_mat.albedo_color = RACKET_NORMAL_COLOR
	frame.material_override = _racket_mat
	frame.name = "Frame"
	racket.add_child(frame)

	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.025
	handle_mesh.bottom_radius = 0.03
	handle_mesh.height = 0.3
	handle.mesh = handle_mesh
	handle.material_override = _solid_material(Color(0.1, 0.08, 0.07))
	handle.position = Vector3(0.0, -0.28, 0.0)
	handle.name = "Handle"
	racket.add_child(handle)

func _solid_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat

## animate=false (resets/serves - teleport, no glide) snaps both the real
## position and the visual rig together. animate=true (in-rally stepping)
## snaps the real (gameplay/audio) position instantly as always, but leaves
## the visual rig's *local* offset where the old spot was and tweens it back
## to zero, so what's rendered glides while what's simulated - AudioListener3D
## position included - never lags behind input.
func _snap_to_current_cell(animate: bool = false) -> void:
	var pos: Vector3 = Court.cell_center(is_player_side, current_col, current_row_local)
	pos.y = Court.HEAD_HEIGHT
	if animate and is_inside_tree():
		var old_pos: Vector3 = global_position
		global_position = pos
		_visual_rig.global_position = old_pos
		if _visual_tween:
			_visual_tween.kill()
		_visual_tween = create_tween()
		_visual_tween.tween_property(_visual_rig, "position", Vector3.ZERO, move_visual_duration) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		global_position = pos
		_visual_rig.position = Vector3.ZERO

## Steps exactly one tile per call (delta_col/delta_row should be -1/0/1).
## Returns false if already at that edge of the grid.
func move(delta_col: int, delta_row: int) -> bool:
	var new_col: int = clampi(current_col + delta_col, 0, Court.GRID - 1)
	var new_row: int = clampi(current_row_local + delta_row, 0, Court.GRID - 1)
	if new_col == current_col and new_row == current_row_local:
		return false
	current_col = new_col
	current_row_local = new_row
	_snap_to_current_cell(true)
	return true

## Puts the character back at the standard starting tile - the closest
## thing to a center on a grid that may not have an exact middle cell.
func reset_position() -> void:
	current_col = (Court.GRID - 1) / 2
	current_row_local = (Court.GRID - 1) / 2
	_snap_to_current_cell(false)

## Public entry point NetworkSession.gd uses (see net_paddle_position) to
## move the client's puppet paddle - current_col/current_row_local are
## expected to already be set by the caller before this runs.
func puppet_snap(animate: bool = true) -> void:
	_snap_to_current_cell(animate)
