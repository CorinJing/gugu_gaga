extends Control

signal action_pressed
signal drag_released(item_id: String, slot_index: int, screen_pos: Vector2)

const PANEL := preload("res://assets/art/ui/inventory_panel.png")
const ICONS := {
	"knife": preload("res://assets/art/ui/item_knife.png"),
	"fish": preload("res://assets/art/ui/item_fish.png"),
	"coin": preload("res://assets/art/items/coin_front_cut.png"),
	"letter": preload("res://assets/art/ui/item_letter.png"),
	"mailbox_key": preload("res://assets/art/ui/item_mailbox_key.png"),
}
const SLOT_CENTERS := [0.145, 0.367, 0.544, 0.715, 0.896]

@onready var panel: TextureRect = %InventoryPanel
@onready var inventory_column: ColorRect = $InventoryColumn
@onready var slot_icons: Array[TextureRect] = [%Slot0Icon, %Slot1Icon, %Slot2Icon, %Slot3Icon, %Slot4Icon]
@onready var slot_labels: Array[Label] = [%Slot0Label, %Slot1Label, %Slot2Label, %Slot3Label, %Slot4Label]
@onready var prompt_label: Label = %PromptLabel
@onready var action_button: Button = %ActionButton
@onready var location_label: Label = %LocationLabel
@onready var location_bg: ColorRect = $LocationBg
@onready var prompt_bg: ColorRect = $PromptBg
@onready var slot_hits: Array[Control] = [$Slot0Hit, $Slot1Hit, $Slot2Hit, $Slot3Hit, $Slot4Hit]
@onready var drag_preview: Control = %DragPreview
@onready var drag_preview_icon: TextureRect = %DragPreviewIcon
@onready var drag_preview_label: Label = %DragPreviewLabel
@onready var speech_bubble: Panel = %SpeechBubble
@onready var speech_label: Label = %SpeechLabel
@onready var speech_pointer: Polygon2D = %SpeechPointer
@onready var note_overlay: Control = %NoteOverlay
@onready var note_dim: ColorRect = $NoteOverlay/NoteDim
@onready var note_paper: Panel = %NotePaper
@onready var note_label: Label = %NoteLabel
@onready var note_hint: Label = %NoteHint
@onready var window_hint: Panel = %WindowHint
@onready var window_hint_label: Label = %WindowHintLabel
@onready var window_hint_tail: Polygon2D = %WindowHintTail
@onready var boat_hint: Label = %BoatHint

var _dragging := false
var _drag_item := ""
var _drag_slot := -1
var _has_layout := false
var _last_stage_rect := Rect2()
var _last_viewport := Vector2.ZERO


func _ready() -> void:
	panel.texture = PANEL
	GameState.inventory_changed.connect(_refresh_inventory)
	action_button.pressed.connect(func() -> void: action_pressed.emit())
	for i in 5:
		slot_hits[i].gui_input.connect(_on_slot_gui_input.bind(i))
	drag_preview.visible = false
	note_overlay.visible = false
	note_overlay.gui_input.connect(_on_note_input)
	window_hint.visible = false
	boat_hint.visible = false
	action_button.visible = false
	location_bg.visible = false
	location_label.visible = false
	prompt_bg.visible = false
	prompt_label.visible = false
	_refresh_inventory()


func set_location(text: String) -> void:
	location_label.text = text


func set_location_visible(_value: bool) -> void:
	# Chapter/location labels are intentionally disabled for the whole game.
	location_bg.visible = false
	location_label.visible = false


func set_prompt(text: String) -> void:
	prompt_label.text = text


func set_action(_text: String) -> void:
	# The bottom-right action box has been removed from the game UI.
	action_button.visible = false


func hide_action() -> void:
	action_button.visible = false


func _refresh_inventory() -> void:
	for i in 5:
		var id: String = GameState.slots[i] if i < GameState.slots.size() else ""
		var icon := ICONS.get(id) as Texture2D
		slot_hits[i].mouse_filter = Control.MOUSE_FILTER_STOP if not id.is_empty() else Control.MOUSE_FILTER_IGNORE
		if id.is_empty():
			slot_icons[i].texture = null
			slot_icons[i].visible = false
			slot_labels[i].visible = false
		elif icon != null:
			slot_icons[i].texture = icon
			slot_icons[i].visible = true
			slot_labels[i].visible = false
		else:
			slot_icons[i].texture = null
			slot_icons[i].visible = false
			slot_labels[i].text = GameState.item_name(id)
			slot_labels[i].visible = true
	if _has_layout:
		apply_layout(_last_stage_rect, _last_viewport, Rect2())


func apply_layout(stage_rect: Rect2, viewport_size: Vector2, _sidebar_rect: Rect2) -> void:
	var vp := viewport_size
	_last_stage_rect = stage_rect
	_last_viewport = viewport_size
	_has_layout = true
	var column_w: float = clampf((vp.y - 40.0) * (381.0 / 1514.0), 170.0, 240.0)
	var column := Rect2(vp.x - column_w, 0.0, column_w, vp.y)
	inventory_column.position = column.position
	inventory_column.size = column.size

	var ph: float = minf(column_w / (381.0 / 1514.0), vp.y - 20.0)
	var pw: float = ph * (381.0 / 1514.0)
	var panel_rect := Rect2(column.position.x + (column_w - pw) * 0.5, (vp.y - ph) * 0.5, pw, ph)
	panel.position = panel_rect.position
	panel.size = panel_rect.size

	var icon_size: float = pw * 0.62
	var icon_font: int = int(clampf(pw * 0.11, 11.0, 20.0))
	for i in 5:
		var cx := panel_rect.position.x + pw * 0.5
		var cy := panel_rect.position.y + ph * float(SLOT_CENTERS[i])
		var is_coin: bool = GameState.slots[i] == "coin"
		var draw_size: float = icon_size * (0.52 if is_coin else 1.0)
		var rect := Rect2(cx - draw_size * 0.5, cy - draw_size * 0.5, draw_size, draw_size)
		slot_icons[i].position = rect.position
		slot_icons[i].size = rect.size
		slot_labels[i].position = Rect2(cx - icon_size * 0.5, cy - icon_size * 0.5, icon_size, icon_size).position
		slot_labels[i].size = Vector2(icon_size, icon_size)
		slot_labels[i].add_theme_font_size_override("font_size", icon_font)
		slot_hits[i].position = Rect2(cx - icon_size * 0.5, cy - icon_size * 0.5, icon_size, icon_size).position
		slot_hits[i].size = Vector2(icon_size, icon_size)

	var safe_right: float = column.position.x - 16.0
	var ui_w: float = maxf(1.0, safe_right)
	var s: float = clampf(minf(ui_w / 960.0, vp.y / 720.0), 0.62, 2.2)

	location_bg.position = Vector2(28.0 * s, 16.0 * s)
	location_bg.size = Vector2(272.0, 42.0) * s
	location_bg.visible = false
	location_label.position = Vector2(40.0 * s, 24.0 * s)
	location_label.size = Vector2(minf(250.0, ui_w - 40.0), 32.0 * s)
	location_label.add_theme_font_size_override("font_size", int(16.0 * s))
	location_label.visible = false

	var prompt_y: float = vp.y - 80.0 * s
	var prompt_w: float = minf(896.0 * s, safe_right - 32.0 * s)
	prompt_bg.position = Vector2(32.0 * s, prompt_y)
	prompt_bg.size = Vector2(prompt_w, 52.0 * s)
	prompt_bg.visible = false
	prompt_label.position = Vector2(48.0 * s, prompt_y + 10.0 * s)
	prompt_label.size = Vector2(prompt_w - 32.0 * s, 34.0 * s)
	prompt_label.add_theme_font_size_override("font_size", int(18.0 * s))
	prompt_label.visible = false

	action_button.position = Vector2(safe_right - (148.0 + 16.0) * s, prompt_y - 60.0 * s)
	action_button.size = Vector2(148.0, 48.0) * s
	action_button.add_theme_font_size_override("font_size", int(17.0 * s))
	action_button.visible = false
	if note_overlay.visible:
		_layout_note()


func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if _dragging:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if mouse.button_index != MOUSE_BUTTON_LEFT or not mouse.pressed:
		return
	var id: String = GameState.slots[index] if index < GameState.slots.size() else ""
	if id.is_empty():
		return
	_start_drag(id, index, mouse.position)
	get_viewport().set_input_as_handled()


func _start_drag(id: String, index: int, mouse_pos: Vector2) -> void:
	_dragging = true
	_drag_item = id
	_drag_slot = index
	var icon := ICONS.get(id) as Texture2D
	if icon != null:
		drag_preview_icon.texture = icon
		drag_preview_icon.visible = true
		drag_preview_label.visible = false
	else:
		drag_preview_icon.texture = null
		drag_preview_icon.visible = false
		drag_preview_label.text = GameState.item_name(id)
		drag_preview_label.visible = true
	drag_preview.visible = true
	_move_preview(mouse_pos)


func _move_preview(mouse_pos: Vector2) -> void:
	drag_preview.position = mouse_pos - Vector2(36.0, 36.0)


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		_move_preview((event as InputEventMouseMotion).position)
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed:
			var item := _drag_item
			var slot := _drag_slot
			var pos := mouse.position
			_dragging = false
			_drag_item = ""
			_drag_slot = -1
			drag_preview.visible = false
			get_viewport().set_input_as_handled()
			drag_released.emit(item, slot, pos)


func show_speech(text: String, anchor_rect: Rect2) -> void:
	var vp := get_viewport_rect().size
	var column_w: float = clampf((vp.y - 40.0) * (381.0 / 1514.0), 170.0, 240.0)
	var area_right: float = vp.x - column_w - 16.0
	var s: float = clampf(minf(area_right / 960.0, vp.y / 720.0), 0.62, 2.2)
	var w: float = clampf(330.0 * s, 260.0, minf(480.0, area_right - 32.0))
	var h: float = 96.0 * s
	var x: float = clampf(anchor_rect.get_center().x - w * 0.5, 16.0, maxf(16.0, area_right - w - 16.0))
	var y: float = anchor_rect.position.y - h - 12.0 * s
	if y < 16.0:
		y = anchor_rect.position.y + 18.0 * s
		y = clampf(y, 16.0, vp.y - h - 100.0 * s)
	speech_bubble.position = Vector2(x, y)
	speech_bubble.size = Vector2(w, h)
	speech_label.position = Vector2(16.0 * s, 10.0 * s)
	speech_label.size = Vector2(w - 32.0 * s, h - 20.0 * s)
	speech_label.add_theme_font_size_override("font_size", int(16.0 * s))
	speech_label.text = text
	speech_pointer.position = Vector2(w * 0.5, h - 1.0)
	speech_bubble.visible = true


func hide_speech() -> void:
	speech_bubble.visible = false


func show_note(text: String) -> void:
	note_label.text = text
	note_overlay.visible = true
	_layout_note()


func hide_note() -> void:
	note_overlay.visible = false


func _layout_note() -> void:
	var vp := get_viewport_rect().size
	var s: float = clampf(minf(vp.x / 1280.0, vp.y / 720.0), 0.68, 2.2)
	var w: float = minf(680.0 * s, vp.x - 80.0 * s)
	var h: float = 300.0 * s
	note_overlay.position = Vector2.ZERO
	note_overlay.size = vp
	note_dim.position = Vector2.ZERO
	note_dim.size = vp
	note_paper.position = Vector2((vp.x - w) * 0.5, (vp.y - h) * 0.5)
	note_paper.size = Vector2(w, h)
	note_label.position = Vector2(28.0 * s, 24.0 * s)
	note_label.size = Vector2(w - 56.0 * s, h - 48.0 * s)
	note_label.set_deferred("size", Vector2(w - 56.0 * s, h - 48.0 * s))
	note_label.add_theme_font_size_override("font_size", int(20.0 * s))
	note_hint.position = Vector2(0.0, note_paper.position.y + h + 14.0 * s)
	note_hint.size = Vector2(vp.x, 24.0 * s)
	note_hint.add_theme_font_size_override("font_size", int(13.0 * s))


func _on_note_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		hide_note()
		get_viewport().set_input_as_handled()


func show_window_hint(anchor_rect: Rect2) -> void:
	_show_hint("点击以打开窗户", anchor_rect)


func show_door_hint(anchor_rect: Rect2) -> void:
	_show_hint("点击以离开船仓", anchor_rect)


func _show_hint(text: String, anchor_rect: Rect2) -> void:
	var vp := get_viewport_rect().size
	var s: float = clampf(minf(vp.x / 1280.0, vp.y / 720.0), 0.68, 2.2)
	var w: float = minf(300.0 * s, vp.x - 40.0 * s)
	var h: float = 62.0 * s
	var x: float = clampf(anchor_rect.get_center().x - w * 0.5, 12.0 * s, vp.x - w - 12.0 * s)
	var y: float = clampf(anchor_rect.position.y + 26.0 * s, 12.0 * s, vp.y - h - 24.0 * s)
	window_hint.position = Vector2(x, y)
	window_hint.size = Vector2(w, h)
	window_hint_label.position = Vector2(10.0 * s, 0.0)
	window_hint_label.size = Vector2(w - 20.0 * s, h)
	window_hint_label.add_theme_font_size_override("font_size", int(16.0 * s))
	window_hint_label.text = text
	window_hint_tail.position = Vector2(w * 0.5, h - 1.0)
	window_hint.visible = true


func hide_window_hint() -> void:
	window_hint.visible = false


func show_boat_hint() -> void:
	var vp := get_viewport_rect().size
	var column_w: float = clampf((vp.y - 40.0) * (381.0 / 1514.0), 170.0, 240.0)
	var area_w: float = vp.x - column_w
	var s: float = clampf(minf(area_w / 960.0, vp.y / 720.0), 0.62, 2.2)
	boat_hint.position = Vector2(0.0, vp.y - 80.0 * s)
	boat_hint.size = Vector2(area_w, 40.0 * s)
	boat_hint.add_theme_font_size_override("font_size", int(20.0 * s))
	boat_hint.text = "点击任意处继续"
	boat_hint.visible = true


func hide_boat_hint() -> void:
	boat_hint.visible = false
