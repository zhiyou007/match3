extends SceneTree

# Visual: trigger a BOMB swap, capture board AFTER cascade+refill (no holes)
var m: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	await process_frame

	for y in m.grid:
		for x in m.grid:
			m.board[y][x] = randi() % m.types
	var guard := 0
	while not m._find_matches().is_empty() and guard < 100:
		for y in m.grid:
			for x in m.grid:
				m.board[y][x] = randi() % m.types
		guard += 1
	m.board[3][3] = m.BOMB
	m.board[3][4] = 0
	m.board[4][4] = m.BOMB
	_sync_nodes()
	await m._try_swap(Vector2i(3, 3), Vector2i(3, 4))
	for i in 10:
		await process_frame
	var holes := 0
	for y in m.grid:
		for x in m.grid:
			if m.board[y][x] < 0:
				holes += 1
	print("holes after bomb cascade: ", holes)
	var img := m.get_viewport().get_texture().get_image()
	var ok := img.save_png("res://screenshots/14_bomb_refill.png")
	print("saved 14_bomb_refill.png: ", ok)
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
