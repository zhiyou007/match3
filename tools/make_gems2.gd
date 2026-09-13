extends SceneTree

# 第二批宝石图处理：抠掉纯黑背景（深色 -> 透明）+ 四角圆角，覆盖 assets/gem_*.png
const SRC_DIR := "C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/assets_raw"
const OUT_DIR := "C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/assets"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for i in 8:
		var img := Image.load_from_file(SRC_DIR + "/gem2_%d.jpeg" % i)
		if img.is_empty():
			print("LOAD FAILED gem2_", i)
			continue
		var w := img.get_width()
		var h := img.get_height()
		img.convert(Image.FORMAT_RGBA8)
		# 1) 抠黑：max(rgb) 越小越透明（宝石主体亮色保留，边缘光晕渐变）
		for y in h:
			for x in w:
				var c: Color = img.get_pixel(x, y)
				var mx := maxf(c.r, maxf(c.g, c.b))
				if mx <= 0.16:
					img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
				elif mx < 0.38:
					var a := (mx - 0.16) / 0.22
					img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
		# 2) 四角圆角透明
		var r := int(min(w, h) * 0.10)
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
		# 3) 缩到 128x128（显示 54px 足够，大幅减小包体）
		img.resize(128, 128, Image.INTERPOLATE_LANCZOS)
		var ok := img.save_png(OUT_DIR + "/gem_%d.png" % i)
		print("gem_", i, ".png -> 128x128 saved=", ok)
	quit(0)
