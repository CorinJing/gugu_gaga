extends Node

## 依次切到第一章各状态并截图，用来肉眼检查构图与热点位置。

func _ready() -> void:
	var scene: Node = load("res://scenes/ch1/ch1.tscn").instantiate()
	add_child(scene)
	await get_tree().create_timer(1.0).timeout
	var dir := ProjectSettings.globalize_path("res://_shots")
	DirAccess.make_dir_recursive_absolute(dir)
	for st in [0, 1, 2, 3, 4]:
		if st == 2:
			GameState.add_item("slip")
			GameState.add_item("thread")
			GameState.add_item("brass_needle")
		scene._set_state(st)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/ch1_%d.png" % [dir, st])
		print("shot ", st)
	get_tree().quit()
