extends Node2D

## MandalaBuilder — top-level in-run scene.
##
## Manages the ghost preview piece with edge-snapping. The ghost is only
## visible when the mouse is within snap_radius world-pixels of an open edge
## midpoint on a placed piece AND the ghost would not overlap any already-
## placed piece. Outside that radius, or when every candidate edge would
## cause an overlap, the ghost hides and no placement can occur.


const MandalaPieceScene := preload("res://gameplay/shapes/mandala_piece.tscn")

## World-pixel radius within which the mouse snaps to the nearest open edge.
## Exported so it can be tuned in the inspector without touching code.
@export var snap_radius: float = 80.0

## How many world-pixels of overlap are "forgiven" during the SAT overlap check.
## Snapped pieces sit flush with zero gap, but floating-point math produces
## micro-overlaps (< 1 px) that would otherwise make every snap look blocked.
## Raise this value if legitimate placements are still rejected; lower it if
## visually overlapping placements are being incorrectly allowed.
@export var overlap_tolerance: float = 1.0

## Opacity of the ghost preview.
const GHOST_ALPHA := 0.4


@onready var _mandala: Mandala    = $Mandala
@onready var _hud:     BuilderHUD = $BuilderHUD

var _ghost: MandalaPiece

var _pending_shape: String = "hexagon"
var _pending_color: String = "blue"


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_hud.piece_selection_changed.connect(_on_selection_changed)
	_create_ghost()


# ---------------------------------------------------------------------------
# Ghost management
# ---------------------------------------------------------------------------

func _create_ghost() -> void:
	_ghost             = MandalaPieceScene.instantiate() as MandalaPiece
	_ghost.shape_type  = _pending_shape
	_ghost.color_tier  = _pending_color
	_ghost.size_tier   = MandalaPiece.SIZE_NORMAL
	_ghost.modulate    = Color(1.0, 1.0, 1.0, GHOST_ALPHA)
	_ghost.visible     = false
	add_child(_ghost)


func _process(_delta: float) -> void:
	# Gather all edges within snap_radius, sorted nearest-first.
	var candidates: Array = _find_snap_candidates()

	# Walk candidates until we find one where the ghost fits without overlap.
	for snap: Dictionary in candidates:
		var transform: Dictionary = _compute_ghost_transform(snap)

		if not _ghost_overlaps_any_piece(transform.position, transform.rotation):
			_ghost.visible  = true
			_ghost.position = transform.position
			_ghost.rotation = transform.rotation
			return

	# No valid snap found — hide the ghost.
	_ghost.visible = false


# ---------------------------------------------------------------------------
# Snap — candidate search
# ---------------------------------------------------------------------------

## Return every open edge within snap_radius of the mouse, sorted by
## ascending distance. Each entry is a Dictionary with keys:
##   "world_midpoint" : Vector2  — edge midpoint in world space
##   "world_normal"   : Vector2  — outward unit normal in world space
##   "dist"           : float    — distance from mouse to midpoint
func _find_snap_candidates() -> Array:
	var mouse_world: Vector2 = get_global_mouse_position()
	var candidates:  Array   = []

	for piece: MandalaPiece in _mandala.pieces:
		for edge: Dictionary in piece.open_edges:
			# Skip edges already occupied by a neighbour.
			if edge.neighbor != null:
				continue

			# piece.to_global() applies the full transform chain (position +
			# rotation) so we get the correct world-space midpoint even if
			# the Mandala node is ever moved or rotated later.
			var world_mid: Vector2 = piece.to_global(edge.midpoint)
			var dist:      float   = mouse_world.distance_to(world_mid)

			if dist <= snap_radius:
				candidates.append({
					"world_midpoint": world_mid,
					"world_normal":   edge.normal.rotated(piece.global_rotation),
					"dist":           dist,
				})

	# Sort nearest-first so _process() always tries the most-likely snap first.
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.dist < b.dist
	)

	return candidates


# ---------------------------------------------------------------------------
# Snap — ghost orientation (pure, no side-effects)
# ---------------------------------------------------------------------------

## Compute the position and rotation the ghost would need to sit flush
## against the given snap edge. Returns a Dictionary with keys:
##   "position" : Vector2  — ghost node position in this scene's local space
##   "rotation" : float    — ghost node rotation in radians
##
## This function does NOT move the ghost — callers apply the result only
## after confirming no overlap.
func _compute_ghost_transform(snap: Dictionary) -> Dictionary:
	var snap_midpoint: Vector2 = snap.world_midpoint
	var snap_normal:   Vector2 = snap.world_normal

	# The direction the ghost's connecting edge must face (into the existing piece).
	var target_dir: Vector2 = -snap_normal

	# Find the ghost edge (at rotation 0) whose local normal is closest to
	# target_dir. Maximising the dot product is equivalent to minimising the
	# angle between them for unit vectors.
	var best_edge_idx: int   = 0
	var best_dot:      float = -2.0

	for i: int in _ghost.open_edges.size():
		var dot: float = (_ghost.open_edges[i].normal as Vector2).dot(target_dir)
		if dot > best_dot:
			best_dot      = dot
			best_edge_idx = i

	var local_normal: Vector2 = _ghost.open_edges[best_edge_idx].normal
	var local_mid:    Vector2 = _ghost.open_edges[best_edge_idx].midpoint

	# Rotation that exactly aligns local_normal with target_dir.
	var ghost_rotation: float = target_dir.angle() - local_normal.angle()

	# Translate so the matched edge midpoint lands on the snap midpoint.
	# local_mid must be rotated by ghost_rotation to get its world-space offset.
	var ghost_position: Vector2 = snap_midpoint - local_mid.rotated(ghost_rotation)

	return {
		"position": ghost_position,
		"rotation": ghost_rotation,
	}


# ---------------------------------------------------------------------------
# Overlap detection — Separating Axis Theorem (SAT)
# ---------------------------------------------------------------------------

## Return true if the ghost, placed at ghost_pos / ghost_rot (in this node's
## local space), would overlap any already-placed piece on the Mandala.
##
## Flush-touching is NOT treated as overlap (uses <= rather than < for the
## separating axis gap test) so snapped pieces that share an edge can sit
## exactly adjacent without triggering a false positive.
func _ghost_overlaps_any_piece(ghost_pos: Vector2, ghost_rot: float) -> bool:
	# Build world-space hull for the ghost at its hypothetical transform.
	var ghost_verts: PackedVector2Array = _get_transformed_vertices(
		_ghost, ghost_pos, ghost_rot
	)

	for piece: MandalaPiece in _mandala.pieces:
		var piece_verts: PackedVector2Array = _get_transformed_vertices(
			piece, piece.global_position, piece.global_rotation
		)

		if _polygons_overlap(ghost_verts, piece_verts):
			return true

	return false


## Build a world-space PackedVector2Array for a piece by applying a given
## world position and rotation to its local polygon vertices.
##
## world_pos and world_rot describe the piece's intended world-space transform.
## For already-placed pieces, pass piece.global_position / piece.global_rotation.
## For the ghost (which lives as a child of MandalaBuilder, not Mandala) pass
## its hypothetical global position and rotation directly.
func _get_transformed_vertices(
	piece:     MandalaPiece,
	world_pos: Vector2,
	world_rot: float,
) -> PackedVector2Array:
	var local_verts: PackedVector2Array = piece.get_vertices()
	var world_verts: PackedVector2Array = PackedVector2Array()

	for v: Vector2 in local_verts:
		# Rotate the local vertex by the piece's world rotation, then
		# translate to world space.
		world_verts.append(world_pos + v.rotated(world_rot))

	return world_verts


## Test whether two convex polygons overlap using the Separating Axis Theorem.
##
## For each edge of each polygon, the edge's outward normal is a candidate
## separating axis. If the projections of both polygons onto ANY axis have a
## gap (strictly positive separation, i.e. min_b > max_a using strict >),
## the polygons are separate. Using strict > means that projections that
## merely touch (gap == 0) are NOT treated as separated — flush-snapped
## pieces are allowed.
##
## Returns true when the polygons DO overlap (no separating axis was found).
func _polygons_overlap(
	verts_a: PackedVector2Array,
	verts_b: PackedVector2Array,
) -> bool:
	# Check axes derived from verts_a, then axes derived from verts_b.
	for verts: PackedVector2Array in [verts_a, verts_b]:
		var count: int = verts.size()

		for i: int in count:
			var vertex_a: Vector2 = verts[i]
			var vertex_b: Vector2 = verts[(i + 1) % count]

			# Outward normal of this edge (perpendicular, not normalised —
			# SAT only needs the direction, not unit length, for projection
			# comparison).
			var edge:   Vector2 = vertex_b - vertex_a
			var normal: Vector2 = Vector2(edge.y, -edge.x)

			# Project both polygons onto this axis.
			var min_a: float =  INF
			var max_a: float = -INF
			for v: Vector2 in verts_a:
				var proj: float = v.dot(normal)
				min_a = min(min_a, proj)
				max_a = max(max_a, proj)

			var min_b: float =  INF
			var max_b: float = -INF
			for v: Vector2 in verts_b:
				var proj: float = v.dot(normal)
				min_b = min(min_b, proj)
				max_b = max(max_b, proj)

			# Gap test with tolerance: treat any separation greater than
			# -overlap_tolerance as a separating axis. This forgives the tiny
			# floating-point micro-overlaps that occur when two snapped pieces
			# sit perfectly flush (where the mathematically correct gap is 0).
			if min_b > max_a - overlap_tolerance or min_a > max_b - overlap_tolerance:
				return false   # Separating axis found — polygons do NOT overlap.

	return true   # No separating axis found — polygons DO overlap.


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_selection_changed(shape_type: String, color_tier: String) -> void:
	_pending_shape    = shape_type
	_pending_color    = color_tier
	_ghost.shape_type = shape_type
	_ghost.color_tier = color_tier


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and _ghost.visible:
			# Place at the ghost's current snapped position and rotation so
			# the real piece lands exactly where the preview showed it.
			_mandala.add_piece(
				_pending_shape,
				_pending_color,
				MandalaPiece.SIZE_NORMAL,
				_ghost.position,
				_ghost.rotation
			)
