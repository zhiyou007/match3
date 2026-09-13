extends Control

# 主菜单：标题、开始游戏、玩法说明、退出

const UIKit = preload("res://scripts/ui_kit.gd")
const VIEW_W := 720
const VIEW_H := 840
const COLORS: Array[Color] = [
	Color("#ff6b6b"), Color("#ffd93d"), Color("#6bcb77"),
	Color("#4d96ff"), Color("#9b5de5"), Color("#ff9f1c"), Color("#00bbf9"),
	Color("#f15bb5")
]


func _ready() -> void:
	size = Vector2(VIEW_W, VIEW_H)
	_build_ui()
	_build_help()
	_menu_float()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#23263a")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 顶部装饰色块（模拟棋盘）
	for i in 8:
		var block := ColorRect.new()
		block.position = Vector2(88 + i * 72, 96)
		block.size = Vector2(48, 48)
		block.color = COLORS[i]
		block.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(block)
		var t := create_tween().set_loops()
		t.tween_property(block, "position:y", 96.0 + 14.0, 1.6 + i * 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(block, "position:y", 96.0, 1.6 + i * 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var title := Label.new()
	title.text = "消消乐"
	title.position = Vector2(0, 250)
	title.size = Vector2(VIEW_W, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color.WHITE
	UIKit.style(title, 72)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Match 3 · 闯关消消乐"
	subtitle.position = Vector2(0, 350)
	subtitle.size = Vector2(VIEW_W, 40)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(1, 1, 1, 0.55)
	UIKit.style(subtitle, 20)
	add_child(subtitle)

	var start: Button = UIKit.make_button("开始游戏", Vector2(220, 460), Vector2(280, 64), Color("#6bcb77"), 28)
	start.pressed.connect(_go_level_select)
	add_child(start)

	var help: Button = UIKit.make_button("玩法说明", Vector2(220, 544), Vector2(280, 60), Color("#4d96ff"), 22)
	help.pressed.connect(_toggle_help)
	add_child(help)

	var quit: Button = UIKit.make_button("退出游戏", Vector2(220, 620), Vector2(280, 60), Color("#9aa0aa"), 22)
	quit.pressed.connect(func() -> void: get_tree().quit())
	add_child(quit)


func _build_help() -> void:
	var panel := ColorRect.new()
	panel.name = "HelpPanel"
	panel.position = Vector2(110, 200)
	panel.size = Vector2(500, 440)
	panel.color = Color("#ffffff")
	panel.visible = false
	add_child(panel)

	var title := Label.new()
	title.text = "玩法说明"
	title.position = Vector2(0, 20)
	title.size = Vector2(500, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color("#2b2d42")
	UIKit.style(title, 30)
	panel.add_child(title)

	var rules := Label.new()
	rules.text = "· 点击一个方块选中，再点击相邻方块交换\n· 三个及以上同色连成一行或一列即消除\n· 消除后上方方块下落补位，可能引发连锁\n· 连锁消除可获得更高分数\n· 在步数用尽前凑满目标分数即可过关\n· 分数越高，星级越高（最多三星）"
	rules.position = Vector2(30, 90)
	rules.size = Vector2(440, 260)
	rules.modulate = Color("#3a3f4b")
	UIKit.style(rules, 19)
	panel.add_child(rules)

	var close: Button = UIKit.make_button("知道了", Vector2(140, 360), Vector2(220, 52), Color("#6bcb77"), 20)
	close.pressed.connect(_toggle_help)
	panel.add_child(close)


func _toggle_help() -> void:
	var panel := get_node("HelpPanel")
	panel.visible = not panel.visible
	if panel.visible:
		var sfx := get_node_or_null("/root/SFX")
		if sfx:
			sfx.play("click")


func _go_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _menu_float() -> void:
	pass
