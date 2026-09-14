extends Control

# 关卡选择：星空背景、糖果卡片、星级、锁定态

const UIKit = preload("res://scripts/ui_kit.gd")
const VIEW_W := 720
const VIEW_H := 840
const COLS := 5
const CARD_W := 116
const CARD_H := 148
const GAP := 16


func _ready() -> void:
	size = Vector2(VIEW_W, VIEW_H)
	_build_ui()
	_build_cards()


func _build_ui() -> void:
	UIKit.bg_gradient(self, Color("#3d1f7a"), Color("#16245e"))
	UIKit.sparkle(self, 24, VIEW_W, VIEW_H)

	var back: Button = UIKit.make_button("← 返回", Vector2(16, 18), Vector2(104, 46), Color("#8a7bb5"), 18)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	add_child(back)

	UIKit.make_title(self, "选择关卡", Vector2(0, 20), Vector2(VIEW_W, 56), 38, Color("#ffffff"), Color("#2a1058"))


func _build_cards() -> void:
	var gs := get_node("/root/GameState")
	var count: int = gs.level_count()
	var total_w: float = COLS * CARD_W + (COLS - 1) * GAP
	var x0 := (VIEW_W - total_w) / 2.0
	var y0 := 108.0
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
	card.pivot_offset = Vector2(CARD_W / 2.0, CARD_H / 2.0)

	var r := 20
	if unlocked:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.16)
		sb.set_corner_radius_all(r)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(1, 1, 1, 0.55)
		sb.shadow_color = Color(0, 0, 0, 0.4)
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 3)
		card.add_theme_stylebox_override("normal", sb)
		var sb_h: StyleBoxFlat = sb.duplicate()
		sb_h.bg_color = Color(1, 1, 1, 0.28)
		card.add_theme_stylebox_override("hover", sb_h)
		var sb_p: StyleBoxFlat = sb.duplicate()
		sb_p.bg_color = Color(1, 1, 1, 0.34)
		card.add_theme_stylebox_override("pressed", sb_p)
		card.pressed.connect(_play_level.bind(idx))
		card.mouse_entered.connect(func() -> void:
			var t := card.create_tween()
			t.tween_property(card, "scale", Vector2(1.07, 1.07), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)
		card.mouse_exited.connect(func() -> void:
			var t := card.create_tween()
			t.tween_property(card, "scale", Vector2.ONE, 0.12)
		)
		card.button_down.connect(func() -> void:
			card.scale = Vector2(0.96, 0.96)
		)
		card.button_up.connect(func() -> void:
			card.scale = Vector2.ONE
		)
	else:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.06)
		sb.set_corner_radius_all(r)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(1, 1, 1, 0.18)
		card.add_theme_stylebox_override("normal", sb)
		card.disabled = true

	add_child(card)

	var num := Label.new()
	num.text = "第 %d 关" % idx
	num.position = pos + Vector2(0, 14)
	num.size = Vector2(CARD_W, 34)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.modulate = Color("#ffffff")
	UIKit.style(num, 21, 2, Color("#2a1058"))
	add_child(num)

	if unlocked:
		var star_y := 62.0
		for s in 3:
			var star := Label.new()
			star.text = "★"
			star.position = pos + Vector2(CARD_W / 2.0 - 54 + s * 36, star_y)
			star.size = Vector2(36, 36)
			star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			star.modulate = Color("#ffd23f") if s < stars else Color(1, 1, 1, 0.22)
			UIKit.style(star, 28, 2, Color("#5a3a00"))
			add_child(star)

		var score_txt: String = "最高 %d" % best if best > 0 else "未挑战"
		var score_label := Label.new()
		score_label.text = score_txt
		score_label.position = pos + Vector2(0, 106)
		score_label.size = Vector2(CARD_W, 26)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.modulate = Color(1, 1, 1, 0.75)
		UIKit.style(score_label, 15)
		add_child(score_label)
	else:
		var lock := Label.new()
		lock.text = "🔒"
		lock.position = pos + Vector2(0, 48)
		lock.size = Vector2(CARD_W, 52)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock.modulate = Color(1, 1, 1, 0.35)
		UIKit.style(lock, 36)
		add_child(lock)


func _play_level(idx: int) -> void:
	var gs := get_node("/root/GameState")
	gs.current_level = idx
	get_tree().change_scene_to_file("res://scenes/main.tscn")
