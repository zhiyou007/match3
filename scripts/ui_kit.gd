class_name UIKit

# 游戏化 UI 工具：渐变背景、描边标题、糖果按钮、胶囊徽章、宝石装饰


static func font() -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "Noto Sans CJK SC"])
	return f


static func style(ctl: Control, size_px: int, outline_px := 0, outline_color := Color(0, 0, 0, 0)) -> void:
	ctl.add_theme_font_override("font", font())
	ctl.add_theme_font_size_override("font_size", size_px)
	if outline_px > 0:
		ctl.add_theme_color_override("font_outline_color", outline_color)
		ctl.add_theme_constant_override("outline_size", outline_px)


static func bg_gradient(parent: Control, top: Color, bottom: Color) -> TextureRect:
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, top)
	g.set_color(1, bottom)
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)
	return tr


static func sparkle(parent: Control, count: int, w: float, h: float) -> void:
	# 半透明星光光斑（单次呼吸动画，绑定父节点，随场景释放自动清理）
	for i in count:
		var dot := ColorRect.new()
		dot.size = Vector2(randf_range(2.0, 5.0), randf_range(2.0, 5.0))
		dot.position = Vector2(randf() * w, randf() * h)
		dot.color = Color(1, 1, 1, randf_range(0.05, 0.3))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(dot)
		var a0: float = dot.modulate.a
		var t := parent.create_tween()
		t.tween_property(dot, "modulate:a", 0.03, randf_range(0.8, 1.6)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(dot, "modulate:a", a0, randf_range(0.8, 1.6)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


static func make_title(parent: Control, text: String, pos: Vector2, size_px: Vector2, px: int, color := Color.WHITE, outline := Color("#3a1d6e")) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size_px
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.modulate = color
	style(l, px, maxi(3, int(px / 7)), outline)
	parent.add_child(l)
	return l


static func make_button(text: String, pos: Vector2, size_px: Vector2, color: Color, font_px: int) -> Button:
	# 糖果按钮：圆角 + 白色描边 + 底部阴影 + hover 上浮放大 + 按下回弹
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size_px
	b.focus_mode = Control.FOCUS_NONE
	b.pivot_offset = size_px / 2.0
	var r := int(size_px.y * 0.26)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(r)
	sb.set_content_margin_all(6)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(1, 1, 1, 0.55)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	b.add_theme_stylebox_override("normal", sb)
	var sb_h: StyleBoxFlat = sb.duplicate()
	sb_h.bg_color = color.lightened(0.10)
	sb_h.shadow_size = 8
	sb_h.shadow_offset = Vector2(0, 5)
	b.add_theme_stylebox_override("hover", sb_h)
	var sb_p: StyleBoxFlat = sb.duplicate()
	sb_p.bg_color = color.darkened(0.16)
	sb_p.shadow_offset = Vector2(0, 1)
	sb_p.shadow_size = 2
	b.add_theme_stylebox_override("pressed", sb_p)
	var sb_d := StyleBoxFlat.new()
	sb_d.bg_color = Color(1, 1, 1, 0.25)
	sb_d.set_corner_radius_all(r)
	b.add_theme_stylebox_override("disabled", sb_d)
	style(b, font_px, maxi(1, int(font_px / 8)), Color(0, 0, 0, 0.35))
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
		b.scale = Vector2(0.95, 0.95)
	)
	b.button_up.connect(func() -> void:
		b.scale = Vector2.ONE
	)
	return b


static func make_pill(parent: Control, text: String, pos: Vector2, size_px: Vector2, color: Color, px: int, text_color := Color.WHITE) -> Label:
	# 胶囊徽章：圆角半透明底 + 白字
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size_px
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(size_px.y / 2.0))
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(1, 1, 1, 0.35)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	l.add_theme_stylebox_override("normal", sb)
	l.modulate = text_color
	style(l, px, maxi(1, int(px / 9)), Color(0, 0, 0, 0.4))
	parent.add_child(l)
	return l


static func make_panel(parent: Control, pos: Vector2, size_px: Vector2, bg: Color, radius := 24) -> Panel:
	# 圆角面板：半透明底 + 亮边 + 投影
	var p := Panel.new()
	p.position = pos
	p.size = size_px
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(1, 1, 1, 0.18)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	return p


static func make_gem(parent: Control, tex: Texture2D, pos: Vector2, size_px: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.position = pos
	t.size = Vector2(size_px, size_px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t
