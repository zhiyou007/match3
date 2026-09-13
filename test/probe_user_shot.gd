extends SceneTree

# 采样用户截图关键点：面板是否存在、文字颜色、按钮颜色
const SRC := "C:/Users/Administrator/AppData/Local/Doubao/User Data/ClipboardTemp/45922092-ba2b-42ee-9edd-030c0dde8a2d.png"
var img: Image


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	img = Image.load_from_file(SRC)
	print("size: ", img.get_width(), "x", img.get_height())

	var pts := {
		"panel_center(360,300)": Vector2i(360, 300),
		"panel_left(160,300)": Vector2i(160, 300),
		"panel_right(560,300)": Vector2i(560, 300),
		"btn_primary(360,500)": Vector2i(360, 500),
		"btn_secondary(360,570)": Vector2i(360, 570),
		"overlay(20,800)": Vector2i(20, 800),
		"board_cell(160,600)": Vector2i(160, 600),
		"title_area(360,275)": Vector2i(360, 275),
	}
	for k in pts:
		var p: Color = img.get_pixelv(pts[k])
		print("PX ", k, " rgb=(", int(p.r * 255), ",", int(p.g * 255), ",", int(p.b * 255), ")")

	# 扫描面板区域（110-610, 210-630）统计颜色分布
	var white := 0
	var colored := 0
	var total := 0
	for y in range(220, 620, 6):
		for x in range(120, 600, 6):
			var p: Color = img.get_pixel(x, y)
			total += 1
			if p.r > 0.9 and p.g > 0.9 and p.b > 0.9:
				white += 1
			elif p.r < 0.85 and p.g < 0.85 and p.b < 0.85 and not (p.r > 0.8 and p.g > 0.75 and p.b < 0.5):
				colored += 1
	print("panel region: white=", white, " colored=", colored, " total=", total)

	# 扫描按钮行（y 460-590）找绿色按钮
	var green := 0
	for y in range(460, 590):
		for x in range(160, 560):
			var p: Color = img.get_pixel(x, y)
			if p.g > 0.65 and p.r < 0.55 and p.b < 0.6:
				green += 1
	print("green button pixels: ", green)

	quit(0)
