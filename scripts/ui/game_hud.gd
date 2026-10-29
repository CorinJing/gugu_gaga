extends Control

signal action_pressed
signal drag_released(item_id: String, slot_index: int, screen_pos: Vector2)

const PANEL := preload("res://assets/art/ui/inventory_panel.png")
const ICONS := {
	"knife": preload("res://assets/art/ui/item_knife.png"),
	"fish": preload("res://assets/art/ui/item_fish.png"),
	"coin": preload("res://assets/art/items/coin_front_cut.png"),
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

var _dragging := false
var _drag_item := ""
var _drag_slot := -1


func _ready() -> void:
	panel.texture = PANEL
	GameState.inventory_changed.connect(_refresh_inventory)
	action_button.pressed.connect(func() -> void: action_pressed.emit())
	for i in 5:
		slot_hits[i].gui_input.connect(_on_slot_gui_input.bind(i))
	drag_preview.visible = false
	_refresh_inventory()


func set_location(text: String) -> void:
	location_label.text = text


func set_location_visible(value: bool) -> void:
	location_bg.visible = value
	location_label.visible = value


func set_prompt(text: String) -> void:
	prompt_label.text = text


func set_action(text: String) -> void:
	action_button.text = text
	action_button.visible = not text.is_empty()


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


func apply_layout(stage_rect: Rect2, viewport_size: Vector2, _sidebar_rect: Rect2) -> void:
	var vp := viewport_size
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
		var rect := Rect2(cx - icon_size * 0.5, cy - icon_size * 0.5, icon_size, icon_size)
		slot_icons[i].position = rect.position
		slot_icons[i].size = rect.size
		slot_labels[i].position = rect.position
		slot_labels[i].size = rect.size
		slot_labels[i].add_theme_font_size_override("font_size", icon_font)
		slot_hits[i].position = rect.position
		slot_hits[i].size = rect.size

	var safe_right: float = column.position.x - 16.0
	var ui_w: float = maxf(1.0, safe_right)
	var s: float = clampf(minf(ui_w / 960.0, vp.y / 720.0), 0.62, 2.2)

	location_bg.position = Vector2(28.0 * s, 16.0 * s)
	location_bg.size = Vector2(272.0, 42.0) * s
	location_label.position = Vector2(40.0 * s, 24.0 * s)
	location_label.size = Vector2(minf(250.0, ui_w - 40.0), 32.0 * s)
	location_label.add_theme_font_size_override("font_size", int(16.0 * s))

	var prompt_y: float = vp.y - 80.0 * s
	var prompt_w: float = minf(896.0 * s, safe_right - 32.0 * s)
	prompt_bg.position = Vector2(32.0 * s, prompt_y)
	prompt_bg.size = Vector2(prompt_w, 52.0 * s)
	prompt_label.position = Vector2(48.0 * s, prompt_y + 10.0 * s)
	prompt_label.size = Vector2(prompt_w - 32.0 * s, 34.0 * s)
	prompt_label.add_theme_font_size_override("font_size", int(18.0 * s))

	action_button.position = Vector2(safe_right - (148.0 + 16.0) * s, prompt_y - 60.0 * s)
	action_button.size = Vector2(148.0, 48.0) * s
	action_button.add_theme_font_size_override("font_size", int(17.0 * s))


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
