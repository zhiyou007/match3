extends SceneTree

# 方向判定专项：点击宝石内偏上位置，向右拖动（较短距离），必须向右交换
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

	var c := Vector2i(-1, -1)
	var dir := Vector2i.ZERO
	# 找一个有效交换对（交换后可消除）
	for y in m.grid:
		for x in m.grid:
			var a := Vector2i(x, y)
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				var b: Vector2i = a + d
				if b.x >= m.grid or b.y >= m.grid:
					continue
				m._swap_data(a, b)
				var ok: bool = not m._find_matches().is_empty()
				m._swap_data(a, b)
				if ok:
					c = a
					dir = d
					break
			if c.x >= 0:
				break
		if c.x >= 0:
			break
	if c.x < 0:
		print("DRAG DIR TEST FAIL: no valid move")
		quit(1)

	# 按下点：宝石中心偏上 25px（仍在宝石内）——模拟"没点中心"
	var center: Vector2 = m._cell_pos(c) + Vector2(32, 32)
	var press_pt := center + Vector2(0, -25)
	# 向 dir 方向拖动 20px（短距离 + 点偏，旧逻辑会误判方向）
	var drag_pt := press_pt + Vector2(dir) * 20.0

	var before: Array = []
	for y in m.grid:
		var row: Array = []
		for x in m.grid:
			row.append(m.board[y][x])
		before.append(row)
	var steps_before: int = m.steps

	_send_button(true, press_pt)
	await process_frame
	_send_motion(drag_pt)
	await process_frame
	await process_frame
	# 此时 _try_swap 已同步交换 board 数据，正在等待交换动画（~0.12s），消除尚未发生
	var target: Vector2i = c + dir
	var swapped_correct: bool = m.board[c.y][c.x] == before[target.y][target.x] and m.board[target.y][target.x] == before[c.y][c.x]
	print("c=", c, " dir=", dir, " swapped_correct=", swapped_correct)
	_send_button(false, drag_pt)
	for i in 180:
		await process_frame

	# 最终还应消耗一步且有得分（方向正确 → 产生消除）
	if swapped_correct and m.steps == steps_before - 1 and m.score > 0:
		print("DRAG DIR TEST PASS: click-off-center + short drag => correct direction, score=", m.score)
		quit(0)
	else:
		print("DRAG DIR TEST FAIL: steps=", m.steps, " score=", m.score)
		quit(1)
