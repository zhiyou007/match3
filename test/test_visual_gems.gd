extends SceneTree

# 视觉验证：宝石方块渲染 + 5连消除特效（闪光+粒子）
var main: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	# 1. 开局棋盘（宝石）
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/screenshots/10_board_gems.png")
	print("board saved")

	# 2. 构造 5 连并触发消除特效（不等待完成，截闪光瞬间）
	for x in 5:
		main.board[0][x] = 0
	var cells: Array = []
	for x in 5:
		cells.append(Vector2i(x, 0))
	main._animate_clear(cells)
	await process_frame
	await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png("C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/screenshots/11_five_match_fx.png")
	print("fx saved")

	# 3. 等动画完成后再截一张（确认无残留）
	await create_timer(0.8).timeout
	img = root.get_viewport().get_texture().get_image()
	img.save_png("C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/screenshots/12_after_clear.png")
	print("after saved")
	quit(0)
