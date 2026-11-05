extends Node

## 全局音频总管：音乐 / 底噪 / 音效，跨场景不中断。
## 由 autoload 加载，顺序在 SettingsMenu 之前，保证三条 bus 在设置面板读档前就建好。
##
## 注意：这里一律用 load() 延迟取流，不用 preload。
## 新加的 wav 在首次导入前没有 .import，autoload 里 preload 会让编辑器启动阶段直接报
## “no resource loaders”，连资源扫描都进不去；延迟加载可以等导入完成后再取。

signal mood_changed(music_id: String, ambience_id: String)

const MUSIC_PATHS := {
	"title": "res://assets/audio/music/mus_title_theme_v01.wav",
	"cabin_warm": "res://assets/audio/music/mus_cabin_warm_v01.wav",
	"boat_drift": "res://assets/audio/music/mus_boat_drift_v01.wav",
	"dock_dusk": "res://assets/audio/music/mus_dock_dusk_v01.wav",
	"hotel_night": "res://assets/audio/music/mus_hotel_night_v01.wav",
	"end_card": "res://assets/audio/music/mus_end_card_v01.wav",
}

const AMBIENCE_PATHS := {
	"cabin_closed": "res://assets/audio/ambience/amb_cabin_closed_v01.wav",
	"cabin_open": "res://assets/audio/ambience/amb_cabin_open_v01.wav",
	"interior": "res://assets/audio/ambience/amb_interior_v01.wav",
	"boat_moving": "res://assets/audio/ambience/amb_boat_moving_v01.wav",
	"dock_dusk": "res://assets/audio/ambience/amb_dock_dusk_v01.wav",
	"hotel_night": "res://assets/audio/ambience/amb_hotel_night_v01.wav",
	"mailbox": "res://assets/audio/ambience/amb_mailbox_v01.wav",
}

const SFX_PATHS := {
	"beak_open": "res://assets/audio/sfx/sfx_beak_open_v01.wav",
	"cloth_shift": "res://assets/audio/sfx/sfx_cloth_shift_v01.wav",
	"coin_drop": "res://assets/audio/sfx/sfx_coin_drop_v01.wav",
	"coin_palm": "res://assets/audio/sfx/sfx_coin_palm_v01.wav",
	"coin_pickup": "res://assets/audio/sfx/sfx_coin_pickup_v01.wav",
	"dock_step": "res://assets/audio/sfx/sfx_dock_step_v01.wav",
	"door_cabin": "res://assets/audio/sfx/sfx_door_cabin_v01.wav",
	"fish_take": "res://assets/audio/sfx/sfx_fish_take_v01.wav",
	"heron_sewn": "res://assets/audio/sfx/sfx_heron_sewn_v01.wav",
	"heron_swallow": "res://assets/audio/sfx/sfx_heron_swallow_v01.wav",
	"hotel_arrive": "res://assets/audio/sfx/sfx_hotel_arrive_v01.wav",
	"hotel_door": "res://assets/audio/sfx/sfx_hotel_door_v01.wav",
	"key_appear": "res://assets/audio/sfx/sfx_key_appear_v01.wav",
	"key_insert": "res://assets/audio/sfx/sfx_key_insert_v01.wav",
	"knife_take": "res://assets/audio/sfx/sfx_knife_take_v01.wav",
	"letter_insert": "res://assets/audio/sfx/sfx_letter_insert_v01.wav",
	"letter_take": "res://assets/audio/sfx/sfx_letter_take_v01.wav",
	"mailbox_close": "res://assets/audio/sfx/sfx_mailbox_close_v01.wav",
	"mailbox_open": "res://assets/audio/sfx/sfx_mailbox_open_v01.wav",
	"nightstand_touch": "res://assets/audio/sfx/sfx_nightstand_touch_v01.wav",
	"suitcase_open": "res://assets/audio/sfx/sfx_suitcase_open_v01.wav",
	"thread_cut": "res://assets/audio/sfx/sfx_thread_cut_v01.wav",
	"window_latch": "res://assets/audio/sfx/sfx_window_latch_v01.wav",
	"window_open": "res://assets/audio/sfx/sfx_window_open_v01.wav",
}

const UI_PATHS := {
	"click": "res://assets/audio/ui/ui_click_v01.wav",
	"drag_pick": "res://assets/audio/ui/ui_drag_pick_v01.wav",
	"drop_fail": "res://assets/audio/ui/ui_drop_fail_v01.wav",
	"drop_ok": "res://assets/audio/ui/ui_drop_ok_v01.wav",
	"item_gain": "res://assets/audio/ui/ui_item_gain_v01.wav",
	"note_close": "res://assets/audio/ui/ui_note_close_v01.wav",
	"note_open": "res://assets/audio/ui/ui_note_open_v01.wav",
	"speech_pop": "res://assets/audio/ui/ui_speech_pop_v01.wav",
}

const STING_PATHS := {
	"logo": "res://assets/audio/sting/sting_logo_v01.wav",
}

const SFX_POOL_SIZE := 8
const UI_POOL_SIZE := 2
const MUSIC_BUS_DB := -12.0
const AMBIENCE_BUS_DB := -14.0
const SFX_BUS_DB := -6.0

var _music_players: Array[AudioStreamPlayer] = []
var _ambience_players: Array[AudioStreamPlayer] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _music_index := 0
var _ambience_index := 0
var _sfx_cursor := 0
var _ui_cursor := 0

var _current_music := ""
var _current_ambience := ""
var _sting_player: AudioStreamPlayer
var _duck_tween: Tween
var _cache: Dictionary = {}


func _enter_tree() -> void:
	_ensure_bus("Music", MUSIC_BUS_DB)
	_ensure_bus("Ambience", AMBIENCE_BUS_DB)
	_ensure_bus("SFX", SFX_BUS_DB)

	for i in 2:
		var p := _make_player("Music")
		p.volume_db = -40.0
		_music_players.append(p)
	for i in 2:
		var p := _make_player("Ambience")
		p.volume_db = -40.0
		_ambience_players.append(p)
	for i in SFX_POOL_SIZE:
		_sfx_players.append(_make_player("SFX"))
	for i in UI_POOL_SIZE:
		_ui_players.append(_make_player("SFX"))
	_sting_player = _make_player("SFX")


func _make_player(bus_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus_name
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	return p


func _ensure_bus(bus_name: String, volume_db: float) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_volume_db(idx, volume_db)


func _stream(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		return null
	var s := load(path) as AudioStream
	if s != null:
		_cache[path] = s
	return s


func _looped(stream: AudioStream) -> AudioStream:
	var wav := stream as AudioStreamWAV
	if wav != null and wav.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * float(wav.mix_rate))
	return stream


## 一次性设置当前场景的音乐和底噪；同一首不会重播。
func set_scene(music_id: String, ambience_id: String, music_fade: float = 0.3, ambience_fade: float = 0.8) -> void:
	set_music(music_id, music_fade)
	set_ambience(ambience_id, ambience_fade)
	mood_changed.emit(music_id, ambience_id)


func set_music(music_id: String, fade: float = 0.3) -> void:
	if music_id == _current_music:
		return
	_current_music = music_id
	var old := _music_players[_music_index]
	var next := _music_players[1 - _music_index]
	_music_index = 1 - _music_index
	_fade_out(old, fade)
	if music_id.is_empty() or not MUSIC_PATHS.has(music_id):
		return
	var stream := _stream(MUSIC_PATHS[music_id])
	if stream == null:
		return
	next.stream = _looped(stream)
	next.volume_db = -40.0
	next.play()
	_fade_in(next, fade)


func set_ambience(ambience_id: String, fade: float = 0.8) -> void:
	if ambience_id == _current_ambience:
		return
	_current_ambience = ambience_id
	var old := _ambience_players[_ambience_index]
	var next := _ambience_players[1 - _ambience_index]
	_ambience_index = 1 - _ambience_index
	_fade_out(old, fade)
	if ambience_id.is_empty() or not AMBIENCE_PATHS.has(ambience_id):
		return
	var stream := _stream(AMBIENCE_PATHS[ambience_id])
	if stream == null:
		return
	next.stream = _looped(stream)
	next.volume_db = -40.0
	next.play()
	_fade_in(next, fade)


func stop_all(fade: float = 0.6) -> void:
	_current_music = ""
	_current_ambience = ""
	for p in _music_players:
		_fade_out(p, fade)
	for p in _ambience_players:
		_fade_out(p, fade)


func _fade_out(player: AudioStreamPlayer, seconds: float) -> void:
	if not player.playing:
		return
	var stream_at_call := player.stream
	var tw := create_tween()
	tw.tween_property(player, "volume_db", -40.0, maxf(seconds, 0.01))
	tw.tween_callback(func() -> void:
		if player.stream == stream_at_call:
			player.stop())


func _fade_in(player: AudioStreamPlayer, seconds: float) -> void:
	var tw := create_tween()
	tw.tween_property(player, "volume_db", 0.0, maxf(seconds, 0.01))


func sfx(id: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not SFX_PATHS.has(id):
		return
	var stream := _stream(SFX_PATHS[id])
	if stream == null:
		return
	var p := _sfx_players[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func ui(id: String, volume_db: float = -3.0) -> void:
	if not UI_PATHS.has(id):
		return
	var stream := _stream(UI_PATHS[id])
	if stream == null:
		return
	var p := _ui_players[_ui_cursor]
	_ui_cursor = (_ui_cursor + 1) % _ui_players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0
	p.play()


func sting(id: String, volume_db: float = 0.0) -> void:
	if not STING_PATHS.has(id):
		return
	var stream := _stream(STING_PATHS[id])
	if stream == null:
		return
	_sting_player.stream = stream
	_sting_player.volume_db = volume_db
	_sting_player.play()


## 对白响起时压低音乐和底噪，duration 秒后恢复。
func duck(duration: float = 1.2, music_db: float = -7.0, ambience_db: float = -5.0) -> void:
	var mi := AudioServer.get_bus_index("Music")
	var ai := AudioServer.get_bus_index("Ambience")
	if mi < 0 or ai < 0:
		return
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	AudioServer.set_bus_volume_db(mi, MUSIC_BUS_DB + music_db)
	AudioServer.set_bus_volume_db(ai, AMBIENCE_BUS_DB + ambience_db)
	_duck_tween = create_tween()
	_duck_tween.tween_interval(maxf(duration, 0.2))
	_duck_tween.tween_callback(func() -> void:
		AudioServer.set_bus_volume_db(mi, MUSIC_BUS_DB)
		AudioServer.set_bus_volume_db(ai, AMBIENCE_BUS_DB))
