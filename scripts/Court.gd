extends Node3D
class_name Court
## Builds the padel court geometry and owns the grid<->world coordinate
## mapping every other script uses. Two 2x2 grids (player nearest +Z, bot
## nearest -Z) sit end-to-end split by a net at Z=0 - total court is 2 tiles
## wide by 4 tiles deep - each with a real back wall behind its baseline
## that shots can legally bank off.
##
## Purely visual/geometric - there's no physics engine involved. Movement is
## discrete grid-stepping (PaddleCharacter.gd) and the ball follows a
## scripted parabolic path (Ball.gd), so nothing here needs collision shapes.

const GRID := 2
const TILE_SIZE := 2.0
const COURT_HALF_WIDTH := GRID * TILE_SIZE / 2.0 # 2.0
const BACK_WALL_DISTANCE := GRID * TILE_SIZE # 4.0, from the net
const HEAD_HEIGHT := 1.6
const WALL_HEIGHT := 3.0
const NET_HEIGHT := 0.9

## World position of the center of a grid cell. row_local 0 = nearest the
## net, GRID-1 = nearest that side's back wall. is_player_side selects +Z vs -Z.
static func cell_center(is_player_side: bool, col: int, row_local: int) -> Vector3:
	var x: float = (col - (GRID - 1) / 2.0) * TILE_SIZE
	var z_offset: float = (row_local + 0.5) * TILE_SIZE
	var z: float = z_offset if is_player_side else -z_offset
	return Vector3(x, 0.0, z)

## Inverse of cell_center's column mapping - which column an x coordinate
## falls in, clamped to the court (used for aiming/AI/spatial cell callouts).
static func x_to_col(x: float) -> int:
	var col: int = int(round(x / TILE_SIZE + (GRID - 1) / 2.0))
	return clampi(col, 0, GRID - 1)

## Inverse of cell_center's row mapping for one side (pass abs(z)).
static func z_to_row_local(abs_z: float) -> int:
	var row: int = int(floor(abs_z / TILE_SIZE))
	return clampi(row, 0, GRID - 1)

func _ready() -> void:
	_build_floor(true)
	_build_floor(false)
	_build_net()
	_build_back_wall(true)
	_build_back_wall(false)
	_build_side_markers()

func _build_floor(is_player_side: bool) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(GRID * TILE_SIZE, 0.1, GRID * TILE_SIZE)
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
	mesh.size = Vector3(GRID * TILE_SIZE + 0.4, NET_HEIGHT, 0.08)
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.9, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	mesh_instance.position = Vector3(0.0, NET_HEIGHT / 2.0, 0.0)
	mesh_instance.name = "Net"
	add_child(mesh_instance)

func _build_back_wall(is_player_side: bool) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(GRID * TILE_SIZE + 0.4, WALL_HEIGHT, 0.15)
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.8, 0.85, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	var z: float = BACK_WALL_DISTANCE if is_player_side else -BACK_WALL_DISTANCE
	mesh_instance.position = Vector3(0.0, WALL_HEIGHT / 2.0, z)
	mesh_instance.name = "BackWall_%s" % ("Player" if is_player_side else "Bot")
	add_child(mesh_instance)

## Thin markers at each tile boundary - visual only, purely to make the grid
## legible if anyone is sighted-testing this.
func _build_side_markers() -> void:
	for is_player_side in [true, false]:
		for col in range(GRID + 1):
			var mesh_instance := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.03, 0.02, GRID * TILE_SIZE)
			mesh_instance.mesh = mesh
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 1.0, 1.0)
			mesh_instance.material_override = mat
			var x: float = (col - GRID / 2.0) * TILE_SIZE
			var z_center: float = BACK_WALL_DISTANCE / 2.0
			mesh_instance.position = Vector3(x, 0.02, z_center if is_player_side else -z_center)
			add_child(mesh_instance)
