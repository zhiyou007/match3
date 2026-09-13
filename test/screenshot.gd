extends SceneTree

# 渲染截图验收：依次加载各场景并保存 PNG（用于 UI 视觉检查）
# 运行方式：godot --path 项目 --script res://test/screenshot.gd（窗口模式，不用 --headless）

const OUT_DIR := "C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/screenshots"


func _init() -> void:
	call_deferred("_run")


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	var ok := img.save_png(OUT_DIR + "/" + name + ".png")
	print("shot ", name, " ok=", ok)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	# 1. 主菜单
	var menu = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await _shot("01_menu")
	menu.queue_free()

	# 2. 选关
	var ls = load("res://scenes/level_select.tscn").instantiate()
	root.add_child(ls)
	await _shot("02_level_select")
	ls.queue_free()

	# 3. 游戏第 1 关
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _shot("03_main")
	main.queue_free()

	# 4. 第 4 关（9x9 大棋盘，验证居中）
	var gs := root.get_node("GameState")
	gs.current_level = 4
	var main4 = load("res://scenes/main.tscn").instantiate()
	root.add_child(main4)
	await _shot("04_level4_9x9")
	main4.queue_free()

	# 5. 过关结算面板
	gs.current_level = 1
	var main5 = load("res://scenes/main.tscn").instantiate()
	root.add_child(main5)
	main5.score = 400
	main5._win_level()
	await _shot("05_win_panel")
	main5.queue_free()

	quit(0)
