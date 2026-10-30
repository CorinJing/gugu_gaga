extends Control

enum State { CABIN_CLOSED, CABIN_OPEN, CABIN_SEARCH, CABIN_BEAK, SUITCASE_VIEW, NIGHTSTAND_VIEW, BOAT, DOCK, FERRYMAN, WAITER, EGRET }

const CABIN_CLOSED := preload("res://assets/art/backgrounds/cabin_closed.png")
const CABIN_OPEN := preload("res://assets/art/backgrounds/cabin_open.png")
const CABIN_BEAK := preload("res://assets/art/backgrounds/cabin_open_beak.png")
const SUITCASE := preload("res://assets/art/backgrounds/suitcase_open.png")
const NIGHTSTAND := preload("res://assets/art/backgrounds/nightstand_closeup.png")
const KNIFE_ICON := preload("res://assets/art/ui/item_knife.png")
const BOAT := preload("res://assets/art/backgrounds/boat_moving.png")
const DOCK := preload("res://assets/art/backgrounds/boat_dock.png")
const FERRYMAN_CUTOUT := preload("res://assets/art/characters/ferryman_cutout.png")
const WAITER_CUTOUT := preload("res://assets/art/characters/waiter_cutout.png")
const EGRET_CUTOUT := preload("res://assets/art/characters/egret_cutout.png")
const COIN := preload("res://assets/art/items/coin_front_cut.png")
const OCCLUDE_SHADER := preload("res://assets/shaders/occlude_bottom.gdshader")
const FERRYMAN_01 := preload("res://assets/audio/npc/ferryman_01_unpaid.mp3")
const FERRYMAN_02 := preload("res://assets/audio/npc/ferryman_02_answer.mp3")

@onready var hud: Control = $GameHUD
@onready var stage: Control = $Stage
@onready var backdrop: TextureRect = $Backdrop
@onready var background: TextureRect = %Background
@onready var character: TextureRect = %Character
@onready var coin_overlay: TextureRect = %CoinOverlay
@onready var coin_hotspot: Control = %CoinHotspot
@onready var window_hotspot: Control = %WindowHotspot
@onready var suitcase_hotspot: Control = %SuitcaseHotspot
@onready var heron_hotspot: Control = %HeronHotspot
@onready var fish_hotspot: Control = %FishHotspot
@onready var door_hotspot: Control = %DoorHotspot
@onready var ferryman_hotspot: Control = %FerrymanHotspot
@onready var cabin_hotspot: Control = %CabinHotspot
@onready var nightstand_hotspot: Control = %NightstandHotspot
@onready var note_hotspot: Control = %NoteHotspot
@onready var suitcase_knife: TextureRect = %SuitcaseKnife
@onready var suitcase_knife_hotspot: Control = %SuitcaseKnifeHotspot
@onready var back_arrow: Button = $BackArrow
@onready var voice: AudioStreamPlayer = $Voice

var state: State = State.CABIN_CLOSED
var _cabin_return_state: State = State.CABIN_OPEN
var _speech_generation := 0


func _ready() -> void:
	GameState.reset()
	window_hotspot.gui_input.connect(_on_window_input)
	suitcase_hotspot.gui_input.connect(_on_suitcase_input)
	heron_hotspot.gui_input.connect(_on_heron_input)
	fish_hotspot.gui_input.connect(_on_fish_input)
	door_hotspot.gui_input.connect(_on_door_input)
	ferryman_hotspot.gui_input.connect(_on_ferryman_input)
	cabin_hotspot.gui_input.connect(_on_cabin_hotspot_input)
	hud.action_pressed.connect(_on_action_pressed)
	hud.drag_released.connect(_on_item_dropped)
	back_arrow.pressed.connect(_on_back_pressed)
	suitcase_knife_hotspot.gui_input.connect(_on_suitcase_knife_input)
	coin_hotspot.gui_input.connect(_on_coin_pickup)
	nightstand_hotspot.gui_input.connect(_on_nightstand_input)
	note_hotspot.gui_input.connect(_on_note_hotspot_input)
	suitcase_knife.texture = KNIFE_ICON
	get_viewport().size_changed.connect(_layout)
	hud.set_location("序章 · 船舱")
	_set_state(State.CABIN_CLOSED)
	_layout()


func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed


func _transition_to(next: State) -> void:
	if next == state:
		return
	await SceneTransition.transition(func() -> void: _set_state(next))


func _set_state(next: State) -> void:
	state = next
	character.material = null
	back_arrow.visible = false
	suitcase_knife.visible = false
	suitcase_knife_hotspot.visible = false
	hud.set_location_visible(true)
	_speech_generation += 1
	voice.stop()
	hud.hide_speech()
	coin_overlay.visible = false
	coin_hotspot.visible = false
	character.visible = false
	window_hotspot.visible = false
	suitcase_hotspot.visible = false
	heron_hotspot.visible = false
	fish_hotspot.visible = false
	door_hotspot.visible = false
	ferryman_hotspot.visible = false
	cabin_hotspot.visible = false
	nightstand_hotspot.visible = false
	note_hotspot.visible = false
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	match state:
		State.CABIN_CLOSED:
			background.texture = CABIN_CLOSED
			window_hotspot.visible = true
			hud.set_location("序章 · 船舱")
			hud.set_prompt("点击窗户，把它拉开。")
			hud.hide_action()
		State.CABIN_OPEN:
			background.texture = CABIN_OPEN
			door_hotspot.visible = true
			nightstand_hotspot.visible = true
			hud.set_location("序章 · 船舱")
			hud.set_prompt("窗开了。该离开船舱了。")
			hud.set_action("离开船舱")
		State.CABIN_SEARCH:
			background.texture = CABIN_OPEN
			nightstand_hotspot.visible = true
			suitcase_hotspot.visible = true
			heron_hotspot.visible = true
			fish_hotspot.visible = true
			door_hotspot.visible = true
			hud.set_location("序章 · 船舱")
			hud.set_prompt("船夫说要付船费。找找船舱里能换钱的东西。")
			if GameState.has_item("coin"):
				hud.set_action("离开船舱")
			else:
				hud.hide_action()
		State.CABIN_BEAK:
			background.texture = CABIN_BEAK
			heron_hotspot.visible = true
			fish_hotspot.visible = true
			door_hotspot.visible = true
			hud.set_location("序章 · 船舱")
			hud.set_prompt("白鹭张开了嘴。把鱼喂给它。")
			if GameState.has_item("coin"):
				hud.set_action("离开船舱")
			else:
				hud.hide_action()
		State.SUITCASE_VIEW:
			background.texture = SUITCASE
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			back_arrow.visible = true
			hud.set_location_visible(false)
			hud.hide_action()
			if not GameState.has_flag("knife_taken"):
				suitcase_knife.visible = true
				suitcase_knife_hotspot.visible = true
				hud.set_prompt("箱子开着。小刀放在里面。")
			else:
				hud.set_prompt("箱子里只剩旧衣服和几封没拆的信。")
		State.NIGHTSTAND_VIEW:
			background.texture = NIGHTSTAND
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			back_arrow.visible = true
			hud.set_location_visible(false)
			note_hotspot.visible = true
			hud.set_prompt("床头柜上有一盏灯和一张纸条。")
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
			character.position = Vector2(560.0, 250.0)
			character.size = Vector2(400.0, 320.0)
			var occlude := ShaderMaterial.new()
			occlude.shader = OCCLUDE_SHADER
			character.material = occlude
			ferryman_hotspot.visible = true
			cabin_hotspot.visible = GameState.has_flag("knows_coin_needed") and not GameState.has_flag("ferry_paid")
			hud.set_location("序章 · 船头")
			if GameState.has_flag("ferry_paid"):
				hud.set_prompt("船夫已经让开了。")
			elif GameState.has_flag("knows_coin_needed"):
				hud.set_prompt("把硬币拖给船夫。点击船舱可以回去找。")
			else:
				hud.set_prompt("点击船夫与他交谈。")
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

	if state == State.FERRYMAN and character.visible and character.texture != null:
		# Stand at the stern (rightmost deck), behind the near gunwale.
		var ftex := character.texture
		var fw: float = 320.0 * float(ftex.get_width()) / float(ftex.get_height())
		var fsafe_right: float = area.size.x - 16.0
		var flocal_safe: float = (fsafe_right - stage_pos.x) / cover_scale
		character.position = Vector2(minf(560.0, maxf(8.0, flocal_safe - fw)), 250.0)
		character.size = Vector2(400.0, 320.0)
		# Keep the clickable area glued to the visible ferryman, not the old stage rect.
		var image_left: float = character.position.x + (character.size.x - fw) * 0.5
		ferryman_hotspot.position = Vector2(image_left - 12.0, character.position.y - 12.0)
		ferryman_hotspot.size = Vector2(fw + 24.0, character.size.y + 24.0)
	elif character.visible and character.texture != null:
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

	var back_s: float = clampf(minf(area.size.x / 960.0, vp.y / 720.0), 0.62, 2.2)
	back_arrow.position = Vector2(18.0 * back_s, 18.0 * back_s)
	back_arrow.size = Vector2(48.0, 48.0) * back_s
	back_arrow.add_theme_font_size_override("font_size", int(26.0 * back_s))

	hud.apply_layout(Rect2(stage_pos, stage_size), vp, Rect2())


func _drop_coin_from_beak() -> void:
	coin_overlay.texture = COIN
	coin_overlay.size = Vector2(28.0, 28.0)
	coin_overlay.pivot_offset = Vector2(14.0, 14.0)
	coin_overlay.position = Vector2(791.0, 157.0)
	coin_overlay.rotation = 0.0
	coin_overlay.visible = true
	hud.set_prompt("白鹭吞下鱼。一枚硬币从它嘴里掉出来。")

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(coin_overlay, "position", Vector2(560.0, 590.0), 0.85)
	tween.parallel().tween_property(coin_overlay, "rotation", TAU * 1.6, 0.85)
	await tween.finished

	coin_hotspot.position = Vector2(532.0, 562.0)
	coin_hotspot.size = Vector2(56.0, 56.0)
	coin_hotspot.visible = true
	hud.set_prompt("硬币落在地板上。点击它捡起来。")


func _on_coin_pickup(event: InputEvent) -> void:
	if not _is_left_click(event) or not coin_hotspot.visible:
		return
	coin_hotspot.visible = false
	coin_overlay.visible = false
	GameState.add_item("coin")
	hud.set_prompt("你从地板上捡起一枚黄铜硬币。")
	hud.set_action("离开船舱")


func _on_window_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.CABIN_CLOSED:
		return
	GameState.set_flag("prologue_window_open")
	_transition_to(State.CABIN_OPEN)


func _on_suitcase_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.CABIN_SEARCH:
		return
	_cabin_return_state = State.CABIN_SEARCH
	_transition_to(State.SUITCASE_VIEW)


func _on_back_pressed() -> void:
	if state == State.SUITCASE_VIEW or state == State.NIGHTSTAND_VIEW:
		_transition_to(_cabin_return_state)


func _on_suitcase_knife_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.SUITCASE_VIEW:
		return
	if GameState.has_flag("knife_taken"):
		hud.set_prompt("箱子里的刀已经拿走了。")
		return
	GameState.set_flag("knife_taken")
	GameState.add_item("knife")
	suitcase_knife.visible = false
	suitcase_knife_hotspot.visible = false
	hud.set_prompt("你从箱子夹层里拿起一把小折刀。")


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
		await _transition_to(State.CABIN_BEAK)
		return
	if item_id == "fish":
		if not GameState.has_flag("heron_cut"):
			hud.set_prompt("喙还缝着。先用小刀割开红线。")
			return
		if GameState.has_flag("heron_fed") or coin_hotspot.visible or GameState.has_item("coin"):
			hud.set_prompt("它已经吃饱了。")
			return
		GameState.remove_item("fish")
		GameState.set_flag("heron_fed")
		hud.set_prompt("白鹭吞下鱼。它抖了抖脖子。")
		await _drop_coin_from_beak()
		return
	hud.set_prompt("白鹭对这个东西不感兴趣。")


func _use_on_ferryman(item_id: String) -> void:
	if item_id == "coin":
		_pay_ferryman()
		return
	hud.set_prompt("船夫不需要这个。")


func _on_note_hotspot_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.NIGHTSTAND_VIEW:
		return
	hud.show_note("Ms.Yanqiu于三周前失踪。\n请继承人于盐月朔日前抵达盐月旅馆。")


func _on_nightstand_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if state != State.CABIN_OPEN and state != State.CABIN_SEARCH:
		return
	_cabin_return_state = state
	_transition_to(State.NIGHTSTAND_VIEW)


func _on_door_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if state == State.CABIN_OPEN:
		_transition_to(State.BOAT)
	elif state == State.CABIN_SEARCH or state == State.CABIN_BEAK:
		if GameState.has_item("coin"):
			# The boat is already docked; returning from the cabin goes straight
			# back to the ferryman, not through the moving-boat screen again.
			_transition_to(State.FERRYMAN)
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
	cabin_hotspot.visible = false
	hud.set_prompt("船夫收下黄铜硬币，侧身让开。")
	hud.set_action("进入旅馆")
	# Payment itself triggers the second line; no extra click required.
	_say_ferryman(1)


func _on_ferryman_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.FERRYMAN:
		return
	if not GameState.has_flag("ferry_paid"):
		GameState.set_flag("knows_coin_needed")
		cabin_hotspot.visible = true
		hud.set_prompt("船夫说要付船费。点击船舱回去找硬币。")
		_say_ferryman(0)
	else:
		_say_ferryman(1)


func _on_cabin_hotspot_input(event: InputEvent) -> void:
	if not _is_left_click(event) or state != State.FERRYMAN:
		return
	if not GameState.has_flag("knows_coin_needed") or GameState.has_flag("ferry_paid"):
		return
	_transition_to(State.CABIN_SEARCH)


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
			_transition_to(State.BOAT)
		State.CABIN_SEARCH:
			if GameState.has_item("coin"):
				_transition_to(State.FERRYMAN)
		State.CABIN_BEAK:
			if GameState.has_item("coin"):
				_transition_to(State.FERRYMAN)
		State.BOAT:
			_transition_to(State.DOCK)
		State.DOCK:
			_transition_to(State.FERRYMAN)
		State.FERRYMAN:
			if GameState.has_flag("ferry_paid"):
				_transition_to(State.WAITER)
		State.WAITER:
			_transition_to(State.EGRET)
		State.EGRET:
			SceneTransition.change_scene("res://scenes/prologue/prologue_end.tscn")
