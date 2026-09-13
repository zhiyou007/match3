extends SceneTree

# Special-items tests: 4-match->BOMB, 5-match->RAINBOW, bomb explode, rainbow clear
var m: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	await process_frame

	# --- 1. 4-match -> BOMB ---
	_reset_board()
	for x in m.grid:
		m.board[0][x] = 0 if x < 4 else 1  # [0,0,0,0,1,1,1,1] guaranteed 4-match
	_sync_nodes()
	await m._resolve_loop()
	var has_bomb := false
	for y in m.grid:
		for x in m.grid:
			if m.board[y][x] == m.BOMB:
				has_bomb = true
	if has_bomb:
		print("1. 4-match spawns BOMB: PASS")
	else:
		print("1. FAIL: no bomb after 4-match")
		quit(1)

	# --- 2. 5-match -> RAINBOW ---
	_reset_board()
	for x in m.grid:
		m.board[0][x] = 1 if x < 5 else 0  # [1,1,1,1,1,0,0,0] guaranteed 5-match
	_sync_nodes()
	await m._resolve_loop()
	var has_rainbow := false
	for y in m.grid:
		for x in m.grid:
			if m.board[y][x] == m.RAINBOW:
				has_rainbow = true
	if has_rainbow:
		print("2. 5-match spawns RAINBOW: PASS")
	else:
		print("2. FAIL: no rainbow after 5-match")
		quit(1)

	# --- 3. BOMB swap -> 3x3 explode ---
	_reset_board()
	m.board[3][3] = m.BOMB
	m.board[4][3] = 0
	m.board[2][2] = 2
	m.board[2][3] = 3
	m.board[3][2] = 4
	_sync_nodes()
	var sc: int = m.score
	m._swap_data(Vector2i(3, 3), Vector2i(3, 4))  # swap (row3,col3)<->(row4,col3); bomb -> (row4,col3)=(3,4)
	await m._trigger_special(Vector2i(3, 4), Vector2i(3, 3))
	await process_frame
	var cleared := true
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var p := Vector2i(3, 4) + Vector2i(dx, dy)
			if p.x >= 0 and p.y >= 0 and p.x < m.grid and p.y < m.grid and m.board[p.y][p.x] >= 0:
				cleared = false
	if cleared and m.score > sc:
		print("3. bomb explode clears 3x3: PASS (score ", sc, "->", m.score, ")")
	else:
		print("3. FAIL: cleared=", cleared, " score=", m.score)
		quit(1)

	# --- 4. RAINBOW swap -> clear all of one color ---
	_reset_board()
	m.board[3][3] = m.RAINBOW
	m.board[4][3] = 2
	m.board[0][0] = 2
	m.board[7][7] = 2
	_sync_nodes()
	m._swap_data(Vector2i(3, 3), Vector2i(3, 4))  # rainbow -> (row4,col3), green -> (row3,col3)
	await m._trigger_special(Vector2i(3, 4), Vector2i(3, 3))
	await process_frame
	var green_left := 0
	for y in m.grid:
		for x in m.grid:
			if m.board[y][x] == 2:
				green_left += 1
	if green_left == 0:
		print("4. rainbow clears all color-2: PASS")
	else:
		print("4. FAIL: green_left=", green_left)
		quit(1)

	print("ALL SPECIAL TESTS PASSED")
	quit(0)


func _reset_board() -> void:
	# Rebuild as a random match-free board (keeps grid size)
	for y in m.grid:
		for x in m.grid:
			m.board[y][x] = randi() % m.types
	var guard := 0
	while not m._find_matches().is_empty() and guard < 100:
		for y in m.grid:
			for x in m.grid:
				m.board[y][x] = randi() % m.types
		guard += 1
	if guard >= 100:
		print("WARN: board could not be cleared of matches")


func _sync_nodes() -> void:
	# Rebuild node references after manual board edits (test-only)
	for y in m.grid:
		for x in m.grid:
			var n: TextureRect = m.nodes[y][x]
			if n != null:
				n.queue_free()
	m.nodes = []
	for y in m.grid:
		var row: Array = []
		for x in m.grid:
			row.append(null)
		m.nodes.append(row)
	for y in m.grid:
		for x in m.grid:
			var v: int = m.board[y][x]
			if v >= 0:
				var n: TextureRect = m._make_cell(x, y, v)
				m.nodes[y][x] = n
