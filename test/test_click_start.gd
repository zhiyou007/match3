extends SceneTree

# 真实路径复现：菜单 → 点击"开始游戏" → 是否卡死

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	change_scene_to_file("res://scenes/menu.tscn")
	await process_frame
	await create_timer(1.5).timeout
	var cs0: Node = current_scene
	print("current_scene=", cs0.name if cs0 else "null")
	var start_btn: Button = null
	if cs0 != null:
		for c in cs0.get_children():
			if c is Button and (c as Button).text == "开始游戏":
				start_btn = c as Button
	print("start btn found: ", start_btn != null)
	if start_btn != null:
		start_btn.pressed.emit()
	await create_timer(3.0).timeout
	var cs: Node = current_scene
	var ok: bool = cs != null and cs.has_method("_build_cards")
	print("after click current_scene=", cs.name if cs else "null")
	print("SWITCH RESULT: ", "OK" if ok else "STUCK/FAIL")
	quit()
