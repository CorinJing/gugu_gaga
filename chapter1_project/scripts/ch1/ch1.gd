extends Control

## 第一章：大堂 → 前台登记 → 取钢笔 → 签名 → 服务生交钥匙 → 左侧门 → 走廊。
## 走廊之后的房间、白鹭夫人和缝纫内容已移除。

enum State { LOBBY, FRONT_DESK, REGISTER, STAIRS, HALL, ROOM }

const LOBBY_BG := preload("res://assets/art/backgrounds/ch1_lobby.png")
const REGISTER_BG := preload("res://assets/art/backgrounds/ch1_register.png")
const REGISTER_NO_PEN_BG := preload("res://assets/art/backgrounds/ch1_register_no_pen.png")
const HALL_BG := preload("res://assets/art/backgrounds/ch1_hall.png")
const STAIRS_BG := preload("res://assets/art/backgrounds/ch1_stairs.png")
const DOLL_SIT := preload("res://assets/art/ui/doll_sitting.png")
const ROOM_BG := preload("res://assets/art/backgrounds/ch1_113.png")
const EGRET := preload("res://assets/art/characters/egret_seated.png")
const DOOR_GLOW := preload("res://assets/art/ui/door_glow.png")
const WAITER := preload("res://assets/art/characters/waiter_cutout.png")
const VOICE_WELCOME := preload("res://assets/audio/npc/waiter_01_welcome.mp3")
const VOICE_REGISTER := preload("res://assets/audio/npc/waiter_02_register.mp3")
const VOICE_KEY := preload("res://assets/audio/npc/waiter_03_key.mp3")

@onready var hud: Control = $GameHUD
@onready var stage: Control = $Stage
@onready var backdrop: TextureRect = $Backdrop
@onready var background: TextureRect = %Background
@onready var character: TextureRect = %Character
@onready var waiter_hotspot: Control = %WaiterHotspot
@onready var desk_hotspot: Control = %DeskHotspot
@onready var pen_hotspot: Control = %PenHotspot
@onready var book_hotspot: Control = %BookHotspot
@onready var tray_hotspot: Control = %TrayHotspot
@onready var left_door_hotspot: Control = %LeftDoorHotspot
@onready var glowing_door_hotspot: Control = %GlowingDoorHotspot
@onready var door_glow: TextureRect = %DoorGlow
@onready var room_back: Button = %RoomBack
@onready var hall_back: Button = %HallBack
@onready var stairs_hotspot: Control = %StairsHotspot
@onready var doll_sitting: TextureRect = %DollSitting
@onready var doll_hotspot: Control = %DollHotspot
@onready var stairs_back: Button = %StairsBack
@onready var desk_view_back: Button = %BackButton
@onready var register_back: Button = %RegisterBack
@onready var checkin_panel: Control = %CheckInPanel
@onready var checkin_paper: ColorRect = %Paper
@onready var checkin_title: Label = %Title
@onready var checkin_body: Label = %Body
@onready var sign_name: Label = %SignName
@onready var signature_line: ColorRect = %SignatureLine
@onready var signature_pad: Control = %SignaturePad
@onready var checkin_back: Button = %CheckInBack
@onready var voice: AudioStreamPlayer = $Voice

var state: State = State.LOBBY
var _speech_gen := 0

func _ready() -> void:
	GameState.reset()
	waiter_hotspot.gui_input.connect(_on_waiter_input)
	desk_hotspot.gui_input.connect(_on_desk_input)
	pen_hotspot.gui_input.connect(_on_pen_input)
	book_hotspot.gui_input.connect(_on_book_input)
	tray_hotspot.gui_input.connect(_on_tray_input)
	left_door_hotspot.gui_input.connect(_on_left_door_input)
	glowing_door_hotspot.gui_input.connect(_on_glowing_door_input)
	room_back.pressed.connect(_on_room_back)
	hall_back.pressed.connect(_on_hall_back)
	stairs_hotspot.gui_input.connect(_on_stairs_input)
	doll_hotspot.gui_input.connect(_on_doll_input)
	stairs_back.pressed.connect(_on_stairs_back)
	doll_sitting.texture = DOLL_SIT
	door_glow.texture = DOOR_GLOW
	desk_view_back.pressed.connect(_on_desk_view_back)
	register_back.pressed.connect(_on_register_back)
	checkin_back.pressed.connect(_on_checkin_back)
	hud.drag_released.connect(_on_item_dropped)
	hud.drag_moved.connect(_on_drag_moved)
	hud.set_location_visible(false)
	get_viewport().size_changed.connect(_layout)
	_set_state(State.LOBBY)

func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed

func _transition_to(next: State) -> void:
	await SceneTransition.transition(func() -> void: _set_state(next))

func _say(text: String, anchor: Control, seconds: float = 3.0) -> void:
	hud.show_speech(text, anchor.get_global_rect())
	_speech_gen += 1
	var gen := _speech_gen
	await get_tree().create_timer(seconds).timeout
	if gen == _speech_gen and is_instance_valid(hud):
		hud.hide_speech()

func _play_voice(stream: AudioStream) -> void:
	if voice == null:
		return
	voice.stop()
	voice.stream = stream
	voice.play()

func _set_state(next: State) -> void:
	state = next
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_speech_gen += 1
	hud.hide_speech()
	character.visible = false
	waiter_hotspot.visible = false
	desk_hotspot.visible = false
	pen_hotspot.visible = false
	book_hotspot.visible = false
	tray_hotspot.visible = false
	left_door_hotspot.visible = false
	glowing_door_hotspot.visible = false
	door_glow.visible = false
	room_back.visible = false
	hall_back.visible = false
	stairs_hotspot.visible = false
	doll_sitting.visible = false
	doll_hotspot.visible = false
	stairs_back.visible = false
	desk_view_back.visible = false
	register_back.visible = false
	checkin_panel.visible = false
	hud.visible = true

	match state:
		State.LOBBY:
			background.texture = LOBBY_BG
			var waiter_gone: bool = GameState.has_flag("waiter_gone")
			character.texture = WAITER
			character.visible = not waiter_gone
			character.modulate = Color(0.82, 0.85, 0.82, 1.0)
			character.position = Vector2(390.0, 220.0)
			character.size = Vector2(150.0, 460.0)
			waiter_hotspot.visible = not waiter_gone
			desk_hotspot.visible = GameState.has_flag("waiter_second_line")
			left_door_hotspot.visible = true
			stairs_hotspot.visible = true
			tray_hotspot.visible = not waiter_gone and GameState.has_flag("key_dialogue_done") and not GameState.has_item("corridor_key")
			hud.set_prompt("前台站着一位服务生。" if not waiter_gone else "前台没有人。")
		State.FRONT_DESK:
			background.texture = REGISTER_NO_PEN_BG if GameState.has_flag("pen_taken") else REGISTER_BG
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			desk_view_back.visible = true
			pen_hotspot.visible = not GameState.has_flag("pen_taken")
			book_hotspot.visible = true
			hud.set_location_visible(false)
			hud.hide_action()
		State.REGISTER:
			background.texture = REGISTER_BG
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			register_back.visible = true
			hud.set_location_visible(false)
			hud.hide_action()
		State.STAIRS:
			background.texture = STAIRS_BG
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			stairs_back.visible = true
			if not GameState.has_flag("doll_taken"):
				doll_sitting.visible = true
				doll_hotspot.visible = true
			hud.set_location_visible(false)
			hud.hide_action()
		State.HALL:
			background.texture = HALL_BG
			glowing_door_hotspot.visible = true
			door_glow.visible = true
			hall_back.visible = true
			hud.set_location_visible(false)
			hud.hide_action()
		State.ROOM:
			background.texture = ROOM_BG
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			character.texture = EGRET
			character.visible = true
			character.position = Vector2(548.0, 273.0)
			character.size = Vector2(172.0, 464.0)
			room_back.visible = true
			hud.set_location_visible(false)
			hud.hide_action()
	_layout()

func _layout() -> void:
	var vp := get_viewport_rect().size
	if vp.x <= 1.0 or vp.y <= 1.0:
		return
	var column_w: float = clampf((vp.y - 40.0) * (381.0 / 1514.0), 170.0, 240.0)
	var area := Rect2(0.0, 0.0, vp.x - column_w, vp.y)
	var cover_scale: float = maxf(area.size.x / 960.0, area.size.y / 720.0)
	var stage_size := Vector2(960.0, 720.0) * cover_scale
	var stage_pos := area.position + (area.size - stage_size) * 0.5
	stage.position = stage_pos
	stage.scale = Vector2(cover_scale, cover_scale)
	backdrop.position = Vector2.ZERO
	backdrop.size = vp
	backdrop.texture = background.texture
	backdrop.modulate = Color(0.22, 0.22, 0.22, 1.0)
	hud.apply_layout(Rect2(stage_pos, stage_size), vp, Rect2())
	room_back.position = Vector2(vp.x * 0.5 - 50.0, vp.y - 64.0)
	room_back.size = Vector2(100.0, 40.0)
	hall_back.position = Vector2(vp.x * 0.5 - 50.0, vp.y - 64.0)
	hall_back.size = Vector2(100.0, 40.0)
	if checkin_panel.visible:
		_layout_checkin()

func _on_waiter_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.LOBBY:
		return
	if GameState.has_flag("signed"):
		_play_voice(VOICE_KEY)
		await _say("这是走廊的钥匙，请收好", waiter_hotspot, 4.5)
		GameState.set_flag("key_dialogue_done")
		if state == State.LOBBY:
			tray_hotspot.visible = not GameState.has_item("corridor_key")
		return
	if not GameState.has_flag("waiter_greeted"):
		GameState.set_flag("waiter_greeted")
		_play_voice(VOICE_WELCOME)
		_say("欢迎来到盐月旅馆，远道而来的客人", waiter_hotspot, 4.5)
		return
	if not GameState.has_flag("waiter_second_line"):
		GameState.set_flag("waiter_second_line")
		desk_hotspot.visible = true
		_play_voice(VOICE_REGISTER)
		_say("您可以在旁边的前台进行登记入住", waiter_hotspot, 4.5)
		return
	_play_voice(VOICE_REGISTER)
	_say("您可以在旁边的前台进行登记入住", waiter_hotspot, 4.5)

func _on_desk_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.LOBBY:
		return
	if not GameState.has_flag("waiter_second_line"):
		hud.set_prompt("先听服务生说完。")
		return
	_transition_to(State.FRONT_DESK)

func _on_desk_view_back() -> void:
	if state == State.FRONT_DESK:
		_transition_to(State.LOBBY)

func _on_register_back() -> void:
	if state == State.REGISTER:
		_transition_to(State.LOBBY)

func _on_pen_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.FRONT_DESK:
		return
	if GameState.has_flag("pen_taken"):
		return
	GameState.set_flag("pen_taken")
	GameState.add_item("pen")
	pen_hotspot.visible = false
	await SceneTransition.transition(func() -> void: background.texture = REGISTER_NO_PEN_BG, 0.18, 0.22)
	hud.set_prompt("你拿起了桌上的钢笔。")

func _on_book_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.FRONT_DESK:
		return
	signature_pad.clear_ink()
	checkin_panel.visible = true
	_layout_checkin()
	hud.set_prompt("入住须知摊开在前台桌上。")

func _on_checkin_back() -> void:
	checkin_panel.visible = false

func _on_tray_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.LOBBY:
		return
	if not GameState.has_flag("key_dialogue_done") or GameState.has_item("corridor_key"):
		return
	GameState.add_item("corridor_key")
	tray_hotspot.visible = false
	hud.set_prompt("你从托盘上拿到了走廊钥匙。")

func _on_glowing_door_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.HALL:
		return
	_transition_to(State.ROOM)


func _on_stairs_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.LOBBY:
		return
	_transition_to(State.STAIRS)


func _on_stairs_back() -> void:
	if state == State.STAIRS:
		_transition_to(State.LOBBY)


func _on_doll_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.STAIRS:
		return
	if GameState.has_flag("doll_taken"):
		return
	GameState.set_flag("doll_taken")
	GameState.add_item("doll")
	doll_sitting.visible = false
	doll_hotspot.visible = false
	hud.set_prompt("你拿到了楼梯上的布偶。")


func _on_room_back() -> void:
	if state == State.ROOM:
		_transition_to(State.HALL)


func _on_hall_back() -> void:
	if state != State.HALL:
		return
	GameState.set_flag("waiter_gone")
	_transition_to(State.LOBBY)


func _on_left_door_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.LOBBY:
		return
	if not GameState.has_item("corridor_key"):
		hud.set_prompt("左侧的门锁着。")
		return
	GameState.remove_item("corridor_key")
	_transition_to(State.HALL)

func _on_drag_moved(item_id: String, screen_pos: Vector2) -> void:
	if not checkin_panel.visible or item_id != "pen":
		return
	if not signature_pad.get_global_rect().has_point(screen_pos):
		return
	signature_pad.add_point(screen_pos)

func _finish_signature() -> void:
	if not signature_pad.has_ink():
		hud.set_prompt("请拖动钢笔，在下方签名。")
		return
	GameState.remove_item("pen")
	GameState.set_flag("signed")
	GameState.set_flag("registered")
	checkin_panel.visible = false
	await _transition_to(State.LOBBY)

func _layout_checkin() -> void:
	var vp := get_viewport_rect().size
	if vp.x <= 1.0 or vp.y <= 1.0:
		return
	var panel_w: float = vp.x * 0.5
	var s: float = clampf(vp.y / 720.0, 0.8, 1.25)
	checkin_panel.position = Vector2.ZERO
	checkin_panel.size = vp
	checkin_paper.position = Vector2.ZERO
	checkin_paper.size = Vector2(panel_w, vp.y)
	checkin_title.position = Vector2(24.0, 22.0)
	checkin_title.size = Vector2(panel_w - 48.0, 48.0 * s)
	checkin_title.add_theme_font_size_override("font_size", int(48.0 * s))
	checkin_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	checkin_body.position = Vector2(24.0, 80.0)
	checkin_body.size = Vector2(panel_w - 48.0, maxf(260.0, vp.y - 220.0))
	checkin_body.add_theme_font_size_override("font_size", int(30.0 * s))
	var line_y: float = vp.y - 95.0
	sign_name.position = Vector2(24.0, line_y - 30.0)
	sign_name.size = Vector2(100.0, 44.0)
	sign_name.add_theme_font_size_override("font_size", int(30.0 * s))
	signature_line.position = Vector2(112.0, line_y)
	signature_line.size = Vector2(panel_w - 140.0, 3.0)
	signature_pad.position = Vector2(100.0, line_y - 140.0)
	signature_pad.size = Vector2(panel_w - 124.0, 240.0)
	checkin_back.position = Vector2(24.0, vp.y - 54.0)
	checkin_back.size = Vector2(100.0, 40.0)

func _on_item_dropped(item_id: String, _slot_index: int, screen_pos: Vector2) -> void:
	if state == State.LOBBY and item_id == "corridor_key" and left_door_hotspot.get_global_rect().has_point(screen_pos):
		GameState.remove_item("corridor_key")
		_transition_to(State.HALL)
		return
	if checkin_panel.visible and item_id == "pen":
		if signature_pad.has_ink():
			_finish_signature()
		else:
			hud.set_prompt("请拖动钢笔，在下方签名。")
		return
	hud.set_prompt("这里用不了这个东西。")
