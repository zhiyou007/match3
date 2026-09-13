extends SceneTree

# 最小复现：手动触发拖动交换，逐步打印状态
var m: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	await process_frame

	# 找一个可交换对
	var found := Vector2i(-1, -1)
	var fdir := Vector2i.ZERO
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
					found = a
					fdir = dir
					break
			if found.x >= 0:
				break
		if found.x >= 0:
			break
	print("pair: ", found, " dir: ", fdir)

	var center: Vector2 = m._cell_pos(found) + Vector2(32, 32)
	var target_pt: Vector2 = center + Vector2(fdir) * 32.0
	print("press at ", center)
	m._press_cell(center)
	print("after press: press_cell=", m.press_cell, " swapped=", m.swapped, " busy=", m.busy)
	await process_frame
	m._drag_cell(target_pt)
	print("after drag: press_cell=", m.press_cell, " swapped=", m.swapped, " busy=", m.busy, " steps=", m.steps)
	await process_frame
	await process_frame
	print("after 2f: score=", m.score, " steps=", m.steps, " busy=", m.busy)
	m._release_cell(target_pt)
	print("after release: score=", m.score, " steps=", m.steps, " busy=", m.busy)
	for i in 120:
		await process_frame
	print("after wait: score=", m.score, " steps=", m.steps, " busy=", m.busy)
	quit(0)
