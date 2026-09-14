extends Control

# 主菜单：星空渐变背景、漂浮宝石、描边标题、糖果按钮

const UIKit = preload("res://scripts/ui_kit.gd")
const VIEW_W := 720
const VIEW_H := 840
const COLORS: Array[Color] = [
	Color("#ff6b6b"), Color("#ffd93d"), Color("#6bcb77"),
	Color("#4d96ff"), Color("#9b5de5"), Color("#ff9f1c"), Color("#00bbf9"),
	Color("#f15bb5")
]

var _gems: Array = []
var _gem_bases: Array = []
var _float_t := 0.0


func _ready() -> void:
	size = Vector2(VIEW_W, VIEW_H)
	_build_ui()
	_build_help()


func _process(delta: float) -> void:
	# 宝石正弦浮动（不依赖 tween，随场景释放自然停止）
	_float_t += delta
	for i in _gems.size():
		var g: TextureRect = _gems[i]
		var base: float = _gem_bases[i]
		g.position.y = base + sin(_float_t * 1.6 + i * 0.9) * 12.0


func _atlas_region(i: int) -> AtlasTexture:
	var atlas: Texture2D = null
	if ResourceLoader.exists("res://assets/atlas_gems.png"):
		atlas = load("res://assets/atlas_gems.png")
	var at := AtlasTexture.new()
	if atlas != null:
		at.atlas = atlas
		at.region = Rect2((i % 5) * 128, (i / 5) * 128, 128, 128)
	else:
		at.region = Rect2(0, 0, 128, 128)
	return at


func _build_ui() -> void:
	# 渐变背景（深紫 → 深蓝）
	UIKit.bg_gradient(self, Color("#3d1f7a"), Color("#16245e"))
	UIKit.sparkle(self, 26, VIEW_W, VIEW_H)

	# 底部漂浮宝石
	_gems = []
	_gem_bases = []
	for i in 8:
		var t := UIKit.make_gem(self, _atlas_region(i), Vector2(60 + i * 80, 700 + (i % 3) * 26), 40.0)
		t.modulate = Color(1, 1, 1, 0.85)
		_gems.append(t)
		_gem_bases.append(t.position.y)

	# 标题（描边）
	UIKit.make_title(self, "消消乐", Vector2(0, 190), Vector2(VIEW_W, 110), 84, Color("#ffffff"), Color("#2a1058"))

	UIKit.make_title(self, "Match 3 · 闯关消消乐", Vector2(0, 300), Vector2(VIEW_W, 44), 21, Color(1, 1, 1, 0.75), Color(0, 0, 0, 0))

	# 装饰横条（宝石色渐变）
	var bar := ColorRect.new()
	bar.position = Vector2(220, 372)
	bar.size = Vector2(280, 5)
	bar.color = Color("#ffd23f")
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	var start: Button = _make_image_button("开始游戏", Vector2(170, 430), Vector2(380, 60), "res://assets/ui/ui_btn_primary.png", 30)
	start.pressed.connect(_go_level_select)
	add_child(start)

	var help: Button = _make_image_button("玩法说明", Vector2(170, 510), Vector2(380, 58), "res://assets/ui/ui_btn_secondary.png", 24)
	help.pressed.connect(_toggle_help)
	add_child(help)

	var quit: Button = UIKit.make_button("退出游戏", Vector2(170, 590), Vector2(380, 58), Color("#8a7bb5"), 24)
	quit.pressed.connect(func() -> void: get_tree().quit())
	add_child(quit)


func _build_help() -> void:
	var panel := UIKit.make_panel(self, Vector2(110, 190), Vector2(500, 460), Color(0.16, 0.12, 0.30, 0.94), 26)
	panel.name = "HelpPanel"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	# z 高于背景装饰
	panel.z_index = 5

	var title := UIKit.make_title(panel, "玩法说明", Vector2(0, 26), Vector2(500, 52), 32, Color("#ffd23f"), Color("#2a1058"))

	var rules := Label.new()
	rules.text = "· 拖动宝石向相邻方向滑动，或点击两个相邻宝石交换\n· 三个及以上同色连成一行或一列即消除\n· 消除后上方宝石下落补位，可能引发连锁\n· 4 连生成炸弹，5 连或十字形生成彩虹\n· 炸弹爆炸 3×3，彩虹与宝石交换可全屏消除该色\n· 在步数用尽前凑满目标分数即可过关"
	rules.position = Vector2(36, 96)
	rules.size = Vector2(428, 280)
	rules.modulate = Color("#e8e4f5")
	UIKit.style(rules, 19)
	panel.add_child(rules)

	var close: Button = UIKit.make_button("知道了", Vector2(150, 380), Vector2(200, 54), Color("#6bcb77"), 22)
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


func _make_image_button(text: String, pos: Vector2, size_px: Vector2, tex_path: String, font_px: int) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size_px
	b.focus_mode = Control.FOCUS_NONE
	b.pivot_offset = size_px / 2.0
	var sb := StyleBoxTexture.new()
	if ResourceLoader.exists(tex_path):
		sb.texture = load(tex_path)
	sb.set_content_margin_all(10)
	b.add_theme_stylebox_override("normal", sb)
	var sb_h: StyleBoxTexture = sb.duplicate()
	sb_h.modulate_color = Color(1.05, 1.05, 1.05, 1.0)
	b.add_theme_stylebox_override("hover", sb_h)
	var sb_p: StyleBoxTexture = sb.duplicate()
	sb_p.modulate_color = Color(0.92, 0.92, 0.92, 1.0)
	b.add_theme_stylebox_override("pressed", sb_p)
	UIKit.style(b, font_px, maxi(1, int(font_px / 8)), Color(0, 0, 0, 0.35))
	b.mouse_entered.connect(func() -> void:
		var t := b.create_tween()
		t.set_parallel(true)
		t.tween_property(b, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	b.mouse_exited.connect(func() -> void:
		var t := b.create_tween()
		t.set_parallel(true)
		t.tween_property(b, "scale", Vector2.ONE, 0.12)
	)
	b.button_down.connect(func() -> void:
		b.scale = Vector2(0.96, 0.96)
	)
	b.button_up.connect(func() -> void:
		b.scale = Vector2.ONE
	)
	return b
