extends Control

# ===== 消消乐（Match-3）游戏场景 =====
# 点击方块选中，点击相邻方块交换；三连及以上消除、下落、连锁计分。
# 关卡参数来自 GameState（棋盘大小/色数/目标分/步数），达标即过关。

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
var result_panel: ColorRect
var result_title: Label
var result_detail: Label
var result_stars: Label
var btn_primary: Button
var btn_secondary: Button
var pause_overlay: Control

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

func _style(ctl: Control, size_px: int) -> void:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "Noto Sans CJK SC"])
	ctl.add_theme_font_override("font", f)
	ctl.add_theme_font_size_override("font_size", size_px)


func _make_button(text: String, pos: Vector2, size_px: Vector2, color: Color, font_px: int) -> Button:
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
	_style(b, font_px)
	return b


func _build_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.color = Color("#f7f4ef")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 顶部栏：返回 / 关卡 / 目标 / 分数 / 步数
	var back := _make_button("← 菜单", Vector2(16, 16), Vector2(104, 46), Color("#4d96ff"), 20)
	back.pressed.connect(_go_menu)
	add_child(back)

	level_label = Label.new()
	level_label.position = Vector2(140, 14)
	level_label.size = Vector2(220, 40)
	level_label.modulate = Color("#2b2d42")
	_style(level_label, 28)
	add_child(level_label)

	target_label = Label.new()
	target_label.position = Vector2(140, 54)
	target_label.size = Vector2(260, 30)
	target_label.modulate = Color("#7a7f8a")
	_style(target_label, 18)
	add_child(target_label)

	score_label = Label.new()
	score_label.position = Vector2(360, 14)
	score_label.size = Vector2(344, 40)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.modulate = Color("#2b2d42")
	_style(score_label, 28)
	add_child(score_label)

	steps_label = Label.new()
	steps_label.position = Vector2(400, 54)
	steps_label.size = Vector2(304, 30)
	steps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	steps_label.modulate = Color("#7a7f8a")
	_style(steps_label, 18)
	add_child(steps_label)

	# 进度条（目标达成度）
	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(140, 94)
	bar_bg.size = Vector2(564, 12)
	bar_bg.color = Color(0, 0, 0, 0.10)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar_bg)

	# 道具栏（棋盘下方）
	hint_btn = _make_button("提示 ×3", Vector2(150, 676), Vector2(120, 44), Color("#4d96ff"), 18)
	hint_btn.pressed.connect(_use_hint)
	add_child(hint_btn)

	shuffle_btn = _make_button("重排 ×2", Vector2(300, 676), Vector2(120, 44), Color("#9b5de5"), 18)
	shuffle_btn.pressed.connect(_use_shuffle)
	add_child(shuffle_btn)

	steps_btn = _make_button("+步 ×1", Vector2(450, 676), Vector2(120, 44), Color("#6bcb77"), 18)
	steps_btn.pressed.connect(_use_add_steps)
	add_child(steps_btn)

	var hint := Label.new()
	hint.text = "点击相邻方块交换，凑满目标分数即可过关"
	hint.position = Vector2(16, 812)
	hint.size = Vector2(688, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.42, 0.44, 0.52)
	_style(hint, 15)
	add_child(hint)

	_build_result_panel()
	_build_pause_panel()
	_update_labels(0.0)


func _build_result_panel() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 10
	overlay.visible = false
	add_child(overlay)

	result_panel = ColorRect.new()
	result_panel.position = Vector2(110, 210)
	result_panel.size = Vector2(500, 420)
	result_panel.color = Color("#ffffff")
	result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_panel.z_index = 10
	result_panel.visible = false
	add_child(result_panel)

	result_title = Label.new()
	result_title.text = ""
	result_title.position = Vector2(110, 240)
	result_title.size = Vector2(500, 70)
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.z_index = 10
	_style(result_title, 42)
	add_child(result_title)

	result_stars = Label.new()
	result_stars.text = ""
	result_stars.position = Vector2(110, 315)
	result_stars.size = Vector2(500, 60)
	result_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_stars.z_index = 10
	_style(result_stars, 36)
	add_child(result_stars)

	result_detail = Label.new()
	result_detail.text = ""
	result_detail.position = Vector2(110, 385)
	result_detail.size = Vector2(500, 60)
	result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail.modulate = Color("#5a5f6a")
	result_detail.z_index = 10
	_style(result_detail, 20)
	add_child(result_detail)

	btn_primary = _make_button("", Vector2(170, 470), Vector2(380, 58), Color("#6bcb77"), 24)
	btn_primary.visible = false
	btn_primary.z_index = 10
	btn_primary.pressed.connect(_on_primary)
	add_child(btn_primary)

	btn_secondary = _make_button("", Vector2(170, 540), Vector2(380, 58), Color("#ff9f1c"), 22)
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
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(dim)

	var panel := ColorRect.new()
	panel.position = Vector2(160, 240)
	panel.size = Vector2(400, 360)
	panel.color = Color("#ffffff")
	pause_overlay.add_child(panel)

	var title := Label.new()
	title.text = "暂停"
	title.position = Vector2(160, 260)
	title.size = Vector2(400, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(title, 36)
	title.modulate = Color("#2b2d42")
	pause_overlay.add_child(title)

	var resume := _make_button("继续", Vector2(200, 350), Vector2(320, 58), Color("#6bcb77"), 22)
	resume.pressed.connect(_toggle_pause)
	pause_overlay.add_child(resume)

	var restart := _make_button("重新开始", Vector2(200, 424), Vector2(320, 58), Color("#ff9f1c"), 22)
	restart.pressed.connect(_on_restart)
	pause_overlay.add_child(restart)

	var menu := _make_button("返回菜单", Vector2(200, 498), Vector2(320, 58), Color("#9b5de5"), 22)
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
	if chain > 1.0:
		score_label.modulate = Color("#ff9f1c")
		score_label.scale = Vector2(1.15, 1.15)
	else:
		score_label.modulate = Color("#2b2d42")
		score_label.scale = Vector2.ONE
