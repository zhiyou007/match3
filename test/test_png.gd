extends SceneTree

# 离线采样 03_main.png：确认 8x8 棋盘渲染边界
var img: Image


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	img = Image.load_from_file("C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/screenshots/03_main.png")
	print("img size: ", img.get_width(), "x", img.get_height())
	# 第 1 关 8x8：origin=(104,150)，cell=64，右边界 104+8*64=616，下边界 150+8*64=662
	var pts := {
		"board_tl": Vector2i(110, 156),
		"board_tr_cell": Vector2i(610, 156),
		"just_inside_right": Vector2i(614, 156),
		"just_outside_right": Vector2i(622, 156),
		"board_bl": Vector2i(110, 656),
		"just_below": Vector2i(110, 668),
		"far_right": Vector2i(700, 400),
	}
	for k in pts:
		var p: Color = img.get_pixelv(pts[k])
		print("PX ", k, " rgb=(", int(p.r * 255), ",", int(p.g * 255), ",", int(p.b * 255), ")")
	quit(0)
