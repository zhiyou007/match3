extends SceneTree

# 诊断：宝石方块节点/纹理/渲染状态
var main: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var n0 = main.nodes[0][0]
	print("node(0,0): pos=", n0.position, " size=", n0.size, " tex=", n0.texture)
	if n0.texture != null:
		print("tex size=", n0.texture.get_size(), " expand=", n0.expand_mode, " stretch=", n0.stretch_mode)

	var count_visible := 0
	var count_total := 0
	for y in main.grid:
		for x in main.grid:
			var n = main.nodes[y][x]
			count_total += 1
			if n != null and n.visible and n.texture != null:
				count_visible += 1
	print("nodes visible: ", count_visible, "/", count_total)

	var img := root.get_viewport().get_texture().get_image()
	print("px(150,300)=", img.get_pixel(150, 300))
	print("px(360,300)=", img.get_pixel(360, 300))
	print("px(560,300)=", img.get_pixel(560, 300))
	quit(0)
