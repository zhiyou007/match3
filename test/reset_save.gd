extends SceneTree

# 重置存档为初始状态（清理测试残留数据）


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs := root.get_node("GameState")
	gs.unlocked = 1
	gs.best = {}
	gs.save()
	print("save reset: unlocked=1 best={}")
	var check: String = FileAccess.get_file_as_string(gs.SAVE_PATH)
	print("on disk: ", check)
	quit(0)
