extends Node

## 第一章流程自测：不点鼠标，直接调用输入回调，检查 flag / 道具。
## 运行：godot --headless --path . res://tests/test_ch1.tscn

var fails := 0


func _evt() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e


func _check(name: String, cond: bool) -> void:
	if cond:
		print("  PASS  ", name)
	else:
		fails += 1
		print("  FAIL  ", name)


func _ready() -> void:
	await get_tree().process_frame
	print("== chapter1 selftest ==")
	var scene: Node = load("res://scenes/ch1/ch1.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame

	_check("初始在 LOBBY", scene.state == 0)

	scene._on_waiter_input(_evt())
	_check("第一次对话 waiter_greeted", GameState.has_flag("waiter_greeted"))

	scene._on_register_input(_evt())
	_check("点登记簿拿到服务单", GameState.has_item("slip"))

	scene._on_stairs_input(_evt())
	_check("上楼到 HALL", scene.state == 1)

	scene._on_door113_input(_evt())
	_check("进入 ROOM", scene.state == 2)

	scene._on_box_input(_evt())
	_check("针线盒给出红线", GameState.has_item("thread"))

	var center: Vector2 = scene.machine_hotspot.get_global_rect().get_center()
	scene._on_item_dropped("thread", 0, center)
	_check("拖线到针上成功", GameState.has_flag("thread_done"))
	_check("红线被消耗", not GameState.has_item("thread"))

	scene._on_box_input(_evt())
	_check("拿到黄铜针", GameState.has_item("brass_needle"))

	scene._on_room_door_input(_evt())
	_check("离开房间回大堂", scene.state == 3)

	scene._on_leave_input(_evt())
	_check("章节结束卡", scene.state == 4)

	print("== done, fails=%d ==" % fails)
	get_tree().quit(0 if fails == 0 else 1)
