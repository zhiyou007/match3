extends SceneTree

# UI 结构断言：_win_level 后结算面板各元素状态
var main: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var failures := 0

	# 初始状态：结算面板隐藏
	if not main.overlay.visible:
		print("UI PASS: overlay hidden initially")
	else:
		print("UI FAIL: overlay visible initially")
		failures += 1

	# 触发过关
	main.score = 400
	main._win_level()

	if main.overlay.visible:
		print("UI PASS: overlay visible after win")
	else:
		print("UI FAIL: overlay not visible")
		failures += 1

	if main.result_title.text == "过关！":
		print("UI PASS: title = ", main.result_title.text)
	else:
		print("UI FAIL: title = ", main.result_title.text)
		failures += 1

	var stars_text: String = main.result_stars.text
	if "★" in stars_text:
		print("UI PASS: stars text = ", stars_text)
	else:
		print("UI FAIL: stars text = '", stars_text, "'")
		failures += 1

	if main.btn_primary.visible:
		print("UI PASS: primary btn visible, text=", main.btn_primary.text)
	else:
		print("UI FAIL: primary btn not visible")
		failures += 1

	if main.btn_secondary.visible:
		print("UI PASS: secondary btn visible, text=", main.btn_secondary.text)
	else:
		print("UI FAIL: secondary btn not visible")
		failures += 1

	# 面板区域位置/尺寸合理性
	var panel_rect := Rect2(Vector2(110, 210), Vector2(500, 420))
	if panel_rect.has_point(main.btn_primary.position + main.btn_primary.size / 2.0):
		print("UI PASS: primary btn inside panel")
	else:
		print("UI FAIL: primary btn outside panel: ", main.btn_primary.position)
		failures += 1

	if failures == 0:
		print("ALL UI TESTS PASSED")
		quit(0)
	else:
		print("UI FAILURES: ", failures)
		quit(1)
