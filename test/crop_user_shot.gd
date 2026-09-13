extends SceneTree

# 放大用户截图的关键区域，确认实际渲染内容
const SRC := "C:/Users/Administrator/AppData/Local/Doubao/User Data/ClipboardTemp/45922092-ba2b-42ee-9edd-030c0dde8a2d.png"
const OUT_DIR := "C:/Users/Administrator/Doubao/chats/2026-09-12/new-chat/match3/screenshots/user_crops"


func _init() -> void:
	call_deferred("_run")


func _crop_and_save(img: Image, rect: Rect2i, name: String, scale := 3) -> void:
	var crop := img.get_region(rect)
	crop.resize(rect.size.x * scale, rect.size.y * scale, Image.INTERPOLATE_NEAREST)
	crop.save_png(OUT_DIR + "/" + name + ".png")
	print("saved ", name, " rect=", rect, " -> ", crop.get_width(), "x", crop.get_height())


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var img := Image.load_from_file(SRC)
	print("source size: ", img.get_width(), "x", img.get_height())

	# 顶栏右侧（分数/步数区域）
	_crop_and_save(img, Rect2i(500, 30, 210, 80), "topbar_score")

	# 结算标题
	_crop_and_save(img, Rect2i(200, 240, 320, 110), "result_title")

	# 星级
	_crop_and_save(img, Rect2i(200, 330, 320, 90), "result_stars")

	# 得分行
	_crop_and_save(img, Rect2i(180, 380, 360, 80), "result_detail")

	# 按钮区
	_crop_and_save(img, Rect2i(150, 450, 420, 190), "result_buttons")

	# 棋盘中央
	_crop_and_save(img, Rect2i(100, 150, 520, 500), "board_mid")

	quit(0)
