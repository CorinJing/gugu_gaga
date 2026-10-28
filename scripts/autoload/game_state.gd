extends Node

## Minimal state container for the vertical slice.
## Keep flags and inventory here so scenes can stay dumb.

var flags: Dictionary = {}
var inventory: Array[String] = []


func reset() -> void:
	flags.clear()
	inventory.clear()


func set_flag(id: String, value: bool = true) -> void:
	flags[id] = value


func has_flag(id: String) -> bool:
	return bool(flags.get(id, false))


func add_item(id: String) -> void:
	if not inventory.has(id):
		inventory.append(id)
