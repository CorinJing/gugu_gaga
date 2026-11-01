extends Control

## Minimal black-ink signature pad. The pen tip is supplied in global coordinates.

var strokes: Array[PackedVector2Array] = []
var _current: PackedVector2Array = PackedVector2Array()


func clear_ink() -> void:
	strokes.clear()
	_current = PackedVector2Array()
	queue_redraw()


func begin_stroke(global_point: Vector2) -> void:
	_current = PackedVector2Array([get_global_transform().affine_inverse() * global_point])
	strokes.append(_current)
	queue_redraw()


func add_point(global_point: Vector2) -> void:
	if _current.is_empty():
		begin_stroke(global_point)
		return
	_current.append(get_global_transform().affine_inverse() * global_point)
	strokes[strokes.size() - 1] = _current
	queue_redraw()


func end_stroke() -> void:
	_current = PackedVector2Array()


func has_ink() -> bool:
	for stroke in strokes:
		if stroke.size() >= 2:
			return true
	return false


func _draw() -> void:
	var ink := Color(0.035, 0.028, 0.022, 1.0)
	for stroke in strokes:
		if stroke.size() >= 2:
			draw_polyline(stroke, ink, 3.0, true)
		elif stroke.size() == 1:
			draw_circle(stroke[0], 1.8, ink)
