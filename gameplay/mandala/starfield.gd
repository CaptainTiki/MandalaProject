extends Node2D

@export var dot_count: int = 100
@export var dot_radius: float = 1.5
@export var spread: float = 2000.0
@export var dot_color: Color = Color(1.0, 1.0, 1.0, 0.5)

var _positions: Array[Vector2] = []


func _ready() -> void:
	for i in dot_count:
		_positions.append(Vector2(
			randf_range(-spread, spread),
			randf_range(-spread, spread)
		))
	queue_redraw()


func _draw() -> void:
	for pos in _positions:
		draw_circle(pos, dot_radius, dot_color)
