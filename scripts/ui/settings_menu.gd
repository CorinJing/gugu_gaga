extends CanvasLayer

## Persistent top-right settings control for the whole game.

const SETTINGS_PATH := "user://settings.cfg"

@onready var root: Control = $Root
@onready var button: Button = %SettingsButton
@onready var panel: Panel = %SettingsPanel
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SfxValue
@onready var close_button: Button = %CloseButton

var _master := 80.0
var _music := 70.0
var _sfx := 80.0


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	close_button.pressed.connect(_on_close_pressed)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	get_viewport().size_changed.connect(_layout)
	_load_settings()
	_layout()
	_apply_all()


func _layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 1.0 or vp.y <= 1.0:
		return
	root.position = Vector2.ZERO
	var s: float = clampf(minf(vp.x / 1280.0, vp.y / 720.0), 0.68, 2.2)
	button.position = Vector2(vp.x - (76.0 * s), 16.0 * s)
	button.size = Vector2(60.0, 38.0) * s
	button.add_theme_font_size_override("font_size", int(13.0 * s))
	var pw: float = minf(320.0 * s, vp.x - 32.0 * s)
	var ph: float = minf(248.0 * s, vp.y - 32.0 * s)
	panel.position = Vector2(vp.x - pw - 16.0 * s, 62.0 * s)
	panel.size = Vector2(pw, ph)
	var title := panel.get_node_or_null("Title") as Label
	if title != null:
		title.position = Vector2(20.0 * s, 14.0 * s)
		title.size = Vector2(pw - 40.0 * s, 30.0 * s)
		title.add_theme_font_size_override("font_size", int(18.0 * s))
	var labels := ["MasterLabel", "MusicLabel", "SfxLabel"]
	for i in labels.size():
		var l := panel.get_node_or_null(labels[i]) as Label
		if l != null:
			l.position = Vector2(20.0 * s, (48.0 + i * 54.0) * s)
			l.size = Vector2(110.0 * s, 22.0 * s)
			l.add_theme_font_size_override("font_size", int(13.0 * s))
	var sliders := [master_slider, music_slider, sfx_slider]
	var values := [master_value, music_value, sfx_value]
	for i in sliders.size():
		sliders[i].position = Vector2(104.0 * s, (48.0 + i * 54.0) * s)
		sliders[i].size = Vector2(pw - 178.0 * s, 24.0 * s)
		values[i].position = Vector2(pw - 62.0 * s, (48.0 + i * 54.0) * s)
		values[i].size = Vector2(48.0 * s, 22.0 * s)
		values[i].add_theme_font_size_override("font_size", int(12.0 * s))
	close_button.position = Vector2(20.0 * s, ph - 44.0 * s)
	close_button.size = Vector2(86.0 * s, 30.0 * s)
	close_button.add_theme_font_size_override("font_size", int(13.0 * s))


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		_master = clampf(float(cfg.get_value("audio", "master", cfg.get_value("audio", "volume", 80.0))), 0.0, 100.0)
		_music = clampf(float(cfg.get_value("audio", "music", 70.0)), 0.0, 100.0)
		_sfx = clampf(float(cfg.get_value("audio", "sfx", 80.0)), 0.0, 100.0)
	master_slider.set_value_no_signal(_master)
	music_slider.set_value_no_signal(_music)
	sfx_slider.set_value_no_signal(_sfx)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", _master)
	cfg.set_value("audio", "music", _music)
	cfg.set_value("audio", "sfx", _sfx)
	cfg.save(SETTINGS_PATH)


func _apply_bus(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if value <= 0.5:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(value / 100.0))


func _apply_all() -> void:
	_apply_bus("Master", _master)
	_apply_bus("Music", _music)
	_apply_bus("Ambience", _music)
	_apply_bus("SFX", _sfx)
	master_value.text = "%d%%" % int(round(_master))
	music_value.text = "%d%%" % int(round(_music))
	sfx_value.text = "%d%%" % int(round(_sfx))


func _on_button_pressed() -> void:
	panel.visible = not panel.visible
	button.text = "关闭" if panel.visible else "设置"
	if not panel.visible:
		_save_settings()


func _on_close_pressed() -> void:
	panel.visible = false
	button.text = "设置"
	_save_settings()


func _on_master_changed(value: float) -> void:
	_master = value
	_apply_all()


func _on_music_changed(value: float) -> void:
	_music = value
	_apply_all()


func _on_sfx_changed(value: float) -> void:
	_sfx = value
	_apply_all()
