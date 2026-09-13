extends SceneTree

# 修复验证：过关后结算面板应完整覆盖棋盘（白色背景 + 绿色/橙色按钮 + 标题/星级）
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
	await process_frame

	var img := root.get_viewport().get_texture().get_image()

	# 面板区域统计（应大部分为白色 255,255,255）
	var white := 0
	var colored := 0
	var total := 0
	for y in range(225, 615, 5):
		for x in range(125, 595, 5):
			var p: Color = img.get_pixel(x, y)
			total += 1
			if p.r > 0.92 and p.g > 0.92 and p.b > 0.92:
				white += 1
			elif not (p.g > 0.6 and p.r < 0.6 and p.b < 0.65) and not (p.r > 0.85 and p.g > 0.6 and p.b < 0.5):
				colored += 1
	print("PANEL white=", white, " colored=", colored, " total=", total, " white%=", int(white * 100.0 / total))

	# 按钮颜色
	var b1: Color = img.get_pixelv(Vector2i(360, 499))
	var b2: Color = img.get_pixelv(Vector2i(360, 569))
	print("BTN primary=", b1, " secondary=", b2)

	# 标题文字区有绿色（"过关！"）
	var title_green := 0
	for y in range(245, 305):
		for x in range(280, 440):
			var p: Color = img.get_pixel(x, y)
			if p.g > 0.75 and p.r < 0.8 and p.b < 0.8:
				title_green += 1
	print("TITLE green px=", title_green)

	# 星级黄色
	var star_yellow := 0
	for y in range(315, 375):
		for x in range(200, 520):
			var p: Color = img.get_pixel(x, y)
			if p.r > 0.85 and p.g > 0.75 and p.b < 0.45:
				star_yellow += 1
	print("STARS yellow px=", star_yellow)

	# 保存整图供人工确认
	img.save_png("C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/screenshots/06_win_fixed.png")

	if white * 100 / total > 60 and b1.g > 0.65 and b2.r > 0.85 and title_green > 100 and star_yellow > 100:
		print("PANEL FIX VERIFIED")
		quit(0)
	else:
		print("PANEL FIX FAILED")
		quit(1)
