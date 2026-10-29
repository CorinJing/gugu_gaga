extends Control

enum State { CABIN_CLOSED, CABIN_OPEN, BOAT, DOCK, FERRYMAN, EGRET }

const CABIN_CLOSED := preload("res://assets/art/backgrounds/cabin_closed.png")
const CABIN_OPEN := preload("res://assets/art/backgrounds/cabin_open.png")
const BOAT := preload("res://assets/art/backgrounds/boat_moving.png")
const DOCK := preload("res://assets/art/backgrounds/boat_dock.png")
const FERRYMAN := preload("res://assets/art/characters/ferryman.png")
const EGRET := preload("res://assets/art/characters/egret.png")
const COIN := preload("res://assets/art/items/coin_front_cut.png")

@onready var hud: Control = $GameHUD
@onready var background: TextureRect = %Background
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
	hud.set_location("序章 · 船舱")
	_set_state(State.CABIN_CLOSED)


func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed


func _set_state(next: State) -> void:
	state = next
	coin_overlay.visible = false
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
			background.texture = FERRYMAN
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ferryman_hotspot.visible = true
			hud.set_location("序章 · 船头")
			hud.set_prompt("你还没付钱。")
			if GameState.has_item("coin"):
				hud.set_action("付船费")
			else:
				hud.hide_action()
		State.EGRET:
			background.texture = EGRET
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hud.set_location("序章 · 旅馆门口")
			hud.set_prompt("你回来了。房间一直给你留着。")
			hud.set_action("序章结束")


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
				_set_state(State.EGRET)
			elif GameState.has_item("coin"):
				_pay_ferryman()
		State.EGRET:
			get_tree().change_scene_to_file("res://scenes/prologue/prologue_end.tscn")
