extends SceneTree

# 复现：主菜单点击"开始游戏"（_go_level_select）→ 场景切换是否卡死

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var menu_scn: PackedScene = load("res://scenes/menu.tscn")
	var m: Control = menu_scn.instantiate()
	root.add_child(m)
	root.current_scene = m
	await process_frame
	await create_timer(1.0).timeout
	print("menu ready, switching scene...")
	m._go_level_select()
	await create_timer(3.0).timeout
	var found := false
	for c in root.get_children():
		if c != null and c.has_method("_build_cards"):
			found = true
			print("LEVEL SELECT loaded: name=", c.name)
	print("switch OK: ", found)
	quit()
