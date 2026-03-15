class_name Mandala
extends Node2D

## Mandala — the active game board for a single run.
##
## Owns and manages all MandalaPiece instances. Lives at world position (0, 0)
## inside MandalaBuilder. The MandalaBuilder handles camera, background, and
## parallax; this node is purely about the pieces on the board.
##
## Placement always operates on Arm 0. For every Arm 0 piece, (symmetry_order - 1)
## mirror copies are spawned automatically at the same distance from the origin
## but rotated by (TAU / symmetry_order) * arm_index. Mirror pieces have:
##   - symmetry_index set to their arm number (1..symmetry_order-1)
##   - process_mode = PROCESS_MODE_DISABLED  (no _process overhead)
##   - No entry in the `pieces` array (snap and Sigil logic ignores them)
##   - input_pickable = false on their Polygon2D (no hit detection)


const MandalaPieceScene := preload("res://gameplay/shapes/mandala_piece.tscn")


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

## Rotational symmetry order for this run.
## Set once at run start based on the center shape the player chose.
##   3 = triangle center  (3-fold symmetry)
##   4 = square center    (4-fold symmetry)
##   5 = pentagon center  (5-fold symmetry)
##   6 = hexagon center   (6-fold symmetry)
## Mirror math: mirror_pos = arm0_pos.rotated((TAU / symmetry_order) * arm_index)
@export_range(3, 6) var symmetry_order: int = 3


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## All MandalaPiece instances on Arm 0 (the canonical, player-interactive arm).
## Mirror pieces are NOT stored here; they are purely visual and the snap,
## adjacency, and Sigil systems never touch them.
var pieces: Array[MandalaPiece] = []

## Parallel array to `pieces`. Each entry is an Array of (symmetry_order - 1)
## mirror MandalaPiece nodes for the corresponding Arm 0 piece.
## Index i in _mirrors corresponds to index i in pieces.
var _mirrors: Array = []


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Place a starter piece at the board origin so the Mandala is never empty
	# on first load. Acts as a visual anchor during development and will
	# become the center-piece selection once that UI is wired up.
	add_piece(MandalaPiece.SHAPE_HEXAGON, MandalaPiece.COLOR_BLUE, MandalaPiece.SIZE_NORMAL, Vector2.ZERO)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Instantiate a MandalaPiece on Arm 0 at the given world position/rotation,
## then automatically spawn (symmetry_order - 1) mirror copies around the
## origin for the remaining arms.
##
## Parameters:
##   shape_type        — one of MandalaPiece.SHAPE_* constants
##   color_tier        — one of MandalaPiece.COLOR_* constants
##   size_tier         — one of MandalaPiece.SIZE_* constants
##   world_position    — position in world space (center of the Arm 0 piece)
##   rotation_radians  — initial rotation for Arm 0; defaults to 0.0
##
## Returns the Arm 0 MandalaPiece so the caller can do further setup if needed.
func add_piece(
		shape_type:       String,
		color_tier:       String,
		size_tier:        String,
		world_position:   Vector2,
		rotation_radians: float = 0.0
) -> MandalaPiece:
	# --- Arm 0 piece ---
	var arm0_piece := _spawn_piece(
		shape_type,
		color_tier,
		size_tier,
		world_position,
		rotation_radians,
		0,          # symmetry_index
		false       # is_mirror
	)

	pieces.append(arm0_piece)

	# --- Mirror arms 1 .. symmetry_order-1 ---
	var mirror_group: Array = []

	for arm_index: int in range(1, symmetry_order):
		var step_angle: float = (TAU / float(symmetry_order)) * float(arm_index)

		# Mirror position: rotate the Arm 0 world position around the origin.
		var mirror_pos: Vector2 = world_position.rotated(step_angle)

		# Mirror rotation: add the same step angle so the piece faces the same
		# direction relative to its arm as the Arm 0 piece does to Arm 0.
		var mirror_rot: float = rotation_radians + step_angle

		var mirror_piece := _spawn_piece(
			shape_type,
			color_tier,
			size_tier,
			mirror_pos,
			mirror_rot,
			arm_index,
			true        # is_mirror
		)

		mirror_group.append(mirror_piece)

	_mirrors.append(mirror_group)

	return arm0_piece


## Remove every piece (Arm 0 and all mirrors) from the board and free their nodes.
## Called when archiving the Mandala at the end of a run or resetting to a
## clean state for a new game.
func clear() -> void:
	for piece in pieces:
		piece.queue_free()
	pieces.clear()

	for mirror_group in _mirrors:
		for mirror_piece in mirror_group:
			mirror_piece.queue_free()
	_mirrors.clear()


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## Instantiate, configure, and add a single MandalaPiece as a child of this
## node. Mirror pieces have process_mode disabled to keep them completely
## inert — they render but run no logic.
func _spawn_piece(
		shape_type:       String,
		color_tier:       String,
		size_tier:        String,
		world_position:   Vector2,
		rotation_radians: float,
		symmetry_index:   int,
		is_mirror:        bool
) -> MandalaPiece:
	var piece := MandalaPieceScene.instantiate() as MandalaPiece

	piece.shape_type     = shape_type
	piece.color_tier     = color_tier
	piece.size_tier      = size_tier
	piece.position       = world_position
	piece.rotation       = rotation_radians
	piece.symmetry_index = symmetry_index

	if is_mirror:
		# Disable all processing — mirror pieces are display-only.
		piece.process_mode = Node.PROCESS_MODE_DISABLED

	add_child(piece)

	return piece
