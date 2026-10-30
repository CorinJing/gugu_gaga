extends Control

signal hint_requested(text: String)
signal finished

@onready var hat_shadow: Polygon2D = %HatShadow
@onready var hand_shadow: Polygon2D = %HandShadow
@onready var feet_shadow: Polygon2D = %FeetShadow
@onready var door_outline: Line2D = %DoorOutline
@onready var door_glow: ColorRect = %DoorGlow
@onready var solved_label: Label = %SolvedLabel
@onready var umbrella_hotspot: Control = %UmbrellaHotspot
@onready var flag_hotspot: Control = %FlagHotspot
@onready var mat_hotspot: Control = %MatHotspot
@onready var postcard_hotspot: Control = %PostcardHotspot
@onready var door_hotspot: Control = %DoorHotspot

var umbrella_index := 0
var mat_index := 0
var flag_up := false
var solved := false
var _intro_shown := false

const HAT_X := [460.0, 495.0, 530.0]
const FEET_X := [455.0, 490.0, 525.0]
const TARGET_UMBRELLA := 1
const TARGET_MAT := 1


func _ready() -> void:
	umbrella_hotspot.gui_input.connect(_on_umbrella_input)
	flag_hotspot.gui_input.connect(_on_flag_input)
	mat_hotspot.gui_input.connect(_on_mat_input)
	postcard_hotspot.gui_input.connect(_on_postcard_input)
	door_hotspot.gui_input.connect(_on_door_input)
	_refresh()


func show_intro() -> void:
	if _intro_shown:
		return
	_intro_shown = true
	hint_requested.emit("旧明信片：伞影是帽子，信箱旗是手，门垫是脚。让三段影子填满门上的铜线。")


func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed


func _on_umbrella_input(event: InputEvent) -> void:
	if not _is_left_click(event) or solved:
		return
	umbrella_index = (umbrella_index + 1) % 3
	_refresh()


func _on_mat_input(event: InputEvent) -> void:
	if not _is_left_click(event) or solved:
		return
	mat_index = (mat_index + 1) % 3
	_refresh()


func _on_flag_input(event: InputEvent) -> void:
	if not _is_left_click(event) or solved:
		return
	flag_up = not flag_up
	_refresh()


func _on_postcard_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	hint_requested.emit("旧明信片：灯照到门口。伞的影子是帽子，信箱旗是手，门垫是脚。让三段影子填满门上的铜线。")


func _on_door_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if solved:
		finished.emit()
	else:
		hint_requested.emit("门上的窥视孔向下看了看，又合上了。它在等一个影子。")


func _refresh() -> void:
	hat_shadow.position = Vector2(HAT_X[umbrella_index], 300.0)
	hand_shadow.position = Vector2(540.0 if flag_up else 590.0, 390.0)
	feet_shadow.position = Vector2(FEET_X[mat_index], 500.0)

	solved = umbrella_index == TARGET_UMBRELLA and mat_index == TARGET_MAT and flag_up
	door_outline.modulate = Color(1.0, 0.78, 0.45, 1.0) if solved else Color(0.72, 0.62, 0.42, 0.55)
	door_glow.visible = solved
	solved_label.visible = solved
	if solved:
		solved_label.text = "门开了。点击门进入。"
