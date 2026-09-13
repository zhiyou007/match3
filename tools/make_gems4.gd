extends SceneTree

# 道具图集：炸弹/彩虹 抠黑转透明 + 缩 128 + 贴入 5x2 图集（前 8 格宝石，第 9 格炸弹，第 10 格彩虹）
const SRC_DIR := "C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/assets_raw"
const OUT := "C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/assets/atlas_gems.png"
const GEM := 128
const COLS := 5
const ROWS := 2


func _init() -> void:
	call_deferred("_run")


func _keyout(src: Image) -> void:
	var w := src.get_width()
	var h := src.get_height()
	for y in h:
		for x in w:
			var c: Color = src.get_pixel(x, y)
			var mx := maxf(c.r, maxf(c.g, c.b))
			if mx <= 0.16:
				src.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
			elif mx < 0.38:
				var a := (mx - 0.16) / 0.22
				src.set_pixel(x, y, Color(c.r, c.g, c.b, a))


func _round_corners(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var r := int(min(w, h) * 0.06)
	var rr := float(r) * r
	for y in h:
		for x in w:
			var dx := 0
			var dy := 0
			if x < r and y < r:
				dx = r - 1 - x
				dy = r - 1 - y
			elif x >= w - r and y < r:
				dx = x - (w - r)
				dy = r - 1 - y
			elif x < r and y >= h - r:
				dx = r - 1 - x
				dy = y - (h - r)
			elif x >= w - r and y >= h - r:
				dx = x - (w - r)
				dy = y - (h - r)
			if dx * dx + dy * dy > rr:
				img.set_pixel(x, y, Color(0, 0, 0, 0))


func _make_cell(src: Image) -> Image:
	src.convert(Image.FORMAT_RGBA8)
	_keyout(src)
	# 等比缩放到最长边 128 内，居中
	var longest := maxi(src.get_width(), src.get_height())
	var s := float(GEM) / float(longest)
	var nw := maxi(1, int(src.get_width() * s))
	var nh := maxi(1, int(src.get_height() * s))
	src.resize(nw, nh, Image.INTERPOLATE_LANCZOS)
	_round_corners(src)
	var canvas := Image.create(GEM, GEM, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	canvas.blit_rect(src, Rect2i(0, 0, nw, nh), Vector2i((GEM - nw) / 2, (GEM - nh) / 2))
	return canvas


func _run() -> void:
	var atlas := Image.create(GEM * COLS, GEM * ROWS, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0, 0, 0, 0))
	for i in 8:
		var src := Image.load_from_file(SRC_DIR + "/gem2_%d.jpeg" % i)
		if src.is_empty():
			print("LOAD FAILED gem2_", i)
			quit(1)
		var cell := _make_cell(src)
		atlas.blit_rect(cell, Rect2i(0, 0, GEM, GEM), Vector2i((i % COLS) * GEM, (i / COLS) * GEM))
	# 第 9 格：炸弹（index 8），第 10 格：彩虹（index 9）—— 5 列布局：(8%5,8/5)=(3,1)、(9%5,9/5)=(4,1)
	var bomb := Image.load_from_file(SRC_DIR + "/gem_bomb.jpeg")
	var rainbow := Image.load_from_file(SRC_DIR + "/gem_rainbow.jpeg")
	if bomb.is_empty() or rainbow.is_empty():
		print("LOAD FAILED item art")
		quit(1)
	atlas.blit_rect(_make_cell(bomb), Rect2i(0, 0, GEM, GEM), Vector2i((8 % COLS) * GEM, (8 / COLS) * GEM))
	atlas.blit_rect(_make_cell(rainbow), Rect2i(0, 0, GEM, GEM), Vector2i((9 % COLS) * GEM, (9 / COLS) * GEM))
	var ok := atlas.save_png(OUT)
	print("atlas_gems.png saved=", ok, " ", atlas.get_width(), "x", atlas.get_height())
	quit(0)
