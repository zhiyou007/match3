extends SceneTree

# 并发输入专项：消除动画进行中立即再入队一次操作，验证不锁输入、依次执行、棋盘干净
var m: Control


func _init() -> void:
	call_deferred("_run")


func _find_valid_pair() -> Array:
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
					return [a, d]
	return []


func _drag_pair(pair: Array) -> void:
	var a: Vector2i = pair[0]
	var d: Vector2i = pair[1]
	var center: Vector2 = m._cell_pos(a) + Vector2(32, 32)
	var target_pt: Vector2 = center + Vector2(d) * 30.0
	var ev1 := InputEventMouseButton.new()
	ev1.button_index = MOUSE_BUTTON_LEFT
	ev1.pressed = true
	ev1.position = center
	ev1.global_position = center
	m._input(ev1)
	var ev2 := InputEventMouseMotion.new()
	ev2.position = target_pt
	ev2.global_position = target_pt
	m._input(ev2)


func _run() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	await process_frame

	var p1 := _find_valid_pair()
	var p2 := _find_valid_pair()
	if p1.is_empty() or p2.is_empty():
		print("QUEUE TEST FAIL: no valid moves")
		quit(1)
	var steps_before: int = m.steps

	_drag_pair(p1)
	await process_frame
	await process_frame
	# 此时第一个交换动画应正在播放（队列运行中），输入不能被锁
	if not m._swap_chain_running:
		print("QUEUE TEST FAIL: chain not running after first drag")
		quit(1)
	# 立即第二个操作
	_drag_pair(p2)
	var queued: bool = m._pending_swaps.size() > 0 or m._swap_chain_running
	print("after 2nd drag: queue=", m._pending_swaps.size(), " chain=", m._swap_chain_running)

	# 等待队列全部完成
	var waited := 0
	while m._swap_chain_running or not m._pending_swaps.is_empty():
		await process_frame
		waited += 1
		if waited > 900:
			print("QUEUE TEST FAIL: stuck")
			quit(1)

	# 验证：至少第一步有效（第二步入队时棋盘已变化，可能变为无效交换=正常回退）、
	# 两次操作均执行完毕不卡死、棋盘干净无残留匹配
	var steps_used: int = steps_before - m.steps
	var leftover: Array = m._find_matches()
	var mismatch := false
	for y in m.grid:
		for x in m.grid:
			var idx: int = m.board[y][x]
			var node: TextureRect = m.nodes[y][x]
			if (node == null and idx >= 0) or (node != null and idx < 0) or (node != null and node.texture != m._gem_textures[idx]):
				mismatch = true
	if steps_used >= 1 and leftover.is_empty() and not mismatch and queued:
		print("QUEUE TEST PASS: input not locked, 2 ops queued & finished, board clean (steps_used=", steps_used, ")")
		quit(0)
	else:
		print("QUEUE TEST FAIL: steps_used=", steps_used, " leftover=", leftover.size(), " mismatch=", mismatch, " queued=", queued)
		quit(1)
