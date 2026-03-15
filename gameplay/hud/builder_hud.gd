class_name BuilderHUD
extends CanvasLayer

## BuilderHUD — the right-side selection panel for the Mandala board.
##
## Presents shape and color pickers. Emits piece_selection_changed whenever
## the player makes a new choice. The MandalaBuilder listens to this signal
## and updates the pending placement state so the next world click places
## a piece with the correct properties.


# Emitted whenever the player changes shape or color selection.
# The MandalaBuilder connects to this to track the pending piece type.
signal piece_selection_changed(shape_type: String, color_tier: String)


# ---------------------------------------------------------------------------
# Selection data
# ---------------------------------------------------------------------------

# Shape options: [ shape_id, display_label ]
const SHAPE_OPTIONS: Array = [
	["triangle", "Triangle"],
	["square",   "Square"],
	["pentagon", "Pentagon"],
	["hexagon",  "Hexagon"],
	["octagon",  "Octagon"],
]

# Color options: [ color_id, display_label, Color ]
# Color values match MandalaPiece.TIER_COLORS so buttons visually reflect
# the actual in-game tier color.
const COLOR_OPTIONS: Array = [
	["grey",   "Grey",   Color(0.55, 0.55, 0.60)],
	["blue",   "Blue",   Color(0.25, 0.45, 0.85)],
	["red",    "Red",    Color(0.85, 0.25, 0.25)],
	["purple", "Purple", Color(0.55, 0.20, 0.80)],
	["gold",   "Gold",   Color(0.85, 0.75, 0.10)],
]

# Currently active selections — defaults match MandalaPiece defaults.
var selected_shape: String = "hexagon"
var selected_color: String = "blue"


# ---------------------------------------------------------------------------
# Node references (paths match builder_hud.tscn structure)
# ---------------------------------------------------------------------------

@onready var _shape_grid: GridContainer = $RightPanel/Margin/VBox/ShapeGrid
@onready var _color_grid: GridContainer = $RightPanel/Margin/VBox/ColorGrid


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_build_shape_buttons()
	_build_color_buttons()


# ---------------------------------------------------------------------------
# Button construction
# ---------------------------------------------------------------------------

## Spawn one toggle button per shape into the ShapeGrid.
## All buttons share a ButtonGroup so only one can be active at a time.
func _build_shape_buttons() -> void:
	var group := ButtonGroup.new()

	for option in SHAPE_OPTIONS:
		var shape_id: String = option[0]
		var label:    String = option[1]

		var button := Button.new()
		button.text                  = label
		button.toggle_mode           = true
		button.button_group          = group
		button.button_pressed        = (shape_id == selected_shape)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_shape_pressed.bind(shape_id))

		_shape_grid.add_child(button)


## Spawn one toggle button per color into the ColorGrid.
## self_modulate tints each button with its tier color so the player can
## see the actual color without needing to read the label.
func _build_color_buttons() -> void:
	var group := ButtonGroup.new()

	for option in COLOR_OPTIONS:
		var color_id:    String = option[0]
		var label:       String = option[1]
		var color_value: Color  = option[2]

		var button := Button.new()
		button.text                  = label
		button.toggle_mode           = true
		button.button_group          = group
		button.button_pressed        = (color_id == selected_color)
		button.self_modulate         = color_value
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_color_pressed.bind(color_id))

		_color_grid.add_child(button)


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_shape_pressed(shape_id: String) -> void:
	selected_shape = shape_id
	piece_selection_changed.emit(selected_shape, selected_color)


func _on_color_pressed(color_id: String) -> void:
	selected_color = color_id
	piece_selection_changed.emit(selected_shape, selected_color)
