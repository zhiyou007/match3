extends SceneTree

# 宝石图集生成：统一 8 色宝石主体大小（最长边缩到统一尺寸、居中），合并为一张 atlas_gems.png
# 输出 4x2 图集（每格 128x128，共 512x256），程序用 AtlasTexture region 分块读取
const SRC_DIR := "C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/assets_raw"
const OUT := "C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/assets/atlas_gems.png"
const GEM := 128            # 单格尺寸
const BODY := 96            # 宝石主体统一尺寸（占格子 75%）
const COLS := 4
const ROWS := 2


func _init() -> void:
	call_deferred("_run")


func _keyout(src: Image) -> void:
	# 抠黑：max(rgb) 越小越透明
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


func _alpha_bbox(src: Image) -> Rect2i:
	# 计算不透明主体包围盒
	var w := src.get_width()
	var h := src.get_height()
	var minx := w
	var miny := h
	var maxx := -1
	var maxy := -1
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.05:
				minx = mini(minx, x)
				miny = mini(miny, y)
				maxx = maxi(maxx, x)
				maxy = maxi(maxy, y)
	if maxx < 0:
		return Rect2i(0, 0, w, h)
	return Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1)


func _extract_body(src: Image) -> Image:
	# 抠出主体 → 等比缩放到 BODY 内 → 居中贴到 GEM 画布
	var bbox := _alpha_bbox(src)
	var body := src.get_region(bbox)
	body.convert(Image.FORMAT_RGBA8)
	# 等比缩放：最长边 = BODY
	var longest := maxi(body.get_width(), body.get_height())
	if longest > BODY:
		var s := float(BODY) / float(longest)
		body.resize(maxi(1, int(body.get_width() * s)), maxi(1, int(body.get_height() * s)), Image.INTERPOLATE_LANCZOS)
	elif longest < BODY:
		var s := float(BODY) / float(longest)
		body.resize(maxi(1, int(body.get_width() * s)), maxi(1, int(body.get_height() * s)), Image.INTERPOLATE_LANCZOS)
	# 居中贴到透明画布
	var canvas := Image.create(GEM, GEM, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	var ox := (GEM - body.get_width()) / 2
	var oy := (GEM - body.get_height()) / 2
	canvas.blit_rect(body, Rect2i(0, 0, body.get_width(), body.get_height()), Vector2i(ox, oy))
	return canvas


func _run() -> void:
	var atlas := Image.create(GEM * COLS, GEM * ROWS, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0, 0, 0, 0))
	for i in 8:
		var src := Image.load_from_file(SRC_DIR + "/gem2_%d.jpeg" % i)
		if src.is_empty():
			print("LOAD FAILED gem2_", i)
			quit(1)
		src.convert(Image.FORMAT_RGBA8)
		_keyout(src)
		var cell := _extract_body(src)
		atlas.blit_rect(cell, Rect2i(0, 0, GEM, GEM), Vector2i((i % COLS) * GEM, (i / COLS) * GEM))
		print("gem_", i, " body size: ", cell.get_width(), "x", cell.get_height())
	var ok := atlas.save_png(OUT)
	print("atlas_gems.png saved=", ok, " ", atlas.get_width(), "x", atlas.get_height())
	quit(0)
