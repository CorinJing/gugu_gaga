extends Control

@onready var hud: Control = $GameHUD
@onready var door_hotspot: Control = %DoorHotspot
@onready var keyhole_hotspot: Control = %KeyholeHotspot
@onready var crank_hotspot: Control = %CrankHotspot
@onready var clock_hotspot: Control = %ClockHotspot
@onready var mat_hotspot: Control = %MatHotspot
@onready var umbrella_hotspot: Control = %UmbrellaHotspot
@onready var mailbox_hotspot: Control = %MailboxHotspot
@onready var door_handle_visual: ColorRect = %DoorHandle
@onready var keyhole_salt: ColorRect = %KeyholeSalt
@onready var cover: ColorRect = %Cover
@onready var egret_panel: ColorRect = %EgretPanel

var dial_panel: ColorRect
var dial_buttons: Array[Button] = []
var dial_values: Array[int] = [0, 0, 0]
var dial_solved := false
var door_open := false


func _ready() -> void:
	door_hotspot.gui_input.connect(_on_door_input)
	keyhole_hotspot.gui_input.connect(_on_keyhole_input)
	crank_hotspot.gui_input.connect(_on_crank_input)
	clock_hotspot.gui_input.connect(_on_clock_input)
	mat_hotspot.gui_input.connect(_on_mat_input)
	umbrella_hotspot.gui_input.connect(_on_umbrella_input)
	mailbox_hotspot.gui_input.connect(_on_mailbox_input)
	hud.action_pressed.connect(_on_action_pressed)
	hud.set_location("序章 · 旅馆门前")
	_build_dial_panel()
	_sync_visuals()
	_refresh_prompt()


func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed


func _sync_visuals() -> void:
	door_handle_visual.visible = GameState.has_flag("door_handle_attached")
	keyhole_salt.visible = not GameState.has_flag("keyhole_cleared")
	cover.visible = not GameState.has_flag("key_used")
	if GameState.has_flag("hotel_door_open"):
		egret_panel.visible = true
		hud.set_action("进门")
	elif GameState.has_flag("prologue_dial_solved"):
		egret_panel.visible = false
		hud.set_action("拉门")
	else:
		egret_panel.visible = false
		hud.hide_action()


func _refresh_prompt() -> void:
	if GameState.has_flag("hotel_door_open"):
		hud.set_prompt("白鹭夫人站在门后。")
	elif GameState.has_flag("prologue_dial_solved"):
		hud.set_prompt("门锁解除。拉下白鹭把手。")
	elif GameState.has_flag("dial_active"):
		hud.set_prompt("三个铜环抬起来了。把它们调到 03:13。")
	elif not GameState.has_flag("door_handle_attached"):
		hud.set_prompt("门板上只有一个方形轴，没有把手。")
	else:
		hud.set_prompt("门能拉动，但里面像有什么东西顶着。")


func _on_door_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if GameState.has_flag("hotel_door_open"):
		hud.set_prompt("门已经开了。")
	elif not GameState.has_flag("door_handle_attached"):
		if GameState.has_item("door_handle"):
			GameState.set_flag("door_handle_attached")
			GameState.remove_item("door_handle")
			_sync_visuals()
			hud.set_prompt("你把白鹭把手卡进方轴。门能拉动，但里面还有东西顶着。")
		else:
			hud.set_prompt("门板上只有一个方形轴，没有把手。")
	elif not GameState.has_flag("prologue_dial_solved"):
		hud.set_prompt("门能拉动，但里面像有什么东西顶着。")
	else:
		_open_door()


func _on_umbrella_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if not GameState.has_flag("door_handle_found"):
		GameState.set_flag("door_handle_found")
		GameState.add_item("door_handle")
		hud.set_prompt("你从伞架最里面抽出一根白鹭形状的黄铜把手。")
	else:
		hud.set_prompt("伞架里只剩几把旧伞。")


func _on_mailbox_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if not GameState.has_flag("mailbox_opened"):
		if GameState.has_item("knife"):
			GameState.set_flag("mailbox_opened")
			GameState.add_item("crank")
			hud.set_prompt("锈死的搭扣断开。信箱里有一根黄铜摇柄。")
		else:
			hud.set_prompt("信箱搭扣锈死了。")
	else:
		hud.set_prompt("信箱已经空了。")


func _on_mat_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if not GameState.has_flag("mat_cut"):
		if GameState.has_item("knife"):
			GameState.set_flag("mat_cut")
			GameState.add_item("brass_key")
			hud.set_prompt("红线断开。你拿到一把黄铜钥匙。")
		else:
			hud.set_prompt("红线把钥匙缝在垫子背面。")
	else:
		hud.set_prompt("门垫下面没有别的东西。")


func _on_keyhole_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if not GameState.has_flag("keyhole_cleared"):
		if GameState.has_item("knife"):
			GameState.set_flag("keyhole_cleared")
			_sync_visuals()
			hud.set_prompt("盐壳一片片剥落，露出钥匙孔。")
		else:
			hud.set_prompt("钥匙孔被盐封住了。")
	elif not GameState.has_flag("key_used"):
		if GameState.has_item("brass_key"):
			GameState.set_flag("key_used")
			GameState.remove_item("brass_key")
			_sync_visuals()
			hud.set_prompt("钥匙转到底。铜盖弹开，露出三个铜环和一个方孔。")
		else:
			hud.set_prompt("需要一把钥匙。")
	else:
		hud.set_prompt("铜盖开着。")


func _on_crank_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if not GameState.has_flag("key_used"):
		hud.set_prompt("方孔被铜盖盖着。")
	elif not GameState.has_flag("crank_inserted"):
		if GameState.has_item("crank"):
			GameState.set_flag("crank_inserted")
			GameState.set_flag("dial_active")
			GameState.remove_item("crank")
			dial_panel.visible = true
			hud.set_prompt("摇柄咬住齿轮。转动后，三个铜环被抬了起来。")
		else:
			hud.set_prompt("方孔里有一套齿轮，需要一根摇柄。")
	else:
		hud.set_prompt("摇柄已经装好。")


func _on_clock_input(event: InputEvent) -> void:
	if _is_left_click(event):
		hud.set_prompt("门楣铜钟停在 03:13。")


func _on_action_pressed() -> void:
	if GameState.has_flag("hotel_door_open"):
		get_tree().change_scene_to_file("res://scenes/prologue/prologue_end.tscn")
	elif GameState.has_flag("prologue_dial_solved"):
		_open_door()


func _open_door() -> void:
	door_open = true
	GameState.set_flag("hotel_door_open")
	_sync_visuals()
	hud.set_prompt("门开了。白鹭夫人站在门后。")


func _build_dial_panel() -> void:
	dial_panel = ColorRect.new()
	dial_panel.position = Vector2(620, 80)
	dial_panel.size = Vector2(300, 520)
	dial_panel.color = Color(0.039, 0.05, 0.047, 0.97)
	dial_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dial_panel.visible = false
	add_child(dial_panel)

	var title := Label.new()
	title.position = Vector2(24, 24)
	title.size = Vector2(252, 40)
	title.text = "潮汐盘"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.91, 0.87, 0.78))
	dial_panel.add_child(title)

	var hint := Label.new()
	hint.position = Vector2(24, 66)
	hint.size = Vector2(252, 30)
	hint.text = "时 · 十分 · 分"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.72, 0.66, 0.55))
	dial_panel.add_child(hint)

	var labels := ["时", "十分", "分"]
	for i in 3:
		var label := Label.new()
		label.position = Vector2(24, 130 + i * 92)
		label.size = Vector2(70, 48)
		label.text = labels[i]
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(0.72, 0.66, 0.55))
		dial_panel.add_child(label)

		var button := Button.new()
		button.position = Vector2(110, 122 + i * 92)
		button.size = Vector2(150, 54)
		button.text = "0"
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(_cycle_dial.bind(i))
		dial_panel.add_child(button)
		dial_buttons.append(button)

	var hint2 := Label.new()
	hint2.position = Vector2(24, 430)
	hint2.size = Vector2(252, 50)
	hint2.text = "门楣铜钟：03:13"
	hint2.add_theme_font_size_override("font_size", 13)
	hint2.add_theme_color_override("font_color", Color(0.55, 0.51, 0.44))
	dial_panel.add_child(hint2)


func _cycle_dial(index: int) -> void:
	dial_values[index] = (dial_values[index] + 1) % 10
	dial_buttons[index].text = str(dial_values[index])
	if dial_values == [3, 1, 3]:
		_solve_dial()


func _solve_dial() -> void:
	dial_solved = true
	GameState.set_flag("prologue_dial_solved")
	dial_panel.visible = false
	_sync_visuals()
	hud.set_prompt("三个铜环对齐。门锁解除。")
