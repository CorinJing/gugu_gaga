extends Control

## 第一章 · 113 号房
## 流程：大堂登记 → 上楼 → 113 → 白鹭夫人 → 找线 → 穿针 → 针线盒最下层 → 黄铜针 → 离开 → 前台空了

enum State { LOBBY, FRONT_DESK, REGISTER, HALL, ROOM, LOBBY_EMPTY, CHAPTER_END }

const LOBBY_BG := preload("res://assets/art/backgrounds/ch1_lobby.png")
const LOBBY_EMPTY_BG := preload("res://assets/art/backgrounds/ch1_lobby_empty.png")
const LOBBY_FG := preload("res://assets/art/backgrounds/ch1_lobby_fg.png")
const REGISTER_BG := preload("res://assets/art/backgrounds/ch1_register.png")
const REGISTER_NO_PEN_BG := preload("res://assets/art/backgrounds/ch1_register_no_pen.png")
const HALL_BG := preload("res://assets/art/backgrounds/ch1_hall.png")
const ROOM_BG := preload("res://assets/art/backgrounds/ch1_113.png")
const WAITER := preload("res://assets/art/characters/waiter_cutout.png")
const EGRET := preload("res://assets/art/characters/egret_seated_nc.png")
const VOICE_WELCOME := preload("res://assets/audio/npc/waiter_01_welcome.mp3")
const VOICE_REGISTER := preload("res://assets/audio/npc/waiter_02_register.mp3")

@onready var hud: Control = $GameHUD
@onready var stage: Control = $Stage
@onready var backdrop: TextureRect = $Backdrop
@onready var background: TextureRect = %Background
@onready var character: TextureRect = %Character
@onready var desk_fg: TextureRect = %DeskForeground
@onready var waiter_hotspot: Control = %WaiterHotspot
@onready var desk_hotspot: Control = %DeskHotspot
@onready var stairs_hotspot: Control = %StairsHotspot
@onready var door113_hotspot: Control = %Door113Hotspot
@onready var egret_hotspot: Control = %EgretHotspot
@onready var machine_hotspot: Control = %MachineHotspot
@onready var box_hotspot: Control = %BoxHotspot
@onready var room_door_hotspot: Control = %RoomDoorHotspot
@onready var leave_hotspot: Control = %LeaveHotspot
@onready var voice: AudioStreamPlayer = $Voice
@onready var desk_view: Control = %DeskView
@onready var desk_view_back: Button = %BackButton
@onready var register_back: Button = %RegisterBack
@onready var pen_hotspot: Control = %PenHotspot
@onready var book_hotspot: Control = %BookHotspot
@onready var checkin_panel: Control = %CheckInPanel
@onready var checkin_paper: ColorRect = %Paper
@onready var checkin_title: Label = %Title
@onready var checkin_body: Label = %Body
@onready var sign_name: Label = %SignName
@onready var signature_line: ColorRect = %SignatureLine
@onready var signature_pad: Control = %SignaturePad
@onready var checkin_back: Button = %CheckInBack

var state: State = State.LOBBY
var _speech_gen := 0
var card: Control
var card_back: Button


func _ready() -> void:
	GameState.reset()
	waiter_hotspot.gui_input.connect(_on_waiter_input)
	desk_hotspot.gui_input.connect(_on_desk_input)
	desk_view_back.pressed.connect(_on_desk_view_back)
	register_back.pressed.connect(_on_register_back)
	pen_hotspot.gui_input.connect(_on_pen_input)
	book_hotspot.gui_input.connect(_on_book_input)
	checkin_back.pressed.connect(_on_checkin_back)
	hud.drag_moved.connect(_on_drag_moved)
	stairs_hotspot.gui_input.connect(_on_stairs_input)
	door113_hotspot.gui_input.connect(_on_door113_input)
	egret_hotspot.gui_input.connect(_on_egret_input)
	machine_hotspot.gui_input.connect(_on_machine_input)
	box_hotspot.gui_input.connect(_on_box_input)
	room_door_hotspot.gui_input.connect(_on_room_door_input)
	leave_hotspot.gui_input.connect(_on_leave_input)
	hud.drag_released.connect(_on_item_dropped)
	hud.set_location_visible(false)
	_build_card()
	get_viewport().size_changed.connect(_layout)
	_set_state(State.LOBBY)


func _build_card() -> void:
	card = Control.new()
	card.visible = false
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.z_index = 400
	add_child(card)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.028, 0.025, 1.0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.name = "Dim"
	card.add_child(dim)

	var title := Label.new()
	title.name = "Title"
	title.text = "第一章 · 完"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.91, 0.87, 0.78))
	title.add_theme_font_size_override("font_size", 46)
	card.add_child(title)

	var sub := Label.new()
	sub.name = "Sub"
	sub.text = "前台没有人了。\n113 号的灯还亮着。"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.69, 0.63, 0.52))
	sub.add_theme_font_size_override("font_size", 18)
	card.add_child(sub)

	card_back = Button.new()
	card_back.name = "BackButton"
	card_back.text = "回到标题"
	card_back.flat = true
	card_back.focus_mode = Control.FOCUS_NONE
	card_back.add_theme_color_override("font_color", Color(0.88, 0.84, 0.75))
	card_back.add_theme_color_override("font_hover_color", Color(1, 0.94, 0.83))
	card_back.add_theme_font_size_override("font_size", 17)
	card_back.pressed.connect(_on_card_back)
	card.add_child(card_back)


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


func _set_state(next: State) -> void:
	state = next
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_speech_gen += 1
	hud.hide_speech()
	character.visible = false
	desk_fg.visible = false
	waiter_hotspot.visible = false
	desk_hotspot.visible = false
	stairs_hotspot.visible = false
	door113_hotspot.visible = false
	egret_hotspot.visible = false
	machine_hotspot.visible = false
	box_hotspot.visible = false
	room_door_hotspot.visible = false
	leave_hotspot.visible = false
	desk_view.visible = false
	desk_view_back.visible = false
	register_back.visible = false
	pen_hotspot.visible = false
	book_hotspot.visible = false
	checkin_panel.visible = false
	card.visible = false
	hud.visible = true

	match state:
		State.LOBBY:
			background.texture = LOBBY_BG
			character.texture = WAITER
			character.visible = true
			character.modulate = Color(0.82, 0.85, 0.82, 1.0)
			# Keep the waiter fully visible and standing on the central red carpet.
			character.position = Vector2(390.0, 220.0)
			character.size = Vector2(150.0, 460.0)
			desk_fg.visible = false
			waiter_hotspot.visible = true
			stairs_hotspot.visible = GameState.has_flag("registered")
			var waiter_ready: bool = GameState.has_flag("waiter_second_line")
			desk_hotspot.visible = waiter_ready
			hud.set_prompt("前台站着一位服务生。")
		State.FRONT_DESK:
			background.texture = REGISTER_NO_PEN_BG if GameState.has_flag("pen_taken") else REGISTER_BG
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			desk_view.visible = false
			desk_view_back.visible = true
			pen_hotspot.visible = true
			book_hotspot.visible = true
			hud.set_location_visible(false)
			hud.hide_action()
		State.REGISTER:
			background.texture = REGISTER_BG
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			register_back.visible = true
			hud.set_location_visible(false)
			hud.hide_action()
		State.HALL:
			background.texture = HALL_BG
			door113_hotspot.visible = true
			hud.set_prompt("二楼走廊。113 号房在右边。")
		State.ROOM:
			background.texture = ROOM_BG
			character.texture = EGRET
			character.visible = true
			character.position = Vector2(578.0, 311.0)
			character.size = Vector2(144.0, 388.0)
			egret_hotspot.visible = true
			machine_hotspot.visible = true
			box_hotspot.visible = true
			room_door_hotspot.visible = true
			hud.set_prompt(_room_prompt())
		State.LOBBY_EMPTY:
			background.texture = LOBBY_BG
			desk_fg.texture = LOBBY_FG
			desk_fg.visible = true
			leave_hotspot.visible = true
			hud.set_prompt("前台没有人。登记簿还摊在那里。")
		State.CHAPTER_END:
			background.texture = LOBBY_EMPTY_BG
			desk_fg.visible = true
			hud.visible = false
			card.visible = true
	_layout()


func _room_prompt() -> String:
	if GameState.has_item("brass_needle"):
		return "该走了。"
	if GameState.has_flag("thread_done"):
		return "她说：最下面那层。有件东西是你的。"
	if GameState.has_item("thread"):
		return "把线拖到针上。"
	return "白鹭夫人在缝一件很小的蓝色外套。"


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

	if card != null:
		card.position = Vector2.ZERO
		card.size = vp
		var dim := card.get_node_or_null("Dim")
		if dim != null:
			dim.position = Vector2.ZERO
			dim.size = vp
		var title := card.get_node_or_null("Title") as Label
		if title != null:
			title.position = Vector2(0.0, vp.y * 0.30)
			title.size = Vector2(vp.x, 70.0)
		var sub := card.get_node_or_null("Sub") as Label
		if sub != null:
			sub.position = Vector2(0.0, vp.y * 0.30 + 84.0)
			sub.size = Vector2(vp.x, 70.0)
		card_back.position = Vector2(vp.x * 0.5 - 90.0, vp.y * 0.62)
		card_back.size = Vector2(180.0, 40.0)


# ---------------------------------------------------------------- 大堂
func _on_waiter_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.LOBBY:
		return
	if not GameState.has_flag("waiter_greeted"):
		GameState.set_flag("waiter_greeted")
		hud.set_prompt("服务生向你问候。")
		_play_voice(VOICE_WELCOME)
		_say("欢迎来到盐月旅馆，远道而来的客人", waiter_hotspot, 4.5)
		return
	GameState.set_flag("waiter_second_line")
	desk_hotspot.visible = true
	hud.set_prompt("服务生示意你到前台登记。")
	_play_voice(VOICE_REGISTER)
	_say("您可以在旁边的前台进行登记入住", waiter_hotspot, 4.5)


func _play_voice(stream: AudioStream) -> void:
	if voice == null:
		return
	voice.stop()
	voice.stream = stream
	voice.play()


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
	stairs_hotspot.visible = true
	hud.set_prompt("签名完成。")


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
	checkin_title.add_theme_font_size_override("font_size", int(30.0 * s))
	checkin_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	checkin_body.position = Vector2(24.0, 80.0)
	checkin_body.size = Vector2(panel_w - 48.0, maxf(190.0, vp.y - 350.0))
	checkin_body.add_theme_font_size_override("font_size", int(20.0 * s))
	var line_y: float = vp.y - 155.0
	sign_name.position = Vector2(24.0, line_y - 28.0)
	sign_name.size = Vector2(100.0, 34.0)
	sign_name.add_theme_font_size_override("font_size", int(20.0 * s))
	signature_line.position = Vector2(112.0, line_y)
	signature_line.size = Vector2(panel_w - 140.0, 2.0)
	# Large invisible signing area centred on the underline.
	signature_pad.position = Vector2(100.0, line_y - 52.0)
	signature_pad.size = Vector2(panel_w - 124.0, 74.0)
	checkin_back.position = Vector2(24.0, vp.y - 54.0)
	checkin_back.size = Vector2(100.0, 40.0)


func _on_desk_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.LOBBY:
		return
	if not GameState.has_flag("waiter_second_line"):
		hud.set_prompt("先听服务生说完。")
		return
	# Enter the front-desk close-up; do not grant an item.
	_transition_to(State.FRONT_DESK)


func _on_desk_view_back() -> void:
	if state == State.FRONT_DESK:
		_transition_to(State.LOBBY)


func _on_register_back() -> void:
	if state == State.REGISTER:
		_transition_to(State.LOBBY)


func _on_stairs_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.LOBBY:
		return
	if not GameState.has_flag("registered"):
		hud.set_prompt("先在前台登记。")
		return
	_transition_to(State.HALL)


# ---------------------------------------------------------------- 走廊
func _on_door113_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.HALL:
		return
	_transition_to(State.ROOM)


# ---------------------------------------------------------------- 113
func _on_egret_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.ROOM:
		return
	if GameState.has_item("brass_needle"):
		_say("最下面那层，你已经拿过了。", egret_hotspot)
	elif GameState.has_flag("thread_done"):
		_say("你母亲以前也穿过这根线。", egret_hotspot, 3.4)
	elif GameState.has_item("thread"):
		_say("帮我穿过去。", egret_hotspot)
	else:
		_say("线断了。", egret_hotspot)


func _on_machine_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.ROOM:
		return
	if GameState.has_flag("thread_done"):
		hud.set_prompt("针已经穿好了，线垂在布上。")
	elif GameState.has_item("thread"):
		hud.set_prompt("把线拖到针上。")
	else:
		hud.set_prompt("机头上插着一根针，针眼空着。")


func _on_box_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.ROOM:
		return
	if not GameState.has_flag("box_open"):
		GameState.set_flag("box_open")
		GameState.add_item("thread")
		hud.set_prompt("针线盒里有半卷红线。")
		_say("线在盒子里。", egret_hotspot)
		return
	if GameState.has_item("brass_needle"):
		hud.set_prompt("盒子空了。")
		return
	if not GameState.has_flag("thread_done"):
		hud.set_prompt("线已经在你手上了。")
		return
	GameState.add_item("brass_needle")
	hud.set_prompt("针线盒最下层有一枚黄铜针，针鼻上刻着 1。")
	_say("针鼻上刻着一个 1。", egret_hotspot, 3.4)


func _on_room_door_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.ROOM:
		return
	if not GameState.has_item("brass_needle"):
		hud.set_prompt("还没拿到东西。")
		return
	_transition_to(State.LOBBY_EMPTY)


func _on_item_dropped(item_id: String, _slot_index: int, screen_pos: Vector2) -> void:
	if checkin_panel.visible and item_id == "pen":
		if signature_pad.has_ink():
			_finish_signature()
		else:
			hud.set_prompt("请拖动钢笔，在下方签名。")
		return
	if state == State.ROOM and item_id == "thread" and machine_hotspot.get_global_rect().has_point(screen_pos):
		_thread_needle()
		return
	hud.set_prompt("这里用不了这个东西。")


func _thread_needle() -> void:
	GameState.remove_item("thread")
	GameState.set_flag("thread_done")
	hud.set_prompt("线穿过去了。白鹭夫人看着你的手。")
	_say("你母亲以前也穿过这根线。", egret_hotspot, 4.0)


# ---------------------------------------------------------------- 结束
func _on_leave_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.LOBBY_EMPTY:
		return
	_transition_to(State.CHAPTER_END)


func _on_card_back() -> void:
	GameState.reset()
	SceneTransition.change_scene("res://scenes/main.tscn")






