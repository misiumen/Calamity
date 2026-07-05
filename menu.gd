extends Control
# CALAMITY menus — THE PANTHEON. The menu is a place; the gods are the menu.
# No widgets anywhere. Text is sharp at native res (canvas_items stretch).

const ROSTER := [
	{"id": "swarm", "name": "THE SWARM", "sub": "plague of locusts", "kit": "tendrils - grabs - evolve",
		"col": Color(1.8, 0.4, 0.45)},
	{"id": "keraunos", "name": "KERAUNOS", "sub": "colossal storm hydra", "kit": "banked bolts - TEMPEST",
		"col": Color(0.5, 1.5, 2.0)},
	{"id": "tzitzimitl", "name": "TZITZIMITL", "sub": "eclipse serpent", "kit": "lance dives - eat the sun",
		"col": Color(1.9, 1.2, 0.3)},
	{"id": "drowned", "name": "THE DROWNED", "sub": "the tide priest", "kit": "madden - flood - DELUGE",
		"col": Color(0.4, 1.6, 1.5)},
	{"id": "rider", "name": "PALE RIDER", "sub": "pestilence", "kit": "fog - scythe - the dead rise",
		"col": Color(1.7, 1.5, 0.7)},
]
const CITIES := [
	{"id": "kowloon", "name": "NEW KOWLOON", "sub": "neon megacity", "pos": Vector2(468, 208), "glow": Color(1.8, 0.5, 1.2)},
	{"id": "thornspire", "name": "THORNSPIRE", "sub": "gothic spires", "pos": Vector2(300, 148), "glow": Color(0.7, 1.0, 2.0)},
	{"id": "ashport", "name": "ASHPORT", "sub": "rusting sprawl", "pos": Vector2(196, 208), "glow": Color(1.9, 1.0, 0.3)},
	{"id": "teotl", "name": "TEOTL RUINS", "sub": "jungle temples", "pos": Vector2(392, 252), "glow": Color(0.7, 1.8, 0.7)},
	{"id": "maren", "name": "PORT MAREN", "sub": "drowned harbor", "pos": Vector2(180, 280), "glow": Color(0.5, 1.4, 1.6)},
]
const MUTS := [
	["", "NO MUTATOR", "the city as the gods found it"],
	["midnight", "MIDNIGHT", "the sun never shows"],
	["glass", "GLASS CITY", "buildings 40% weaker"],
	["mobilization", "FULL MOBILIZATION", "the army keeps coming"],
	["famine", "FAMINE", "25% less essence"],
]

var ui_font: FontFile
var bold_font: FontFile
var screen := "root"
var picked_char := ""
var picked_city := ""
var hover := -1
var t := 0.0
var save_line := ""
var frames := 0

func _ready() -> void:
	ui_font = load("res://art/Silkscreen-Regular.ttf")
	bold_font = load("res://art/Silkscreen-Bold.ttf")
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(640, 360)
	Global.music("menu")
	_read_save_line()
	if OS.get_environment("CAL_MENU_SCREEN") != "":
		screen = OS.get_environment("CAL_MENU_SCREEN")
		picked_char = "swarm"
		picked_city = "kowloon"

func _read_save_line() -> void:
	save_line = ""
	if not FileAccess.file_exists(Global.SAVE_PATH):
		return
	var f := FileAccess.open(Global.SAVE_PATH, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if d == null:
		return
	var chr: String = str(d.get("character", "?")).to_upper()
	if int(d.get("act", 1)) == 1:
		save_line = "%s - act I, %s" % [chr, str(d.get("province", "?")).to_upper()]
	else:
		save_line = "%s - act II, %d burnt" % [chr, d.get("razed", []).size()]

func _process(delta: float) -> void:
	t += delta
	frames += 1
	queue_redraw()
	if OS.get_environment("CAL_SHOT") != "" and frames == 40:
		get_viewport().get_texture().get_image().save_png(OS.get_environment("CAL_SHOT"))
		get_tree().quit()

# ---------- click zones per screen ----------
func _cards() -> Array:
	var out: Array = []
	match screen:
		"root":
			var n := 3 if save_line != "" else 2
			for i in n:
				out.append(Rect2(130.0 + i * 190.0 - 56.0, 100, 112, 118))
		"char_crusade", "char_skirmish":
			for i in ROSTER.size():
				out.append(Rect2(76.0 + i * 122.0 - 55.0, 150, 110, 160))
		"city_skirmish":
			for i in CITIES.size():
				out.append(Rect2(CITIES[i].pos.x - 34, CITIES[i].pos.y - 30, 68, 56))
		"mutator":
			for i in MUTS.size():
				out.append(Rect2(88.0 + i * 96.0, 96, 84, 160))
		"prologue":
			out.append(Rect2(150, 226, 160, 92))
			out.append(Rect2(330, 226, 160, 92))
	return out

func _activate(i: int) -> void:
	var cs := _cards()
	if i < 0 or i >= cs.size():
		return
	match screen:
		"root":
			var has_save := save_line != ""
			if i == 0:
				screen = "char_crusade"
			elif has_save and i == 1:
				if Global.load_crusade():
					if Global.act == 1:
						Global.launch_act1()
					else:
						Global.goto("res://map.tscn")
			else:
				screen = "char_skirmish"
			hover = -1
		"char_crusade", "char_skirmish":
			picked_char = ROSTER[i].id
			screen = "prologue" if screen == "char_crusade" else "city_skirmish"
			hover = -1
		"city_skirmish":
			picked_city = CITIES[i].id
			screen = "mutator"
			hover = -1
		"mutator":
			Global.mode = "skirmish"
			Global.character = picked_char
			Global.city = picked_city
			Global.mutator = MUTS[i][0]
			Global.goto("res://main.tscn")
		"prologue":
			Global.reset_crusade(picked_char)
			if i == 0:
				Global.node_params = {"kind": "prologue"}
				Global.goto("res://main.tscn")
			else:
				Global.launch_act1()

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		hover = -1
		var cs := _cards()
		for i in cs.size():
			if cs[i].has_point(e.position):
				hover = i
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var cs := _cards()
		for i in cs.size():
			if cs[i].has_point(e.position):
				_activate(i)
				accept_event()
				return

func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed:
		if e.physical_keycode == KEY_ESCAPE and screen != "root":
			screen = {"char_crusade": "root", "char_skirmish": "root", "city_skirmish": "char_skirmish",
				"mutator": "city_skirmish", "prologue": "char_crusade"}.get(screen, "root")
			hover = -1
			return
		var ki: int = e.physical_keycode - KEY_1
		if ki >= 0 and ki < 9:
			_activate(ki)

# ---------- the place ----------
func _scene() -> void:
	# dusk gradient sky
	for i in 20:
		var f: float = i / 19.0
		draw_rect(Rect2(0, f * 200.0, 640, 11), Color(0.06, 0.03, 0.10).lerp(Color(0.42, 0.12, 0.15), f))
	# burning city on the horizon
	for i in 24:
		var bw := 10.0 + fmod(i * 23.3, 26.0)
		var bh := 12.0 + fmod(i * 37.7, 42.0)
		draw_rect(Rect2(i * 27.0, 208.0 - bh, bw, bh), Color("#170f1e"))
		if i % 4 == 0:
			var fl: float = 0.6 + 0.4 * sin(t * 4.0 + i)
			draw_circle(Vector2(i * 27.0 + bw * 0.5, 206.0 - bh), 4.0, Color(1.9 * fl, 0.8 * fl, 0.25, 0.4))
	draw_rect(Rect2(0, 205, 640, 155), Color("#0d0916"))
	# smoke columns crawling up
	for sm in 3:
		for p in 5:
			draw_circle(Vector2(120 + sm * 190 + sin(t * 0.5 + p * 1.7) * 6.0, 195.0 - p * 14.0),
				7.0 + p * 2.5, Color(0.10, 0.07, 0.12, 0.5 - p * 0.08))
	# embers rising
	for e in 16:
		var ey: float = fmod(e * 53.7 + t * 16.0, 330.0)
		draw_rect(Rect2(fmod(e * 97.3 + sin(t * 0.5 + e) * 12.0, 640.0), 345.0 - ey, 1.5, 1.5),
			Color(1.9, 0.7, 0.3, clampf(0.6 - ey * 0.0012, 0.0, 0.6)))

func _god_figure(i: int, gp: Vector2, awake: bool, sc: float = 1.0) -> void:
	var col: Color = ROSTER[i].col
	if awake:
		draw_circle(gp + Vector2(0, -40 * sc), 58.0 * sc, Color(col.r, col.g, col.b, 0.07))
		draw_rect(Rect2(gp.x - 40 * sc, gp.y + 24 * sc, 80 * sc, 3), Color(col.r, col.g, col.b, 0.25))
	match i:
		0:
			draw_circle(gp + Vector2(0, -38 * sc), 26.0 * sc, Color(0.9, 0.12, 0.18, 0.13))
			draw_circle(gp + Vector2(0, -38 * sc), 17.0 * sc, Color("#20040e"))
			for mm in 22:
				var ma: float = mm * 2.4 + t * (0.9 if awake else 0.35)
				var mp := gp + Vector2(0, -38 * sc) + Vector2(cos(ma), sin(ma * 1.3)) * (9.0 + fmod(mm * 5.3, 15.0)) * sc
				draw_line(mp, mp + Vector2(2.5, 1), Color(1.6, 0.35, 0.4), 1.0)
			if awake:
				draw_circle(gp + Vector2(8 * sc, -44 * sc), 3.5 * sc, Color(1.8, 1.1, 0.3))
		1:
			draw_circle(gp + Vector2(0, -26 * sc), 15.0 * sc, Color("#0e0f18"))
			for wg in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([gp + Vector2(wg * 8, -34) * sc,
					gp + Vector2(wg * 40, -58 + sin(t * 2.0) * 4.0) * sc, gp + Vector2(wg * 30, -24) * sc]),
					Color(0.05, 0.06, 0.11, 0.9))
			for hh in 3:
				var hp4 := gp + Vector2((hh - 1) * 13.0, -62.0 + sin(t * 2.0 + hh) * 2.0) * sc
				draw_line(gp + Vector2((hh - 1) * 5.0, -38.0) * sc, hp4, Color("#0e0f18"), 4.0 * sc)
				draw_circle(hp4, 4.0 * sc, Color("#161826"))
				if awake:
					draw_circle(hp4 + Vector2(2 * sc, 0), 1.3, Color(1.2, 2.0, 2.6))
			if awake and randf() < 0.08:
				draw_line(gp + Vector2(randf_range(-20, 20), -50) * sc, gp + Vector2(randf_range(-26, 26), 10) * sc,
					Color(1.4, 1.9, 2.4, 0.7), 1.0)
		2:
			var prev := gp + Vector2(-30, 0) * sc
			for sgm in 11:
				var f4: float = sgm / 10.0
				var npt := gp + Vector2(-30 + f4 * 60.0, -sin(f4 * PI) * 46.0 + sin(t * (2.0 if awake else 0.7) + f4 * 9.0) * 3.0) * sc
				draw_line(prev, npt, Color(0.10, 0.48, 0.47), 7.0 * sc * (1.0 - absf(f4 - 0.5)))
				prev = npt
			draw_circle(prev + Vector2(2, -4) * sc, 5.0 * sc, Color(0.23, 0.72, 0.66))
			if awake:
				draw_circle(prev + Vector2(4, -5) * sc, 1.5, Color(2.4, 1.5, 0.3))
				for fth in 4:
					draw_line(gp + Vector2(-18 + fth * 10.0, -42.0) * sc, gp + Vector2(-22 + fth * 10.0, -52.0) * sc,
						Color(0.9, 0.35, 0.2), 1.5)
		3:
			draw_colored_polygon(PackedVector2Array([gp + Vector2(-14, 0) * sc, gp + Vector2(-12, -34) * sc,
				gp + Vector2(-4, -52) * sc, gp + Vector2(5, -51) * sc, gp + Vector2(12, -32) * sc, gp + Vector2(14, 0) * sc]),
				Color(0.02, 0.08, 0.10))
			for tn in 6:
				draw_line(gp + Vector2((tn - 2.5) * 3.2, -40) * sc,
					gp + Vector2((tn - 2.5) * 4.0 + sin(t * 1.8 + tn) * 2.0, -28 + (tn % 2) * 4) * sc,
					Color(0.04, 0.13, 0.15), 2.0 * sc)
			if awake and fmod(t, 5.0) < 4.7:
				draw_circle(gp + Vector2(-3, -44) * sc, 1.6 * sc, Color(1.3, 2.4, 2.2))
				draw_circle(gp + Vector2(3, -44) * sc, 1.6 * sc, Color(1.3, 2.4, 2.2))
		4:
			draw_colored_polygon(PackedVector2Array([gp + Vector2(16, 0) * sc, gp + Vector2(17, -26) * sc,
				gp + Vector2(7, -44) * sc, gp + Vector2(-3, -48) * sc, gp + Vector2(-15, -34 + sin(t * 1.6) * 2.0) * sc,
				gp + Vector2(-22, -10) * sc, gp + Vector2(-17, 0) * sc]), Color(0.075, 0.06, 0.09))
			draw_circle(gp + Vector2(-2, -42) * sc, 3.6 * sc, Color(0.88, 0.83, 0.66))
			draw_arc(gp + Vector2(2, -54) * sc, 13.0 * sc, -0.4, 1.5, 12, Color(0.97, 0.93, 0.78), 2.4 * sc)
			for lg in 3:
				draw_line(gp + Vector2(-10 + lg * 8.0, 0) * sc, gp + Vector2(-10 + lg * 8.0, -10) * sc,
					Color(0.88, 0.83, 0.66), 2.0 * sc)
			if awake:
				draw_circle(gp + Vector2(-1, -43) * sc, 1.0, Color(1.9, 1.6, 0.6))

func _draw() -> void:
	_scene()
	var cs := _cards()
	match screen:
		"root":
			# the five stand on the ridge, small, watching their work
			for i in 5:
				_god_figure(i, Vector2(180.0 + i * 70.0, 228.0), false, 0.45)
			draw_string(bold_font, Vector2(0, 62), "C A L A M I T Y", HORIZONTAL_ALIGNMENT_CENTER, 640, 34, Color(1.9, 0.45, 0.5))
			draw_string(ui_font, Vector2(0, 82), "you are the apocalypse", HORIZONTAL_ALIGNMENT_CENTER, 640, 9, Color(0.75, 0.68, 0.8))
			# war banners on the beam
			draw_rect(Rect2(56, 94, 528, 4), Color("#241a2c"))
			var titles := [["NEW CRUSADE", "prologue - three acts"]]
			if save_line != "":
				titles.append(["CONTINUE", save_line])
			titles.append(["SKIRMISH", "one god, one city"])
			for i in titles.size():
				var bx: float = 130.0 + i * 190.0
				var hot: bool = hover == i
				var cloth := Color(0.46, 0.11, 0.14) if hot else Color(0.20, 0.15, 0.26)
				var wobble: float = sin(t * 1.4 + i * 2.0) * 2.0
				var pts := PackedVector2Array([Vector2(bx - 52, 98), Vector2(bx + 52, 98)])
				for wv in 5:
					pts.append(Vector2(bx + 50 - wv * 5.0 + wobble * (wv * 0.2), 206.0 + sin(wv * 1.9 + i + t * 1.2) * 4.0 + (wv % 2) * 8.0))
				for wv in 5:
					pts.append(Vector2(bx - 30 - wv * 5.0 + 16.0 - wobble * (wv * 0.2), 212.0 - sin(wv * 1.7 + i + t * 1.1) * 4.0 - (wv % 2) * 8.0))
				draw_colored_polygon(pts, cloth)
				draw_rect(Rect2(bx - 52, 96, 104, 6), Color("#3a2c1c"))
				draw_line(Vector2(bx - 50, 102), Vector2(bx - 48, 192), cloth.darkened(0.35), 2.0)
				draw_line(Vector2(bx + 50, 102), Vector2(bx + 48, 188), cloth.darkened(0.35), 2.0)
				draw_circle(Vector2(bx, 128), 12.0, cloth.darkened(0.3))
				draw_arc(Vector2(bx, 128), 12.0, 0, TAU, 18, Color(1.7, 1.3, 0.7, 0.55), 1.0)
				draw_string(ui_font, Vector2(bx - 50, 158), titles[i][0], HORIZONTAL_ALIGNMENT_CENTER, 100, 11,
					Color(1.9, 0.8, 0.6) if hot else Color(0.9, 0.85, 0.95))
				draw_string(ui_font, Vector2(bx - 56, 176), titles[i][1], HORIZONTAL_ALIGNMENT_CENTER, 112, 5, Color(0.7, 0.64, 0.76))
				if hot:
					for fe in 5:
						draw_circle(Vector2(bx - 34 + fe * 16.0, 204.0 + (fe % 2) * 7.0),
							2.5 + sin(t * 8.0 + fe) * 0.8, Color(2.0, 0.9, 0.3, 0.7))
		"char_crusade", "char_skirmish":
			draw_string(bold_font, Vector2(0, 44), "THE PANTHEON", HORIZONTAL_ALIGNMENT_CENTER, 640, 18, Color(1.9, 0.45, 0.5))
			draw_string(ui_font, Vector2(0, 62), "choose your calamity   [esc - back]", HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color(0.75, 0.68, 0.8))
			draw_rect(Rect2(0, 268, 640, 92), Color("#0a0714"))
			for cr in 10:
				draw_rect(Rect2(cr * 68.0, 264.0 + fmod(cr * 7.7, 8.0), 60.0, 10.0), Color("#0d0918"))
			for i in ROSTER.size():
				var gx: float = 76.0 + i * 122.0
				var awake: bool = hover == i
				_god_figure(i, Vector2(gx, 240.0), awake)
				draw_string(ui_font, Vector2(gx - 55, 284), ROSTER[i].name, HORIZONTAL_ALIGNMENT_CENTER, 110, 9,
					ROSTER[i].col if awake else Color(0.8, 0.75, 0.85))
				if awake:
					draw_string(ui_font, Vector2(gx - 55, 300), ROSTER[i].sub, HORIZONTAL_ALIGNMENT_CENTER, 110, 7, Color(0.85, 0.8, 0.9))
					draw_string(ui_font, Vector2(gx - 55, 314), ROSTER[i].kit, HORIZONTAL_ALIGNMENT_CENTER, 110, 6, Color(0.7, 0.65, 0.75))
				else:
					draw_string(ui_font, Vector2(gx - 55, 300), "[%d]" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, 110, 7, Color(0.55, 0.5, 0.65))
		"city_skirmish":
			draw_string(bold_font, Vector2(0, 44), "THE CITY THAT DIES TONIGHT", HORIZONTAL_ALIGNMENT_CENTER, 640, 15, Color(1.9, 0.45, 0.5))
			draw_string(ui_font, Vector2(0, 62), "[esc - back]", HORIZONTAL_ALIGNMENT_CENTER, 640, 7, Color(0.75, 0.68, 0.8))
			# the continent, and five burning beacons on it
			draw_colored_polygon(PackedVector2Array([Vector2(120, 300), Vector2(96, 220), Vector2(150, 140),
				Vector2(260, 108), Vector2(420, 120), Vector2(540, 170), Vector2(548, 250), Vector2(470, 296),
				Vector2(320, 312), Vector2(190, 316)]), Color("#141020"))
			for i in CITIES.size():
				var ci: Dictionary = CITIES[i]
				var hot: bool = hover == i
				var gl: Color = ci.glow
				var rr: float = 7.0 + (3.0 if hot else 0.0) + sin(t * 3.0 + i) * 1.0
				draw_circle(ci.pos, rr + 5.0, Color(gl.r, gl.g, gl.b, 0.14))
				draw_circle(ci.pos, rr * 0.55, gl)
				for fe2 in 3:
					draw_circle(ci.pos + Vector2((fe2 - 1) * 4.0, -rr * 0.8 - fmod(t * 20.0 + fe2 * 9.0, 8.0)),
						1.2, Color(gl.r, gl.g, gl.b, 0.5))
				draw_string(ui_font, Vector2(ci.pos.x - 60, ci.pos.y - rr - 10), ci.name, HORIZONTAL_ALIGNMENT_CENTER, 120, 8,
					gl if hot else Color(0.85, 0.8, 0.9))
				if hot:
					draw_string(ui_font, Vector2(ci.pos.x - 60, ci.pos.y + rr + 14), ci.sub, HORIZONTAL_ALIGNMENT_CENTER, 120, 7, Color(0.8, 0.75, 0.85))
				else:
					draw_string(ui_font, Vector2(ci.pos.x - 60, ci.pos.y + rr + 14), "[%d]" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, 120, 6, Color(0.5, 0.46, 0.58))
		"mutator":
			draw_string(bold_font, Vector2(0, 44), "BEND THE NIGHT", HORIZONTAL_ALIGNMENT_CENTER, 640, 15, Color(1.9, 0.45, 0.5))
			draw_string(ui_font, Vector2(0, 62), "wax-sealed edicts   [esc - back]", HORIZONTAL_ALIGNMENT_CENTER, 640, 7, Color(0.75, 0.68, 0.8))
			draw_rect(Rect2(80, 90, 480, 4), Color("#241a2c"))
			for i in MUTS.size():
				var ex: float = 130.0 + i * 96.0
				var hot: bool = hover == i
				var sway: float = sin(t * 1.2 + i * 1.7) * 2.0
				# the hanging scroll
				draw_line(Vector2(ex, 94), Vector2(ex + sway, 104), Color("#3a2c1c"), 2.0)
				var sr := Rect2(ex - 42 + sway, 104, 84, 130 + (14 if hot else 0))
				draw_rect(sr, Color(0.86, 0.78, 0.62) if hot else Color(0.62, 0.55, 0.44))
				draw_rect(Rect2(sr.position, Vector2(sr.size.x, 5)), Color(0.4, 0.32, 0.24))
				draw_rect(Rect2(sr.position + Vector2(0, sr.size.y - 5), Vector2(sr.size.x, 5)), Color(0.4, 0.32, 0.24))
				# wax seal
				draw_circle(Vector2(ex + sway, sr.position.y + sr.size.y - 18), 8.0,
					Color(0.62, 0.12, 0.14) if not hot else Color(0.8, 0.16, 0.18))
				draw_string(ui_font, Vector2(sr.position.x + 4, sr.position.y + 28), MUTS[i][1],
					HORIZONTAL_ALIGNMENT_CENTER, sr.size.x - 8, 8, Color(0.2, 0.14, 0.1))
				var words: PackedStringArray = str(MUTS[i][2]).split(" ")
				var line := ""
				var ly: float = sr.position.y + 50.0
				for w2 in words:
					if line.length() + w2.length() > 13:
						draw_string(ui_font, Vector2(sr.position.x + 4, ly), line, HORIZONTAL_ALIGNMENT_CENTER, sr.size.x - 8, 6, Color(0.32, 0.24, 0.18))
						ly += 10.0
						line = w2
					else:
						line += (" " if line != "" else "") + w2
				if line != "":
					draw_string(ui_font, Vector2(sr.position.x + 4, ly), line, HORIZONTAL_ALIGNMENT_CENTER, sr.size.x - 8, 6, Color(0.32, 0.24, 0.18))
				draw_string(ui_font, Vector2(sr.position.x, sr.position.y + sr.size.y - 40), "[%d]" % (i + 1),
					HORIZONTAL_ALIGNMENT_CENTER, sr.size.x, 6, Color(0.4, 0.3, 0.24))
		"prologue":
			var gi := 0
			for j in ROSTER.size():
				if ROSTER[j].id == picked_char:
					gi = j
			draw_string(bold_font, Vector2(0, 44), ROSTER[gi].name, HORIZONTAL_ALIGNMENT_CENTER, 640, 17, ROSTER[gi].col)
			draw_string(ui_font, Vector2(0, 62), "every calamity has an origin", HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color(0.75, 0.68, 0.8))
			# the altar
			draw_rect(Rect2(240, 196, 160, 14), Color("#241a2c"))
			draw_rect(Rect2(256, 210, 128, 8), Color("#1a1220"))
			_god_figure(gi, Vector2(320, 196.0), true, 0.9)
			# two torches: live the origin / skip to the war
			var opts := [["LIVE THE ORIGIN", "a playable birth", ROSTER[gi].col], ["SKIP TO ACT I", "straight to the war", Color(0.9, 0.5, 0.3)]]
			for i in 2:
				var tx: float = 230.0 + i * 180.0
				var hot: bool = hover == i
				draw_rect(Rect2(tx - 2, 240, 4, 52), Color("#3a2c1c"))
				var fcol: Color = opts[i][2]
				var fh: float = (14.0 if hot else 9.0) + sin(t * 9.0 + i * 3.0) * 2.0
				draw_circle(Vector2(tx, 238), 7.0, Color(fcol.r, fcol.g, fcol.b, 0.2))
				draw_colored_polygon(PackedVector2Array([Vector2(tx - 5, 240), Vector2(tx + sin(t * 7.0 + i) * 3.0, 240 - fh),
					Vector2(tx + 5, 240)]), fcol)
				draw_string(ui_font, Vector2(tx - 80, 306), opts[i][0], HORIZONTAL_ALIGNMENT_CENTER, 160, 10,
					fcol if hot else Color(0.9, 0.85, 0.95))
				draw_string(ui_font, Vector2(tx - 80, 320), opts[i][1], HORIZONTAL_ALIGNMENT_CENTER, 160, 6, Color(0.7, 0.64, 0.76))
