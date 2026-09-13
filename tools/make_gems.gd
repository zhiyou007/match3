extends SceneTree

# 宝石图圆角处理：把四角变成透明，保存为 PNG 到 assets/
const SRC_DIR := "C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/assets_raw"
const OUT_DIR := "C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/assets"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for i in 8:
		var img := Image.load_from_file(SRC_DIR + "/gem_%d.jpeg" % i)
		if img.is_empty():
			print("LOAD FAILED gem_", i)
			continue
		var w := img.get_width()
		var h := img.get_height()
		img.convert(Image.FORMAT_RGBA8)
		var r := int(min(w, h) * 0.09)
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
		var ok := img.save_png(OUT_DIR + "/gem_%d.png" % i)
		print("gem_", i, ".png ", w, "x", h, " r=", r, " saved=", ok)
	quit(0)
