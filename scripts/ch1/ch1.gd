extends Control

## 第一章 · 113 号房
## 流程：大堂登记 → 上楼 → 113 → 白鹭夫人 → 找线 → 穿针 → 针线盒最下层 → 黄铜针 → 离开 → 前台空了

enum State { LOBBY, HALL, ROOM, LOBBY_EMPTY, CHAPTER_END }

const LOBBY_BG := preload("res://assets/art/backgrounds/ch1_lobby.png")
const LOBBY_EMPTY_BG := preload("res://assets/art/backgrounds/ch1_lobby_empty.png")
const LOBBY_FG := preload("res://assets/art/backgrounds/ch1_lobby_fg.png")
const HALL_BG := preload("res://assets/art/backgrounds/ch1_hall.png")
const ROOM_BG := preload("res://assets/art/backgrounds/ch1_113.png")
const WAITER := preload("res://assets/art/characters/waiter_cutout.png")
const EGRET := preload("res://assets/art/characters/egret_seated_nc.png")

@onready var hud: Control = $GameHUD
@onready var stage: Control = $Stage
@onready var backdrop: TextureRect = $Backdrop
@onready var background: TextureRect = %Background
@onready var character: TextureRect = %Character
@onready var desk_fg: TextureRect = %DeskForeground
@onready var waiter_hotspot: Control = %WaiterHotspot
@onready var desk_hotspot: Control = %DeskHotspot
@onready var register_hotspot: Control = %RegisterHotspot
@onready var stairs_hotspot: Control = %StairsHotspot
@onready var door113_hotspot: Control = %Door113Hotspot
@onready var egret_hotspot: Control = %EgretHotspot
@onready var machine_hotspot: Control = %MachineHotspot
@onready var box_hotspot: Control = %BoxHotspot
@onready var room_door_hotspot: Control = %RoomDoorHotspot
@onready var leave_hotspot: Control = %LeaveHotspot

var state: State = State.LOBBY
var _speech_gen := 0
var card: Control
var card_back: Button


func _ready() -> void:
	GameState.reset()
	waiter_hotspot.gui_input.connect(_on_waiter_input)
	desk_hotspot.gui_input.connect(_on_desk_input)
	register_hotspot.gui_input.connect(_on_register_input)
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


func _say(text: String, anchor: Control, seconds: float = 3.0) -> void:
	hud.show_speech(text, anchor.get_global_rect())
	_speech_gen += 1
	var gen := _speech_gen
	await get_tree().create_timer(seconds).timeout
	if gen == _speech_gen and is_instance_valid(hud):
		hud.hide_speech()


func _set_state(next: State) -> void:
	state = next
	_speech_gen += 1
	hud.hide_speech()
	character.visible = false
	desk_fg.visible = false
	waiter_hotspot.visible = false
	desk_hotspot.visible = false
	register_hotspot.visible = false
	stairs_hotspot.visible = false
	door113_hotspot.visible = false
	egret_hotspot.visible = false
	machine_hotspot.visible = false
	box_hotspot.visible = false
	room_door_hotspot.visible = false
	leave_hotspot.visible = false
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
			desk_hotspot.visible = true
			register_hotspot.visible = true
			stairs_hotspot.visible = GameState.has_item("slip")
			hud.set_prompt("前台站着一位服务生。")
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
		hud.set_prompt("服务生把登记簿推到你面前。")
		_say("欢迎。请登记。", waiter_hotspot)
		return
	if not GameState.has_item("slip"):
		hud.set_prompt("登记簿在前台右侧，翻开的那本。")
		_say("请在那边的登记簿上签字。", waiter_hotspot)
		return
	_say("113 号房。她在等你。", waiter_hotspot)


func _on_register_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.LOBBY:
		return
	if not GameState.has_flag("waiter_greeted"):
		hud.set_prompt("登记簿摊开着，还没有人招呼你。")
		return
	if GameState.has_item("slip"):
		hud.set_prompt("已经登记过了。")
		return
	GameState.add_item("slip")
	stairs_hotspot.visible = true
	hud.set_prompt("你签下名字。服务单：113 · 白鹭夫人 · 缝补")
	_say("113 号房，白鹭夫人。她需要缝补。", waiter_hotspot, 3.4)


func _on_desk_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.LOBBY:
		return
	if GameState.has_item("slip"):
		hud.set_prompt("服务单：113 · 白鹭夫人 · 缝补")
	else:
		hud.set_prompt("登记簿摊开着，等一个名字。")


func _on_stairs_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.LOBBY:
		return
	if not GameState.has_item("slip"):
		hud.set_prompt("先在前台登记。")
		return
	_set_state(State.HALL)


# ---------------------------------------------------------------- 走廊
func _on_door113_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.HALL:
		return
	_set_state(State.ROOM)


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
	_set_state(State.LOBBY_EMPTY)


func _on_item_dropped(item_id: String, _slot_index: int, screen_pos: Vector2) -> void:
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
	_set_state(State.CHAPTER_END)


func _on_card_back() -> void:
	GameState.reset()
	SceneTransition.change_scene("res://scenes/main.tscn")






