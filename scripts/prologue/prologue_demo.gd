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

var state: State = State.CABIN_CLOSED


func _ready() -> void:
	GameState.reset()
	window_hotspot.gui_input.connect(_on_window_input)
	suitcase_hotspot.gui_input.connect(_on_suitcase_input)
	heron_hotspot.gui_input.connect(_on_heron_input)
	fish_hotspot.gui_input.connect(_on_fish_input)
	door_hotspot.gui_input.connect(_on_door_input)
	ferryman_hotspot.gui_input.connect(_on_ferryman_input)
	hud.action_pressed.connect(_on_action_pressed)
	get_viewport().size_changed.connect(_layout)
	hud.set_location("序章 · 船舱")
	_set_state(State.CABIN_CLOSED)
	_layout()


func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed


func _set_state(next: State) -> void:
	state = next
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
			hud.set_prompt("你还没付钱。")
			if GameState.has_item("coin"):
				hud.set_action("付船费")
			else:
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

	var aspect := vp.x / vp.y
	var sidebar_rect: Rect2
	var stage_size: Vector2
	var stage_pos: Vector2
	var scale: float = 1.0

	if aspect >= 1.45:
		# Wide: stage + right sidebar.
		var sw: float = clampf(vp.x * 0.25, 260.0, 380.0)
		sidebar_rect = Rect2(vp.x - sw, 0.0, sw, vp.y)
		var area := Rect2(0.0, 0.0, vp.x - sw, vp.y)
		scale = minf(area.size.x / 960.0, area.size.y / 720.0)
		stage_size = Vector2(960.0, 720.0) * scale
		stage_pos = area.position + (area.size - stage_size) * 0.5
	elif aspect >= 1.30:
		# Near-4:3: stage fills the window, inventory becomes a top bar.
		var top_h: float = clampf(vp.y * 0.11, 70.0, 100.0)
		sidebar_rect = Rect2(0.0, 0.0, vp.x, top_h)
		var cover_scale: float = maxf(vp.x / 960.0, vp.y / 720.0)
		stage_size = Vector2(960.0, 720.0) * cover_scale
		stage_pos = (vp - stage_size) * 0.5
	else:
		# Portrait / square: stage on top, inventory at the bottom.
		var sh: float = clampf(vp.y * 0.24, 140.0, 220.0)
		sidebar_rect = Rect2(0.0, vp.y - sh, vp.x, sh)
		var area := Rect2(0.0, 0.0, vp.x, vp.y - sh)
		scale = minf(area.size.x / 960.0, area.size.y / 720.0)
		stage_size = Vector2(960.0, 720.0) * scale
		stage_pos = area.position + (area.size - stage_size) * 0.5

	stage.position = stage_pos
	stage.scale = Vector2(scale, scale)
	backdrop.position = Vector2.ZERO
	backdrop.size = vp
	backdrop.texture = background.texture
	backdrop.modulate = Color(0.22, 0.22, 0.22, 1.0)
	hud.apply_layout(Rect2(stage_pos, stage_size), vp, sidebar_rect)


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
		return
	if not GameState.has_item("knife"):
		hud.set_prompt("白鹭的喙被红线缝住了。")
		return
	if not GameState.has_item("fish"):
		hud.set_prompt("喙张开了。它好像在等一条鱼。")
		return
	GameState.remove_item("fish")
	GameState.set_flag("heron_fed")
	GameState.add_item("coin")
	_show_coin()
	hud.set_prompt("白鹭仰起脖子，吞下鱼。它抖了抖尾巴，下了一枚黄铜硬币。")
	hud.set_action("离开船舱")


func _on_door_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if GameState.has_item("coin"):
		_set_state(State.BOAT)
	else:
		hud.set_prompt("船夫还在等船费。")


func _pay_ferryman() -> void:
	if not GameState.has_item("coin"):
		hud.set_prompt("你还没付钱。")
		return
	GameState.remove_item("coin")
	GameState.set_flag("ferry_paid")
	hud.set_prompt("船夫收下黄铜硬币，侧身让开。")
	hud.set_action("进入旅馆")


func _on_ferryman_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.FERRYMAN:
		return
	if GameState.has_flag("ferry_paid"):
		hud.set_prompt("船夫已经让开了。")
	else:
		_pay_ferryman()


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
			elif GameState.has_item("coin"):
				_pay_ferryman()
		State.WAITER:
			_set_state(State.EGRET)
		State.EGRET:
			get_tree().change_scene_to_file("res://scenes/prologue/prologue_end.tscn")
