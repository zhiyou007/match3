extends SceneTree

# 全流程场景测试：菜单 -> 选关 -> 游戏 -> 过关结算 -> 存档/解锁/星级
# 验证场景切换、GameState 存档读写、关卡参数化
var frames := 0
var stage := 0
var current: Node
var gs: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# 注意：--script 模式下 autoload 依然注册，直接使用 /root/GameState
	gs = root.get_node("GameState")
	var sfx: Node = root.get_node("SFX")

	# 清掉旧存档，保证确定性
	gs.unlocked = 1
	gs.best = {}
	gs.save()

	# 切到主菜单
	change_scene_to_file("res://scenes/menu.tscn")
	stage = 1


func _process(_delta: float) -> bool:
	frames += 1
	match stage:
		1:
			# 主菜单已加载
			current = root.get_child(root.get_child_count() - 1)
			if current and current.name == "Menu" and frames > 5:
				print("FLOW PASS: menu loaded")
				# 进入选关
				current._go_level_select()
				stage = 2
				frames = 0
		2:
			current = root.get_child(root.get_child_count() - 1)
			if current and current.name == "LevelSelect" and frames > 5:
				print("FLOW PASS: level select loaded")
				# 检查第 1 关解锁、第 2 关锁定
				var unlocked1: bool = gs.is_unlocked(1)
				var unlocked2: bool = gs.is_unlocked(2)
				if unlocked1 and not unlocked2:
					print("FLOW PASS: level locking correct (1 open, 2 locked)")
				else:
					print("FLOW FAIL: locking state wrong: 1=", unlocked1, " 2=", unlocked2)
					quit(1)
				# 点第 1 关
				current._play_level(1)
				stage = 3
				frames = 0
		3:
			current = root.get_child(root.get_child_count() - 1)
			if current and current.name == "Main" and frames > 5:
				print("FLOW PASS: game loaded with level 1 params: grid=", current.grid, " types=", current.types, " steps=", current.steps, " target=", current.target)
				if current.grid != 8 or current.types != 6 or current.steps != 30 or current.target != 300:
					print("FLOW FAIL: level 1 params wrong")
					quit(1)
				# 模拟过关（直接置分）
				current.score = 310
				print("DEBUG pre-win: gs.best=", gs.best, " unlocked=", gs.unlocked)
				print("DEBUG root children: ", root.get_children())
				current._win_level()
				print("DEBUG post-win: member gs.best=", gs.best, " unlocked=", gs.unlocked, " rootGS.best=", root.get_node("GameState").best, " same=", (gs == root.get_node("GameState")))
				stage = 4
				frames = 0
		4:
			if frames > 5:
				if gs.is_unlocked(2):
					print("FLOW PASS: level 2 unlocked after win")
				else:
					print("FLOW FAIL: level 2 not unlocked")
					quit(1)
				if gs.best_score(1) == 310:
					print("FLOW PASS: best score saved = 310")
				else:
					print("FLOW FAIL: best score = ", gs.best_score(1))
					quit(1)
				var stars: int = gs.stars_for(1, 310)
				if stars >= 1:
					print("FLOW PASS: stars for 310 = ", stars)
				else:
					print("FLOW FAIL: stars = ", stars)
					quit(1)
				# 重新加载存档验证持久化
				gs.load_save()
				if gs.is_unlocked(2) and gs.best_score(1) == 310:
					print("FLOW PASS: save.json persisted & reloaded")
				else:
					print("FLOW FAIL: persistence broken")
					quit(1)
				print("ALL FLOW TESTS PASSED")
				quit(0)
	return false


func _notification(what: int) -> void:
	pass
