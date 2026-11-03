extends Control

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton
@onready var subtitle_label: Label = %Subtitle
@onready var top_rule: ColorRect = $TopRule
@onready var version_label: Label = %Version
@onready var menu_panel: Panel = %MenuPanel


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	get_viewport().size_changed.connect(_layout)
	_layout()
	start_button.grab_focus()


func _layout() -> void:
	var vp := get_viewport_rect().size
	if vp.x <= 1.0 or vp.y <= 1.0:
		return
	var s: float = clampf(minf(vp.x / 1280.0, vp.y / 720.0), 0.68, 2.2)

	var pw: float = minf(360.0 * s, vp.x - 32.0 * s)
	var ph: float = minf(218.0 * s, vp.y - 32.0 * s)
	var px: float = vp.x - pw - 32.0 * s
	var py: float = vp.y - ph - 32.0 * s

	menu_panel.position = Vector2(px, py)
	menu_panel.size = Vector2(pw, ph)

	subtitle_label.position = Vector2(px + 22.0 * s, py + 18.0 * s)
	subtitle_label.size = Vector2(pw - 44.0 * s, 20.0 * s)
	subtitle_label.add_theme_font_size_override("font_size", int(11.0 * s))

	top_rule.position = Vector2(px + 22.0 * s, py + 44.0 * s)
	top_rule.size = Vector2(pw - 44.0 * s, 1.0)

	start_button.position = Vector2(px + 22.0 * s, py + 60.0 * s)
	start_button.size = Vector2(pw - 44.0 * s, 52.0 * s)
	start_button.add_theme_font_size_override("font_size", int(19.0 * s))

	quit_button.position = Vector2(px + 22.0 * s, py + 120.0 * s)
	quit_button.size = Vector2(pw - 44.0 * s, 40.0 * s)
	quit_button.add_theme_font_size_override("font_size", int(16.0 * s))

	version_label.position = Vector2(px + 22.0 * s, py + ph - 24.0 * s)
	version_label.size = Vector2(pw - 44.0 * s, 18.0 * s)
	version_label.add_theme_font_size_override("font_size", int(9.0 * s))


func _on_start_pressed() -> void:
	GameState.reset()
	SceneTransition.change_scene("res://scenes/ch1/ch1.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
