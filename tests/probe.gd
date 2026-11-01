extends Node

func _ready() -> void:
	var scene: Node = load("res://scenes/ch1/ch1.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	var fg: TextureRect = scene.desk_fg
	var ch: TextureRect = scene.character
	print("fg visible=", fg.visible, " idx=", fg.get_index(), " size=", fg.size,
		" tex=", fg.texture, " mod=", fg.modulate)
	print("ch visible=", ch.visible, " idx=", ch.get_index(), " size=", ch.size,
		" tex=", ch.texture)
	print("stage children=", scene.stage.get_children().map(func(n): return n.name))
	get_tree().quit()
