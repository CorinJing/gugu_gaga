extends CanvasLayer

## Reusable fade-to-black transition for both scene changes and in-scene cuts.

const FADE_OUT := 0.28
const FADE_IN := 0.34

var _rect: ColorRect
var _busy := false


func _ready() -> void:
	layer = 1000
	_rect = ColorRect.new()
	_rect.color = Color(0.015, 0.02, 0.018, 1.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_rect)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.modulate.a = 1.0
	await get_tree().process_frame
	await _fade_to(0.0, 0.45)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_rect, "modulate:a", alpha, duration)
	await tween.finished


func transition(callback: Callable) -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0, FADE_OUT)
	callback.call()
	await get_tree().process_frame
	await _fade_to(0.0, FADE_IN)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0, FADE_OUT)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0, FADE_IN)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
