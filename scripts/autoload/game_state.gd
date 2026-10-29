extends Node

## Minimal state container for the prologue vertical slice.

signal inventory_changed
signal flag_changed(id: String, value: bool)

const ITEM_NAMES := {
	"knife": "小折刀",
	"fish": "死鱼",
	"coin": "旧硬币",
	"pocket_watch": "怀表",
	"door_handle": "白鹭把手",
	"crank": "黄铜摇柄",
	"brass_key": "黄铜钥匙",
}

const SLOT_COUNT := 5

var flags: Dictionary = {}
var slots: Array[String] = ["", "", "", "", ""]
var next_slot := 0

var inventory: Array[String]:
	get:
		var out: Array[String] = []
		for id in slots:
			if not id.is_empty():
				out.append(id)
		return out


func reset() -> void:
	flags.clear()
	slots = ["", "", "", "", ""]
	next_slot = 0
	inventory_changed.emit()


func set_flag(id: String, value: bool = true) -> void:
	flags[id] = value
	flag_changed.emit(id, value)


func has_flag(id: String) -> bool:
	return bool(flags.get(id, false))


func add_item(id: String) -> void:
	if has_item(id):
		return
	var index := next_slot
	if index >= SLOT_COUNT:
		index = slots.find("")
	if index < 0 or index >= SLOT_COUNT:
		return
	slots[index] = id
	next_slot = maxi(next_slot, index + 1)
	inventory_changed.emit()


func remove_item(id: String) -> void:
	var index := slots.find(id)
	if index >= 0:
		slots[index] = ""
		inventory_changed.emit()


func has_item(id: String) -> bool:
	return slots.has(id)


func item_name(id: String) -> String:
	return str(ITEM_NAMES.get(id, id))
