extends Control

@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var menu_panel: Panel = %MenuPanel
@onready var settings_overlay: Control = %SettingsOverlay
@onready var settings_panel: Panel = $SettingsOverlay/Panel
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue
@onready var settings_close: Button = %SettingsClose

const SETTINGS_PATH := "user://settings.cfg"
var _volume: float = 80.0


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_close.pressed.connect(_on_settings_close)
	volume_slider.value_changed.connect(_on_volume_changed)
	_load_settings()
	get_viewport().size_changed.connect(_layout)
	_layout()
	start_button.grab_focus()


func _layout() -> void:
	var vp := get_viewport_rect().size
	if vp.x <= 1.0 or vp.y <= 1.0:
		return
	var s: float = clampf(minf(vp.x / 1280.0, vp.y / 720.0), 0.68, 2.2)

	var pw: float = minf(360.0 * s, vp.x - 32.0 * s)
	var ph: float = minf(260.0 * s, vp.y - 32.0 * s)
	var px: float = vp.x - pw - 32.0 * s
	var py: float = vp.y - ph - 32.0 * s

	menu_panel.position = Vector2(px, py)
	menu_panel.size = Vector2(pw, ph)

	start_button.position = Vector2(px + 22.0 * s, py + 24.0 * s)
	start_button.size = Vector2(pw - 44.0 * s, 52.0 * s)
	start_button.add_theme_font_size_override("font_size", int(19.0 * s))

	settings_button.position = Vector2(px + 22.0 * s, py + 90.0 * s)
	settings_button.size = Vector2(pw - 44.0 * s, 44.0 * s)
	settings_button.add_theme_font_size_override("font_size", int(17.0 * s))

	quit_button.position = Vector2(px + 22.0 * s, py + 150.0 * s)
	quit_button.size = Vector2(pw - 44.0 * s, 40.0 * s)
	quit_button.add_theme_font_size_override("font_size", int(16.0 * s))

	settings_overlay.position = Vector2.ZERO
	settings_overlay.size = vp
	var spw: float = minf(360.0 * s, vp.x - 48.0 * s)
	var sph: float = minf(240.0 * s, vp.y - 48.0 * s)
	settings_panel.position = Vector2((vp.x - spw) * 0.5, (vp.y - sph) * 0.5)
	settings_panel.size = Vector2(spw, sph)
	var title := settings_panel.get_node_or_null("Title") as Label
	if title != null:
		title.position = Vector2(24.0 * s, 20.0 * s)
		title.size = Vector2(spw - 48.0 * s, 34.0 * s)
		title.add_theme_font_size_override("font_size", int(22.0 * s))
	var label := settings_panel.get_node_or_null("VolumeLabel") as Label
	if label != null:
		label.position = Vector2(24.0 * s, 70.0 * s)
		label.size = Vector2(220.0 * s, 28.0 * s)
		label.add_theme_font_size_override("font_size", int(15.0 * s))
	volume_slider.position = Vector2(24.0 * s, 106.0 * s)
	volume_slider.size = Vector2(spw - 48.0 * s, 32.0 * s)
	volume_value.position = Vector2(24.0 * s, 146.0 * s)
	volume_value.size = Vector2(120.0 * s, 24.0 * s)
	volume_value.add_theme_font_size_override("font_size", int(14.0 * s))
	settings_close.position = Vector2(24.0 * s, sph - 50.0 * s)
	settings_close.size = Vector2(132.0 * s, 38.0 * s)
	settings_close.add_theme_font_size_override("font_size", int(16.0 * s))


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		_volume = clampf(float(cfg.get_value("audio", "volume", 80.0)), 0.0, 100.0)
	volume_slider.set_value_no_signal(_volume)
	_apply_volume()


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", _volume)
	cfg.save(SETTINGS_PATH)


func _apply_volume() -> void:
	if _volume <= 0.5:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, linear_to_db(_volume / 100.0))
	volume_value.text = "%d%%" % int(round(_volume))


func _on_volume_changed(value: float) -> void:
	_volume = value
	_apply_volume()


func _on_settings_pressed() -> void:
	settings_overlay.visible = true
	volume_slider.grab_focus()


func _on_settings_close() -> void:
	settings_overlay.visible = false
	_save_settings()


func _on_start_pressed() -> void:
	GameState.reset()
	SceneTransition.change_scene("res://scenes/prologue/prologue_demo.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
