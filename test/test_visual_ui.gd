extends SceneTree

# UI 游戏化重构截图验收（窗口模式运行；headless 会挂起）
# 依次加载 主菜单 / 选关 / 游戏主界面 / 结算面板 并截图到 res://screenshots/

var shot_dir := "res://screenshots"
var step := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _snap_scene("res://scenes/menu.tscn", "15_ui_menu.png")
	await _snap_scene("res://scenes/level_select.tscn", "16_ui_levels.png")
	await _snap_scene("res://scenes/main.tscn", "17_ui_main.png")
	await _win_panel()
	print("UI SNAPSHOTS DONE")
	quit()


func _snap_scene(path: String, fname: String) -> void:
	var scn: PackedScene = load(path)
	root.add_child(scn.instantiate())
	await process_frame
	await process_frame
	await create_timer(0.6).timeout
	_save(fname)
	for c in root.get_children():
		if c is Control:
			c.queue_free()
	await process_frame


func _win_panel() -> void:
	var scn: PackedScene = load("res://scenes/main.tscn")
	var m: Control = scn.instantiate()
	root.add_child(m)
	await process_frame
	await create_timer(0.6).timeout
	if m.has_method("_win_level"):
		m._win_level()
	await process_frame
	await create_timer(0.5).timeout
	_save("18_ui_win.png")
	for c in root.get_children():
		if c is Control:
			c.queue_free()


func _save(fname: String) -> void:
	var img := root.get_texture().get_image()
	var err := img.save_png(shot_dir + "/" + fname)
	print("saved ", fname, " err=", err)
