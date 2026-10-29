extends Node

## Responsive shell: the window can be any size; scenes lay themselves out
## against the real viewport instead of letterboxing a fixed 1280x720 frame.

const MIN_SIZE := Vector2i(960, 540)


func _ready() -> void:
	var window := get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	window.min_size = MIN_SIZE
