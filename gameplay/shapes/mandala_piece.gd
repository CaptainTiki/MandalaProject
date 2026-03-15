class_name MandalaPiece
extends Node2D

## MandalaPiece — a single geometric tile placed on the Mandala board.
##
## Owns its own polygon geometry, color, and edge/neighbor state.
## The Mandala system creates and positions these; this class only
## knows about itself and its immediate neighbors.
##
## See GDD §14 for the full data model spec.


# ---------------------------------------------------------------------------
# Shape type constants
# ---------------------------------------------------------------------------

const SHAPE_TRIANGLE := "triangle"
const SHAPE_SQUARE   := "square"
const SHAPE_PENTAGON := "pentagon"
const SHAPE_HEXAGON  := "hexagon"
const SHAPE_OCTAGON  := "octagon"


# ---------------------------------------------------------------------------
# Color tier constants
# ---------------------------------------------------------------------------

const COLOR_GREY   := "grey"
const COLOR_BLUE   := "blue"
const COLOR_RED    := "red"
const COLOR_PURPLE := "purple"
const COLOR_GOLD   := "gold"


# ---------------------------------------------------------------------------
# Size tier constants
# ---------------------------------------------------------------------------

const SIZE_SMALL  := "small"
const SIZE_NORMAL := "normal"
const SIZE_LARGE  := "large"
const SIZE_VAST   := "vast"


# ---------------------------------------------------------------------------
# Lookup tables
# ---------------------------------------------------------------------------

## Number of polygon sides per shape type.
const SHAPE_SIDES: Dictionary = {
	SHAPE_TRIANGLE: 3,
	SHAPE_SQUARE:   4,
	SHAPE_PENTAGON: 5,
	SHAPE_HEXAGON:  6,
	SHAPE_OCTAGON:  8,
}

## Edge length in world pixels per size tier.
## Every shape at the same tier has exactly this side length, regardless of
## how many sides it has. The circumradius is derived per-shape at build time:
##   circumradius = side_length / (2 * sin(PI / N))
## This guarantees flush snapping between any two shapes of the same tier.
const SIZE_SIDE_LENGTHS: Dictionary = {
	SIZE_SMALL:  40.0,
	SIZE_NORMAL: 60.0,
	SIZE_LARGE:  80.0,
	SIZE_VAST:   120.0,
}

## Base fill color per color tier.
## Shaders will modulate these for glow and saturation effects.
const TIER_COLORS: Dictionary = {
	COLOR_GREY:   Color(0.55, 0.55, 0.60, 1.0),
	COLOR_BLUE:   Color(0.25, 0.45, 0.85, 1.0),
	COLOR_RED:    Color(0.85, 0.25, 0.25, 1.0),
	COLOR_PURPLE: Color(0.55, 0.20, 0.80, 1.0),
	COLOR_GOLD:   Color(0.85, 0.75, 0.10, 1.0),
}


# ---------------------------------------------------------------------------
# Exported properties — editable in the Godot inspector
# ---------------------------------------------------------------------------

@export_enum("triangle", "square", "pentagon", "hexagon", "octagon")
var shape_type: String = SHAPE_HEXAGON :
	set(value):
		shape_type = value
		if is_node_ready():
			rebuild()

@export_enum("grey", "blue", "red", "purple", "gold")
var color_tier: String = COLOR_BLUE :
	set(value):
		color_tier = value
		if is_node_ready():
			rebuild()

@export_enum("small", "normal", "large", "vast")
var size_tier: String = SIZE_NORMAL :
	set(value):
		size_tier = value
		if is_node_ready():
			rebuild()


# ---------------------------------------------------------------------------
# Runtime state  (GDD §14)
# ---------------------------------------------------------------------------

## Which symmetry arm this piece belongs to.
## 0 = canonical Arm 0 (player-interactive).
## 1..N-1 = mirror arms (display only, no hit detection or Sigil logic).
var symmetry_index: int = 0

## Edge descriptors for this piece.
## Each entry is a Dictionary:
##   "index"    : int     — edge number, 0 .. sides-1
##   "midpoint" : Vector2 — midpoint in local space
##   "normal"   : Vector2 — outward unit normal in local space
##   "neighbor" : MandalaPiece or null — piece sharing this edge, if any
## Rebuilt every time rebuild() runs.
var open_edges: Array = []

## MandalaPiece references for every piece sharing an edge with this one.
## Kept in sync with open_edges by the adjacency system.
var neighbors: Array = []

## Sigil instances this piece currently participates in.
## Populated and cleared by the Sigil detection system.
var active_sigils: Array = []


# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@onready var _polygon:  Polygon2D      = $Polygon
@onready var _material: ShaderMaterial = null


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Duplicate the shared ShaderMaterial so each piece instance owns its own
	# copy. Without this, setting glow_intensity or saturation on one piece
	# would affect every piece that shares the same material resource.
	_material = (_polygon.material as ShaderMaterial).duplicate()
	_polygon.material = _material
	rebuild()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Rebuild polygon geometry and edge data from current property values.
## Safe to call at any time after _ready(); the inspector setters call it
## automatically when properties change in-editor.
func rebuild() -> void:
	_build_polygon()
	_compute_open_edges()


## Return the circumradius of the current shape in world pixels.
## Derived from the shared side length so it is consistent with _build_polygon.
func get_radius() -> float:
	var side_count:  int   = SHAPE_SIDES[shape_type]
	var side_length: float = SIZE_SIDE_LENGTHS[size_tier]
	return side_length / (2.0 * sin(PI / float(side_count)))


## Return the number of sides for the current shape.
func get_side_count() -> int:
	return SHAPE_SIDES[shape_type]


## Return the polygon vertex positions in this node's local space.
## Used by MandalaBuilder's overlap detection to build world-space hulls
## without needing direct access to the private Polygon2D child.
func get_vertices() -> PackedVector2Array:
	return _polygon.polygon


## Set the overall glow multiplier on this piece's shader.
## Called by the Sigil system on activation and by Resonance event handlers.
## Tween this value for smooth transitions rather than snapping it.
func set_glow_intensity(value: float) -> void:
	_material.set_shader_parameter("glow_intensity", value)


## Set the color saturation multiplier on this piece's shader.
## Chromatic Dissonance calls this with values below 1.0 (towards grey).
## Chromatic Resonance calls this with values above 1.0 (vivid oversaturation).
func set_saturation(value: float) -> void:
	_material.set_shader_parameter("saturation", value)


# ---------------------------------------------------------------------------
# Private — polygon geometry
# ---------------------------------------------------------------------------

## Generate a regular N-gon and apply it to the Polygon2D child node.
##
## Orientation rule:
##   - Odd-sided shapes (triangle, pentagon): one vertex points straight up.
##   - Even-sided shapes (square, hexagon, octagon): one flat edge faces up.
## This keeps pieces visually stable and aligns edges predictably for the
## adjacency system.
func _build_polygon() -> void:
	var side_count:  int   = SHAPE_SIDES[shape_type]
	var side_length: float = SIZE_SIDE_LENGTHS[size_tier]
	var fill_color:  Color = TIER_COLORS[color_tier]

	# Circumradius derived from the shared side length.
	# All N-gons at the same size tier produce edges of exactly side_length px,
	# so any two same-tier pieces snap flush with no gap or overlap.
	var radius: float = side_length / (2.0 * sin(PI / float(side_count)))

	# -PI/2 puts the first vertex at the top (12 o'clock).
	# For even-sided shapes, rotating by one half-step gives a flat top edge.
	var start_angle: float = -PI / 2.0
	if side_count % 2 == 0:
		start_angle += PI / float(side_count)

	var vertices := PackedVector2Array()
	for i in side_count:
		var angle: float = start_angle + (TAU / float(side_count)) * float(i)
		vertices.append(Vector2(cos(angle), sin(angle)) * radius)

	_polygon.polygon = vertices
	_polygon.color   = fill_color

	# Keep the shader's shape_radius uniform in sync so the inner glow gradient
	# always scales to fit the actual polygon size.
	if _material:
		_material.set_shader_parameter("shape_radius", radius)


# ---------------------------------------------------------------------------
# Private — edge data
# ---------------------------------------------------------------------------

## Populate open_edges from the current polygon vertices.
##
## Each edge runs from vertex[i] to vertex[(i+1) % side_count].
## The outward normal is perpendicular to the edge and points away from
## the polygon center (origin in local space).
## All edges start as open (neighbor = null); the adjacency system fills
## neighbors in after pieces are placed.
func _compute_open_edges() -> void:
	open_edges.clear()

	var vertices:   PackedVector2Array = _polygon.polygon
	var side_count: int                = vertices.size()

	for i in side_count:
		var vertex_a: Vector2 = vertices[i]
		var vertex_b: Vector2 = vertices[(i + 1) % side_count]

		var midpoint:    Vector2 = (vertex_a + vertex_b) * 0.5
		var edge_vector: Vector2 = vertex_b - vertex_a

		# Rotate the edge vector 90° clockwise to get a candidate normal,
		# then ensure it faces outward by checking the sign of its dot product
		# with the midpoint (which itself points away from the center).
		var outward_normal: Vector2 = Vector2(edge_vector.y, -edge_vector.x).normalized()
		if outward_normal.dot(midpoint) < 0.0:
			outward_normal = -outward_normal

		open_edges.append({
			"index":    i,
			"midpoint": midpoint,
			"normal":   outward_normal,
			"neighbor": null,
		})
