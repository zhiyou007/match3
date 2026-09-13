extends SceneTree

# 拖动交换测试：按住方块向相邻方向拖动，松手后发生交换
var m: Control


func _init() -> void:
	call_deferred("_run")


func _send_button(pressed: bool, gp: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = gp
	ev.global_position = gp
	m._input(ev)


func _send_motion(gp: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = gp
	ev.global_position = gp
	m._input(ev)


func _run() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	await process_frame

	var steps_before: int = m.steps
	var score_before: int = m.score

	# 找一个必然可交换的方向：先构造 board 使 (0,0) 向右交换产生三连
	# 第 0 列构造 A B A / A，使 (0,1) 与 (1,1) 交换后成列三连
	# 简化：随机找一对（通过 _has_valid_move 验证后直接拖动那一对）
	var found := false
	for y in m.grid:
		for x in m.grid:
			var a := Vector2i(x, y)
			for dir in [Vector2i(1, 0), Vector2i(0, 1)]:
				var b: Vector2i = a + dir
				if b.x >= m.grid or b.y >= m.grid:
					continue
				m._swap_data(a, b)
				var ok: bool = not m._find_matches().is_empty()
				m._swap_data(a, b)
				if ok:
					# 模拟：按住 a，向 dir 方向拖出阈值
					var center: Vector2 = m._cell_pos(a) + Vector2(m.cell / 2.0, m.cell / 2.0)
					var target_pt: Vector2 = center + Vector2(dir) * (m.cell * 0.5)
					_send_button(true, center)
					await process_frame
					_send_motion(target_pt)
					await process_frame
					_send_button(false, target_pt)
					await _wait_swap()
					found = true
					break
			if found:
				break
		if found:
			break

	if found and m.steps == steps_before - 1 and m.score > score_before:
		print("DRAG TEST PASS: swap via drag, score ", score_before, "->", m.score, ", steps ", steps_before, "->", m.steps)
		quit(0)
	elif not found:
		print("DRAG TEST FAIL: no valid move found")
		quit(1)
	else:
		print("DRAG TEST FAIL: steps=", m.steps, " score=", m.score)
		quit(1)


func _wait_swap() -> void:
	# 等待 _try_swap 完成（内部动画链），最多 3 秒
	for i in 180:
		await process_frame
