extends Control

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton
@onready var title_label: Label = $Title
@onready var subtitle_label: Label = $Subtitle
@onready var chapter_label: Label = $Chapter
@onready var top_rule: ColorRect = $TopRule
@onready var version_label: Label = $Version
@onready var footer_label: Label = $Footer


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
	var cx := vp.x * 0.5
	var top: float = maxf(40.0, (vp.y - 420.0 * s) * 0.5)

	top_rule.position = Vector2(cx - 200.0 * s, top - 24.0 * s)
	top_rule.size = Vector2(400.0 * s, 1.0)

	title_label.position = Vector2(0.0, top)
	title_label.size = Vector2(vp.x, 110.0 * s)
	title_label.add_theme_font_size_override("font_size", int(74.0 * s))

	subtitle_label.position = Vector2(0.0, top + 112.0 * s)
	subtitle_label.size = Vector2(vp.x, 35.0 * s)
	subtitle_label.add_theme_font_size_override("font_size", int(19.0 * s))

	chapter_label.position = Vector2(0.0, top + 165.0 * s)
	chapter_label.size = Vector2(vp.x, 35.0 * s)
	chapter_label.add_theme_font_size_override("font_size", int(17.0 * s))

	start_button.position = Vector2(cx - 128.0 * s, top + 245.0 * s)
	start_button.size = Vector2(256.0 * s, 54.0 * s)
	start_button.add_theme_font_size_override("font_size", int(21.0 * s))

	quit_button.position = Vector2(cx - 128.0 * s, top + 315.0 * s)
	quit_button.size = Vector2(256.0 * s, 40.0 * s)
	quit_button.add_theme_font_size_override("font_size", int(15.0 * s))

	version_label.position = Vector2(0.0, vp.y - 92.0 * s)
	version_label.size = Vector2(vp.x, 24.0 * s)
	version_label.add_theme_font_size_override("font_size", int(12.0 * s))

	footer_label.position = Vector2(0.0, vp.y - 58.0 * s)
	footer_label.size = Vector2(vp.x, 22.0 * s)
	footer_label.add_theme_font_size_override("font_size", int(11.0 * s))


func _on_start_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/prologue/prologue_demo.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
