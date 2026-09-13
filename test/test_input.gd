extends SceneTree

# 输入模拟：注入一次鼠标左键点击，验证棋盘选中生效
var m: Control


func _init() -> void:
	call_deferred("_run")


func _setup_autoloads() -> void:
	# autoload 已在 --script 模式下注册，无需手动创建
	pass


func _run() -> void:
	_setup_autoloads()
	var main_script: GDScript = load("res://scripts/main.gd")
	m = main_script.new()
	root.add_child(m)
	await process_frame

	var pos: Vector2 = m._grid_origin() + Vector2(32, 32)  # (0,0) 格子中心
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = pos
	ev.global_position = pos
	m._input(ev)  # 按下
	var ev2 := InputEventMouseButton.new()
	ev2.button_index = MOUSE_BUTTON_LEFT
	ev2.pressed = false
	ev2.position = pos
	ev2.global_position = pos
	m._input(ev2)  # 松开（完整点击）
	await process_frame

	if m.selected == Vector2i(0, 0):
		print("INPUT TEST PASS: click selected (0,0)")
		quit(0)
	else:
		print("INPUT TEST FAIL: selected=", m.selected)
		quit(1)
