extends SceneTree

# 压力测试：随机执行大量有效交换，每步后检查棋盘是否有匹配残留
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
	var swap_count := 0
	while swap_count < 300:
		var found := false
		for tries in 100:
			var a := Vector2i(randi() % g, randi() % g)
			var d: Vector2i = [Vector2i(1, 0), Vector2i(0, 1)][randi() % 2]
			var b := a + d
			if b.x >= g or b.y >= g:
				continue
			m._swap_data(a, b)
			var ok: bool = not m._find_matches().is_empty()
			m._swap_data(a, b)
			if ok:
				await m._try_swap(a, b)
				swap_count += 1
				var leftover: Array = m._find_matches()
				if not leftover.is_empty():
					print("LEFTOVER after ", swap_count, " swaps: ", leftover)
					for y in g:
						var s := ""
						for x in g:
							s += str(m.board[y][x])
						print(s)
					quit(1)
				found = true
				break
		if not found:
			m._reshuffle()

	print("ALL ", swap_count, " SWAPS CLEAN")
	quit(0)
