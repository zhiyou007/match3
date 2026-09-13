extends SceneTree

# 道具功能测试：提示/重排/加步，次数管理
var m: Control


func _init() -> void:
	call_deferred("_run")


func _snapshot() -> Array:
	var s: Array = []
	for y in m.grid:
		var row: Array = []
		for x in m.grid:
			row.append(m.board[y][x])
		s.append(row)
	return s


func _run() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	await process_frame

	# 1. 初始次数
	if m.hints_left == 3 and m.shuffles_left == 2 and m.steps_add_left == 1:
		print("1. item counts init: PASS")
	else:
		print("1. FAIL: ", m.hints_left, m.shuffles_left, m.steps_add_left)
		quit(1)

	# 2. 提示：次数递减 + 找到高亮对（scale 变化）
	var before: int = m.hints_left
	await m._use_hint()
	if m.hints_left == before - 1 and m.busy == false:
		print("2. hint used: PASS (left=", m.hints_left, ")")
	else:
		print("2. FAIL: left=", m.hints_left, " busy=", m.busy)
		quit(1)

	# 3. 重排：棋盘变化 + 次数递减
	var snap := _snapshot()
	var s_before: int = m.shuffles_left
	m._use_shuffle()
	await process_frame
	await process_frame
	var changed := false
	for y in m.grid:
		for x in m.grid:
			if snap[y][x] != m.board[y][x]:
				changed = true
	if m.shuffles_left == s_before - 1 and changed:
		print("3. shuffle works: PASS (left=", m.shuffles_left, ")")
	else:
		print("3. FAIL: left=", m.shuffles_left, " changed=", changed)
		quit(1)

	# 4. 加步：steps +5
	var st_before: int = m.steps
	m._use_add_steps()
	if m.steps == st_before + 5 and m.steps_add_left == 0:
		print("4. add steps: PASS (", st_before, "->", m.steps, ")")
	else:
		print("4. FAIL")
		quit(1)

	# 5. 耗尽后无效
	m.hints_left = 0
	var h2: int = m.hints_left
	m._use_hint()
	await process_frame
	await process_frame
	if m.hints_left == h2 and m.busy == false:
		print("5. exhausted hint ignored: PASS")
	else:
		print("5. FAIL: left=", m.hints_left, " busy=", m.busy)
		quit(1)

	print("ALL ITEM TESTS PASSED")
	quit(0)
