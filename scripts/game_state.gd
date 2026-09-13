extends Node

# 全局游戏状态：关卡数据、进度存档、当前关卡
# 注册为 autoload（project.godot [autoload] GameState）

const SAVE_PATH := "user://save.json"

# 每关配置：目标分数 / 步数 / 棋盘边长 / 方块种类数（难度递增）
const LEVELS: Array[Dictionary] = [
	{"target": 300, "steps": 30, "size": 8, "types": 6},
	{"target": 600, "steps": 28, "size": 8, "types": 6},
	{"target": 900, "steps": 26, "size": 8, "types": 7},
	{"target": 1200, "steps": 26, "size": 9, "types": 6},
	{"target": 1500, "steps": 24, "size": 9, "types": 7},
	{"target": 1800, "steps": 22, "size": 9, "types": 7},
	{"target": 2200, "steps": 22, "size": 9, "types": 8},
	{"target": 2600, "steps": 20, "size": 10, "types": 8},
	{"target": 3000, "steps": 18, "size": 10, "types": 8},
	{"target": 3600, "steps": 18, "size": 10, "types": 8},
]

var unlocked := 1            # 已解锁的最高关卡（1 起）
var best: Dictionary = {}    # { "关卡号": 最高分 }
var current_level := 1       # 当前要玩的关卡


func _ready() -> void:
	load_save()


func level_count() -> int:
	return LEVELS.size()


func level_data(idx: int) -> Dictionary:
	return LEVELS[clampi(idx - 1, 0, LEVELS.size() - 1)]


func is_unlocked(idx: int) -> bool:
	return idx <= unlocked


func best_score(idx: int) -> int:
	return int(best.get(str(idx), 0))


func stars_for(level: int, score: int) -> int:
	var t: int = int(level_data(level)["target"])
	if score >= t * 2:
		return 3
	if score >= int(t * 1.5):
		return 2
	if score >= t:
		return 1
	return 0


# 记录一局结果：更新最高分，过关则解锁下一关
func record_result(level: int, score: int) -> void:
	var key := str(level)
	if best_score(level) < score:
		best[key] = score
	if level >= unlocked and score >= int(level_data(level)["target"]) and level < LEVELS.size():
		unlocked = level + 1
	save()


func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"unlocked": unlocked, "best": best}))
		f.close()


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var data: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if data is Dictionary:
			unlocked = clampi(int(data.get("unlocked", 1)), 1, LEVELS.size())
			var b = data.get("best", {})
			if b is Dictionary:
				best = b
