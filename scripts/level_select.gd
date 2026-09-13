extends Control

# 关卡选择：网格卡片，锁定/解锁、最高分、星级

const UIKit = preload("res://scripts/ui_kit.gd")
const VIEW_W := 720
const VIEW_H := 840
const COLS := 5
const CARD_W := 116
const CARD_H := 132
const GAP := 16


func _ready() -> void:
	size = Vector2(VIEW_W, VIEW_H)
	_build_ui()
	_build_cards()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#f7f4ef")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var back: Button = UIKit.make_button("← 返回", Vector2(16, 16), Vector2(104, 46), Color("#9aa0aa"), 18)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	add_child(back)

	var title := Label.new()
	title.text = "选择关卡"
	title.position = Vector2(0, 24)
	title.size = Vector2(VIEW_W, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color("#2b2d42")
	UIKit.style(title, 32)
	add_child(title)


func _build_cards() -> void:
	var gs := get_node("/root/GameState")
	var count: int = gs.level_count()
	var total_w: float = COLS * CARD_W + (COLS - 1) * GAP
	var x0 := (VIEW_W - total_w) / 2.0
	var y0 := 120.0
	for i in count:
		var idx := i + 1
		var col := i % COLS
		var row := int(i / COLS)
		var pos := Vector2(x0 + col * (CARD_W + GAP), y0 + row * (CARD_H + GAP))
		_make_card(idx, pos)


func _make_card(idx: int, pos: Vector2) -> void:
	var gs := get_node("/root/GameState")
	var unlocked: bool = gs.is_unlocked(idx)
	var best: int = gs.best_score(idx)
	var stars: int = gs.stars_for(idx, best)

	var card := Button.new()
	card.position = pos
	card.size = Vector2(CARD_W, CARD_H)
	card.text = ""
	card.focus_mode = Control.FOCUS_NONE

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(6)
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 4
	if unlocked:
		sb.bg_color = Color("#ffffff")
		card.add_theme_stylebox_override("normal", sb)
		var sb_hover: StyleBoxFlat = sb.duplicate()
		sb_hover.bg_color = Color("#eef3ff")
		card.add_theme_stylebox_override("hover", sb_hover)
		var sb_pressed: StyleBoxFlat = sb.duplicate()
		sb_pressed.bg_color = Color("#dde6ff")
		card.add_theme_stylebox_override("pressed", sb_pressed)
		card.pressed.connect(_play_level.bind(idx))
	else:
		sb.bg_color = Color("#e4e6ea")
		card.add_theme_stylebox_override("normal", sb)
		card.disabled = true

	add_child(card)

	var num := Label.new()
	num.text = "第 %d 关" % idx
	num.position = pos + Vector2(0, 10)
	num.size = Vector2(CARD_W, 34)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.modulate = Color("#2b2d42")
	UIKit.style(num, 20)
	add_child(num)

	if unlocked:
		var stars_txt := ""
		for s in 3:
			stars_txt += "★" if s < stars else "☆"
		var star_label := Label.new()
		star_label.text = stars_txt
		star_label.position = pos + Vector2(0, 52)
		star_label.size = Vector2(CARD_W, 30)
		star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_label.modulate = Color("#ffb703")
		UIKit.style(star_label, 22)
		add_child(star_label)

		var score_txt: String = "最高 %d" % best if best > 0 else "未挑战"
		var score_label := Label.new()
		score_label.text = score_txt
		score_label.position = pos + Vector2(0, 90)
		score_label.size = Vector2(CARD_W, 28)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.modulate = Color("#7a7f8a")
		UIKit.style(score_label, 15)
		add_child(score_label)
	else:
		var lock := Label.new()
		lock.text = "🔒"
		lock.position = pos + Vector2(0, 40)
		lock.size = Vector2(CARD_W, 46)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock.modulate = Color("#a0a5af")
		UIKit.style(lock, 34)
		add_child(lock)


func _play_level(idx: int) -> void:
	var gs := get_node("/root/GameState")
	gs.current_level = idx
	get_tree().change_scene_to_file("res://scenes/main.tscn")
