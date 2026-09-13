extends SceneTree

# 用截图棋盘矩阵验证匹配检测
var m: Control

const COLORS: Array[String] = ["R", "Y", "G", "B", "P", "O", "C"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_script: GDScript = load("res://scripts/main.gd")
	m = main_script.new()
	root.add_child(m)
	await process_frame

	var matrix := [
		["C", "G", "O", "P", "G", "C", "O", "O"],
		["P", "C", "O", "P", "C", "C", "G", "G"],
		["Y", "G", "C", "O", "R", "C", "O", "P"],
		["O", "Y", "R", "O", "B", "B", "R", "B"],
		["C", "O", "Y", "O", "R", "O", "G", "Y"],
		["G", "P", "C", "P", "G", "C", "R", "O"],
		["P", "R", "O", "G", "Y", "O", "Y", "C"],
		["C", "O", "B", "Y", "Y", "B", "B", "P"],
	]
	m.board = []
	for r in 8:
		var row: Array = []
		for c in 8:
			row.append(COLORS.find(matrix[r][c]))
		m.board.append(row)

	var matches: Array = m._find_matches()
	print("found matches: ", matches.size())
	for mm in matches:
		print("  ", mm)
	quit(0)
