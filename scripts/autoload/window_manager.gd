extends Node

## Keep the game's 16:9 design space intact on any window size.
## The 4:3 stage is part of that design space; resizing must not distort it.

const DESIGN_SIZE := Vector2i(1280, 720)
const MIN_SIZE := Vector2i(960, 540)


func _ready() -> void:
	var window := get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_size = DESIGN_SIZE
	window.min_size = MIN_SIZE
