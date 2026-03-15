extends Camera2D

const ZOOM_MIN := 0.3
const ZOOM_MAX := 3.0
const ZOOM_STEP := 0.15
const ZOOM_LERP_SPEED := 10.0

var _target_zoom := 1.0
var _dragging := false
var _drag_start_mouse := Vector2.ZERO
var _drag_start_pos := Vector2.ZERO

@onready var _background: Polygon2D = get_parent().get_node("Background")

func _ready() -> void:
	_target_zoom = zoom.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				_dragging = event.pressed
				if _dragging:
					_drag_start_mouse = get_viewport().get_mouse_position()
					_drag_start_pos = position
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_target_zoom = clampf(_target_zoom + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_target_zoom = clampf(_target_zoom - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)

	elif event is InputEventMouseMotion and _dragging:
		var delta := get_viewport().get_mouse_position() - _drag_start_mouse
		position = _drag_start_pos - delta / zoom.x


func _process(delta: float) -> void:
	zoom = zoom.lerp(Vector2(_target_zoom, _target_zoom), ZOOM_LERP_SPEED * delta)
	#_background.global_position = global_position
