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


func transition(callback: Callable, fade_out: float = FADE_OUT, fade_in: float = FADE_IN) -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0, fade_out)
	callback.call()
	await get_tree().process_frame
	await _fade_to(0.0, fade_in)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func change_scene(path: String, fade_out: float = FADE_OUT, fade_in: float = FADE_IN) -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0, fade_out)
	# 黑场里先把声音压掉：读图和建场景期间音频线程容易欠载，压掉就听不见了。
	AudioDirector.fade_master_out(0.12)
	await get_tree().create_timer(0.12).timeout
	await _await_threaded(path)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	AudioDirector.fade_master_in(0.45)
	await _fade_to(0.0, fade_in)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


## 如果这个场景已经在后台预读，就在黑场里等它读完，避免切场景时主线程卡住。
## ThreadLoadStatus: 0=INVALID 1=IN_PROGRESS 2=FAILED 3=DONE
func _await_threaded(path: String) -> void:
	if int(ResourceLoader.load_threaded_get_status(path)) != 1:
		return
	var guard := 0
	while int(ResourceLoader.load_threaded_get_status(path)) == 1 and guard < 240:
		guard += 1
		await get_tree().process_frame
