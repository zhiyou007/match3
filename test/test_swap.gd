extends SceneTree

# 端到端：构造一次必成三连的交换，验证 交换→消除→下落→计分 全链路
# 注意：棋盘坐标用 Vector2i(x, y)，垂直相邻是 (x=0, y=1)
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

	# 目标：交换 (0,0) 与 (0,1)（同一列上下相邻）后，(0,0)(1,0)(2,0) 成列三连
	var A := 3
	var B := 4
	m.board[0][0] = B
	m.board[1][0] = A
	m.board[0][1] = A
	m.board[0][2] = A

	var steps_before: int = m.steps
	var score_before: int = m.score
	await m._try_swap(Vector2i(0, 0), Vector2i(0, 1))

	if m.score > score_before and m.steps == steps_before - 1:
		print("SWAP TEST PASS: score ", score_before, "->", m.score, ", steps ", steps_before, "->", m.steps)
		quit(0)
	else:
		print("SWAP TEST FAIL: score ", score_before, "->", m.score, ", steps ", steps_before, "->", m.steps)
		quit(1)
