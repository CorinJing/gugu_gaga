extends Node

## Responsive shell: the window can be any size; scenes lay themselves out
## against the real viewport instead of letterboxing a fixed 1280x720 frame.
##
## Important: do NOT set Window.min_size here. In Godot's embedded game panel,
## min_size can become the actual render viewport (e.g. 960x540 inside a
## 1280x720 panel), which looks like the game "cannot be enlarged".

func _ready() -> void:
	var window := get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
