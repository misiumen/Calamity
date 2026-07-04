extends Control
# CALAMITY menus — one visual system (THE MOLT card language), zero default widgets.
# Burning skyline behind everything; every string drawn inside a fixed width.

const ROSTER := [
	{"id": "swarm", "name": "THE SWARM", "sub": "plague of locusts", "kit": "tendrils - grabs - evolve",
		"col": Color(1.8, 0.4, 0.45)},
	{"id": "keraunos", "name": "KERAUNOS", "sub": "colossal storm hydra", "kit": "banked bolts - TEMPEST",
		"col": Color(0.5, 1.5, 2.0)},
	{"id": "tzitzimitl", "name": "TZITZIMITL", "sub": "eclipse serpent", "kit": "lance dives - eat the sun",
		"col": Color(1.9, 1.2, 0.3)},
	{"id": "drowned", "name": "THE DROWNED", "sub": "the tide priest", "kit": "madden - flood - fishmen",
		"col": Color(0.4, 1.6, 1.5)},
	{"id": "rider", "name": "PALE RIDER", "sub": "pestilence", "kit": "fog infects - dead rise",
		"col": Color(1.7, 1.5, 0.7)},
]
const CITIES := [
	{"id": "kowloon", "name": "NEW KOWLOON", "sub": "neon megacity - the baseline hunt",
		"sky": [Color("#1a1440"), Color("#7a2244")]},
	{"id": "thornspire", "name": "THORNSPIRE", "sub": "cold gothic spires - hardened garrison",
		"sky": [Color("#070c22"), Color("#2a4470")]},
	{"id": "ashport", "name": "ASHPORT", "sub": "rusting sprawl - endless reinforcements",
		"sky": [Color("#241408"), Color("#8a5416")]},
	{"id": "teotl", "name": "TEOTL RUINS", "sub": "jungle temples - old gods' ground",
		"sky": [Color("#0a241a"), Color("#37945a")]},
	{"id": "maren", "name": "PORT MAREN", "sub": "half-drowned harbor - standing water",
		"sky": [Color("#131c2c"), Color("#587a8a")]},
]
const MUTS := [
	["", "NO MUTATOR", "the city as the gods found it"],
	["midnight", "MIDNIGHT", "the sun never shows"],
	["glass", "GLASS CITY", "buildings 40% weaker"],
	["mobilization", "FULL MOBILIZATION", "the army keeps coming"],
	["famine", "FAMINE", "25% less essence in everything"],
]

var ui_font: FontFile
var bold_font: FontFile
var screen := "root"   # root | char_crusade | char_skirmish | city_skirmish | mutator | prologue
var picked_char := ""
var picked_city := ""
var hover := -1
var t := 0.0
var save_line := ""    # what CONTINUE resumes
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
		save_line = "%s - act I, the rise of %s" % [chr, str(d.get("province", "?")).to_upper()]
	else:
		save_line = "%s - act II, %d places burnt" % [chr, d.get("razed", []).size()]

func _process(delta: float) -> void:
	t += delta
	frames += 1
	queue_redraw()
	if OS.get_environment("CAL_SHOT") != "" and frames == 40:
		get_viewport().get_texture().get_image().save_png(OS.get_environment("CAL_SHOT"))
		get_tree().quit()

# ---------- layout: one source of truth for draw + input ----------
func _cards() -> Array:
	var out: Array = []
	match screen:
		"root":
			var rows := [["NEW CRUSADE", "prologue, three acts, a continent to raze"]]
			if save_line != "":
				rows.append(["CONTINUE CRUSADE", save_line])
			rows.append(["SKIRMISH", "one god, one city, no stakes"])
			for i in rows.size():
				out.append({"r": Rect2(170, 140 + i * 62, 300, 50), "name": rows[i][0], "sub": rows[i][1]})
		"char_crusade", "char_skirmish":
			for i in ROSTER.size():
				out.append({"r": Rect2(14 + i * 124, 78, 116, 240), "god": i})
		"city_skirmish":
			for i in CITIES.size():
				out.append({"r": Rect2(14 + i * 124, 88, 116, 200), "city": i})
		"mutator":
			for i in MUTS.size():
				out.append({"r": Rect2(170, 84 + i * 52, 300, 44), "name": MUTS[i][1], "sub": MUTS[i][2]})
		"prologue":
			out.append({"r": Rect2(170, 196, 300, 52), "name": "LIVE THE ORIGIN", "sub": "a playable birth — learn your verb"})
			out.append({"r": Rect2(170, 260, 300, 52), "name": "SKIP TO ACT I", "sub": "straight to the war"})
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
			if cs[i].r.has_point(e.position):
				hover = i
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var cs := _cards()
		for i in cs.size():
			if cs[i].r.has_point(e.position):
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

# ---------- drawing ----------
func _frame(r: Rect2, bord: Color, fill: Color) -> void:
	draw_rect(r, fill)
	for edge in [Rect2(r.position, Vector2(r.size.x, 2)), Rect2(r.position + Vector2(0, r.size.y - 2), Vector2(r.size.x, 2)),
			Rect2(r.position, Vector2(2, r.size.y)), Rect2(r.position + Vector2(r.size.x - 2, 0), Vector2(2, r.size.y))]:
		draw_rect(edge, bord)
	for c in [Vector2.ZERO, Vector2(r.size.x - 6, 0), Vector2(0, r.size.y - 6), Vector2(r.size.x - 6, r.size.y - 6)]:
		draw_rect(Rect2(r.position + c, Vector2(6, 6)), bord)

func _bg() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("#0a0712"))
	# burning skyline at the foot of every menu
	for i in 16:
		var bw := 24.0 + fmod(i * 37.7, 40.0)
		var bh := 30.0 + fmod(i * 53.3, 70.0)
		var bx := i * 41.0
		draw_rect(Rect2(bx, 360 - bh, bw, bh), Color("#151020"))
		if i % 3 == 0:
			var fl: float = 0.7 + 0.3 * sin(t * 5.0 + i)
			draw_circle(Vector2(bx + bw * 0.5, 360 - bh - 2), 5.0, Color(1.8 * fl, 0.7 * fl, 0.2, 0.35))
			draw_circle(Vector2(bx + bw * 0.5, 360 - bh - 2), 2.0, Color(2.2, 1.2, 0.4, 0.7 * fl))
	draw_rect(Rect2(0, 300, 640, 60), Color(0.04, 0.02, 0.07, 0.55))
	# drifting embers
	for e in 14:
		var ey: float = fmod(e * 53.7 + t * 14.0, 320.0)
		draw_rect(Rect2(fmod(e * 97.3 + sin(t * 0.6 + e) * 10.0, 640.0), 340.0 - ey, 1.5, 1.5),
			Color(1.9, 0.7, 0.3, 0.5 - ey * 0.001))

func _emblem(i: int, gp: Vector2, col: Color) -> void:
	draw_circle(gp, 34.0, Color("#100c1a"))
	draw_arc(gp, 34.0, 0, TAU, 24, Color(col.r, col.g, col.b, 0.4), 1.0)
	match i:
		0:
			draw_circle(gp, 15.0, Color("#2a0614"))
			for mm in 16:
				var ma: float = mm * 2.4 + t * 0.7
				var mp := gp + Vector2(cos(ma), sin(ma * 1.3)) * (8.0 + fmod(mm * 5.3, 12.0))
				draw_line(mp, mp + Vector2(2.5, 1), Color(1.7, 0.4, 0.4), 1.0)
			draw_circle(gp + Vector2(7, -4), 3.0, Color(1.8, 1.1, 0.3))
		1:
			for h2 in 3:
				var hh := gp + Vector2((h2 - 1) * 11.0, -14.0 + sin(t * 2.0 + h2) * 2.0)
				draw_line(gp + Vector2((h2 - 1) * 4.0, 4.0), hh, Color(0.10, 0.11, 0.18), 3.0)
				draw_circle(hh, 3.0, Color(0.16, 0.18, 0.28))
				draw_circle(hh + Vector2(2, 0), 1.1, Color(1.2, 2.0, 2.6))
			draw_circle(gp + Vector2(0, 8), 10.0, Color(0.10, 0.11, 0.18))
			if randf() < 0.06:
				draw_line(gp + Vector2(randf_range(-12, 12), -14), gp + Vector2(randf_range(-16, 16), 12),
					Color(1.4, 1.9, 2.4, 0.7), 1.0)
		2:
			var prev := gp + Vector2(-20, 10)
			for s2 in 9:
				var f4: float = s2 / 8.0
				var npt := gp + Vector2(-20 + f4 * 40.0, 10.0 - sin(f4 * PI) * 22.0 + sin(t * 2.0 + f4 * 5.0) * 1.5)
				draw_line(prev, npt, Color(0.10, 0.48, 0.47), 4.5 * (1.0 - absf(f4 - 0.5)))
				prev = npt
			draw_circle(prev, 3.5, Color(0.23, 0.72, 0.66))
			draw_circle(prev + Vector2(2, -1), 1.2, Color(2.4, 1.5, 0.3))
		3:
			draw_colored_polygon(PackedVector2Array([gp + Vector2(-11, 24), gp + Vector2(-9, -6),
				gp + Vector2(-3, -19), gp + Vector2(4, -18), gp + Vector2(9, -4), gp + Vector2(11, 24)]),
				Color(0.02, 0.08, 0.10))
			for tn in 5:
				draw_line(gp + Vector2((tn - 2) * 3.5, -12),
					gp + Vector2((tn - 2) * 4.5 + sin(t * 2.0 + tn) * 2.0, -2 + (tn % 2) * 4), Color(0.04, 0.13, 0.15), 2.0)
			var blink: float = 0.0 if fmod(t, 5.0) < 4.8 else 1.0
			if blink < 0.5:
				draw_circle(gp + Vector2(-3, -13), 1.4, Color(1.3, 2.4, 2.2))
				draw_circle(gp + Vector2(3, -13), 1.4, Color(1.3, 2.4, 2.2))
		4:
			draw_colored_polygon(PackedVector2Array([gp + Vector2(13, 22), gp + Vector2(14, -2),
				gp + Vector2(5, -17), gp + Vector2(-3, -21), gp + Vector2(-13, -11 + sin(t * 1.8) * 1.5),
				gp + Vector2(-19, 7), gp + Vector2(-14, 22)]), Color(0.075, 0.06, 0.09))
			draw_circle(gp + Vector2(-2, -15), 2.8, Color(0.88, 0.83, 0.66))
			draw_circle(gp + Vector2(-1, -16), 0.8, Color(1.9, 1.6, 0.6))
			draw_arc(gp + Vector2(2, -24), 10.0, -0.4, 1.5, 10, Color(0.97, 0.93, 0.78), 2.0)

func _draw() -> void:
	_bg()
	var cs := _cards()
	match screen:
		"root":
			draw_string(bold_font, Vector2(0, 92), "C A L A M I T Y", HORIZONTAL_ALIGNMENT_CENTER, 640, 34, Color(1.9, 0.45, 0.5))
			draw_string(ui_font, Vector2(0, 112), "you are the apocalypse", HORIZONTAL_ALIGNMENT_CENTER, 640, 9, Color("#8d86a8"))
			for i in cs.size():
				_banner(cs[i], i, Color(1.8, 0.55, 0.55) if i == 0 else Color(0.95, 0.9, 1.0))
		"char_crusade", "char_skirmish":
			draw_string(bold_font, Vector2(0, 42), "CHOOSE YOUR CALAMITY", HORIZONTAL_ALIGNMENT_CENTER, 640, 15, Color(1.9, 0.45, 0.5))
			draw_string(ui_font, Vector2(0, 58), "[esc - back]", HORIZONTAL_ALIGNMENT_CENTER, 640, 7, Color("#8d86a8"))
			for i in cs.size():
				var g: Dictionary = ROSTER[i]
				var r: Rect2 = cs[i].r
				var hov: bool = hover == i
				if hov:
					r.position.y -= 6.0
					draw_rect(Rect2(r.position - Vector2(4, 4), r.size + Vector2(8, 8)), Color(g.col.r, g.col.g, g.col.b, 0.12))
				_frame(r, g.col if hov else Color(0.4, 0.32, 0.45), Color("#151020"))
				_emblem(i, r.position + Vector2(58, 74), g.col)
				draw_string(ui_font, Vector2(r.position.x, r.position.y + 134), g.name, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, g.col)
				draw_string(ui_font, Vector2(r.position.x + 6, r.position.y + 156), g.sub, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 12, 7, Color("#b8b0c8"))
				draw_string(ui_font, Vector2(r.position.x + 6, r.position.y + 172), g.kit, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 12, 6, Color("#8d86a8"))
				draw_string(ui_font, Vector2(r.position.x, r.position.y + r.size.y - 12), "[%d]" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 7, Color(0.6, 0.55, 0.7))
		"city_skirmish":
			draw_string(bold_font, Vector2(0, 42), "THE CITY THAT DIES TONIGHT", HORIZONTAL_ALIGNMENT_CENTER, 640, 15, Color(1.9, 0.45, 0.5))
			draw_string(ui_font, Vector2(0, 58), "[esc - back]", HORIZONTAL_ALIGNMENT_CENTER, 640, 7, Color("#8d86a8"))
			for i in cs.size():
				var ci: Dictionary = CITIES[i]
				var r: Rect2 = cs[i].r
				var hov: bool = hover == i
				if hov:
					r.position.y -= 6.0
					draw_rect(Rect2(r.position - Vector2(4, 4), r.size + Vector2(8, 8)), Color(1.9, 0.6, 0.6, 0.10))
				_frame(r, Color(1.9, 0.6, 0.6) if hov else Color(0.4, 0.32, 0.45), Color("#151020"))
				# the city's own dusk in a window
				var wr := Rect2(r.position + Vector2(8, 10), Vector2(r.size.x - 16, 64))
				draw_rect(wr, ci.sky[0])
				draw_rect(Rect2(wr.position + Vector2(0, wr.size.y * 0.55), Vector2(wr.size.x, wr.size.y * 0.45)), ci.sky[1])
				for bz in 6:
					var bh2: float = 8.0 + fmod(bz * 17.3 + i * 7.0, 26.0)
					draw_rect(Rect2(wr.position.x + 2 + bz * 16.0, wr.position.y + wr.size.y - bh2, 12.0, bh2), Color("#100c1a"))
				draw_string(ui_font, Vector2(r.position.x, r.position.y + 96), ci.name, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 8, Color(0.95, 0.9, 1.0))
				var words: PackedStringArray = str(ci.sub).split(" ")
				var line := ""
				var ly: float = r.position.y + 116.0
				for w2 in words:
					if line.length() + w2.length() > 17:
						draw_string(ui_font, Vector2(r.position.x + 6, ly), line, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 12, 6, Color("#8d86a8"))
						ly += 10.0
						line = w2
					else:
						line += (" " if line != "" else "") + w2
				if line != "":
					draw_string(ui_font, Vector2(r.position.x + 6, ly), line, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 12, 6, Color("#8d86a8"))
				draw_string(ui_font, Vector2(r.position.x, r.position.y + r.size.y - 12), "[%d]" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 7, Color(0.6, 0.55, 0.7))
		"mutator":
			draw_string(bold_font, Vector2(0, 42), "BEND THE NIGHT", HORIZONTAL_ALIGNMENT_CENTER, 640, 15, Color(1.9, 0.45, 0.5))
			draw_string(ui_font, Vector2(0, 58), "[esc - back]", HORIZONTAL_ALIGNMENT_CENTER, 640, 7, Color("#8d86a8"))
			for i in cs.size():
				_banner(cs[i], i, Color(0.95, 0.9, 1.0))
		"prologue":
			var g2: Dictionary = ROSTER[0]
			for gi in ROSTER.size():
				if ROSTER[gi].id == picked_char:
					g2 = ROSTER[gi]
					_emblem(gi, Vector2(320, 118), g2.col)
			draw_string(bold_font, Vector2(0, 42), g2.name, HORIZONTAL_ALIGNMENT_CENTER, 640, 15, g2.col)
			draw_string(ui_font, Vector2(0, 172), "every calamity has an origin.", HORIZONTAL_ALIGNMENT_CENTER, 640, 9, Color(0.85, 0.8, 0.85))
			for i in cs.size():
				_banner(cs[i], i, g2.col if i == 0 else Color(0.95, 0.9, 1.0))

func _banner(c: Dictionary, i: int, name_col: Color) -> void:
	var r: Rect2 = c.r
	var hov: bool = hover == i
	if hov:
		r.position.y -= 3.0
		draw_rect(Rect2(r.position - Vector2(4, 4), r.size + Vector2(8, 8)), Color(1.9, 0.5, 0.5, 0.10))
	_frame(r, Color(1.9, 0.6, 0.6) if hov else Color(0.4, 0.32, 0.45), Color("#151020"))
	draw_string(ui_font, Vector2(r.position.x, r.position.y + 20), c.name, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13,
		Color(1.8, 0.55, 0.55) if hov else name_col)
	draw_string(ui_font, Vector2(r.position.x + 8, r.position.y + r.size.y - 12), c.sub, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 7, Color("#8d86a8"))
