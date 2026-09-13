extends SceneTree

# 像素级验收：按钮颜色 / 星级 / 棋盘边界
var main: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.score = 400
	main._win_level()
	await process_frame
	await process_frame
	await process_frame

	var img := root.get_viewport().get_texture().get_image()

	# 结算按钮颜色（美化后应为绿色/橙色）
	var b1: Color = img.get_pixelv(Vector2i(360, 500))
	var b2: Color = img.get_pixelv(Vector2i(360, 570))
	print("PX primary_btn rgb=(", int(b1.r * 255), ",", int(b1.g * 255), ",", int(b1.b * 255), ")")
	print("PX secondary_btn rgb=(", int(b2.r * 255), ",", int(b2.g * 255), ",", int(b2.b * 255), ")")

	# 星级行扫描：y=345 附近找黄色像素（#ffd93d）
	var found_yellow := false
	for x in range(150, 570, 2):
		var p: Color = img.get_pixel(x, 345)
		if p.r > 0.85 and p.g > 0.75 and p.b < 0.45:
			found_yellow = true
			break
	print("PX stars yellow found: ", found_yellow)

	# 棋盘边界：第 1 关 8x8，origin=(104,150)，右边界 x=616
	var o := Vector2i(104, 150)
	var in_board: Color = img.get_pixelv(o + Vector2i(10, 10))
	var right_edge: Color = img.get_pixelv(Vector2i(615, 160))
	var out_right: Color = img.get_pixelv(Vector2i(625, 160))
	print("PX board(104,150)=", in_board)
	print("PX x=615 (edge)=", right_edge)
	print("PX x=625 (outside)=", out_right, " bg should be #f7f4ef")
	quit(0)
