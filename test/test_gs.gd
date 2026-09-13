extends SceneTree

# 最小复现：GameState 存档逻辑单独验证
var gs: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	gs = load("res://scripts/game_state.gd").new()
	gs.name = "GameState"
	root.add_child(gs)
	print("GS TEST: initial best=", gs.best, " unlocked=", gs.unlocked)
	gs.unlocked = 1
	gs.best = {}
	gs.record_result(1, 310)
	print("GS TEST: after record best=", gs.best, " unlocked=", gs.unlocked)
	var bs: int = gs.best_score(1)
	print("GS TEST: best_score(1)=", bs)
	gs.load_save()
	print("GS TEST: after reload best=", gs.best, " unlocked=", gs.unlocked)
	if gs.is_unlocked(2) and gs.best_score(1) == 310:
		print("GS TEST PASS")
		quit(0)
	else:
		print("GS TEST FAIL")
		quit(1)
