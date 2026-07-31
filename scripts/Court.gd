extends Node3D
class_name Court
## Builds the padel court geometry and owns the grid<->world coordinate
## mapping every other script uses. Two 3x2 grids (player nearest +Z, bot
## nearest -Z) sit end-to-end split by a net at Z=0 - each side is 3 tiles
## wide (left/middle/right) by 2 tiles deep - each with a real back wall
## behind its baseline that shots can legally bank off.
##
## Purely visual/geometric - there's no physics engine involved. Movement is
## discrete grid-stepping (PaddleCharacter.gd) and the ball follows a
## scripted parabolic path (Ball.gd), so nothing here needs collision shapes.
##
## Mostly sighted-player visuals: net posts, a surrounding ground apron,
## simple crowd stands, and a sky background - the original two-rectangles-
## and-a-net version worked fine for gameplay but per feedback read as
## "floating in a void" to sighted spectators. None of that is interactive.
## The side glass walls are the one exception: purely decorative in every
## normal mode (the ball only ever banks off the two BACK walls there, never
## the sides - see Ball.gd), but in LAN Wall Mode (NetworkSession.wall_mode)
## these exact walls - same position, same geometry - become interactive:
## a curved shot that would otherwise sail out to the side instead bounces
## off them into play. See Ball.gd's class doc comment for the physics.

## Across (left-right, x-axis) tiles per side - left/middle/right, so a
## straight, left-spun, and right-spun shot each have their own landing tile.
const COLS := 3
## Deep (front-back, z-axis) tiles per side - unchanged from the original
## court, only the width grew.
const ROWS := 2
const TILE_SIZE := 2.0
const COURT_HALF_WIDTH := COLS * TILE_SIZE / 2.0 # 3.0
const BACK_WALL_DISTANCE := ROWS * TILE_SIZE # 4.0, from the net
const HEAD_HEIGHT := 1.6
const WALL_HEIGHT := 3.0
const NET_HEIGHT := 0.9

## World position of the center of a grid cell. row_local 0 = nearest the
## net, ROWS-1 = nearest that side's back wall. is_player_side selects +Z vs -Z.
static func cell_center(is_player_side: bool, col: int, row_local: int) -> Vector3:
	var x: float = (col - (COLS - 1) / 2.0) * TILE_SIZE
	var z_offset: float = (row_local + 0.5) * TILE_SIZE
	var z: float = z_offset if is_player_side else -z_offset
	return Vector3(x, 0.0, z)

## Inverse of cell_center's column mapping - which column an x coordinate
## falls in, clamped to the court (used for aiming/AI/spatial cell callouts).
static func x_to_col(x: float) -> int:
	var col: int = int(round(x / TILE_SIZE + (COLS - 1) / 2.0))
	return clampi(col, 0, COLS - 1)

## Inverse of cell_center's row mapping for one side (pass abs(z)).
static func z_to_row_local(abs_z: float) -> int:
	var row: int = int(floor(abs_z / TILE_SIZE))
	return clampi(row, 0, ROWS - 1)

func _ready() -> void:
	_build_environment()
	_build_ground()
	_build_floor(true)
	_build_floor(false)
	_build_net()
	_build_back_wall(true)
	_build_back_wall(false)
	_build_side_walls()
	_build_side_markers()
	_build_stands()

## A plain sky-blue background plus a touch of ambient fill light - without
## this the court sat in Godot's default near-black void, which read as
## "floating" even with the ground apron added below.
func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.72, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.7)
	env.ambient_light_energy = 0.6
	world_env.environment = env
	add_child(world_env)

## A big neutral apron under and around the whole court, so the two playing
## surfaces (and everything else built below) read as sitting on solid
## ground rather than floating over a void.
func _build_ground() -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(BACK_WALL_DISTANCE * 6.0, 0.2, BACK_WALL_DISTANCE * 6.0)
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.4, 0.32)
	mesh_instance.material_override = mat
	mesh_instance.position = Vector3(0.0, -0.15, 0.0)
	mesh_instance.name = "Ground"
	add_child(mesh_instance)

func _build_floor(is_player_side: bool) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(COLS * TILE_SIZE, 0.1, ROWS * TILE_SIZE)
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.35, 0.55) if is_player_side else Color(0.55, 0.2, 0.2)
	mesh_instance.material_override = mat
	var z_center: float = BACK_WALL_DISTANCE / 2.0
	mesh_instance.position = Vector3(0.0, -0.05, z_center if is_player_side else -z_center)
	mesh_instance.name = "Floor_%s" % ("Player" if is_player_side else "Bot")
	add_child(mesh_instance)

func _build_net() -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(COLS * TILE_SIZE + 0.4, NET_HEIGHT, 0.08)
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.9, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	mesh_instance.position = Vector3(0.0, NET_HEIGHT / 2.0, 0.0)
	mesh_instance.name = "Net"
	add_child(mesh_instance)

	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.15, 0.15, 0.17)
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var post_mesh := CylinderMesh.new()
		post_mesh.top_radius = 0.05
		post_mesh.bottom_radius = 0.06
		post_mesh.height = NET_HEIGHT + 0.2
		post.mesh = post_mesh
		post.material_override = post_mat
		post.position = Vector3(side * (COLS * TILE_SIZE / 2.0 + 0.2), (NET_HEIGHT + 0.2) / 2.0, 0.0)
		post.name = "NetPost_%s" % ("Left" if side < 0 else "Right")
		add_child(post)

func _build_back_wall(is_player_side: bool) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(COLS * TILE_SIZE + 0.4, WALL_HEIGHT, 0.15)
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.8, 0.85, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	var z: float = BACK_WALL_DISTANCE if is_player_side else -BACK_WALL_DISTANCE
	mesh_instance.position = Vector3(0.0, WALL_HEIGHT / 2.0, z)
	mesh_instance.name = "BackWall_%s" % ("Player" if is_player_side else "Bot")
	add_child(mesh_instance)

## Glass side walls (real padel courts are fully enclosed) - purely visual
## in every mode except LAN Wall Mode, positioned at exactly x = ±COURT_
## HALF_WIDTH, the same boundary Ball.gd already checks curved shots
## against, so Wall Mode's physics and this geometry always agree.
func _build_side_walls() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.8, 0.85, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for side in [-1.0, 1.0]:
		var mesh_instance := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.15, WALL_HEIGHT, BACK_WALL_DISTANCE * 2.0 + 0.3)
		mesh_instance.mesh = mesh
		mesh_instance.material_override = mat
		mesh_instance.position = Vector3(side * COURT_HALF_WIDTH, WALL_HEIGHT / 2.0, 0.0)
		mesh_instance.name = "SideWall_%s" % ("Left" if side < 0 else "Right")
		add_child(mesh_instance)

## Thin markers at each tile boundary - visual only, purely to make the grid
## legible if anyone is sighted-testing this.
func _build_side_markers() -> void:
	for is_player_side in [true, false]:
		for col in range(COLS + 1):
			var mesh_instance := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.03, 0.02, ROWS * TILE_SIZE)
			mesh_instance.mesh = mesh
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 1.0, 1.0)
			mesh_instance.material_override = mat
			var x: float = (col - COLS / 2.0) * TILE_SIZE
			var z_center: float = BACK_WALL_DISTANCE / 2.0
			mesh_instance.position = Vector3(x, 0.02, z_center if is_player_side else -z_center)
			add_child(mesh_instance)

## A simple tiered stand beyond each glass wall (both sides, both ends) with
## a scatter of small "spectator" blobs on top - not meant to read as
## individual people up close, just enough shape/color/movement-adjacent
## variety at a distance that the court doesn't look like it's sitting in an
## empty field. Purely decorative, built once, no per-frame cost.
func _build_stands() -> void:
	var stand_mat := StandardMaterial3D.new()
	stand_mat.albedo_color = Color(0.3, 0.28, 0.32)
	var spectator_colors := [
		Color(0.8, 0.3, 0.3), Color(0.3, 0.5, 0.8), Color(0.9, 0.8, 0.3),
		Color(0.4, 0.7, 0.4), Color(0.7, 0.4, 0.7), Color(0.85, 0.85, 0.85),
	]

	# Left/right stands, tiers stepping outward along X, running along Z.
	for side in [-1.0, 1.0]:
		var base := Vector3(side * (COURT_HALF_WIDTH + 1.4), 0.0, 0.0)
		_build_one_stand(base, Vector3(side, 0.0, 0.0), Vector3(0.0, 0.0, 1.0),
				BACK_WALL_DISTANCE * 2.0 + 1.0, stand_mat, spectator_colors)

	# Stands behind each back wall, tiers stepping outward along Z, running along X.
	for is_player_side in [true, false]:
		var sgn: float = 1.0 if is_player_side else -1.0
		var base := Vector3(0.0, 0.0, sgn * (BACK_WALL_DISTANCE + 1.4))
		_build_one_stand(base, Vector3(0.0, 0.0, sgn), Vector3(1.0, 0.0, 0.0),
				COLS * TILE_SIZE + 2.0, stand_mat, spectator_colors)

## base_pos: the first (lowest, nearest-court) tier's center. away_dir: unit
## vector pointing outward from the court - each successive tier steps
## further along this. run_dir: the perpendicular horizontal axis the
## stand's long side runs along (and where individual tiers/spectators are
## spread out).
func _build_one_stand(base_pos: Vector3, away_dir: Vector3, run_dir: Vector3, run_length: float,
		stand_mat: StandardMaterial3D, spectator_colors: Array) -> void:
	const TIERS := 3
	const TIER_HEIGHT := 0.5
	const TIER_DEPTH := 0.9
	for tier in range(TIERS):
		var y: float = tier * TIER_HEIGHT + TIER_HEIGHT / 2.0
		var offset: float = tier * TIER_DEPTH * 0.6
		var pos: Vector3 = base_pos + away_dir * offset
		pos.y = y

		var step := MeshInstance3D.new()
		var step_mesh := BoxMesh.new()
		if run_dir.x != 0.0:
			step_mesh.size = Vector3(run_length, TIER_HEIGHT, TIER_DEPTH)
		else:
			step_mesh.size = Vector3(TIER_DEPTH, TIER_HEIGHT, run_length)
		step.mesh = step_mesh
		step.material_override = stand_mat
		step.position = pos
		add_child(step)

		# A handful of spectator blobs riding on top of this tier.
		for i in range(6):
			var blob := MeshInstance3D.new()
			var blob_mesh := CapsuleMesh.new()
			blob_mesh.radius = 0.14
			blob_mesh.height = randf_range(0.4, 0.55)
			blob.mesh = blob_mesh
			var mat := StandardMaterial3D.new()
			mat.albedo_color = spectator_colors[randi() % spectator_colors.size()]
			blob.material_override = mat
			var jitter: float = randf_range(-run_length / 2.0 + 0.3, run_length / 2.0 - 0.3)
			var blob_pos: Vector3 = pos + run_dir * jitter
			blob_pos.y = pos.y + TIER_HEIGHT / 2.0 + blob_mesh.height / 2.0
			blob.position = blob_pos
			add_child(blob)
