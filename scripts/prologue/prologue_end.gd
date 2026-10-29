extends Control

@onready var title_label: Label = $Title
@onready var subtitle_label: Label = $Subtitle
@onready var placeholder_label: Label = $Placeholder
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var vp := get_viewport_rect().size
	if vp.x <= 1.0 or vp.y <= 1.0:
		return
	var s: float = clampf(minf(vp.x / 1280.0, vp.y / 720.0), 0.68, 2.2)
	var cx := vp.x * 0.5

	title_label.position = Vector2(0.0, vp.y * 0.30)
	title_label.size = Vector2(vp.x, 80.0 * s)
	title_label.add_theme_font_size_override("font_size", int(44.0 * s))

	subtitle_label.position = Vector2(0.0, vp.y * 0.30 + 90.0 * s)
	subtitle_label.size = Vector2(vp.x, 34.0 * s)
	subtitle_label.add_theme_font_size_override("font_size", int(18.0 * s))

	placeholder_label.position = Vector2(0.0, vp.y * 0.30 + 145.0 * s)
	placeholder_label.size = Vector2(vp.x, 26.0 * s)
	placeholder_label.add_theme_font_size_override("font_size", int(13.0 * s))

	back_button.position = Vector2(cx - 100.0 * s, vp.y * 0.66)
	back_button.size = Vector2(200.0 * s, 44.0 * s)
	back_button.add_theme_font_size_override("font_size", int(16.0 * s))


func _on_back_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
