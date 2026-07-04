extends Node2D
# ACT 2 — THE CRUSADE. A continent of nodes; your trail burns behind you.

const NODES := [
	{"id": 0, "pos": Vector2(70, 250), "kind": "start", "name": "THE LANDFALL"},
	{"id": 1, "pos": Vector2(150, 190), "kind": "hamlet", "name": "GREYFEN", "links": [0]},
	{"id": 2, "pos": Vector2(160, 300), "kind": "town", "name": "MILLWATCH", "links": [0]},
	{"id": 3, "pos": Vector2(250, 140), "kind": "town", "name": "COLDBARROW", "links": [1]},
	{"id": 4, "pos": Vector2(260, 240), "kind": "city", "city": "ashport", "name": "ASHPORT", "links": [1, 2]},
	{"id": 5, "pos": Vector2(280, 320), "kind": "city", "city": "maren", "name": "PORT MAREN", "links": [2]},
	{"id": 6, "pos": Vector2(360, 180), "kind": "city", "city": "thornspire", "name": "THORNSPIRE", "links": [3, 4]},
	{"id": 7, "pos": Vector2(380, 290), "kind": "town", "name": "SALTCROSS", "links": [4, 5]},
	{"id": 8, "pos": Vector2(450, 120), "kind": "hamlet", "name": "HIGH HOLLOW", "links": [6]},
	{"id": 9, "pos": Vector2(470, 240), "kind": "city", "city": "teotl", "name": "TEOTL RUINS", "links": [6, 7]},
	{"id": 10, "pos": Vector2(540, 300), "kind": "city", "city": "kowloon", "name": "NEW KOWLOON", "links": [7, 9]},
	{"id": 11, "pos": Vector2(580, 170), "kind": "capital", "city": "kowloon", "name": "THE CAPITAL", "links": [8, 9, 10]},
	{"id": 12, "pos": Vector2(210, 100), "kind": "relicsite", "name": "OLD ALTAR", "links": [1, 3]},
	{"id": 13, "pos": Vector2(440, 330), "kind": "relicsite", "name": "SUNKEN VAULT", "links": [5, 7]},
]
const RELICS := [
	{"id": "oldhunger", "name": "OLD HUNGER", "desc": "begin every city with your first evolution ready"},
	{"id": "thickhide", "name": "THICK HIDE", "desc": "15% less damage taken"},
	{"id": "darkomen", "name": "DARK OMEN", "desc": "special meter starts half full"},
	{"id": "locustyears", "name": "LOCUST YEARS", "desc": "all essence gains +25%"},
	{"id": "dreadname", "name": "DREAD NAME", "desc": "threat climbs 20% slower — they whisper, not shout"},
	{"id": "warfeast", "name": "WARFEAST", "desc": "kills mend your body twice as well"},
	{"id": "longshadow", "name": "LONG SHADOW", "desc": "begin 10% larger"},
	{"id": "carrionwind", "name": "CARRION WIND", "desc": "+30% tribute from every city"},
]

var ui_font: FontFile
var picking_relic := false

func _ready() -> void:
	Global.music("map")
	ui_font = load("res://art/Silkscreen-Regular.ttf")
	# offered a relic after each razing (skip the very first arrival)
	picking_relic = Global.node_params.get("offer_relic", false)
	Global.node_params = {}
	if picking_relic:
		_relic_overlay()

func _reachable(id: int) -> bool:
	if id == Global.map_pos or id in Global.razed:
		return false
	var n: Dictionary = NODES[id]
	for l in n.get("links", []):
		if l == Global.map_pos or l in Global.razed:
			return true
	return false

func _unhandled_input(e: InputEvent) -> void:
	if picking_relic:
		return
	if e is InputEventKey and e.pressed and e.physical_keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://menu.tscn")
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var mp := get_global_mouse_position()
		for n in NODES:
			if n.pos.distance_to(mp) < 16.0 and _reachable(n.id):
				if n.kind == "relicsite":
					# no battle here — an old power waits to be claimed
					Global.map_pos = n.id
					Global.razed.append(n.id)
					Global.save_crusade()
					picking_relic = true
					_relic_overlay()
					return
				_launch(n)
				return

func _launch(n: Dictionary) -> void:
	Global.map_pos = n.id
	Global.city = n.get("city", ["kowloon", "thornspire", "ashport", "teotl", "maren"][randi() % 5])
	var alert: int = Global.razed.size()
	var params := {"map_node": n.id, "alert": alert, "kind": n.kind}
	match n.kind:
		"hamlet":
			params.world_w = 2000.0
			params.tier_cap = 2 + int(alert / 3.0)
			params.objective = "raze"
		"town":
			params.world_w = 3000.0
			params.tier_cap = 3 + int(alert / 3.0)
			params.objective = ["raze", "blackout", "extinction"][randi() % 3]
		"capital":
			params.world_w = 5200.0
			params.tier_cap = 5
			params.capital = true
			params.objective = "decapitation"
		_:
			params.tier_cap = 5
			params.objective = ["raze", "decapitation", "extinction", "blackout", "terror", "feast"][randi() % 6]
	Global.node_params = params
	Global.save_crusade()
	get_tree().change_scene_to_file("res://main.tscn")

func _relic_overlay() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var dim := ColorRect.new()
	dim.size = Vector2(640, 360)
	dim.color = Color(0.02, 0.0, 0.05, 0.8)
	layer.add_child(dim)
	var title := Label.new()
	title.text = "THE RUIN LEAVES A GIFT — take one"
	title.position = Vector2(0, 70)
	title.size = Vector2(640, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ui_font)
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1.8, 0.5, 0.5))
	layer.add_child(title)
	var pool := RELICS.filter(func(r): return not r.id in Global.relics)
	pool.shuffle()
	for i in mini(3, pool.size()):
		var rl: Dictionary = pool[i]
		var btn := Button.new()
		btn.text = rl.name
		btn.position = Vector2(190, 120 + i * 58)
		btn.size = Vector2(260, 26)
		btn.add_theme_font_override("font", ui_font)
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(func():
			Global.relics.append(rl.id)
			Global.save_crusade()
			picking_relic = false
			layer.queue_free())
		layer.add_child(btn)
		var d := Label.new()
		d.text = rl.desc
		d.position = Vector2(0, 147 + i * 58)
		d.size = Vector2(640, 14)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.add_theme_font_override("font", ui_font)
		d.add_theme_font_size_override("font_size", 8)
		d.add_theme_color_override("font_color", Color("#9ab0d0"))
		layer.add_child(d)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var f := ui_font
	draw_rect(Rect2(0, 0, 640, 360), Color("#0c0a12"))
	# faded landmass
	draw_rect(Rect2(30, 60, 590, 280), Color("#141020"))
	for i in 40:
		var hx := 30.0 + fmod(sin(i * 37.7) * 917.0, 1.0) * 580.0
		var hy := 70.0 + fmod(sin(i * 71.3) * 517.0, 1.0) * 260.0
		draw_circle(Vector2(hx, hy), 8.0 + fmod(float(i), 4.0) * 4.0, Color(0.1, 0.09, 0.15, 0.5))
	draw_string(f, Vector2(320, 34), "ACT II — THE CRUSADE", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(1.8, 0.5, 0.5))
	draw_string(f, Vector2(320, 52), "WORLD ALERT %d   ·   TRIBUTE %d   ·   ESC — retreat" % [Global.razed.size(), Global.tribute],
		HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color("#9ab0d0"))
	# roads
	for n in NODES:
		for l in n.get("links", []):
			var a: Vector2 = NODES[l].pos
			var b: Vector2 = n.pos
			var burnt: bool = (n.id in Global.razed or n.id == Global.map_pos) and (l in Global.razed or l == Global.map_pos)
			draw_line(a, b, Color(0.5, 0.15, 0.1, 0.8) if burnt else Color(0.25, 0.22, 0.35), 2.0 if burnt else 1.0)
	# nodes
	for n in NODES:
		var col: Color
		var r := 8.0
		match n.kind:
			"start": col = Color(0.4, 0.35, 0.5)
			"hamlet":
				col = Color(0.5, 0.6, 0.45)
				r = 6.0
			"town": col = Color(0.6, 0.55, 0.4)
			"capital":
				col = Color(1.8, 1.2, 0.4)
				r = 12.0
			"relicsite":
				col = Color(0.9, 0.5, 1.4)
				r = 7.0
			_: col = Color(0.55, 0.4, 0.6)
		var razed_n: bool = n.id in Global.razed
		if razed_n:
			col = Color(0.35, 0.12, 0.1)
		draw_circle(n.pos, r, col)
		if n.id == Global.map_pos:
			draw_arc(n.pos, r + 4.0 + sin(Time.get_ticks_msec() * 0.005) * 1.5, 0, TAU, 20, Color(1.8, 0.4, 0.4), 1.5)
		elif _reachable(n.id):
			draw_arc(n.pos, r + 3.0, 0, TAU, 20, Color(1.5, 1.3, 0.7, 0.5 + sin(Time.get_ticks_msec() * 0.004) * 0.3), 1.0)
		if razed_n:
			draw_line(n.pos + Vector2(-4, -4), n.pos + Vector2(4, 4), Color(0.9, 0.3, 0.2), 1.5)
			draw_line(n.pos + Vector2(-4, 4), n.pos + Vector2(4, -4), Color(0.9, 0.3, 0.2), 1.5)
		draw_string(f, n.pos + Vector2(0, -r - 5), n.name, HORIZONTAL_ALIGNMENT_CENTER, -1, 7,
			Color(0.9, 0.85, 0.8, 0.85))
	draw_string(f, Vector2(320, 350), "choose where the ruin goes next", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(0.7, 0.65, 0.7, 0.6))
