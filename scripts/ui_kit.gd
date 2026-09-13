class_name UIKit

# 通用 UI 工具：中文字体 + 圆角按钮


static func style(ctl: Control, size_px: int) -> void:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "Noto Sans CJK SC"])
	ctl.add_theme_font_override("font", f)
	ctl.add_theme_font_size_override("font_size", size_px)


static func make_button(text: String, pos: Vector2, size_px: Vector2, color: Color, font_px: int) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size_px
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(8)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 3
	b.add_theme_stylebox_override("normal", sb)
	var sb_hover: StyleBoxFlat = sb.duplicate()
	sb_hover.bg_color = color.lightened(0.12)
	b.add_theme_stylebox_override("hover", sb_hover)
	var sb_pressed: StyleBoxFlat = sb.duplicate()
	sb_pressed.bg_color = color.darkened(0.18)
	b.add_theme_stylebox_override("pressed", sb_pressed)
	style(b, font_px)
	return b
