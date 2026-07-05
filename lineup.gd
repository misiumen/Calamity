extends Node2D
# Design lineup renderer — CAL_LINEUP=rider|drowned|swarm|hamlet, CAL_SHOT=out.png
# Draws 3 candidate designs side by side at readable scale, screenshots, quits.

var frames := 0
var ui_font: FontFile

const OUT := Color("#0c0a0a")
const BONE := Color("#cfc4a4")
const BONE2 := Color("#eae0c4")
const SHRD := Color("#3a3430")
const SHRD2 := Color("#57504a")
const GLOW := Color(1.8, 1.5, 0.6)
const SICK := Color(0.65, 0.85, 0.35)
const D1C := Color("#1c3a44")
const D2C := Color("#2e5a62")
const D3C := Color("#4a8a88")
const DGL := Color("#b8e8d8")
const GOLD := Color(1.9, 1.5, 0.5)

var cands: Array = []            # [[Texture2D, title, sub], ...] baked once
var kit_rows: Array = []         # hamlet: [[title, sub, [Texture2D...]], ...]

func _ready() -> void:
	ui_font = load("res://art/Silkscreen-Regular.ttf")
	match OS.get_environment("CAL_LINEUP"):
		"rider":
			cands = [[ImageTexture.create_from_image(_rider_a()), "A — GAUNT REAPER", "long bone scythe, trailing tatters"],
				[ImageTexture.create_from_image(_rider_b()), "B — PLAGUE KNIGHT", "armored warhorse, crown, war-banner"],
				[ImageTexture.create_from_image(_rider_c()), "C — HORSEMAN OF RUIN", "rearing horse, cloak becomes the fog"]]
		"drowned":
			cands = [[ImageTexture.create_from_image(_drowned_a()), "A — DEEP PRIEST", "kelp robes, angler lure, seven eyes"],
				[ImageTexture.create_from_image(_drowned_b()), "B — ABYSSAL COLOSSUS", "coral crown, glowing chest-maw"],
				[ImageTexture.create_from_image(_drowned_c()), "C — SUNKEN KING", "gold crown, trident, fish-spine"]]
		"hamlet":
			for row in [["A — FARMLAND", "grain silos tower, barns burst, windmills fall", _kit_farm()],
					["B — MILL TOWN", "sawmill + smokestack, 3-story timber rows", _kit_mill()],
					["C — HOLLOW PARISH", "oversized stone church, crooked cottages, graves", _kit_parish()]]:
				var texs: Array = []
				for img in row[2]:
					texs.append(ImageTexture.create_from_image(img))
				kit_rows.append([row[0], row[1], texs])

func _outline(img: Image, col: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var src := Image.new()
	src.copy_from(img)
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.05:
				continue
			var edge := false
			for off in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
				var nx: int = x + off[0]
				var ny: int = y + off[1]
				if nx >= 0 and ny >= 0 and nx < w and ny < h and src.get_pixel(nx, ny).a > 0.05:
					edge = true
					break
			if edge:
				img.set_pixel(x, y, col)

func _fr(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), c)

# ============================ RIDER CANDIDATES ============================
func _rider_a() -> Image:
	# A — GAUNT REAPER: current bones, better proportions, longer scythe, trailing cloak
	var img := Image.create(46, 36, false, Image.FORMAT_RGBA8)
	_fr(img, 8, 18, 24, 7, BONE)          # horse body
	_fr(img, 5, 19, 5, 5, BONE)           # haunch
	_fr(img, 29, 12, 5, 8, BONE)          # neck
	_fr(img, 31, 9, 9, 5, BONE2)          # long skull
	img.set_pixel(38, 11, OUT)
	img.set_pixel(37, 13, OUT)            # nostril
	for leg in [[10, 25, 10], [16, 25, 9], [23, 25, 10], [29, 25, 9]]:
		_fr(img, leg[0], leg[1], 2, leg[2], BONE)
	for r in 4:
		_fr(img, 12 + r * 4, 19, 1, 5, BONE2)   # ribs
	# rider — tall hooded shape, cloak streaming back
	_fr(img, 15, 5, 9, 14, SHRD)
	_fr(img, 16, 2, 7, 5, SHRD2)          # deep hood
	_fr(img, 18, 4, 3, 1, GLOW)           # eye slit
	for tt in 3:                          # cloak tatters
		_fr(img, 8 - tt * 3, 8 + tt * 3, 8, 3, SHRD)
	# the scythe — a moon of bone
	_fr(img, 25, 0, 1, 16, SHRD2)
	for sx in 8:
		img.set_pixel(26 + sx, 1 + int(sx * 0.4), BONE2)
		img.set_pixel(26 + sx, 2 + int(sx * 0.4), BONE2)
	_outline(img, OUT)
	return img

func _rider_b() -> Image:
	# B — PLAGUE KNIGHT: armored warhorse, crowned helm, war-banner
	var img := Image.create(46, 38, false, Image.FORMAT_RGBA8)
	_fr(img, 8, 20, 24, 8, BONE)
	_fr(img, 8, 20, 24, 3, SHRD2)         # barding plate
	_fr(img, 5, 21, 5, 6, SHRD2)
	_fr(img, 29, 13, 5, 9, BONE)
	_fr(img, 29, 13, 5, 3, SHRD2)         # neck armor
	_fr(img, 31, 10, 9, 5, BONE2)
	_fr(img, 31, 9, 6, 2, SHRD2)          # chamfron
	img.set_pixel(33, 8, SHRD2)           # chamfron spike
	img.set_pixel(38, 12, Color(1.6, 0.4, 0.3))  # burning eye
	for leg in [[10, 28, 9], [16, 28, 8], [23, 28, 9], [29, 28, 8]]:
		_fr(img, leg[0], leg[1], 2, leg[2], BONE)
	# knight — bulkier, pauldrons, crown of rust
	_fr(img, 15, 7, 10, 14, SHRD)
	_fr(img, 13, 9, 3, 4, SHRD2)          # pauldron
	_fr(img, 24, 9, 3, 4, SHRD2)
	_fr(img, 17, 3, 6, 5, SHRD2)          # helm
	for cx in [17, 19, 21]:
		img.set_pixel(cx + 1, 2, GOLD)     # crown points
	_fr(img, 18, 5, 4, 1, GLOW)
	# banner pole with torn standard
	_fr(img, 11, 0, 1, 21, SHRD2)
	_fr(img, 4, 1, 7, 5, Color(0.45, 0.28, 0.3))
	_fr(img, 4, 6, 5, 2, Color(0.45, 0.28, 0.3))
	img.set_pixel(6, 3, BONE2)            # sigil
	# scythe-lance couched forward
	_fr(img, 25, 12, 16, 1, SHRD2)
	for sx in 5:
		img.set_pixel(38 + sx if 38 + sx < 46 else 45, 11, BONE2)
	_outline(img, OUT)
	return img

func _rider_c() -> Image:
	# C — HORSEMAN OF RUIN: rearing horse, cloak becomes the fog itself
	var img := Image.create(46, 42, false, Image.FORMAT_RGBA8)
	# rearing body — diagonal
	_fr(img, 12, 18, 16, 8, BONE)
	_fr(img, 24, 12, 6, 10, BONE)          # chest up
	_fr(img, 28, 6, 5, 8, BONE)            # neck vertical
	_fr(img, 29, 3, 9, 5, BONE2)           # skull skyward
	img.set_pixel(36, 4, OUT)
	# front legs pawing air
	_fr(img, 31, 12, 2, 7, BONE)
	_fr(img, 35, 10, 2, 6, BONE)
	# hind legs planted
	_fr(img, 14, 26, 2, 12, BONE)
	_fr(img, 21, 26, 2, 12, BONE)
	for r in 3:
		_fr(img, 15 + r * 4, 19, 1, 5, BONE2)
	# rider leaning back, hood, lantern eyes
	_fr(img, 14, 6, 9, 13, SHRD)
	_fr(img, 15, 3, 7, 5, SHRD2)
	_fr(img, 17, 5, 3, 1, SICK)            # sickly green gaze
	# cloak streaming into fog wisps (left edge dissolves)
	for w in 5:
		_fr(img, 2 + w * 2, 8 + w * 4, 6, 3, Color(SHRD.r, SHRD.g, SHRD.b, 1.0 - w * 0.15))
		img.set_pixel(1 + w * 2, 10 + w * 4, Color(0.5, 0.6, 0.3, 0.6))
	# scythe raised high overhead
	_fr(img, 23, 0, 1, 10, SHRD2)
	for sx in 9:
		img.set_pixel(14 + sx, 0 + int((8 - sx) * 0.25), BONE2)
	_outline(img, OUT)
	return img

# ============================ DROWNED CANDIDATES ============================
func _drowned_a() -> Image:
	# A — DEEP PRIEST: taller hunch, kelp robe, angler lure, seven lights
	var img := Image.create(40, 44, false, Image.FORMAT_RGBA8)
	_fr(img, 8, 10, 24, 24, D2C)
	_fr(img, 10, 7, 20, 7, D2C)
	_fr(img, 6, 18, 5, 14, D1C)            # robe sides
	_fr(img, 29, 16, 5, 16, D1C)
	_fr(img, 12, 9, 16, 5, D3C)            # crown of the brow
	# angler lure
	_fr(img, 19, 2, 1, 6, D3C)
	img.set_pixel(20, 1, DGL)
	img.set_pixel(20, 0, Color(1.6, 2.0, 1.8))
	# kelp robe strips
	for k in 6:
		_fr(img, 9 + k * 4, 32, 2, 8 + (k % 3) * 3, D1C)
	# tentacle beard, longer
	for tb in 7:
		_fr(img, 10 + tb * 3, 26, 2, 9 + ((tb * 2) % 5), D2C)
	# seven pale eyes in an arc
	for e in [[13, 13], [16, 11], [20, 10], [24, 11], [27, 13], [18, 16], [22, 16]]:
		img.set_pixel(e[0], e[1], DGL)
	# barnacle plates
	for mp in [[11, 20], [26, 22], [15, 24], [24, 18]]:
		_fr(img, mp[0], mp[1], 2, 2, D3C)
	_outline(img, OUT)
	return img

func _drowned_b() -> Image:
	# B — ABYSSAL COLOSSUS: broad shoulders, coral crown, chest-maw glow
	var img := Image.create(46, 42, false, Image.FORMAT_RGBA8)
	_fr(img, 6, 12, 34, 18, D2C)           # massive shoulders
	_fr(img, 14, 6, 18, 10, D2C)           # head sunk between them
	_fr(img, 4, 16, 6, 18, D1C)            # arm columns
	_fr(img, 36, 16, 6, 18, D1C)
	_fr(img, 3, 32, 8, 5, D3C)             # webbed claws
	_fr(img, 35, 32, 8, 5, D3C)
	for cl in 3:
		img.set_pixel(4 + cl * 3, 37, D3C)
		img.set_pixel(36 + cl * 3, 37, D3C)
	# coral crown spikes
	for c in [[15, 3, 2, 4], [19, 1, 2, 6], [24, 0, 2, 7], [28, 2, 2, 5]]:
		_fr(img, c[0], c[1], c[2], c[3], Color(0.75, 0.4, 0.45))
	# chest maw — glowing vertical grin
	_fr(img, 20, 20, 6, 9, Color("#08201c"))
	for tm in 4:
		img.set_pixel(21 + tm, 21 + (tm % 2), DGL)
		img.set_pixel(21 + tm, 27 - (tm % 2), DGL)
	_fr(img, 22, 23, 2, 3, Color(0.9, 1.8, 1.5))
	# small hateful eyes
	img.set_pixel(19, 10, DGL)
	img.set_pixel(26, 10, DGL)
	# scale ridges
	for s in 5:
		_fr(img, 10 + s * 5, 14, 1, 4, D3C)
	_outline(img, OUT)
	return img

func _drowned_c() -> Image:
	# C — SUNKEN KING: drowned monarch, gold crown, trident, kelp robes
	var img := Image.create(42, 44, false, Image.FORMAT_RGBA8)
	_fr(img, 12, 10, 18, 24, D2C)          # regal torso
	_fr(img, 14, 5, 14, 9, D2C)            # head
	_fr(img, 10, 18, 4, 18, D1C)           # robe fall
	_fr(img, 28, 18, 4, 18, D1C)
	for k in 5:
		_fr(img, 12 + k * 4, 34, 2, 7 + (k % 2) * 3, D1C)   # kelp hem
	# the crown — gold above rot
	_fr(img, 14, 3, 14, 2, GOLD)
	for cp in [15, 19, 23, 26]:
		img.set_pixel(cp, 1, GOLD)
		img.set_pixel(cp, 2, GOLD)
	# dead royal gaze — two lights, one dimmer (half-drowned)
	img.set_pixel(18, 8, DGL)
	img.set_pixel(24, 8, Color(0.6, 0.9, 0.85))
	# exposed fish-spine along one side
	for r in 5:
		_fr(img, 29, 14 + r * 4, 2, 1, BONE2)
	# trident held tall
	_fr(img, 6, 2, 1, 34, D3C)
	_fr(img, 4, 2, 5, 1, D3C)
	for tp in [4, 6, 8]:
		img.set_pixel(tp, 0, DGL)
		img.set_pixel(tp, 1, D3C)
	# barnacles on the robe
	for mp in [[16, 20], [24, 24], [20, 28]]:
		_fr(img, mp[0], mp[1], 2, 2, D3C)
	_outline(img, OUT)
	return img

# ============================ SHEETS ============================
func _draw() -> void:
	var mode := OS.get_environment("CAL_LINEUP")
	draw_rect(Rect2(0, 0, 640, 360), Color("#100c16"))
	draw_string(ui_font, Vector2(320, 24), mode.to_upper() + " — DESIGN LINEUP",
		HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(1.8, 0.5, 0.5))
	match mode:
		"rider", "drowned":
			_show_row()
		"swarm":
			_swarm_sheet()
		"hamlet":
			_hamlet_sheet()
		"draftui":
			_draftui_mock()
		"menu_root":
			_menu_root_mock()
		"menu_char":
			_menu_char_mock()
		"menu2_root":
			_menu2_root_mock()
		"menu2_char":
			_menu2_char_mock()

func _menu2_scene() -> void:
	for i in 20:
		var f: float = i / 19.0
		draw_rect(Rect2(0, f * 200.0, 640, 11), Color(0.06, 0.03, 0.10).lerp(Color(0.45, 0.13, 0.16), f))
	for i in 24:
		var bw := 10.0 + fmod(i * 23.3, 26.0)
		var bh := 12.0 + fmod(i * 37.7, 42.0)
		draw_rect(Rect2(i * 27.0, 208.0 - bh, bw, bh), Color("#170f1e"))
		if i % 4 == 0:
			draw_circle(Vector2(i * 27.0 + bw * 0.5, 206.0 - bh), 4.0, Color(1.9, 0.8, 0.25, 0.4))
	draw_rect(Rect2(0, 205, 640, 155), Color("#0d0916"))
	for sm in 3:
		for p in 5:
			draw_circle(Vector2(120 + sm * 190 + sin(p * 1.7) * 6.0, 195.0 - p * 14.0), 7.0 + p * 2.5,
				Color(0.10, 0.07, 0.12, 0.5 - p * 0.08))
	for e in 18:
		draw_rect(Rect2(fmod(e * 97.3, 640.0), 40.0 + fmod(e * 53.7, 280.0), 1.5, 1.5), Color(1.9, 0.7, 0.3, 0.5))

func _bold_f() -> FontFile:
	return load("res://art/Silkscreen-Bold.ttf")

func _menu2_root_mock() -> void:
	_menu2_scene()
	var gx := [180.0, 250.0, 320.0, 390.0, 460.0]
	var silh := Color("#080510")
	draw_circle(Vector2(gx[0], 222.0), 7.0, silh)
	draw_rect(Rect2(gx[1] - 4, 204.0, 8, 26), silh)
	for hh in 3:
		draw_circle(Vector2(gx[1] + (hh - 1) * 5.0, 202.0), 2.2, silh)
	var prev := Vector2(gx[2] - 12, 228.0)
	for sgm in 7:
		var f2: float = sgm / 6.0
		var npt := Vector2(gx[2] - 12 + f2 * 24.0, 228.0 - sin(f2 * PI) * 14.0)
		draw_line(prev, npt, silh, 3.0)
		prev = npt
	draw_colored_polygon(PackedVector2Array([Vector2(gx[3] - 6, 230), Vector2(gx[3] - 4, 206),
		Vector2(gx[3] + 4, 206), Vector2(gx[3] + 6, 230)]), silh)
	draw_circle(Vector2(gx[3] - 1.5, 211.0), 0.9, Color(1.3, 2.4, 2.2))
	draw_circle(Vector2(gx[3] + 1.5, 211.0), 0.9, Color(1.3, 2.4, 2.2))
	draw_colored_polygon(PackedVector2Array([Vector2(gx[4] - 8, 230), Vector2(gx[4] - 6, 212),
		Vector2(gx[4], 206), Vector2(gx[4] + 7, 214), Vector2(gx[4] + 8, 230)]), silh)
	draw_string(ui_font, Vector2(0, 60), "C A L A M I T Y", HORIZONTAL_ALIGNMENT_CENTER, 640, 30, Color(1.9, 0.45, 0.5))
	draw_string(ui_font, Vector2(0, 80), "you are the apocalypse", HORIZONTAL_ALIGNMENT_CENTER, 640, 9, Color(0.75, 0.68, 0.8))
	draw_rect(Rect2(60, 96, 520, 4), Color("#241a2c"))
	var titles := [["NEW CRUSADE", true], ["CONTINUE", false], ["SKIRMISH", false]]
	for i in 3:
		var bx: float = 130.0 + i * 190.0
		var hot: bool = titles[i][1]
		var cloth := Color(0.46, 0.11, 0.14) if hot else Color(0.24, 0.18, 0.30)
		var pts := PackedVector2Array([Vector2(bx - 46, 100)])
		pts.append(Vector2(bx + 46, 100))
		for wv in 5:
			pts.append(Vector2(bx + 46 - wv * 4.0, 208.0 + sin(wv * 1.9 + i) * 5.0 + (wv % 2) * 7.0))
		for wv in 5:
			pts.append(Vector2(bx - 14 - wv * 4.0, 214.0 - sin(wv * 1.7 + i) * 5.0 - (wv % 2) * 7.0))
		draw_colored_polygon(pts, cloth)
		draw_rect(Rect2(bx - 46, 100, 92, 5), Color("#3a2c1c"))
		draw_line(Vector2(bx - 46, 105), Vector2(bx - 46, 190), cloth.darkened(0.35), 2.0)
		draw_line(Vector2(bx + 46, 105), Vector2(bx + 46, 186), cloth.darkened(0.35), 2.0)
		draw_circle(Vector2(bx, 130), 11.0, cloth.darkened(0.3))
		draw_arc(Vector2(bx, 130), 11.0, 0, TAU, 16, Color(1.7, 1.3, 0.7, 0.5), 1.0)
		draw_string(ui_font, Vector2(bx - 44, 160), titles[i][0], HORIZONTAL_ALIGNMENT_CENTER, 88, 10,
			Color(1.9, 0.8, 0.6) if hot else Color(0.85, 0.8, 0.9))
		if hot:
			for fe in 6:
				var fx3: float = bx - 36 + fe * 13.0
				draw_circle(Vector2(fx3, 206.0 + (fe % 2) * 6.0), 2.5, Color(2.0, 0.9, 0.3, 0.7))
			draw_string(ui_font, Vector2(bx - 44, 176), "act I - III", HORIZONTAL_ALIGNMENT_CENTER, 88, 6, Color(1.5, 1.0, 0.7))
	draw_string(ui_font, Vector2(0, 262), "the five stand on the ridge, watching their work", HORIZONTAL_ALIGNMENT_CENTER, 640, 7, Color(0.6, 0.55, 0.7))

func _menu2_char_mock() -> void:
	_menu2_scene()
	draw_string(ui_font, Vector2(0, 40), "THE PANTHEON", HORIZONTAL_ALIGNMENT_CENTER, 640, 17, Color(1.9, 0.45, 0.5))
	draw_string(ui_font, Vector2(0, 56), "no cards. the gods ARE the menu. click one.", HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color(0.75, 0.68, 0.8))
	draw_rect(Rect2(0, 268, 640, 92), Color("#0a0714"))
	for cr in 10:
		draw_rect(Rect2(cr * 68.0, 264.0 + fmod(cr * 7.7, 8.0), 60.0, 10.0), Color("#0d0918"))
	var names := ["THE SWARM", "KERAUNOS", "TZITZIMITL", "THE DROWNED", "PALE RIDER"]
	var cols := [Color(1.8, 0.4, 0.45), Color(0.5, 1.5, 2.0), Color(1.9, 1.2, 0.3), Color(0.4, 1.6, 1.5), Color(1.7, 1.5, 0.7)]
	for i in 5:
		var gx2: float = 76.0 + i * 122.0
		var gy := 240.0
		var hot: bool = i == 2
		if hot:
			draw_circle(Vector2(gx2, gy - 40), 58.0, Color(cols[i].r, cols[i].g, cols[i].b, 0.07))
			draw_rect(Rect2(gx2 - 40, gy + 24, 80, 3), Color(cols[i].r, cols[i].g, cols[i].b, 0.25))
		match i:
			0:
				draw_circle(Vector2(gx2, gy - 38), 26.0, Color(0.9, 0.12, 0.18, 0.13))
				draw_circle(Vector2(gx2, gy - 38), 17.0, Color("#20040e"))
				for mm in 22:
					var mp2 := Vector2(gx2, gy - 38) + Vector2(cos(mm * 2.4), sin(mm * 3.1)) * (9.0 + fmod(mm * 5.3, 15.0))
					draw_line(mp2, mp2 + Vector2(2.5, 1), Color(1.6, 0.35, 0.4), 1.0)
				draw_circle(Vector2(gx2 + 8, gy - 44), 3.5, Color(1.8, 1.1, 0.3))
			1:
				draw_circle(Vector2(gx2, gy - 26), 15.0, Color("#0e0f18"))
				for hh2 in 3:
					var hp4 := Vector2(gx2 + (hh2 - 1) * 13.0, gy - 62.0)
					draw_line(Vector2(gx2 + (hh2 - 1) * 5.0, gy - 38.0), hp4, Color("#0e0f18"), 4.0)
					draw_circle(hp4, 4.0, Color("#161826"))
					draw_circle(hp4 + Vector2(2, 0), 1.3, Color(1.2, 2.0, 2.6))
				for wg in [-1.0, 1.0]:
					draw_colored_polygon(PackedVector2Array([Vector2(gx2 + wg * 8, gy - 34),
						Vector2(gx2 + wg * 40, gy - 58), Vector2(gx2 + wg * 30, gy - 24)]), Color(0.05, 0.06, 0.11, 0.9))
			2:
				var prev2 := Vector2(gx2 - 30, gy)
				for sgm2 in 11:
					var f4: float = sgm2 / 10.0
					var npt2 := Vector2(gx2 - 30 + f4 * 60.0, gy - sin(f4 * PI) * 46.0 + sin(f4 * 9.0) * 3.0)
					draw_line(prev2, npt2, Color(0.10, 0.48, 0.47), 7.0 * (1.0 - absf(f4 - 0.5)))
					prev2 = npt2
				draw_circle(prev2 + Vector2(2, -4), 5.0, Color(0.23, 0.72, 0.66))
				draw_circle(prev2 + Vector2(4, -5), 1.5, Color(2.4, 1.5, 0.3))
				for fth in 4:
					draw_line(Vector2(gx2 - 18 + fth * 10.0, gy - 42.0), Vector2(gx2 - 22 + fth * 10.0, gy - 52.0),
						Color(0.9, 0.35, 0.2), 1.5)
			3:
				draw_colored_polygon(PackedVector2Array([Vector2(gx2 - 14, gy), Vector2(gx2 - 12, gy - 34),
					Vector2(gx2 - 4, gy - 52), Vector2(gx2 + 5, gy - 51), Vector2(gx2 + 12, gy - 32), Vector2(gx2 + 14, gy)]),
					Color(0.02, 0.08, 0.10))
				for tn2 in 6:
					draw_line(Vector2(gx2 + (tn2 - 2.5) * 3.2, gy - 40), Vector2(gx2 + (tn2 - 2.5) * 4.0, gy - 28 + (tn2 % 2) * 4),
						Color(0.04, 0.13, 0.15), 2.0)
				draw_circle(Vector2(gx2 - 3, gy - 44), 1.6, Color(1.3, 2.4, 2.2))
				draw_circle(Vector2(gx2 + 3, gy - 44), 1.6, Color(1.3, 2.4, 2.2))
			4:
				draw_colored_polygon(PackedVector2Array([Vector2(gx2 + 16, gy), Vector2(gx2 + 17, gy - 26),
					Vector2(gx2 + 7, gy - 44), Vector2(gx2 - 3, gy - 48), Vector2(gx2 - 15, gy - 34),
					Vector2(gx2 - 22, gy - 10), Vector2(gx2 - 17, gy)]), Color(0.075, 0.06, 0.09))
				draw_circle(Vector2(gx2 - 2, gy - 42), 3.6, Color(0.88, 0.83, 0.66))
				draw_arc(Vector2(gx2 + 2, gy - 54), 13.0, -0.4, 1.5, 12, Color(0.97, 0.93, 0.78), 2.4)
				for lg in 3:
					draw_line(Vector2(gx2 - 10 + lg * 8.0, gy), Vector2(gx2 - 10 + lg * 8.0, gy - 10), Color(0.88, 0.83, 0.66), 2.0)
		draw_string(ui_font, Vector2(gx2 - 55, gy + 44), names[i], HORIZONTAL_ALIGNMENT_CENTER, 110, 9,
			cols[i] if hot else Color(0.8, 0.75, 0.85))
		if hot:
			draw_string(ui_font, Vector2(gx2 - 55, gy + 58), "eclipse serpent", HORIZONTAL_ALIGNMENT_CENTER, 110, 7, Color(0.85, 0.8, 0.9))
			draw_string(ui_font, Vector2(gx2 - 55, gy + 70), "lance dives - eat the sun", HORIZONTAL_ALIGNMENT_CENTER, 110, 6, Color(0.7, 0.65, 0.75))

func _frame(r: Rect2, bord: Color, fill: Color) -> void:
	draw_rect(r, fill)
	for edge in [Rect2(r.position, Vector2(r.size.x, 2)), Rect2(r.position + Vector2(0, r.size.y - 2), Vector2(r.size.x, 2)),
			Rect2(r.position, Vector2(2, r.size.y)), Rect2(r.position + Vector2(r.size.x - 2, 0), Vector2(2, r.size.y))]:
		draw_rect(edge, bord)
	for c in [Vector2.ZERO, Vector2(r.size.x - 6, 0), Vector2(0, r.size.y - 6), Vector2(r.size.x - 6, r.size.y - 6)]:
		draw_rect(Rect2(r.position + c, Vector2(6, 6)), bord)

func _menu_bg() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("#0a0712"))
	# burning skyline silhouette at the foot of the menu
	for i in 16:
		var bw := 24.0 + fmod(i * 37.7, 40.0)
		var bh := 30.0 + fmod(i * 53.3, 70.0)
		var bx := i * 41.0
		draw_rect(Rect2(bx, 360 - bh, bw, bh), Color("#151020"))
		if i % 3 == 0:
			draw_circle(Vector2(bx + bw * 0.5, 360 - bh - 2), 5.0, Color(1.8, 0.7, 0.2, 0.35))
			draw_circle(Vector2(bx + bw * 0.5, 360 - bh - 2), 2.0, Color(2.2, 1.2, 0.4, 0.7))
	draw_rect(Rect2(0, 300, 640, 60), Color(0.04, 0.02, 0.07, 0.55))
	# drifting embers
	for e in 14:
		draw_rect(Rect2(fmod(e * 97.3, 640.0), 40.0 + fmod(e * 53.7, 260.0), 1.5, 1.5), Color(1.9, 0.7, 0.3, 0.5))

func _menu_root_mock() -> void:
	_menu_bg()
	draw_string(ui_font, Vector2(0, 92), "C A L A M I T Y", HORIZONTAL_ALIGNMENT_CENTER, 640, 34, Color(1.9, 0.45, 0.5))
	draw_string(ui_font, Vector2(0, 110), "you are the apocalypse", HORIZONTAL_ALIGNMENT_CENTER, 640, 9, Color("#8d86a8"))
	var rows := [["NEW CRUSADE", "prologue, three acts, a continent to raze", true],
		["CONTINUE CRUSADE", "act II — the crusade, 4 provinces burnt", false],
		["SKIRMISH", "one god, one city, no stakes", false]]
	for i in rows.size():
		var r := Rect2(170, 138 + i * 62, 300, 50)
		var hov: bool = rows[i][2]
		if hov:
			r.position.y -= 3
			draw_rect(Rect2(r.position - Vector2(4, 4), r.size + Vector2(8, 8)), Color(1.9, 0.5, 0.5, 0.10))
		_frame(r, Color(1.9, 0.6, 0.6) if hov else Color(0.4, 0.32, 0.45), Color("#151020"))
		draw_string(ui_font, Vector2(r.position.x, r.position.y + 20), rows[i][0], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13,
			Color(1.8, 0.55, 0.55) if hov else Color(0.95, 0.9, 1.0))
		draw_string(ui_font, Vector2(r.position.x + 8, r.position.y + 38), rows[i][1], HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 7, Color("#8d86a8"))

func _menu_char_mock() -> void:
	_menu_bg()
	draw_string(ui_font, Vector2(0, 40), "CHOOSE YOUR CALAMITY", HORIZONTAL_ALIGNMENT_CENTER, 640, 15, Color(1.9, 0.45, 0.5))
	draw_string(ui_font, Vector2(0, 56), "[esc - back]", HORIZONTAL_ALIGNMENT_CENTER, 640, 7, Color("#8d86a8"))
	var gods := [["THE SWARM", Color(1.8, 0.4, 0.45), "plague of locusts", "tendrils - grabs - evolve", false],
		["KERAUNOS", Color(0.5, 1.5, 2.0), "colossal storm hydra", "banked bolts - TEMPEST", false],
		["TZITZIMITL", Color(1.9, 1.2, 0.3), "eclipse serpent", "lance dives - eat the sun", true],
		["THE DROWNED", Color(0.4, 1.6, 1.5), "tide priest", "madden - flood - fishmen", false],
		["PALE RIDER", Color(1.7, 1.5, 0.7), "pestilence", "fog infects - dead rise", false]]
	for i in gods.size():
		var r := Rect2(14 + i * 124, 78 + (-6 if gods[i][4] else 0), 116, 236)
		var col: Color = gods[i][1]
		if gods[i][4]:
			draw_rect(Rect2(r.position - Vector2(4, 4), r.size + Vector2(8, 8)), Color(col.r, col.g, col.b, 0.12))
		_frame(r, col if gods[i][4] else Color(0.4, 0.32, 0.45), Color("#151020"))
		# emblem well
		var gp := r.position + Vector2(58, 74)
		draw_circle(gp, 34.0, Color("#100c1a"))
		draw_arc(gp, 34.0, 0, TAU, 24, Color(col.r, col.g, col.b, 0.4), 1.0)
		match i:
			0:
				draw_circle(gp, 15.0, Color("#2a0614"))
				for mm in 16:
					var mp := gp + Vector2(cos(mm * 2.4), sin(mm * 3.1)) * (8.0 + fmod(mm * 5.3, 12.0))
					draw_line(mp, mp + Vector2(2.5, 1), Color(1.7, 0.4, 0.4), 1.0)
				draw_circle(gp + Vector2(7, -4), 3.0, Color(1.8, 1.1, 0.3))
			1:
				for h2 in 3:
					var hh := gp + Vector2((h2 - 1) * 11.0, -14.0)
					draw_line(gp + Vector2((h2 - 1) * 4.0, 4.0), hh, Color(0.10, 0.11, 0.18), 3.0)
					draw_circle(hh, 3.0, Color(0.16, 0.18, 0.28))
					draw_circle(hh + Vector2(2, 0), 1.1, Color(1.2, 2.0, 2.6))
				draw_circle(gp + Vector2(0, 8), 10.0, Color(0.10, 0.11, 0.18))
			2:
				var prev := gp + Vector2(-20, 10)
				for s2 in 9:
					var f4 := s2 / 8.0
					var npt := gp + Vector2(-20 + f4 * 40.0, 10.0 - sin(f4 * PI) * 22.0)
					draw_line(prev, npt, Color(0.10, 0.48, 0.47), 4.5 * (1.0 - absf(f4 - 0.5)))
					prev = npt
				draw_circle(prev, 3.5, Color(0.23, 0.72, 0.66))
				draw_circle(prev + Vector2(2, -1), 1.2, Color(2.4, 1.5, 0.3))
			3:
				draw_colored_polygon(PackedVector2Array([gp + Vector2(-11, 24), gp + Vector2(-9, -6),
					gp + Vector2(-3, -19), gp + Vector2(4, -18), gp + Vector2(9, -4), gp + Vector2(11, 24)]),
					Color(0.02, 0.08, 0.10))
				draw_circle(gp + Vector2(-3, -13), 1.4, Color(1.3, 2.4, 2.2))
				draw_circle(gp + Vector2(3, -13), 1.4, Color(1.3, 2.4, 2.2))
			4:
				draw_colored_polygon(PackedVector2Array([gp + Vector2(13, 22), gp + Vector2(14, -2),
					gp + Vector2(5, -17), gp + Vector2(-3, -21), gp + Vector2(-13, -11), gp + Vector2(-19, 7),
					gp + Vector2(-14, 22)]), Color(0.075, 0.06, 0.09))
				draw_circle(gp + Vector2(-2, -15), 2.8, Color(0.88, 0.83, 0.66))
				draw_arc(gp + Vector2(2, -24), 10.0, -0.4, 1.5, 10, Color(0.97, 0.93, 0.78), 2.0)
		draw_string(ui_font, Vector2(r.position.x, r.position.y + 134), gods[i][0], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, col)
		draw_string(ui_font, Vector2(r.position.x + 6, r.position.y + 156), gods[i][2], HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 12, 7, Color("#b8b0c8"))
		draw_string(ui_font, Vector2(r.position.x + 6, r.position.y + 172), gods[i][3], HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 12, 6, Color("#8d86a8"))
		# crusade record chip
		draw_rect(Rect2(r.position.x + 8, r.position.y + 196, r.size.x - 16, 14), Color("#100c1a"))
		draw_string(ui_font, Vector2(r.position.x, r.position.y + 206), "best: act II", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 6, Color(0.6, 0.55, 0.7))
		draw_string(ui_font, Vector2(r.position.x, r.position.y + 228), "[%d]" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 7, Color(0.6, 0.55, 0.7))

func _draftui_mock() -> void:
	# static mock of the proposed evolution screen — THE MOLT
	draw_rect(Rect2(0, 0, 640, 360), Color("#0a0712"))
	# dimmed battlefield hint behind
	draw_rect(Rect2(0, 250, 640, 110), Color("#120c1a"))
	for i in 8:
		draw_rect(Rect2(30 + i * 78, 250 - 20 - (i % 3) * 22, 46, 20 + (i % 3) * 22), Color("#1a1226"))
	draw_string(ui_font, Vector2(320, 34), "T H E   M O L T", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(1.9, 0.5, 0.55))
	draw_string(ui_font, Vector2(320, 50), "the swarm sheds what it was", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color("#8890b0"))
	# left: the god itself on an essence pedestal
	var gp := Vector2(100, 170)
	draw_circle(gp + Vector2(0, 62), 40.0, Color(0.5, 0.1, 0.15, 0.25))
	draw_arc(gp + Vector2(0, 62), 40.0, PI, TAU, 24, Color(1.6, 0.4, 0.4, 0.5), 1.5)
	draw_circle(gp, 30.0, Color(0.9, 0.12, 0.18, 0.14))
	draw_circle(gp, 20.0, Color("#2a0614"))
	for m in 26:
		var ma := m * 2.4
		var mp := gp + Vector2(cos(ma), sin(ma * 1.3)) * (12.0 + fmod(m * 7.7, 16.0))
		draw_line(mp, mp + Vector2(2.5, 1), Color(1.7, 0.4, 0.4), 1.0)
	for e in 5:
		draw_rect(Rect2(gp.x - 20 + e * 9, gp.y + 40 - fmod(e * 13.7, 26.0), 1.5, 1.5), Color(1.8, 0.6, 0.5, 0.7))
	draw_string(ui_font, Vector2(100, 250), "THE SWARM", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1.7, 0.5, 0.5))
	draw_string(ui_font, Vector2(100, 262), "stage II — IRONMAW line", HORIZONTAL_ALIGNMENT_CENTER, -1, 7, Color("#8890b0"))
	# three cards — center card hovered (lifted, glowing)
	var cards := [
		["SEISMIC SLAM", "ACTIVE — RMB", ["slam the street: a shockwave", "rolls both ways, flipping units"],
			["NEW VERB:  RMB shockwave", "crater radius     22px", "units flipped     yes"], false],
		["DENSE CHITIN", "PASSIVE", ["armored mass — shellfire", "cracks against you"],
			["damage taken   -35%", "body mass        +10%", "knockback        immune"], true],
		["AFTERSHOCK", "PASSIVE", ["every maul smash echoes a", "second, delayed shockwave"],
			["hits per smash   1 > 2", "echo delay       0.4s", "echo damage      60%"], false]]
	for i in 3:
		var cx: float = 262.0 + i * 128.0
		var lift: float = -8.0 if cards[i][4] else 0.0
		var cy: float = 78.0 + lift
		var bord: Color = Color(1.9, 0.6, 0.6) if cards[i][4] else Color(0.4, 0.32, 0.45)
		# card body — custom frame, no godot grey
		draw_rect(Rect2(cx, cy, 116, 190), Color("#151020"))
		draw_rect(Rect2(cx, cy, 116, 2), bord)
		draw_rect(Rect2(cx, cy + 188, 116, 2), bord)
		draw_rect(Rect2(cx, cy, 2, 190), bord)
		draw_rect(Rect2(cx + 114, cy, 2, 190), bord)
		for corner in [[0, 0], [110, 0], [0, 184], [110, 184]]:
			draw_rect(Rect2(cx + corner[0], cy + corner[1], 6, 6), bord)
		if cards[i][4]:
			draw_rect(Rect2(cx - 3, cy - 3, 122, 196), Color(1.9, 0.6, 0.6, 0.12))
		# kind ribbon
		var rib: Color = Color(0.9, 0.4, 0.2) if i == 0 else Color(0.35, 0.5, 0.75)
		draw_rect(Rect2(cx + 8, cy + 8, 100, 12), Color(rib.r, rib.g, rib.b, 0.25))
		draw_string(ui_font, Vector2(cx + 58, cy + 17), cards[i][1], HORIZONTAL_ALIGNMENT_CENTER, -1, 7, rib.lightened(0.4))
		# icon glyph
		draw_circle(Vector2(cx + 58, cy + 44), 14.0, Color("#221a30"))
		draw_arc(Vector2(cx + 58, cy + 44), 14.0, 0, TAU, 16, bord, 1.0)
		match i:
			0:
				draw_line(Vector2(cx + 50, cy + 50), Vector2(cx + 66, cy + 50), Color(1.8, 1.0, 0.5), 2.0)
				draw_line(Vector2(cx + 58, cy + 36), Vector2(cx + 58, cy + 50), Color(1.8, 1.0, 0.5), 2.0)
			1:
				draw_arc(Vector2(cx + 58, cy + 44), 8.0, 0, TAU, 12, Color(0.7, 0.9, 1.4), 2.0)
			2:
				draw_arc(Vector2(cx + 58, cy + 44), 5.0, 0, TAU, 10, Color(1.8, 1.0, 0.5), 1.5)
				draw_arc(Vector2(cx + 58, cy + 44), 10.0, 0, TAU, 12, Color(1.8, 1.0, 0.5, 0.5), 1.0)
		# name
		draw_string(ui_font, Vector2(cx + 58, cy + 74), cards[i][0], HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(0.95, 0.9, 1.0))
		# flavor
		for l in cards[i][2].size():
			draw_string(ui_font, Vector2(cx + 58, cy + 88 + l * 9), cards[i][2][l], HORIZONTAL_ALIGNMENT_CENTER, -1, 6, Color("#8890b0"))
		# WHAT CHANGES block
		draw_rect(Rect2(cx + 8, cy + 112, 100, 1), Color(bord.r, bord.g, bord.b, 0.5))
		draw_string(ui_font, Vector2(cx + 58, cy + 124), "WHAT CHANGES", HORIZONTAL_ALIGNMENT_CENTER, -1, 6, Color(1.6, 1.3, 0.6))
		for l in cards[i][3].size():
			draw_string(ui_font, Vector2(cx + 14, cy + 138 + l * 11), cards[i][3][l], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.75, 0.85, 0.75))
		# pick key hint
		draw_string(ui_font, Vector2(cx + 58, cy + 182), "[%d]" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, -1, 7, Color(0.6, 0.55, 0.7))
	draw_string(ui_font, Vector2(320, 348), "1 / 2 / 3 or click   —   the unpicked wither away", HORIZONTAL_ALIGNMENT_CENTER, -1, 7, Color(0.6, 0.55, 0.7))

func _show_row() -> void:
	for i in cands.size():
		var tex: Texture2D = cands[i][0]
		var cx: float = 110.0 + i * 210.0
		var sc := 5.0
		draw_rect(Rect2(cx - 85, 60, 180, 240), Color("#181322"))
		draw_texture_rect(tex, Rect2(cx - tex.get_width() * sc * 0.5, 175.0 - tex.get_height() * sc * 0.5,
			tex.get_width() * sc, tex.get_height() * sc), false)
		draw_string(ui_font, Vector2(cx, 320), cands[i][1], HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(1.6, 1.4, 0.8))
		draw_string(ui_font, Vector2(cx, 336), cands[i][2], HORIZONTAL_ALIGNMENT_CENTER, -1, 7, Color("#9ab0d0"))

func _swarm_sheet() -> void:
	var labels := [["A — LOCUST HEART", "visible queen-core, veins of light"],
		["B — THE HUNGERING MAW", "the cloud shapes a skull that eats"],
		["C — WING COLUMN", "a standing tornado of wings"]]
	for i in 3:
		var cx: float = 110.0 + i * 210.0
		var cy := 170.0
		draw_rect(Rect2(cx - 80, 60, 170, 240), Color("#181322"))
		match i:
			0:
				# core + orbiting locusts + glowing veins
				draw_circle(Vector2(cx, cy), 55.0, Color(0.9, 0.12, 0.18, 0.12))
				draw_circle(Vector2(cx, cy), 38.0, Color("#2a0614"))
				for v in 5:
					var a := v * TAU / 5.0
					draw_line(Vector2(cx, cy), Vector2(cx, cy) + Vector2.from_angle(a) * 26.0, Color(1.4, 0.3, 0.3, 0.5), 2.0)
				draw_circle(Vector2(cx, cy), 10.0, Color(2.2, 0.5, 0.4))
				draw_circle(Vector2(cx, cy), 5.0, Color(2.6, 1.4, 0.8))
				for m in 40:
					var ma := m * 2.399
					var mr := 20.0 + fmod(m * 13.7, 34.0)
					var mp := Vector2(cx, cy) + Vector2(cos(ma) * mr, sin(ma * 1.3) * mr * 0.9)
					draw_line(mp, mp + Vector2(3, 1), Color(1.7, 0.4, 0.4), 1.0)
					draw_line(mp, mp + Vector2(-1, -2), Color(1.2, 0.5, 0.5, 0.6), 0.8)
			1:
				# skull-maw silhouette made of motes
				for m in 90:
					var ma := m * 2.399
					var mr := 44.0 + fmod(m * 7.3, 12.0)
					var mp := Vector2(cx, cy) + Vector2(cos(ma), sin(ma)) * mr
					if mp.y > cy + 18.0 and absf(mp.x - cx) < 22.0:
						continue   # jaw gap
					draw_line(mp, mp + Vector2(2.5, 1), Color(1.6, 0.35, 0.4), 1.0)
				for m in 30:
					var mp2 := Vector2(cx - 30.0 + fmod(m * 17.3, 60.0), cy + 24.0 + fmod(m * 7.7, 14.0))
					draw_line(mp2, mp2 + Vector2(2, 1), Color(1.4, 0.3, 0.35), 1.0)  # lower jaw drifting
				# eye sockets — holes in the swarm
				draw_circle(Vector2(cx - 16, cy - 10), 9.0, Color("#181322"))
				draw_circle(Vector2(cx + 16, cy - 10), 9.0, Color("#181322"))
				draw_circle(Vector2(cx - 16, cy - 10), 2.5, Color(2.2, 0.5, 0.4))
				draw_circle(Vector2(cx + 16, cy - 10), 2.5, Color(2.2, 0.5, 0.4))
			2:
				# vertical wing column
				for m in 80:
					var my: float = cy - 85.0 + fmod(m * 11.3, 170.0)
					var wob := sin(my * 0.06 + m) * (10.0 + (my - cy + 85.0) * 0.14)
					var mp3 := Vector2(cx + wob, my)
					draw_line(mp3, mp3 + Vector2(2.5, 0.5), Color(1.6, 0.35, 0.4), 1.0)
					if m % 3 == 0:
						draw_line(mp3, mp3 + Vector2(-1.5, -2), Color(1.9, 0.7, 0.6, 0.7), 0.8)
				draw_circle(Vector2(cx, cy + 70), 16.0, Color(0.9, 0.12, 0.18, 0.25))
		draw_string(ui_font, Vector2(cx, 320), labels[i][0], HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(1.6, 1.4, 0.8))
		draw_string(ui_font, Vector2(cx, 336), labels[i][1], HORIZONTAL_ALIGNMENT_CENTER, -1, 7, Color("#9ab0d0"))

# ============================ HAMLET KITS ============================
func _hamlet_sheet() -> void:
	for r in kit_rows.size():
		var y: float = 52.0 + r * 102.0
		draw_rect(Rect2(20, y, 600, 92), Color("#181322"))
		draw_string(ui_font, Vector2(26, y + 12), kit_rows[r][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.6, 1.4, 0.8))
		draw_string(ui_font, Vector2(220, y + 12), kit_rows[r][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#9ab0d0"))
		var x := 40.0
		for tex in kit_rows[r][2]:
			draw_texture_rect(tex, Rect2(x, y + 88.0 - tex.get_height(), tex.get_width(), tex.get_height()), false)
			x += tex.get_width() + 18.0

func _kit_farm() -> Array:
	var wall := Color("#6a4a38")
	var roof := Color("#8a3026")
	var out: Array = []
	# barn — wide, gambrel roof
	var barn := Image.create(56, 40, false, Image.FORMAT_RGBA8)
	_fr(barn, 0, 14, 56, 26, wall)
	_fr(barn, 4, 6, 48, 9, roof)
	_fr(barn, 10, 0, 36, 7, roof.darkened(0.15))
	_fr(barn, 22, 26, 12, 14, Color("#2a1c14"))
	_fr(barn, 24, 28, 8, 10, Color("#402c1c"))
	for xr in [8, 44]:
		_fr(barn, xr, 18, 6, 6, Color("#402c1c"))
	_outline(barn, Color("#1a100c"))
	out.append(barn)
	# silo — TALL vertical anchor
	var silo := Image.create(18, 78, false, Image.FORMAT_RGBA8)
	_fr(silo, 2, 8, 14, 70, Color("#8a8a92"))
	_fr(silo, 2, 8, 4, 70, Color("#a8a8b0"))
	_fr(silo, 0, 2, 18, 8, Color("#5a5a64"))
	for band in 6:
		_fr(silo, 2, 16 + band * 10, 14, 1, Color("#6a6a74"))
	_fr(silo, 6, 60, 6, 18, Color("#3a3a42"))
	_outline(silo, Color("#14141a"))
	out.append(silo)
	# farmhouse — two-story with porch
	var house := Image.create(34, 44, false, Image.FORMAT_RGBA8)
	_fr(house, 2, 12, 30, 32, wall.lightened(0.15))
	_fr(house, 0, 4, 34, 10, roof.darkened(0.1))
	_fr(house, 0, 38, 34, 3, Color("#402c1c"))
	for wy in [18, 30]:
		for wx in [7, 16, 25]:
			_fr(house, wx, wy, 4, 5, Color(1.6, 1.2, 0.5))
	_outline(house, Color("#1a100c"))
	out.append(house)
	# windmill — pole + blades
	var mill := Image.create(40, 74, false, Image.FORMAT_RGBA8)
	_fr(mill, 18, 14, 4, 60, Color("#5a5a64"))
	_fr(mill, 14, 68, 12, 6, Color("#3a3a42"))
	for a in 3:
		var ang := a * TAU / 3.0 + 0.5
		var bx := 20 + int(cos(ang) * 14.0)
		var by := 14 + int(sin(ang) * 14.0)
		_fr(mill, mini(20, bx), mini(14, by), absi(bx - 20) + 2, absi(by - 14) + 2, Color("#c8c8d0"))
	_fr(mill, 17, 11, 6, 6, Color("#8a8a92"))
	_outline(mill, Color("#14141a"))
	out.append(mill)
	return out

func _kit_mill() -> Array:
	var timber := Color("#5a4432")
	var out: Array = []
	# 3-story timber rowhouse
	var row := Image.create(30, 56, false, Image.FORMAT_RGBA8)
	_fr(row, 2, 8, 26, 48, timber)
	_fr(row, 0, 0, 30, 10, Color("#3a2c20"))
	for fy in 3:
		for wx in [6, 14, 22]:
			_fr(row, wx, 14 + fy * 13, 4, 6, Color(1.6, 1.2, 0.5) if (fy + wx) % 3 != 0 else Color("#241a12"))
		_fr(row, 2, 21 + fy * 13, 26, 1, Color("#402c1e"))
	_outline(row, Color("#160e08"))
	out.append(row)
	# sawmill — long shed + big smokestack
	var saw := Image.create(70, 66, false, Image.FORMAT_RGBA8)
	_fr(saw, 0, 40, 54, 26, timber.darkened(0.1))
	_fr(saw, 0, 32, 58, 10, Color("#3a2c20"))
	_fr(saw, 6, 46, 10, 20, Color("#241a12"))
	_fr(saw, 30, 48, 16, 8, Color(1.5, 1.1, 0.4))
	_fr(saw, 56, 0, 10, 66, Color("#6a5a52"))   # smokestack
	_fr(saw, 56, 0, 3, 66, Color("#7e6e64"))
	_fr(saw, 54, 0, 14, 4, Color("#4a3e38"))
	_outline(saw, Color("#160e08"))
	out.append(saw)
	# lumber stacks
	var lum := Image.create(36, 18, false, Image.FORMAT_RGBA8)
	for ly in 3:
		for lx in 4:
			_fr(lum, lx * 9, ly * 6, 8, 5, Color("#8a6a48") if (lx + ly) % 2 == 0 else Color("#755a3e"))
	_outline(lum, Color("#160e08"))
	out.append(lum)
	# waterwheel
	var wheel := Image.create(34, 40, false, Image.FORMAT_RGBA8)
	_fr(wheel, 14, 0, 6, 40, Color("#3a2c20"))
	for a in 8:
		var ang := a * TAU / 8.0
		var sx := 17 + int(cos(ang) * 13.0)
		var sy := 20 + int(sin(ang) * 13.0)
		_fr(wheel, sx - 1, sy - 1, 3, 3, Color("#5a4432"))
	_outline(wheel, Color("#160e08"))
	out.append(wheel)
	return out

func _kit_parish() -> Array:
	var stone := Color("#4a4a56")
	var out: Array = []
	# the church — oversized, spire dominates
	var ch := Image.create(46, 84, false, Image.FORMAT_RGBA8)
	_fr(ch, 6, 40, 34, 44, stone)
	_fr(ch, 2, 34, 42, 8, stone.darkened(0.2))
	_fr(ch, 16, 12, 14, 30, stone.lightened(0.1))    # tower
	for sp in 7:
		_fr(ch, 19 + sp % 2, 2 + sp, 8 - (sp % 2) * 2, 2, Color("#2e2e38"))
	_fr(ch, 21, 0, 4, 4, Color("#2e2e38"))
	_fr(ch, 21, 18, 4, 7, Color(1.4, 1.1, 0.4))      # bell light
	_fr(ch, 12, 50, 6, 12, Color(0.8, 0.5, 1.2))     # stained glass
	_fr(ch, 28, 50, 6, 12, Color(0.8, 0.5, 1.2))
	_fr(ch, 19, 66, 8, 18, Color("#241f2c"))
	_outline(ch, Color("#12101a"))
	out.append(ch)
	# crooked cottage
	var cot := Image.create(30, 30, false, Image.FORMAT_RGBA8)
	_fr(cot, 2, 12, 26, 18, Color("#544438"))
	for ry in 5:
		_fr(cot, 0 + ry, 10 - ry, 30 - ry * 2, 2, Color("#33261c"))   # sagging roof
	_fr(cot, 8, 18, 5, 6, Color(1.5, 1.1, 0.4))
	_fr(cot, 19, 20, 6, 10, Color("#241a12"))
	_outline(cot, Color("#12101a"))
	out.append(cot)
	# dead tree
	var tree := Image.create(26, 44, false, Image.FORMAT_RGBA8)
	_fr(tree, 12, 14, 3, 30, Color("#2c2420"))
	for br in [[12, 14, -8, -6], [14, 18, 8, -8], [13, 10, -5, -8], [14, 8, 6, -6]]:
		var steps := 6
		for s in steps:
			var bx: int = br[0] + int(br[2] * s / float(steps))
			var by: int = br[1] + int(br[3] * s / float(steps))
			if bx >= 0 and bx < 26 and by >= 0:
				tree.set_pixel(bx, by, Color("#2c2420"))
	_outline(tree, Color("#12101a"))
	out.append(tree)
	# graveyard strip
	var grv := Image.create(50, 16, false, Image.FORMAT_RGBA8)
	for g in 5:
		var gx := g * 10 + 2
		_fr(grv, gx, 6, 5, 10, stone.darkened(0.1))
		_fr(grv, gx + 1, 4, 3, 3, stone)
	_outline(grv, Color("#12101a"))
	out.append(grv)
	return out

func _process(_d: float) -> void:
	frames += 1
	queue_redraw()
	if frames == 20 and OS.get_environment("CAL_SHOT") != "":
		get_viewport().get_texture().get_image().save_png(OS.get_environment("CAL_SHOT"))
		get_tree().quit()
