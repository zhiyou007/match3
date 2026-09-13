extends SceneTree

# 验证：开局/重开时结算文字全部隐藏，过关/失败时显示；点重新挑战后无残留
var main: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	# 1. 开局：三个文字标签应全部隐藏
	var ok := true
	ok = ok and not main.result_title.visible
	ok = ok and not main.result_stars.visible
	ok = ok and not main.result_detail.visible
	ok = ok and not main.overlay.visible
	ok = ok and not main.result_panel.visible
	print("1. OPENING hidden: ", ok, " (title=", main.result_title.visible, " stars=", main.result_stars.visible, " detail=", main.result_detail.visible, ")")

	# 2. 过关：全部显示
	main.score = 700
	main._win_level()
	await process_frame
	ok = main.result_title.visible and main.result_stars.visible and main.result_detail.visible
	ok = ok and main.overlay.visible and main.result_panel.visible and main.btn_primary.visible and main.btn_secondary.visible
	print("2. WIN shown: ", ok, " title=", main.result_title.text, " stars=", main.result_stars.text)

	# 3. 点"重新挑战"（_on_secondary，is_win=true → _on_restart）
	main._on_secondary()
	await process_frame
	await process_frame
	ok = not main.result_title.visible and not main.result_stars.visible and not main.result_detail.visible
	ok = ok and not main.overlay.visible and not main.result_panel.visible
	ok = ok and not main.btn_primary.visible and not main.btn_secondary.visible
	ok = ok and main.score == 0 and main.steps == main.max_steps
	print("3. RESTART cleared: ", ok, " score=", main.score, " steps=", main.steps, " title.visible=", main.result_title.visible)

	# 4. 再过关：再次显示
	main.score = 800
	main._win_level()
	await process_frame
	ok = main.result_title.visible and main.result_stars.visible and main.result_detail.visible
	print("4. WIN again shown: ", ok, " title=", main.result_title.text)

	# 5. 失败 → 再试一次（_on_primary，is_win=false → _on_restart）
	main._lose_level()
	await process_frame
	ok = main.result_title.visible and main.result_stars.visible
	print("5. LOSE shown: ", ok, " title=", main.result_title.text)
	main._on_primary()
	await process_frame
	await process_frame
	ok = not main.result_title.visible and not main.result_stars.visible and not main.result_detail.visible
	ok = ok and main.score == 0 and main.steps == main.max_steps
	print("6. RETRY cleared: ", ok)

	# 保存重开后截图确认无残留文字
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/screenshots/09_restart_clean.png")

	if ok and main.result_title.visible == false:
		print("RESTART FIX VERIFIED")
		quit(0)
	else:
		print("RESTART FIX FAILED")
		quit(1)
