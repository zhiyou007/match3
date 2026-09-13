extends SceneTree

# 核心逻辑自测：匹配检测 + 重力下落 + 合法移动
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

	var failures := 0
	var g: int = m.grid

	# TEST 1: 全 1 棋盘 -> 每行全连，共 g*g 格匹配
	m.board = []
	for y in g:
		var row: Array = []
		for x in g:
			row.append(1)
		m.board.append(row)
	var matches: Array = m._find_matches()
	if matches.size() == g * g:
		print("TEST1 PASS: full-board match = ", matches.size())
	else:
		print("TEST1 FAIL: expected ", g * g, ", got ", matches.size())
		failures += 1

	# TEST 2: 第 0 列全 5 -> 列向 g 连，应标记 g 格
	m.board = []
	for y in g:
		var row: Array = []
		for x in g:
			row.append(5 if x == 0 else (y + x) % 7 + 1)
		m.board.append(row)
	matches = m._find_matches()
	if matches.size() == g:
		print("TEST2 PASS: column match = ", matches.size())
	else:
		print("TEST2 FAIL: expected ", g, ", got ", matches.size())
		failures += 1

	# TEST 3: 交错棋盘（无连续 3 同色）-> 0 匹配
	m.board = []
	for y in g:
		var row: Array = []
		for x in g:
			row.append((x + y) % 6)
		m.board.append(row)
	matches = m._find_matches()
	if matches.size() == 0:
		print("TEST3 PASS: no-match board = 0")
	else:
		print("TEST3 FAIL: expected 0, got ", matches.size())
		failures += 1

	# TEST 4: 重力下落——制造空洞后应填满且底部实心
	m._start_game()
	m.board[g - 1][0] = -1
	m.nodes[g - 1][0] = null
	m.board[g - 3][3] = -1
	m.nodes[g - 3][3] = null
	await m._apply_gravity()
	var gravity_ok := true
	for x in g:
		var seen_hole := false
		for y in range(g - 1, -1, -1):
			if m.board[y][x] == -1:
				seen_hole = true
			elif seen_hole:
				gravity_ok = false
	if gravity_ok:
		print("TEST4 PASS: gravity filled all holes, bottom solid")
	else:
		print("TEST4 FAIL: hole left above a block")
		failures += 1

	# TEST 5: 合法移动检测——全同色棋盘必有合法移动
	m.board = []
	for y in g:
		var row: Array = []
		for x in g:
			row.append(0)
		m.board.append(row)
	if m._has_valid_move():
		print("TEST5 PASS: valid move detected")
	else:
		print("TEST5 FAIL: should have valid move")
		failures += 1

	if failures == 0:
		print("ALL TESTS PASSED")
	else:
		print("FAILURES: ", failures)
	quit(failures)
