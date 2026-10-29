extends Control

enum State { CABIN_CLOSED, CABIN_OPEN, BOAT, DOCK, FERRYMAN, WAITER, EGRET }

const CABIN_CLOSED := preload("res://assets/art/backgrounds/cabin_closed.png")
const CABIN_OPEN := preload("res://assets/art/backgrounds/cabin_open.png")
const BOAT := preload("res://assets/art/backgrounds/boat_moving.png")
const DOCK := preload("res://assets/art/backgrounds/boat_dock.png")
const FERRYMAN_CUTOUT := preload("res://assets/art/characters/ferryman_cutout.png")
const WAITER_CUTOUT := preload("res://assets/art/characters/waiter_cutout.png")
const EGRET_CUTOUT := preload("res://assets/art/characters/egret_cutout.png")
const COIN := preload("res://assets/art/items/coin_front_cut.png")
const FERRYMAN_01 := preload("res://assets/audio/npc/ferryman_01_unpaid.mp3")
const FERRYMAN_02 := preload("res://assets/audio/npc/ferryman_02_answer.mp3")

@onready var hud: Control = $GameHUD
@onready var stage: Control = $Stage
@onready var backdrop: TextureRect = $Backdrop
@onready var background: TextureRect = %Background
@onready var character: TextureRect = %Character
@onready var coin_overlay: TextureRect = %CoinOverlay
@onready var window_hotspot: Control = %WindowHotspot
@onready var suitcase_hotspot: Control = %SuitcaseHotspot
@onready var heron_hotspot: Control = %HeronHotspot
@onready var fish_hotspot: Control = %FishHotspot
@onready var door_hotspot: Control = %DoorHotspot
@onready var ferryman_hotspot: Control = %FerrymanHotspot
@onready var voice: AudioStreamPlayer = $Voice

var state: State = State.CABIN_CLOSED
var _speech_generation := 0


func _ready() -> void:
	GameState.reset()
	window_hotspot.gui_input.connect(_on_window_input)
	suitcase_hotspot.gui_input.connect(_on_suitcase_input)
	heron_hotspot.gui_input.connect(_on_heron_input)
	fish_hotspot.gui_input.connect(_on_fish_input)
	door_hotspot.gui_input.connect(_on_door_input)
	ferryman_hotspot.gui_input.connect(_on_ferryman_input)
	hud.action_pressed.connect(_on_action_pressed)
	hud.drag_released.connect(_on_item_dropped)
	get_viewport().size_changed.connect(_layout)
	hud.set_location("序章 · 船舱")
	_set_state(State.CABIN_CLOSED)
	_layout()


func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed


func _set_state(next: State) -> void:
	state = next
	_speech_generation += 1
	voice.stop()
	hud.hide_speech()
	coin_overlay.visible = false
	character.visible = false
	window_hotspot.visible = false
	suitcase_hotspot.visible = false
	heron_hotspot.visible = false
	fish_hotspot.visible = false
	door_hotspot.visible = false
	ferryman_hotspot.visible = false
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	match state:
		State.CABIN_CLOSED:
			background.texture = CABIN_CLOSED
			window_hotspot.visible = true
			suitcase_hotspot.visible = true
			heron_hotspot.visible = true
			fish_hotspot.visible = true
			door_hotspot.visible = true
			hud.set_location("序章 · 船舱")
			hud.set_prompt("点击窗户，把它拉开。")
			hud.hide_action()
		State.CABIN_OPEN:
			background.texture = CABIN_OPEN
			suitcase_hotspot.visible = true
			heron_hotspot.visible = true
			fish_hotspot.visible = true
			door_hotspot.visible = true
			hud.set_location("序章 · 船舱")
			hud.set_prompt("海面很静。船身的影子停在水里，没有跟着船走。")
			if GameState.has_item("coin"):
				hud.set_action("离开船舱")
			else:
				hud.hide_action()
		State.BOAT:
			background.texture = BOAT
			hud.set_location("序章 · 船上")
			hud.set_prompt("船正在行驶。")
			hud.set_action("继续")
		State.DOCK:
			background.texture = DOCK
			hud.set_location("序章 · 码头")
			hud.set_prompt("船靠岸了。")
			hud.set_action("上岸")
		State.FERRYMAN:
			background.texture = DOCK
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			character.texture = FERRYMAN_CUTOUT
			character.visible = true
			character.position = Vector2(200.0, 0.0)
			character.size = Vector2(600.0, 632.0)
			ferryman_hotspot.visible = true
			hud.set_location("序章 · 船头")
			hud.set_prompt("把硬币拖给船夫。点击船夫可以交谈。")
			hud.hide_action()
		State.WAITER:
			background.texture = DOCK
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			character.texture = WAITER_CUTOUT
			character.visible = true
			character.position = Vector2(350.0, 0.0)
			character.size = Vector2(500.0, 632.0)
			hud.set_location("序章 · 旅馆门口")
			hud.set_prompt("欢迎。请登记。")
			hud.set_action("进入旅馆")
		State.EGRET:
			background.texture = DOCK
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			character.texture = EGRET_CUTOUT
			character.visible = true
			character.position = Vector2(550.0, 0.0)
			character.size = Vector2(350.0, 632.0)
			hud.set_location("序章 · 旅馆门口")
			hud.set_prompt("你回来了。房间一直给你留着。")
			hud.set_action("序章结束")
	_layout()


func _layout() -> void:
	var vp := get_viewport_rect().size
	if vp.x <= 1.0 or vp.y <= 1.0:
		return

	# The game world owns the left area; the inventory column owns the right edge.
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

	if character.visible and character.texture != null:
		var base_x: float = 200.0
		match state:
			State.WAITER:
				base_x = 350.0
			State.EGRET:
				base_x = 550.0
		var tex := character.texture
		var actual_w: float = character.size.y * float(tex.get_width()) / float(tex.get_height())

		var safe_right: float = area.size.x - 16.0
		var local_safe: float = (safe_right - stage_pos.x) / cover_scale
		character.position.x = minf(base_x, maxf(8.0, local_safe - actual_w))

		var ui_s: float = clampf(minf(area.size.x / 960.0, vp.y / 720.0), 0.62, 2.2)
		var prompt_screen: float = vp.y - 80.0 * ui_s
		var top_local: float = maxf(0.0, -stage_pos.y) / cover_scale
		var bottom_local: float = minf(stage_size.y, (prompt_screen - stage_pos.y) / cover_scale - 8.0)
		var body_h: float = maxf(180.0, minf(632.0, bottom_local - top_local))
		character.position.y = top_local
		character.size.y = body_h

	hud.apply_layout(Rect2(stage_pos, stage_size), vp, Rect2())


func _show_coin() -> void:
	coin_overlay.texture = COIN
	coin_overlay.visible = true


func _on_window_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.CABIN_CLOSED:
		return
	GameState.set_flag("prologue_window_open")
	_set_state(State.CABIN_OPEN)


func _on_suitcase_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if not GameState.has_item("knife"):
		GameState.add_item("knife")
		hud.set_prompt("你从行李箱里找到一把小折刀。")
	else:
		hud.set_prompt("行李箱里只剩旧衣服和几封没拆的信。")


func _on_fish_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if not GameState.has_item("fish"):
		GameState.add_item("fish")
		hud.set_prompt("你从水桶里拿起一条死鱼。")
	else:
		hud.set_prompt("水桶里空了。")


func _on_heron_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if GameState.has_flag("heron_fed"):
		hud.set_prompt("白鹭一动不动。")
	elif not GameState.has_flag("heron_cut"):
		hud.set_prompt("白鹭的喙被红线缝住了。把小刀拖到喙上。")
	else:
		hud.set_prompt("喙张开了。它好像在等一条鱼。把鱼拖进嘴里。")


func _on_item_dropped(item_id: String, _slot_index: int, screen_pos: Vector2) -> void:
	if heron_hotspot.visible and heron_hotspot.get_global_rect().has_point(screen_pos):
		_use_on_heron(item_id)
	elif state == State.FERRYMAN and ferryman_hotspot.visible and ferryman_hotspot.get_global_rect().has_point(screen_pos):
		_use_on_ferryman(item_id)
	else:
		hud.set_prompt("这里用不了这个东西。")


func _use_on_heron(item_id: String) -> void:
	if item_id == "knife":
		if GameState.has_flag("heron_cut"):
			hud.set_prompt("红线已经割开了。")
			return
		GameState.remove_item("knife")
		GameState.set_flag("heron_cut")
		hud.set_prompt("你用刀割开喙上的红线。白鹭慢慢张开嘴。")
		return
	if item_id == "fish":
		if not GameState.has_flag("heron_cut"):
			hud.set_prompt("喙还缝着。先用小刀割开红线。")
			return
		if GameState.has_flag("heron_fed"):
			hud.set_prompt("它已经吃饱了。")
			return
		GameState.remove_item("fish")
		GameState.set_flag("heron_fed")
		GameState.add_item("coin")
		_show_coin()
		hud.set_prompt("白鹭仰起脖子，吞下鱼。它抖了抖尾巴，下了一枚黄铜硬币。")
		hud.set_action("离开船舱")
		return
	hud.set_prompt("白鹭对这个东西不感兴趣。")


func _use_on_ferryman(item_id: String) -> void:
	if item_id == "coin":
		_pay_ferryman()
		return
	hud.set_prompt("船夫不需要这个。")


func _on_door_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if GameState.has_item("coin"):
		_set_state(State.BOAT)
	else:
		hud.set_prompt("船夫还在等船费。")


func _pay_ferryman() -> void:
	if GameState.has_flag("ferry_paid"):
		return
	if not GameState.has_item("coin"):
		hud.set_prompt("你还没付钱。")
		return
	GameState.remove_item("coin")
	GameState.set_flag("ferry_paid")
	hud.set_prompt("船夫收下黄铜硬币，侧身让开。")
	hud.set_action("进入旅馆")
	# Payment itself triggers the second line; no extra click required.
	_say_ferryman(1)


func _on_ferryman_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.FERRYMAN:
		return
	# The line is gated by payment, not by click count.
	# Unpaid: line 1 only. Paid: line 2 only.
	_say_ferryman(1 if GameState.has_flag("ferry_paid") else 0)


func _say_ferryman(index: int) -> void:
	var line: Dictionary = [
		{"text": "你还没有付船费", "audio": FERRYMAN_01},
		{"text": "希望你能找到你所希望的答案", "audio": FERRYMAN_02},
	][index]
	hud.show_speech(str(line["text"]), character.get_global_rect())
	voice.stop()
	voice.stream = line["audio"]
	voice.play()
	_speech_generation += 1
	var generation := _speech_generation
	var duration: float = (line["audio"] as AudioStream).get_length()
	await get_tree().create_timer(duration + 0.8).timeout
	if generation == _speech_generation and state == State.FERRYMAN:
		hud.hide_speech()


func _on_action_pressed() -> void:
	match state:
		State.CABIN_OPEN:
			if GameState.has_item("coin"):
				_set_state(State.BOAT)
		State.BOAT:
			_set_state(State.DOCK)
		State.DOCK:
			_set_state(State.FERRYMAN)
		State.FERRYMAN:
			if GameState.has_flag("ferry_paid"):
				_set_state(State.WAITER)
		State.WAITER:
			_set_state(State.EGRET)
		State.EGRET:
			get_tree().change_scene_to_file("res://scenes/prologue/prologue_end.tscn")
