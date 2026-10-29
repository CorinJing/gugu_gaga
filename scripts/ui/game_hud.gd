extends Control

signal action_pressed

@onready var inventory_label: Label = %InventoryLabel
@onready var prompt_label: Label = %PromptLabel
@onready var action_button: Button = %ActionButton
@onready var location_label: Label = %LocationLabel
@onready var sidebar: ColorRect = $Sidebar
@onready var sidebar_title: Label = $SidebarTitle
@onready var sidebar_line: ColorRect = $SidebarLine
@onready var location_bg: ColorRect = $LocationBg
@onready var prompt_bg: ColorRect = $PromptBg
@onready var corner_mask: ColorRect = $CornerMask


func _ready() -> void:
	GameState.inventory_changed.connect(_refresh_inventory)
	action_button.pressed.connect(func() -> void: action_pressed.emit())
	_refresh_inventory()


func set_location(text: String) -> void:
	location_label.text = text


func set_prompt(text: String) -> void:
	prompt_label.text = text


func set_action(text: String) -> void:
	action_button.text = text
	action_button.visible = not text.is_empty()


func hide_action() -> void:
	action_button.visible = false


func _refresh_inventory() -> void:
	if GameState.inventory.is_empty():
		inventory_label.text = "空"
		return
	var lines: Array[String] = []
	for id in GameState.inventory:
		lines.append("· " + GameState.item_name(id))
	inventory_label.text = "\n".join(lines)


func apply_layout(stage_rect: Rect2, viewport_size: Vector2, sidebar_rect: Rect2) -> void:
	var s: float = clampf(stage_rect.size.y / 720.0, 0.62, 2.2)
	sidebar.position = sidebar_rect.position
	sidebar.size = sidebar_rect.size

	var top_mode := sidebar_rect.position.y <= 1.0 and sidebar_rect.size.y < viewport_size.y * 0.3
	var bottom_mode := (not top_mode) and sidebar_rect.size.y < viewport_size.y * 0.8
	var sx := sidebar_rect.position.x
	var sy := sidebar_rect.position.y
	var sw := sidebar_rect.size.x
	var sh := sidebar_rect.size.y

	if top_mode:
		var uis: float = clampf(sh / 80.0, 0.8, 1.3)
		sidebar_title.position = Vector2(sx + 24.0, sy + 12.0)
		sidebar_title.size = Vector2(110.0 * uis, 32.0 * uis)
		sidebar_title.add_theme_font_size_override("font_size", int(20.0 * uis))
		sidebar_line.position = Vector2(sx + 150.0 * uis, sy + 13.0 * uis)
		sidebar_line.size = Vector2(1.0, sh - 26.0 * uis)
		inventory_label.position = Vector2(sx + 170.0 * uis, sy + 12.0 * uis)
		inventory_label.size = Vector2(sw - 190.0 * uis, sh - 20.0 * uis)
		inventory_label.add_theme_font_size_override("font_size", int(14.0 * uis))
	elif bottom_mode:
		var uis: float = clampf(sh / 180.0, 0.72, 1.35)
		sidebar_title.position = Vector2(sx + 24.0, sy + 12.0)
		sidebar_title.size = Vector2(sw - 48.0, 34.0 * uis)
		sidebar_title.add_theme_font_size_override("font_size", int(21.0 * uis))
		sidebar_line.position = Vector2(sx + 24.0, sy + 52.0)
		sidebar_line.size = Vector2(sw - 48.0, 1.0)
		inventory_label.position = Vector2(sx + 24.0, sy + 62.0)
		inventory_label.size = Vector2(sw - 48.0, sh - 70.0)
		inventory_label.add_theme_font_size_override("font_size", int(14.0 * uis))
	else:
		var uis: float = clampf(sw / 320.0, 0.78, 1.5)
		sidebar_title.position = Vector2(sx + 30.0 * uis, sy + 38.0 * uis)
		sidebar_title.size = Vector2(sw - 60.0 * uis, 40.0 * uis)
		sidebar_title.add_theme_font_size_override("font_size", int(23.0 * uis))
		sidebar_line.position = Vector2(sx + 30.0 * uis, sy + 92.0 * uis)
		sidebar_line.size = Vector2(sw - 60.0 * uis, 1.0)
		inventory_label.position = Vector2(sx + 30.0 * uis, sy + 112.0 * uis)
		inventory_label.size = Vector2(sw - 60.0 * uis, sh - 140.0 * uis)
		inventory_label.add_theme_font_size_override("font_size", int(15.0 * uis))

	var loc_y := sidebar_rect.end.y + 12.0 if top_mode else stage_rect.position.y + 16.0 * s
	location_bg.position = Vector2(stage_rect.position.x + 28.0 * s, loc_y)
	location_bg.size = Vector2(272.0, 42.0) * s
	location_label.position = Vector2(stage_rect.position.x + 40.0 * s, loc_y + 8.0 * s)
	location_label.size = Vector2(250.0, 32.0) * s
	location_label.add_theme_font_size_override("font_size", int(16.0 * s))

	prompt_bg.position = stage_rect.position + Vector2(32.0, 640.0) * s
	prompt_bg.size = Vector2(896.0, 52.0) * s
	prompt_label.position = stage_rect.position + Vector2(48.0, 650.0) * s
	prompt_label.size = Vector2(864.0, 34.0) * s
	prompt_label.add_theme_font_size_override("font_size", int(18.0 * s))

	action_button.position = stage_rect.position + Vector2(780.0, 580.0) * s
	action_button.size = Vector2(148.0, 48.0) * s
	action_button.add_theme_font_size_override("font_size", int(17.0 * s))

	# Keep this corner cover on the actual stage edge, never on a hard-coded 1280x720 spot.
	corner_mask.position = stage_rect.position + Vector2(900.0, 680.0) * s
	corner_mask.size = Vector2(60.0, 40.0) * s
