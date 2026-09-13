extends SceneTree

# 验证：开局时结算白色底板隐藏（棋盘完整），过关时显示（面板白色覆盖棋盘中央）
var main: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	# --- 开局状态 ---
	var img1 := root.get_viewport().get_texture().get_image()
	var white1 := 0
	var total1 := 0
	# 棋盘中央区域（如果白底板常驻，这里会是纯白）
	for y in range(300, 400):
		for x in range(200, 500):
			var p: Color = img1.get_pixel(x, y)
			total1 += 1
			if p.r > 0.92 and p.g > 0.92 and p.b > 0.92:
				white1 += 1
	print("OPENING: white%=", int(white1 * 100.0 / total1), " (should be LOW, board visible)")
	img1.save_png("C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/screenshots/07_open_fixed.png")

	# --- 过关状态 ---
	main.score = 400
	main._win_level()
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var img2 := root.get_viewport().get_texture().get_image()
	var white2 := 0
	var total2 := 0
	for y in range(225, 615, 3):
		for x in range(125, 595, 3):
			var p: Color = img2.get_pixel(x, y)
			total2 += 1
			if p.r > 0.92 and p.g > 0.92 and p.b > 0.92:
				white2 += 1
	print("WIN: white%=", int(white2 * 100.0 / total2), " (should be HIGH, panel shown)")
	img2.save_png("C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/screenshots/08_win_fixed2.png")

	if white1 * 100 / total1 < 40 and white2 * 100 / total2 > 60:
		print("PANEL VISIBILITY VERIFIED")
		quit(0)
	else:
		print("PANEL VISIBILITY FAILED")
		quit(1)
