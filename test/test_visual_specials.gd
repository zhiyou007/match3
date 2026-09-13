extends SceneTree

# Visual verification: render board with BOMB(8)/RAINBOW(9) cells, save screenshot
var m: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	await process_frame

	# Build a match-free random board
	for y in m.grid:
		for x in m.grid:
			m.board[y][x] = randi() % m.types
	var guard := 0
	while not m._find_matches().is_empty() and guard < 100:
		for y in m.grid:
			for x in m.grid:
				m.board[y][x] = randi() % m.types
		guard += 1
	# Place specials
	m.board[2][3] = m.BOMB
	m.board[4][6] = m.RAINBOW
	m.board[5][2] = m.BOMB
	m.board[6][5] = m.RAINBOW
	_sync_nodes()
	await process_frame
	await process_frame

	var img := m.get_viewport().get_texture().get_image()
	var ok := img.save_png("res://screenshots/13_specials.png")
	print("saved 13_specials.png: ", ok)
	quit(0)


func _sync_nodes() -> void:
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
