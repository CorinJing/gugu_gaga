extends Node

## Minimal state container for the prologue vertical slice.

signal inventory_changed
signal flag_changed(id: String, value: bool)

const ITEM_NAMES := {
	"knife": "小折刀",
	"coin": "旧硬币",
	"pocket_watch": "怀表",
	"door_handle": "白鹭把手",
	"crank": "黄铜摇柄",
	"brass_key": "黄铜钥匙",
}

var flags: Dictionary = {}
var inventory: Array[String] = []


func reset() -> void:
	flags.clear()
	inventory.clear()
	inventory_changed.emit()


func set_flag(id: String, value: bool = true) -> void:
	flags[id] = value
	flag_changed.emit(id, value)


func has_flag(id: String) -> bool:
	return bool(flags.get(id, false))


func add_item(id: String) -> void:
	if not inventory.has(id):
		inventory.append(id)
		inventory_changed.emit()


func remove_item(id: String) -> void:
	if inventory.has(id):
		inventory.erase(id)
		inventory_changed.emit()


func has_item(id: String) -> bool:
	return inventory.has(id)


func item_name(id: String) -> String:
	return str(ITEM_NAMES.get(id, id))
