extends SceneTree

# 真实点击序列压力测试：随机点相邻格子（含无效交换），检查残留匹配、卡死与显示错位
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

	var g: int = m.grid
	var cells: Array = []
	for y in g:
		for x in g:
			cells.append(Vector2i(x, y))

	var clicks := 0
	while clicks < 400:
		var a: Vector2i = cells[randi() % cells.size()]
		var d: Vector2i = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)][randi() % 4]
		var b: Vector2i = a + d
		if b.x < 0 or b.x >= g or b.y < 0 or b.y >= g:
			continue
		m._on_cell_clicked(a)
		m._on_cell_clicked(b)
		clicks += 1
		var waited := 0
		while m._swap_chain_running or not m._pending_swaps.is_empty():
			await process_frame
			waited += 1
			if waited > 600:
				print("BUSY STUCK after ", clicks, " click-pairs!")
				quit(1)
		if m.selected.x >= 0:
			m._on_cell_clicked(m.selected)
		var leftover: Array = m._find_matches()
		if not leftover.is_empty():
			print("LEFTOVER after ", clicks, " click-pairs: ", leftover)
			for y in g:
				var s := ""
				for x in g:
					s += str(m.board[y][x])
				print(s)
			quit(1)
		for y in g:
			for x in g:
				var idx: int = m.board[y][x]
				var node: TextureRect = m.nodes[y][x]
				if (node == null and idx >= 0) or (node != null and idx < 0) or (node != null and node.texture != m._gem_textures[idx]):
					print("MISMATCH after ", clicks, " click-pairs at (", x, ",", y, ")")
					quit(1)

	print("ALL ", clicks, " CLICK PAIRS CLEAN")
	quit(0)
