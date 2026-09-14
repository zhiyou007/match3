extends Control

# ===== 消消乐（Match-3）游戏场景 =====
# 点击方块选中，点击相邻方块交换；三连及以上消除、下落、连锁计分。
# 关卡参数来自 GameState（棋盘大小/色数/目标分/步数），达标即过关。

const UIKit = preload("res://scripts/ui_kit.gd")

const COLORS: Array[Color] = [
	Color("#ff6b6b"), Color("#ffd93d"), Color("#6bcb77"),
	Color("#4d96ff"), Color("#9b5de5"), Color("#ff9f1c"), Color("#00bbf9"),
	Color("#f15bb5")
]

# 特殊道具类型（图集 index 8=炸弹，9=彩虹）
const BOMB := 8
const RAINBOW := 9

const VIEW_W := 720
const VIEW_H := 840

var grid := 8
var cell := 64
var types := 6
var max_steps := 30
var target := 300
var level_no := 1

var board: Array = []            # board[y][x] -> int（颜色索引，-1 为空）
var nodes: Array = []            # nodes[y][x] -> TextureRect（宝石方块）
var _gem_textures: Array = []    # 宝石纹理（与 COLORS 索引对应）
var selected := Vector2i(-1, -1)
var busy := false
# 交换操作队列：消除动画进行中不锁输入，新操作入队依次执行
var _swap_chain_running := false
var _pending_swaps: Array = []
var game_over := false
var paused := false
var score := 0
var steps := 30
var is_win := false

var level_label: Label
var target_label: Label
var score_label: Label
var steps_label: Label
var overlay: ColorRect
var result_panel: TextureRect
var result_title: Label
var result_detail: Label
var result_stars: Label
var btn_primary: Button
var btn_secondary: Button
var pause_overlay: Control

# 进度条与棋盘底纹
var _progress_fill: Panel
var _board_panel: TextureRect
var _cell_bgs: Array = []

const _TEX_HEADER := "res://assets/ui/ui_header.png"
const _TEX_RESULT := "res://assets/ui/ui_result.png"
const _TEX_PAUSE := "res://assets/ui/ui_pause.png"
const _TEX_BTN_PRIMARY := "res://assets/ui/ui_btn_primary.png"
const _TEX_BTN_SECONDARY := "res://assets/ui/ui_btn_secondary.png"
const _TEX_BOARD := "res://assets/ui/ui_board.png"

# 道具
var hints_left := 3
var shuffles_left := 2
var steps_add_left := 1
var hint_btn: Button
var shuffle_btn: Button
var steps_btn: Button


func _ready() -> void:
	size = Vector2(VIEW_W, VIEW_H)
	_load_gem_textures()
	_build_ui()
	_setup_level()
	_start_game()


func _load_gem_textures() -> void:
	_gem_textures.clear()
	# 图集：assets/atlas_gems.png（4x2，每格 128x128），用 AtlasTexture 分块读取
	var atlas_path := "res://assets/atlas_gems.png"
	var atlas: Texture2D = null
	if ResourceLoader.exists(atlas_path):
		atlas = load(atlas_path)
	for i in COLORS.size() + 2:
		var tex: Texture2D = null
		if atlas != null:
			var at := AtlasTexture.new()
			at.atlas = atlas
			at.region = Rect2((i % 5) * 128, (i / 5) * 128, 128, 128)
			tex = at
		if tex == null:
			tex = _fallback_cell_texture(COLORS[i % COLORS.size()])
		_gem_textures.append(tex)


func _fallback_cell_texture(color: Color) -> ImageTexture:
	# 兜底：无导入资源时生成圆角色块纹理（测试/异常环境）
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var r := 14
	var rr := float(r) * r
	for y in 64:
		for x in 64:
			var dx := 0
			var dy := 0
			if x < r and y < r:
				dx = r - 1 - x
				dy = r - 1 - y
			elif x >= 64 - r and y < r:
				dx = x - (64 - r)
				dy = r - 1 - y
			elif x < r and y >= 64 - r:
				dx = r - 1 - x
				dy = y - (64 - r)
			elif x >= 64 - r and y >= 64 - r:
				dx = x - (64 - r)
				dy = y - (64 - r)
			if dx * dx + dy * dy > rr:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


func _grid_origin() -> Vector2:
	return Vector2((VIEW_W - grid * cell) / 2.0, 150)


# ---------- UI ----------

func _style(ctl: Control, size_px: int, outline_px := 0, outline_color := Color(0, 0, 0, 0)) -> void:
	ctl.add_theme_font_override("font", UIKit.font())
	ctl.add_theme_font_size_override("font_size", size_px)
	if outline_px > 0:
		ctl.add_theme_color_override("font_outline_color", outline_color)
		ctl.add_theme_constant_override("outline_size", outline_px)


func _make_button(text: String, pos: Vector2, size_px: Vector2, color: Color, font_px: int) -> Button:
	return UIKit.make_button(text, pos, size_px, color, font_px)


func _make_image_button(text: String, pos: Vector2, size_px: Vector2, tex_path: String, font_px: int) -> Button:
	# 图片按钮：用 UI 素材图做背景（StyleBoxTexture），保留 Button 文字与信号
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size_px
	b.focus_mode = Control.FOCUS_NONE
	b.pivot_offset = size_px / 2.0
	var sb := StyleBoxTexture.new()
	if ResourceLoader.exists(tex_path):
		sb.texture = load(tex_path)
	sb.set_content_margin_all(10)
	b.add_theme_stylebox_override("normal", sb)
	var sb_h: StyleBoxTexture = sb.duplicate()
	sb_h.modulate_color = Color(1.05, 1.05, 1.05, 1.0)
	b.add_theme_stylebox_override("hover", sb_h)
	var sb_p: StyleBoxTexture = sb.duplicate()
	sb_p.modulate_color = Color(0.92, 0.92, 0.92, 1.0)
	b.add_theme_stylebox_override("pressed", sb_p)
	_style(b, font_px, maxi(1, int(font_px / 8)), Color(0, 0, 0, 0.35))
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
		b.scale = Vector2(0.96, 0.96)
	)
	b.button_up.connect(func() -> void:
		b.scale = Vector2.ONE
	)
	return b


func _build_ui() -> void:
	# 背景：星空渐变 + 光斑
	UIKit.bg_gradient(self, Color("#3d1f7a"), Color("#16245e"))
	UIKit.sparkle(self, 22, VIEW_W, VIEW_H)

	# 顶部信息面板（游戏UI 素材图）
	var header := TextureRect.new()
	if ResourceLoader.exists(_TEX_HEADER):
		header.texture = load(_TEX_HEADER)
	header.position = Vector2(132, 12)
	header.size = Vector2(576, 115)
	header.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	header.stretch_mode = TextureRect.STRETCH_SCALE
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var back := _make_button("← 菜单", Vector2(16, 16), Vector2(104, 46), Color("#8a7bb5"), 18)
	back.pressed.connect(_go_menu)
	add_child(back)

	# 关卡徽章（左侧胶囊）
	level_label = Label.new()
	level_label.position = Vector2(148, 20)
	level_label.size = Vector2(120, 38)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.modulate = Color("#ffffff")
	var lpill := StyleBoxFlat.new()
	lpill.bg_color = Color("#a06cd5")
	lpill.set_corner_radius_all(19)
	lpill.border_width_left = 2
	lpill.border_width_top = 2
	lpill.border_width_right = 2
	lpill.border_width_bottom = 2
	lpill.border_color = Color(1, 1, 1, 0.5)
	lpill.shadow_color = Color(0, 0, 0, 0.3)
	lpill.shadow_size = 4
	lpill.shadow_offset = Vector2(0, 2)
	level_label.add_theme_stylebox_override("normal", lpill)
	_style(level_label, 22, 2, Color("#2a1058"))
	add_child(level_label)

	# 目标胶囊
	target_label = Label.new()
	target_label.text = "目标：%d 分" % target
	target_label.position = Vector2(148, 68)
	target_label.size = Vector2(200, 32)
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	target_label.modulate = Color(1, 1, 1, 0.85)
	_style(target_label, 16)
	add_child(target_label)

	# 分数（右侧金色大字）
	score_label = Label.new()
	score_label.position = Vector2(360, 14)
	score_label.size = Vector2(336, 44)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.modulate = Color("#ffd23f")
	_style(score_label, 28, 2, Color("#5a3a00"))
	add_child(score_label)

	# 步数（右侧胶囊）
	steps_label = Label.new()
	steps_label.position = Vector2(420, 60)
	steps_label.size = Vector2(276, 36)
	steps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	steps_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	steps_label.modulate = Color("#7fd8ff")
	_style(steps_label, 20, 1, Color("#0a2a4a"))
	add_child(steps_label)

	# 进度条：轨道 + 金色填充
	var track := UIKit.make_panel(self, Vector2(148, 102), Vector2(544, 14), Color(0, 0, 0, 0.35), 7)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_fill = Panel.new()
	_progress_fill.position = Vector2(152, 106)
	_progress_fill.size = Vector2(0, 6)
	_progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color("#ffd23f")
	psb.set_corner_radius_all(3)
	psb.border_width_left = 1
	psb.border_width_top = 1
	psb.border_width_right = 1
	psb.border_width_bottom = 1
	psb.border_color = Color(1, 1, 0.8, 0.9)
	_progress_fill.add_theme_stylebox_override("panel", psb)
	add_child(_progress_fill)

	# 道具栏
	hint_btn = _make_button("提示 ×3", Vector2(150, 686), Vector2(120, 50), Color("#4d96ff"), 19)
	hint_btn.pressed.connect(_use_hint)
	add_child(hint_btn)

	shuffle_btn = _make_button("重排 ×2", Vector2(300, 686), Vector2(120, 50), Color("#a06cd5"), 19)
	shuffle_btn.pressed.connect(_use_shuffle)
	add_child(shuffle_btn)

	steps_btn = _make_button("+步 ×1", Vector2(450, 686), Vector2(120, 50), Color("#6bcb77"), 19)
	steps_btn.pressed.connect(_use_add_steps)
	add_child(steps_btn)

	var hint := Label.new()
	hint.text = "拖动宝石滑向相邻方向交换 · 4连炸弹 · 5连彩虹"
	hint.position = Vector2(16, 812)
	hint.size = Vector2(688, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1, 1, 1, 0.5)
	_style(hint, 15)
	add_child(hint)

	_build_result_panel()
	_build_pause_panel()
	_update_labels(0.0)


func _build_board_panel() -> void:
	# 棋盘底板（金色外框素材图）+ 每格底纹（在宝石下方）
	if _board_panel != null and is_instance_valid(_board_panel):
		_board_panel.queue_free()
	for row in _cell_bgs:
		for c in row:
			if c != null:
				(c as Control).queue_free()
	_cell_bgs.clear()
	var origin := _grid_origin()
	_board_panel = TextureRect.new()
	if ResourceLoader.exists(_TEX_BOARD):
		_board_panel.texture = load(_TEX_BOARD)
	_board_panel.position = origin - Vector2(10, 10)
	_board_panel.size = Vector2(660, 660)
	_board_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_board_panel.stretch_mode = TextureRect.STRETCH_SCALE
	_board_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_board_panel)
	for y in grid:
		var brow: Array = []
		for x in grid:
			var bgc := Panel.new()
			bgc.position = origin + Vector2(x * cell, y * cell) + Vector2(3, 3)
			bgc.size = Vector2(cell - 6, cell - 6)
			bgc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var bsb := StyleBoxFlat.new()
			bsb.bg_color = Color(1, 1, 1, 0.08)
			bsb.set_corner_radius_all(10)
			bgc.add_theme_stylebox_override("panel", bsb)
			add_child(bgc)
			brow.append(bgc)
		_cell_bgs.append(brow)


func _build_result_panel() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.05, 0.02, 0.15, 0.72)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 10
	overlay.visible = false
	add_child(overlay)

	result_panel = TextureRect.new()
	if ResourceLoader.exists(_TEX_RESULT):
		result_panel.texture = load(_TEX_RESULT)
	result_panel.position = Vector2(110, 150)
	result_panel.size = Vector2(500, 560)
	result_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_panel.stretch_mode = TextureRect.STRETCH_SCALE
	result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_panel.z_index = 10
	result_panel.visible = false
	add_child(result_panel)

	result_title = Label.new()
	result_title.text = ""
	result_title.position = Vector2(110, 180)
	result_title.size = Vector2(500, 76)
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_title.z_index = 10
	_style(result_title, 46, 5, Color("#3a1050"))
	add_child(result_title)

	result_stars = Label.new()
	result_stars.text = ""
	result_stars.position = Vector2(110, 268)
	result_stars.size = Vector2(500, 64)
	result_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_stars.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_stars.z_index = 10
	_style(result_stars, 40, 4, Color("#5a3a00"))
	add_child(result_stars)

	result_detail = Label.new()
	result_detail.text = ""
	result_detail.position = Vector2(110, 344)
	result_detail.size = Vector2(500, 60)
	result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_detail.modulate = Color(1, 1, 1, 0.85)
	result_detail.z_index = 10
	_style(result_detail, 21)
	add_child(result_detail)

	btn_primary = _make_image_button("", Vector2(170, 428), Vector2(380, 60), _TEX_BTN_PRIMARY, 26)
	btn_primary.visible = false
	btn_primary.z_index = 10
	btn_primary.pressed.connect(_on_primary)
	add_child(btn_primary)

	btn_secondary = _make_image_button("", Vector2(170, 502), Vector2(380, 58), _TEX_BTN_SECONDARY, 22)
	btn_secondary.visible = false
	btn_secondary.z_index = 10
	btn_secondary.pressed.connect(_on_secondary)
	add_child(btn_secondary)


func _build_pause_panel() -> void:
	pause_overlay = Control.new()
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.visible = false
	pause_overlay.z_index = 10
	add_child(pause_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.02, 0.15, 0.66)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(dim)

	var panel := TextureRect.new()
	if ResourceLoader.exists(_TEX_PAUSE):
		panel.texture = load(_TEX_PAUSE)
	panel.position = Vector2(150, 170)
	panel.size = Vector2(420, 470)
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.add_child(panel)

	var title := Label.new()
	title.text = "暂停"
	title.position = Vector2(150, 200)
	title.size = Vector2(420, 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style(title, 40, 4, Color("#3a1050"))
	title.modulate = Color("#ffffff")
	pause_overlay.add_child(title)

	var resume := _make_image_button("继续", Vector2(200, 296), Vector2(320, 52), _TEX_BTN_PRIMARY, 24)
	resume.pressed.connect(_toggle_pause)
	pause_overlay.add_child(resume)

	var restart := _make_image_button("重新开始", Vector2(200, 358), Vector2(320, 52), _TEX_BTN_PRIMARY, 24)
	restart.pressed.connect(_on_restart)
	pause_overlay.add_child(restart)

	var menu := _make_image_button("返回菜单", Vector2(200, 420), Vector2(320, 52), _TEX_BTN_SECONDARY, 24)
	menu.pressed.connect(_go_menu)
	pause_overlay.add_child(menu)


# ---------- 关卡与棋盘 ----------

func _setup_level() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		level_no = gs.current_level
		var d: Dictionary = gs.level_data(level_no)
		target = int(d["target"])
		max_steps = int(d["steps"])
		grid = int(d["size"])
		types = int(d["types"])
	else:
		level_no = 1
		target = 300
		max_steps = 30
		grid = 8
		types = 6
	cell = 64
	steps = max_steps
	level_label.text = "第 %d 关" % level_no
	target_label.text = "目标：%d 分" % target
	_build_board_panel()


func _start_game() -> void:
	for row in nodes:
		for n in row:
			if n != null:
				n.queue_free()
	nodes.clear()
	board.clear()
	score = 0
	steps = max_steps
	game_over = false
	busy = false
	_swap_chain_running = false
	_pending_swaps.clear()
	selected = Vector2i(-1, -1)
	is_win = false
	hints_left = 3
	shuffles_left = 2
	steps_add_left = 1
	_update_item_buttons()
	overlay.visible = false
	result_panel.visible = false
	result_title.visible = false
	result_stars.visible = false
	result_stars.scale = Vector2.ONE
	result_detail.visible = false
	btn_primary.visible = false
	btn_secondary.visible = false
	_init_board()
	if not _has_valid_move():
		_reshuffle()
	_update_labels(0.0)


func _init_board() -> void:
	for y in grid:
		var row: Array = []
		var nrow: Array = []
		board.append(row)
		for x in grid:
			var t := randi() % types
			while _forms_match(x, y, t):
				t = randi() % types
			row.append(t)
			nrow.append(_make_cell(x, y, t))
		nodes.append(nrow)


func _forms_match(x: int, y: int, t: int) -> bool:
	if x >= 2 and board[y][x - 1] == t and board[y][x - 2] == t:
		return true
	if y >= 2 and board[y - 1][x] == t and board[y - 2][x] == t:
		return true
	return false


func _make_cell(x: int, y: int, t: int) -> TextureRect:
	var c := TextureRect.new()
	c.texture = _gem_textures[t]
	c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	c.position = _cell_pos(Vector2i(x, y))
	c.size = Vector2(cell - 10, cell - 10)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c


func _cell_pos(cell_p: Vector2i) -> Vector2:
	return _grid_origin() + Vector2(cell_p) * cell + Vector2(5, 5)


func _reshuffle() -> void:
	for row in nodes:
		for n in row:
			if n != null:
				n.queue_free()
	nodes.clear()
	board.clear()
	_init_board()


# ---------- 道具 ----------

func _update_item_buttons() -> void:
	hint_btn.text = "提示 ×%d" % hints_left
	shuffle_btn.text = "重排 ×%d" % shuffles_left
	steps_btn.text = "+步 ×%d" % steps_add_left


func _use_hint() -> void:
	if busy or _swap_chain_running or game_over or hints_left <= 0:
		return
	hints_left -= 1
	hint_btn.text = "提示 ×%d" % hints_left
	busy = true
	await _highlight_hint()
	busy = false


func _highlight_hint() -> void:
	# 找一个可交换产生消除的相邻对并脉冲高亮
	for y in grid:
		for x in grid:
			var a := Vector2i(x, y)
			for dir in [Vector2i(1, 0), Vector2i(0, 1)]:
				var b: Vector2i = a + dir
				if b.x >= grid or b.y >= grid:
					continue
				_swap_data(a, b)
				var ok := not _find_matches().is_empty()
				_swap_data(a, b)
				if ok:
					await _pulse_pair(a, b)
					return


func _pulse_pair(a: Vector2i, b: Vector2i) -> void:
	var na: TextureRect = nodes[a.y][a.x]
	var nb: TextureRect = nodes[b.y][b.x]
	if na == null or nb == null:
		return
	var t := create_tween()
	t.set_loops(3)
	for i in 3:
		t.tween_property(na, "scale", Vector2(1.28, 1.28), 0.14)
		t.tween_property(nb, "scale", Vector2(1.28, 1.28), 0.14)
		t.tween_property(na, "scale", Vector2(1.0, 1.0), 0.14)
		t.tween_property(nb, "scale", Vector2(1.0, 1.0), 0.14)
	await t.finished


func _use_shuffle() -> void:
	if busy or _swap_chain_running or game_over or shuffles_left <= 0:
		return
	shuffles_left -= 1
	shuffle_btn.text = "重排 ×%d" % shuffles_left
	_reshuffle()
	_sfx("swap")


func _use_add_steps() -> void:
	if busy or _swap_chain_running or game_over or steps_add_left <= 0:
		return
	steps_add_left -= 1
	steps_btn.text = "+步 ×%d" % steps_add_left
	steps += 5
	_update_labels(0.0)
	_sfx("click")


# ---------- 输入 ----------

var press_cell := Vector2i(-1, -1)
var press_screen := Vector2.ZERO
var press_node: TextureRect
var swapped := false


func _input(event: InputEvent) -> void:
	if game_over or busy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_cell(event.global_position)
		else:
			_release_cell(event.global_position)
	elif event is InputEventMouseMotion and press_cell.x >= 0 and not swapped:
		_drag_cell(event.global_position)


func _press_cell(gp: Vector2) -> void:
	press_cell = _cell_at(gp)
	press_screen = gp
	swapped = false
	press_node = null
	if press_cell == Vector2i(-1, -1):
		_set_selected(Vector2i(-1, -1))
		return
	press_node = nodes[press_cell.y][press_cell.x]
	if press_node == null:
		return
	press_node.modulate = Color(1, 1, 1, 0.85)
	press_node.scale = Vector2(1.15, 1.15)


func _drag_cell(gp: Vector2) -> void:
	if press_node == null:
		return
	# 方向用「相对按下位置的位移」判定；宝石不跟手，保证交换是干净直线
	var offset := gp - press_screen
	if offset.length() > cell * 0.28:
		var dir := Vector2i.ZERO
		if absf(offset.x) > absf(offset.y):
			dir = Vector2i(int(sign(offset.x)), 0)
		else:
			dir = Vector2i(0, int(sign(offset.y)))
		var target := press_cell + dir
		if target.x >= 0 and target.y >= 0 and target.x < grid and target.y < grid:
			swapped = true
			var c := press_cell
			press_cell = Vector2i(-1, -1)
			press_node = null
			_queue_swap(c, target)


func _release_cell(gp: Vector2) -> void:
	if press_cell == Vector2i(-1, -1) or press_node == null:
		press_cell = Vector2i(-1, -1)
		press_node = null
		return
	var moved := (gp - press_screen).length()
	press_node.modulate = Color.WHITE
	press_node.scale = Vector2.ONE
	var c := press_cell
	press_cell = Vector2i(-1, -1)
	press_node = null
	if not swapped:
		if moved < 10.0:
			_on_cell_clicked(c)
		else:
			# 拖到无效方向：方块未动，直接选中
			_set_selected(c)


func _cell_at(p: Vector2) -> Vector2i:
	var local := p - _grid_origin()
	if local.x < 0 or local.y < 0:
		return Vector2i(-1, -1)
	var c := Vector2i(int(local.x / cell), int(local.y / cell))
	if c.x >= grid or c.y >= grid:
		return Vector2i(-1, -1)
	return c


func _on_cell_clicked(cell_p: Vector2i) -> void:
	if cell_p == Vector2i(-1, -1):
		_set_selected(Vector2i(-1, -1))
		return
	if selected == Vector2i(-1, -1):
		_set_selected(cell_p)
		_sfx("click")
	elif selected == cell_p:
		_set_selected(Vector2i(-1, -1))
	else:
		var a := selected
		var diff := a - cell_p
		if abs(diff.x) + abs(diff.y) == 1:
			_set_selected(Vector2i(-1, -1))
			_queue_swap(a, cell_p)
		else:
			_set_selected(cell_p)
			_sfx("click")


func _set_selected(cell_p: Vector2i) -> void:
	if selected.x >= 0 and selected.y >= 0 and selected.x < grid and selected.y < grid:
		var old: TextureRect = nodes[selected.y][selected.x]
		if old != null:
			old.modulate = Color.WHITE
			old.scale = Vector2.ONE
	selected = cell_p
	if cell_p.x >= 0:
		var n: TextureRect = nodes[cell_p.y][cell_p.x]
		if n != null:
			n.modulate = Color(1, 1, 1, 0.6)
			n.scale = Vector2(1.12, 1.12)


# ---------- 交换与消除 ----------

func _queue_swap(a: Vector2i, b: Vector2i) -> void:
	if game_over:
		return
	_pending_swaps.append([a, b])
	if not _swap_chain_running:
		_process_queue()


func _process_queue() -> void:
	_swap_chain_running = true
	while not _pending_swaps.is_empty():
		if game_over:
			break
		var pair: Array = _pending_swaps.pop_front()
		await _try_swap(pair[0], pair[1])
	_swap_chain_running = false


func _try_swap(a: Vector2i, b: Vector2i) -> void:
	if game_over:
		return
	_swap_data(a, b)
	var tb: int = board[b.y][b.x]
	# 特殊道具触发：交换后落到 b 位置的是炸弹/彩虹 → 触发效果
	if tb == BOMB or tb == RAINBOW:
		steps -= 1
		_update_labels(0.0)
		_sfx("swap")
		await _animate_swap(a, b)
		await _trigger_special(b, a)
		await _apply_gravity()
		await _resolve_loop()
		if score >= target:
			_win_level()
		elif steps <= 0:
			_lose_level()
		elif not _has_valid_move():
			_reshuffle()
		return
	var matches := _find_matches()
	if not matches.is_empty():
		steps -= 1
		_update_labels(0.0)
		_sfx("swap")
		await _animate_swap(a, b)
		await _resolve_loop()
		if score >= target:
			_win_level()
		elif steps <= 0:
			_lose_level()
		elif not _has_valid_move():
			_reshuffle()
	else:
		await _animate_swap(a, b)
		_swap_data(a, b)
		var na: TextureRect = nodes[b.y][b.x]
		var nb: TextureRect = nodes[a.y][a.x]
		nodes[a.y][a.x] = na
		nodes[b.y][b.x] = nb
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(na, "position", _cell_pos(a), 0.1)
		t.tween_property(nb, "position", _cell_pos(b), 0.1)
		await t.finished


# ---------- 特殊道具 ----------

func _trigger_special(pos: Vector2i, ref: Vector2i) -> void:
	var kind: int = board[pos.y][pos.x]
	if kind == BOMB:
		await _bomb_explode(pos)
	elif kind == RAINBOW:
		var color: int = board[ref.y][ref.x]
		if _is_normal(color):
			await _rainbow_clear(color)
		else:
			# 彩虹 + 炸弹：全屏爆炸
			await _bomb_explode(Vector2i(grid / 2, grid / 2), true)


func _bomb_explode(center: Vector2i, full_screen := false) -> void:
	# 炸弹：3×3 范围消除（full_screen=全屏爆炸）
	var cells: Array = []
	if full_screen:
		for y in grid:
			for x in grid:
				if board[y][x] >= 0:
					cells.append(Vector2i(x, y))
	else:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var p := center + Vector2i(dx, dy)
				if p.x >= 0 and p.y >= 0 and p.x < grid and p.y < grid and board[p.y][p.x] >= 0:
					cells.append(p)
	if cells.is_empty():
		return
	score += cells.size() * 10 + 30
	_update_labels(0.0)
	_flash_screen()
	await _animate_clear(cells)
	_screen_shake(3)
	_sfx("mega")


func _rainbow_clear(color: int) -> void:
	# 彩虹：全屏消除指定颜色
	var cells: Array = []
	for y in grid:
		for x in grid:
			if board[y][x] == color:
				cells.append(Vector2i(x, y))
	if cells.is_empty():
		return
	score += cells.size() * 10 + 50
	_update_labels(0.0)
	_flash_screen()
	await _animate_clear(cells)
	_screen_shake(2)
	_sfx("mega")


func _swap_data(a: Vector2i, b: Vector2i) -> void:
	var tmp: int = board[a.y][a.x]
	board[a.y][a.x] = board[b.y][b.x]
	board[b.y][b.x] = tmp


func _animate_swap(a: Vector2i, b: Vector2i) -> void:
	var na: TextureRect = nodes[a.y][a.x]
	var nb: TextureRect = nodes[b.y][b.x]
	nodes[a.y][a.x] = nb
	nodes[b.y][b.x] = na
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(na, "position", _cell_pos(b), 0.12)
	t.tween_property(nb, "position", _cell_pos(a), 0.12)
	await t.finished


func _find_matches() -> Array:
	var marked := {}
	for y in grid:
		var run_start := 0
		for x in range(1, grid + 1):
			if x < grid and _is_normal(board[y][x]) and board[y][x] == board[y][run_start]:
				continue
			if x - run_start >= 3 and _is_normal(board[y][run_start]):
				for k in range(run_start, x):
					marked[Vector2i(k, y)] = true
			run_start = x
	for x in grid:
		var run_start := 0
		for y in range(1, grid + 1):
			if y < grid and _is_normal(board[y][x]) and board[y][x] == board[run_start][x]:
				continue
			if y - run_start >= 3 and _is_normal(board[run_start][x]):
				for k in range(run_start, y):
					marked[Vector2i(x, k)] = true
			run_start = y
	return marked.keys()


func _is_normal(v: int) -> bool:
	return v >= 0 and v < COLORS.size()


func _resolve_loop() -> void:
	var chain := 0
	while true:
		var matches := _find_matches()
		if matches.is_empty():
			break
		chain += 1
		score += matches.size() * 10
		_update_labels(float(chain))
		if chain > 1:
			_sfx("combo")
		var specials := _detect_specials(matches)
		await _animate_clear(matches)
		for pos in specials:
			_spawn_special(pos, specials[pos])
		await _apply_gravity()


func _detect_specials(matches: Array) -> Dictionary:
	# 在消除格中检测 4 连/5 连（同色直线）→ 中间格生成炸弹/彩虹
	# 返回 { Vector2i: int }（位置 → BOMB/RAINBOW）
	var out := {}
	var marked := {}
	for pos in matches:
		marked[pos] = true
	for y in grid:
		var run := 0
		var run_cells: Array = []
		var run_color := -1
		for x in range(grid + 1):
			var cell := Vector2i(x, y)
			if x < grid and marked.has(cell) and (run == 0 or board[y][x] == run_color):
				run += 1
				run_cells.append(cell)
				run_color = board[y][x]
			else:
				if run >= 4:
					var mid: Vector2i = run_cells[run / 2]
					out[mid] = RAINBOW if run >= 5 else BOMB
				run = 0
				run_cells.clear()
				run_color = -1
	for x in grid:
		var run := 0
		var run_cells: Array = []
		var run_color := -1
		for y in range(grid + 1):
			var cell := Vector2i(x, y)
			if y < grid and marked.has(cell) and (run == 0 or board[y][x] == run_color):
				run += 1
				run_cells.append(cell)
				run_color = board[y][x]
			else:
				if run >= 4:
					var mid: Vector2i = run_cells[run / 2]
					if not out.has(mid) or run >= 5:
						out[mid] = RAINBOW if run >= 5 else BOMB
				run = 0
				run_cells.clear()
				run_color = -1
	# 十字/T/L 形：同一格横 >=3 且 竖 >=3 → 彩虹
	for pos in matches:
		if out.has(pos):
			continue
		var c: int = board[pos.y][pos.x]
		var row_len := 1
		var col_len := 1
		for dx in [-1, 1]:
			var nx: int = pos.x + dx
			while nx >= 0 and nx < grid and board[pos.y][nx] == c and marked.has(Vector2i(nx, pos.y)):
				row_len += 1
				nx += dx
		for dy in [-1, 1]:
			var ny: int = pos.y + dy
			while ny >= 0 and ny < grid and board[ny][pos.x] == c and marked.has(Vector2i(pos.x, ny)):
				col_len += 1
				ny += dy
		if row_len >= 3 and col_len >= 3:
			out[pos] = RAINBOW
	return out


func _spawn_special(pos: Vector2i, kind: int) -> void:
	board[pos.y][pos.x] = kind
	var n := _make_cell(pos.x, pos.y, kind)
	nodes[pos.y][pos.x] = n
	n.scale = Vector2(0.1, 0.1)
	n.modulate.a = 0.0
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(n, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(n, "modulate:a", 1.0, 0.15)


func _animate_clear(cells: Array) -> void:
	# 按消除数量分级特效：3消=小爆散 / 4消=强爆散+震动 / 5消以上=全屏闪光+大爆散+强震动
	var count := cells.size()
	var level := 1
	if count >= 5:
		level = 3
	elif count >= 4:
		level = 2
	if level >= 3:
		_flash_screen()
	var tweens: Array = []
	var burst := 1.5 + level * 0.4
	for c in cells:
		var node: TextureRect = nodes[c.y][c.x]
		if node == null:
			continue
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(node, "modulate:a", 0.0, 0.22)
		t.tween_property(node, "scale", Vector2(burst, burst), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tweens.append(t)
		var col: Color = COLORS[board[c.y][c.x]] if _is_normal(board[c.y][c.x]) else Color.WHITE
		_spawn_particles(node.position + node.size / 2.0, col, 12 * level)
	for t in tweens:
		await t.finished
	for c in cells:
		var node: TextureRect = nodes[c.y][c.x]
		if node != null:
			node.queue_free()
			nodes[c.y][c.x] = null
			board[c.y][c.x] = -1
	if level >= 2:
		_screen_shake(level)
	if level == 1:
		_sfx("pop")
	elif level == 2:
		_sfx("power")
	else:
		_sfx("mega")


var _flash_node: ColorRect


func _flash_screen() -> void:
	if _flash_node != null and is_instance_valid(_flash_node):
		return
	_flash_node = ColorRect.new()
	_flash_node.color = Color(1, 1, 1, 0.85)
	_flash_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_node.z_index = 30
	add_child(_flash_node)
	var t := create_tween()
	t.tween_property(_flash_node, "color:a", 0.0, 0.35)
	t.tween_callback(func() -> void:
		if _flash_node != null:
			_flash_node.queue_free()
			_flash_node = null
	)


func _screen_shake(level: int) -> void:
	var t := create_tween()
	var strength := 5.0 * level
	for i in 3:
		t.tween_property(self, "position", Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), 0.04)
	t.tween_property(self, "position", Vector2.ZERO, 0.06)


var _particle_tex: ImageTexture


func _get_particle_texture() -> ImageTexture:
	if _particle_tex == null:
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 0))
		for yy in 16:
			for xx in 16:
				var d := Vector2(xx - 7.5, yy - 7.5).length()
				if d <= 7.5:
					img.set_pixel(xx, yy, Color(1, 1, 1, clampf(1.0 - d / 7.5, 0.0, 1.0)))
		_particle_tex = ImageTexture.create_from_image(img)
	return _particle_tex


func _spawn_particles(pos: Vector2, color: Color, amount := 18) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.texture = _get_particle_texture()
	p.color = color
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.55
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 360)
	p.initial_velocity_min = 80 + amount * 2
	p.initial_velocity_max = 190 + amount * 3
	p.scale_amount_min = 1.6
	p.scale_amount_max = 3.2
	add_child(p)
	p.finished.connect(p.queue_free)


func _apply_gravity() -> void:
	var tweens: Array = []
	for x in grid:
		var stack: Array = []
		for y in range(grid - 1, -1, -1):
			if board[y][x] >= 0:
				stack.append(y)
		var write := grid - 1
		for i in stack.size():
			var src_y: int = stack[i]
			if src_y != write:
				var n: TextureRect = nodes[src_y][x]
				nodes[src_y][x] = null
				nodes[write][x] = n
				board[write][x] = board[src_y][x]
				board[src_y][x] = -1
				var t := create_tween()
				t.tween_property(n, "position", _cell_pos(Vector2i(x, write)), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tweens.append(t)
			else:
				board[write][x] = board[src_y][x]
			write -= 1
		while write >= 0:
			var t := randi() % types
			board[write][x] = t
			var n := _make_cell(x, write, t)
			n.position = _cell_pos(Vector2i(x, -1))
			nodes[write][x] = n
			var tw := create_tween()
			tw.tween_property(n, "position", _cell_pos(Vector2i(x, write)), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tweens.append(tw)
			write -= 1
	for t in tweens:
		await t.finished


# ---------- 音效 ----------

func _sfx(name: String) -> void:
	var sfx := get_node_or_null("/root/SFX")
	if sfx:
		sfx.play(name)


# ---------- 状态 ----------

func _has_valid_move() -> bool:
	for y in grid:
		for x in grid:
			var a := Vector2i(x, y)
			for dir in [Vector2i(1, 0), Vector2i(0, 1)]:
				var b: Vector2i = a + dir
				if b.x < grid and b.y < grid:
					_swap_data(a, b)
					var ok := not _find_matches().is_empty()
					_swap_data(a, b)
					if ok:
						return true
	return false


func _win_level() -> void:
	game_over = true
	busy = false
	_swap_chain_running = false
	_pending_swaps.clear()
	is_win = true
	selected = Vector2i(-1, -1)
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.record_result(level_no, score)
	var stars := 0
	if gs:
		stars = gs.stars_for(level_no, score)
	overlay.visible = true
	result_panel.visible = true
	result_title.visible = true
	result_title.text = "过关！"
	result_title.modulate = Color("#6bcb77")
	result_stars.visible = true
	result_stars.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	result_stars.modulate = Color("#ffd93d")
	result_stars.add_theme_font_size_override("font_size", 36)
	result_stars.scale = Vector2(0.2, 0.2)
	var st := create_tween()
	st.tween_property(result_stars, "scale", Vector2(1.25, 1.25), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	st.tween_property(result_stars, "scale", Vector2.ONE, 0.16)
	result_detail.visible = true
	result_detail.text = "得分 %d  /  目标 %d" % [score, target]
	btn_primary.visible = true
	btn_secondary.visible = true
	if gs and level_no < gs.level_count():
		btn_primary.text = "下一关"
	else:
		btn_primary.text = "返回菜单"
	btn_secondary.text = "重新挑战"
	_sfx("win")


func _lose_level() -> void:
	game_over = true
	busy = false
	_swap_chain_running = false
	_pending_swaps.clear()
	is_win = false
	selected = Vector2i(-1, -1)
	overlay.visible = true
	result_panel.visible = true
	result_title.visible = true
	result_title.text = "差一点！"
	result_title.modulate = Color("#ff6b6b")
	result_stars.visible = true
	result_stars.text = "目标未达成"
	result_stars.modulate = Color("#9aa0aa")
	result_stars.add_theme_font_size_override("font_size", 26)
	result_detail.visible = true
	result_detail.text = "得分 %d  /  目标 %d" % [score, target]
	btn_primary.visible = true
	btn_primary.text = "再试一次"
	btn_secondary.visible = true
	btn_secondary.text = "返回菜单"
	_sfx("lose")


func _on_primary() -> void:
	if is_win:
		var gs := get_node_or_null("/root/GameState")
		if gs and level_no < gs.level_count():
			_go_next_level()
		else:
			_go_menu()
	else:
		_on_restart()


func _on_secondary() -> void:
	if is_win:
		_on_restart()
	else:
		_go_menu()


func _go_next_level() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs and level_no < gs.level_count():
		gs.current_level = level_no + 1
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_restart() -> void:
	if paused:
		_toggle_pause()
	_start_game()


func _go_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _toggle_pause() -> void:
	if game_over:
		return
	paused = not paused
	get_tree().paused = paused
	pause_overlay.visible = paused


func _update_labels(chain: float) -> void:
	score_label.text = "分数：%d" % score
	steps_label.text = "步数：%d" % steps
	if _progress_fill != null and is_instance_valid(_progress_fill):
		var ratio := clampf(float(score) / float(target), 0.0, 1.0)
		_progress_fill.size = Vector2(536.0 * ratio, 6)
	if chain > 1.0:
		score_label.modulate = Color("#ffffff")
		score_label.scale = Vector2(1.15, 1.15)
	else:
		score_label.modulate = Color("#ffd23f")
		score_label.scale = Vector2.ONE
