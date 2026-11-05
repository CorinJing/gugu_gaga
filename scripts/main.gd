extends Control

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton
@onready var menu_panel: Panel = %MenuPanel


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	get_viewport().size_changed.connect(_layout)
	_layout()
	start_button.grab_focus()
	AudioDirector.set_scene("title", "")


func _layout() -> void:
	var vp := get_viewport_rect().size
	if vp.x <= 1.0 or vp.y <= 1.0:
		return
	var s: float = clampf(minf(vp.x / 1280.0, vp.y / 720.0), 0.68, 2.2)

	var pw: float = minf(360.0 * s, vp.x - 32.0 * s)
	var ph: float = minf(180.0 * s, vp.y - 32.0 * s)
	var px: float = vp.x - pw - 32.0 * s
	var py: float = vp.y - ph - 32.0 * s

	menu_panel.position = Vector2(px, py)
	menu_panel.size = Vector2(pw, ph)

	start_button.position = Vector2(px + 22.0 * s, py + 24.0 * s)
	start_button.size = Vector2(pw - 44.0 * s, 52.0 * s)
	start_button.add_theme_font_size_override("font_size", int(19.0 * s))

	quit_button.position = Vector2(px + 22.0 * s, py + 90.0 * s)
	quit_button.size = Vector2(pw - 44.0 * s, 40.0 * s)
	quit_button.add_theme_font_size_override("font_size", int(16.0 * s))


func _on_start_pressed() -> void:
	AudioDirector.ui("click")
	AudioDirector.set_music("", 0.3)
	GameState.reset()
	SceneTransition.change_scene("res://scenes/prologue/prologue_demo.tscn")


func _on_quit_pressed() -> void:
	AudioDirector.ui("click")
	get_tree().quit()
