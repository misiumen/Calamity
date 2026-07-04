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

const ACT1_NODES := [
	{"id": 0, "pos": Vector2(80, 265), "kind": "start", "name": "THE WAKING"},
	{"id": 1, "pos": Vector2(185, 235), "kind": "hamlet", "links": [0]},
	{"id": 2, "pos": Vector2(295, 165), "kind": "farms", "links": [1]},
	{"id": 3, "pos": Vector2(305, 300), "kind": "mill", "links": [1]},
	{"id": 4, "pos": Vector2(415, 235), "kind": "town", "links": [2, 3]},
	{"id": 5, "pos": Vector2(475, 135), "kind": "relicsite", "name": "OLD SHRINE", "links": [4]},
	{"id": 6, "pos": Vector2(565, 245), "kind": "provcity", "links": [4, 5]},
]
const PROVINCE_NAMES := {
	"ashport": ["CINDER ROW", "GREYWATER FARMS", "THE COKEWORKS", "KILNMOOR", "ASHPORT"],
	"thornspire": ["BLACKFEN", "PILGRIM'S FIELD", "THE SAWGATE", "CANDLEMERE", "THORNSPIRE"],
	"teotl": ["XOCHITAN", "THE MILPA TERRACES", "OBSIDIAN CAMP", "TEPETLAN", "TEOTL"],
	"maren": ["SALTHOLLOW", "THE OYSTER BEDS", "WRECKER'S MILL", "BRINEWATCH", "PORT MAREN"],
	"kowloon": ["PYLON SHANTIES", "THE PADDY SPRAWL", "SCRAP QUARTER", "NEON FRINGE", "NEW KOWLOON"],
}

var ns: Array = []               # active node set (act 1 rise map or act 2 continent)

const FATE_NAMES := {
	"richfeeding": "RICH FEEDING", "garrisoned": "GARRISONED", "cultshrine": "CULT SHRINE",
	"refugees": "REFUGEE COLUMN", "stormcrossing": "STORM CROSSING", "quietroads": "QUIET ROADS",
	"titheroad": "TITHE ROAD", "cache": "OLD CACHE",
}
const EVENTS := [
	{"t": "A PILGRIM CARAVAN crosses your road, singing against the dark.",
		"a": ["DEVOUR THEM ALL", {"essence": 35.0, "quiet": -1}],
		"b": ["LET THEM PASS", {"quiet": 1}]},
	{"t": "A LESSER BEAST crawls from the fen and offers fealty.",
		"a": ["ACCEPT ITS SERVICE", {"allies": 2}],
		"b": ["EAT THE OFFERING", {"essence": 50.0}]},
	{"t": "A VILLAGE ELDER offers tribute if you spare his fields.",
		"a": ["TAKE THE GOLD", {"tribute": 45}],
		"b": ["TAKE EVERYTHING", {"essence": 25.0, "quiet": -1}]},
	{"t": "A STRANGE IDOL stands at the crossroads, humming.",
		"a": ["CLAIM IT", {"relic": true}],
		"b": ["SHATTER IT", {"essence": 30.0}]},
	{"t": "AN ARMY CHECKPOINT bars the fastest road.",
		"a": ["SMASH THROUGH", {"tribute": 30, "threat": 12.0}],
		"b": ["TAKE THE LONG WAY", {"quiet": 1}]},
	{"t": "DESERTERS kneel in the mud and beg to be spared.",
		"a": ["SPARE THEM — LET FEAR SPREAD", {"quiet": 1, "essence": 10.0}],
		"b": ["THE HARVEST TAKES ALL", {"essence": 30.0, "quiet": -1}]},
]

var ui_font: FontFile
var picking_relic := false
var relic_opts: Array = []
var in_event := false
var ev_cur := {}
var ev_node := {}
var march = null                 # marching animation -> interstitial -> launch
var ev_extra := {}               # event outcome folded into the next launch
var ov_hover := -1

func _ready() -> void:
	Global.music("map")
	ui_font = load("res://art/Silkscreen-Regular.ttf")
	# pick the node set: act 1 = the Rise (one province), act 2 = the continent
	if Global.act == 1:
		ns = []
		var pnames: Array = PROVINCE_NAMES.get(Global.province, PROVINCE_NAMES["kowloon"])
		var ni := 0
		for n0 in ACT1_NODES:
			var n: Dictionary = n0.duplicate()
			if not n.has("name"):
				n.name = pnames[mini(ni, pnames.size() - 1)]
				ni += 1
			ns.append(n)
	else:
		ns = NODES
	# roll each crusade's road-fates once — the map is a hand you're dealt (continent only)
	if Global.act == 2 and not Global.node_fates.has("rolled"):
		Global.node_fates["rolled"] = true
		var pool := ["richfeeding", "garrisoned", "cultshrine", "refugees",
			"stormcrossing", "quietroads", "titheroad", "cache"]
		for n in NODES:
			if n.kind in ["hamlet", "town"] and randf() < 0.8:
				Global.node_fates[str(n.id)] = pool[randi() % pool.size()]
		Global.save_crusade()
	# offered a relic after each razing (skip the very first arrival)
	picking_relic = Global.node_params.get("offer_relic", false)
	Global.node_params = {}
	if picking_relic:
		_relic_overlay()

func _reachable(id: int) -> bool:
	if id == Global.map_pos or id in Global.razed or id in Global.bypassed:
		return false
	var n: Dictionary = ns[id]
	for l in n.get("links", []):
		if l == Global.map_pos or l in Global.razed:
			return true
	return false

func _unhandled_input(e: InputEvent) -> void:
	if march != null:
		return
	if picking_relic or in_event:
		if e is InputEventMouseMotion:
			ov_hover = -1
			var oc := _overlay_cards()
			for i in oc.size():
				if oc[i].has_point(get_global_mouse_position()):
					ov_hover = i
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			var oc2 := _overlay_cards()
			for i in oc2.size():
				if oc2[i].has_point(get_global_mouse_position()):
					if picking_relic:
						_relic_pick(i)
					else:
						_ev_pick(i)
					return
		return
	if e is InputEventKey and e.pressed and e.physical_keycode == KEY_ESCAPE:
		Global.goto("res://menu.tscn")
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var mp := get_global_mouse_position()
		for n in ns:
			if n.pos.distance_to(mp) < 16.0 and _reachable(n.id):
				if n.kind == "relicsite":
					# no battle here — an old power waits to be claimed
					Global.map_pos = n.id
					Global.razed.append(n.id)
					Global.save_crusade()
					picking_relic = true
					_relic_overlay()
					return
				# the road itself has opinions
				if randf() < 0.4:
					_event_overlay(n)
				else:
					_begin_march(n)
				return

func _event_overlay(n: Dictionary) -> void:
	in_event = true
	ev_cur = EVENTS[randi() % EVENTS.size()]
	ev_node = n
	ov_hover = -1

func _apply_ev(fx: Dictionary) -> void:
	Global.c_essence += fx.get("essence", 0.0)
	Global.tribute += int(fx.get("tribute", 0))
	Global.alert_discount = maxi(0, Global.alert_discount + int(fx.get("quiet", 0)))
	if fx.get("relic", false):
		var pool := RELICS.filter(func(r): return not r.id in Global.relics)
		if not pool.is_empty():
			var rl: Dictionary = pool[randi() % pool.size()]
			Global.relics.append(rl.id)
	ev_extra = {}
	if fx.has("allies"):
		ev_extra["allies_bonus"] = int(fx.allies)
	if fx.has("threat"):
		ev_extra["threat_bonus"] = float(fx.threat)
	Global.save_crusade()

func _obj_for(n: Dictionary) -> String:
	# deterministic per (node, progress) so the map can promise what the battle delivers
	match n.kind:
		"hamlet", "farms", "mill", "provcity": return "raze"
		"town": return ["raze", "blackout", "extinction"][(n.id * 7 + Global.razed.size() * 3) % 3]
		"capital": return "decapitation"
		"city": return ["raze", "decapitation", "extinction", "blackout", "terror", "feast"][(n.id * 5 + Global.razed.size()) % 6]
	return "raze"

func _launch(n: Dictionary) -> void:
	Global.map_pos = n.id
	Global.city = n.get("city", ["kowloon", "thornspire", "ashport", "teotl", "maren"][randi() % 5])
	var fate: String = Global.node_fates.get(str(n.id), "")
	if fate == "quietroads":
		Global.alert_discount += 1
	var alert: int = maxi(0, Global.razed.size() - Global.alert_discount)
	var params := {"map_node": n.id, "alert": alert, "kind": n.kind, "objective": _obj_for(n), "fate": fate,
		"place": n.name}
	if fate == "cultshrine":
		params.allies_bonus = 2
	params.merge(ev_extra, true)
	ev_extra = {}
	if Global.act == 1:
		Global.city = Global.province
		# the fork is a choice — the other road closes behind you
		if n.kind == "farms":
			Global.bypassed.append(3)
		elif n.kind == "mill":
			Global.bypassed.append(2)
	match n.kind:
		"hamlet":
			params.world_w = 2000.0 if Global.act == 2 else 1900.0
			params.tier_cap = (2 + int(alert / 3.0)) if Global.act == 2 else 1
			params.militia = Global.act == 1
		"farms", "mill":
			params.kind = "hamlet"
			params.world_w = 2300.0
			params.tier_cap = 2
			params.militia = true
		"town":
			params.world_w = 3000.0
			params.tier_cap = 3 + int(alert / 3.0)
		"provcity":
			params.kind = "city"
			params.world_w = 4600.0
			params.tier_cap = 5
			params.provcity = true
		"capital":
			params.world_w = 5200.0
			params.tier_cap = 5
			params.capital = true
		_:
			params.tier_cap = 5
	Global.node_params = params
	Global.save_crusade()
	Global.goto("res://main.tscn")

func _relic_overlay() -> void:
	var pool := RELICS.filter(func(r): return not r.id in Global.relics)
	pool.shuffle()
	relic_opts = pool.slice(0, 3)
	ov_hover = -1

func _relic_pick(i: int) -> void:
	if i < 0 or i >= relic_opts.size():
		return
	Global.relics.append(relic_opts[i].id)
	Global.save_crusade()
	picking_relic = false
	relic_opts = []

func _ev_pick(i: int) -> void:
	var opt: Array = ev_cur.a if i == 0 else ev_cur.b
	_apply_ev(opt[1])
	in_event = false
	var n: Dictionary = ev_node
	ev_cur = {}
	ev_node = {}
	_begin_march(n)

func _overlay_cards() -> Array:
	var out: Array = []
	if picking_relic:
		for i in relic_opts.size():
			out.append(Rect2(112 + i * 146, 110, 134, 150))
	elif in_event:
		for i in 2:
			out.append(Rect2(150, 180 + i * 52, 340, 44))
	return out

func _begin_march(n: Dictionary) -> void:
	march = {"n": n, "t": 0.0, "from": ns[Global.map_pos].pos}

func _process(delta: float) -> void:
	if march != null:
		march.t += delta
		if march.t > 2.6:
			var n: Dictionary = march.n
			march = null
			_launch(n)
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
	var title_s: String = "ACT II — THE CRUSADE" if Global.act == 2 else 		"ACT I — THE RISE OF " + str(PROVINCE_NAMES.get(Global.province, ["", "", "", "", "?"])[4])
	draw_string(f, Vector2(0, 34), title_s, HORIZONTAL_ALIGNMENT_CENTER, 640, 18, Color(1.8, 0.5, 0.5))
	if Global.act == 1:
		var gm: float = [0.7, 0.8, 0.88, 0.94, 1.0][mini(4, Global.razed.size())]
		var body: int = int(minf(1.75, gm * (1.0 + minf(0.75, Global.c_essence / 900.0))) * 100.0)
		draw_string(f, Vector2(0, 64), "THE BODY  %d%%   ·   ESSENCE CARRIED  %d   ·   THE ROAR  %d" 			% [body, int(Global.c_essence), int(Global.roar)],
			HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color(1.2, 0.9, 1.3, 0.85))
	if Global.headline != "":
		draw_string(f, Vector2(0, 344), "THE PROVINCIAL HERALD:  " + Global.headline,
			HORIZONTAL_ALIGNMENT_CENTER, 640, 7, Color(1.5, 1.3, 0.8, 0.9))
	draw_string(f, Vector2(0, 52), "WORLD ALERT %d   ·   TRIBUTE %d   ·   ESC — retreat" % [maxi(0, Global.razed.size() - Global.alert_discount), Global.tribute],
		HORIZONTAL_ALIGNMENT_CENTER, 640, 9, Color("#9ab0d0"))
	# THE ROAR — the louder you feed, the farther you are heard
	var slain: int = Global.heralds_slain.size()
	if slain < 3 and not Global.herald_queue.is_empty():
		var gate: float = Global.ROAR_GATES[mini(slain, 2)]
		var heard: bool = Global.roar >= gate
		draw_string(f, Vector2(0, 64), "THE ROAR  %d / %d%s" % [int(Global.roar), int(gate),
			"    —    SOMETHING HAS HEARD YOU" if heard else ""],
			HORIZONTAL_ALIGNMENT_CENTER, 640, 8,
			Color(2.0, 0.5, 1.2) if heard else Color(1.2, 0.7, 1.3, 0.8))
	elif slain >= 3:
		draw_string(f, Vector2(0, 64), "THREE HERALDS DEVOURED — THE STARS ARE LISTENING",
			HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color(2.0, 1.4, 2.2))
	# roads
	for n in ns:
		for l in n.get("links", []):
			var a: Vector2 = ns[l].pos
			var b: Vector2 = n.pos
			var burnt: bool = (n.id in Global.razed or n.id == Global.map_pos) and (l in Global.razed or l == Global.map_pos)
			draw_line(a, b, Color(0.5, 0.15, 0.1, 0.8) if burnt else Color(0.25, 0.22, 0.35), 2.0 if burnt else 1.0)
	# nodes
	for n in ns:
		var col: Color
		var r := 8.0
		match n.kind:
			"start": col = Color(0.4, 0.35, 0.5)
			"hamlet", "farms", "mill":
				col = Color(0.5, 0.6, 0.45)
				r = 6.0
			"town": col = Color(0.6, 0.55, 0.4)
			"capital", "provcity":
				col = Color(1.8, 1.2, 0.4)
				r = 12.0
			"relicsite":
				col = Color(0.9, 0.5, 1.4)
				r = 7.0
			_: col = Color(0.55, 0.4, 0.6)
		var razed_n: bool = n.id in Global.razed
		var passed: bool = n.id in Global.bypassed
		if razed_n:
			col = Color(0.35, 0.12, 0.1)
		elif passed:
			col = Color(0.2, 0.19, 0.24)
		draw_circle(n.pos, r, col)
		if n.id == Global.map_pos:
			draw_arc(n.pos, r + 4.0 + sin(Time.get_ticks_msec() * 0.005) * 1.5, 0, TAU, 20, Color(1.8, 0.4, 0.4), 1.5)
		elif _reachable(n.id):
			draw_arc(n.pos, r + 3.0, 0, TAU, 20, Color(1.5, 1.3, 0.7, 0.5 + sin(Time.get_ticks_msec() * 0.004) * 0.3), 1.0)
		if razed_n:
			draw_line(n.pos + Vector2(-4, -4), n.pos + Vector2(4, 4), Color(0.9, 0.3, 0.2), 1.5)
			draw_line(n.pos + Vector2(-4, 4), n.pos + Vector2(4, -4), Color(0.9, 0.3, 0.2), 1.5)
		draw_string(f, n.pos + Vector2(-70, -r - 5), n.name, HORIZONTAL_ALIGNMENT_CENTER, 140, 7,
			Color(0.9, 0.85, 0.8, 0.4) if passed else Color(0.9, 0.85, 0.8, 0.85))
		if passed:
			draw_string(f, n.pos + Vector2(-70, r + 12), "PASSED BY", HORIZONTAL_ALIGNMENT_CENTER, 140, 6,
				Color(0.55, 0.5, 0.6, 0.7))
		# reachable nodes show what the war will ask of you — and what the road carries
		if _reachable(n.id) and n.kind in ["hamlet", "farms", "mill", "town", "city", "capital", "provcity"]:
			draw_string(f, n.pos + Vector2(-70, r + 12), _obj_for(n).to_upper(),
				HORIZONTAL_ALIGNMENT_CENTER, 140, 6, Color(1.5, 1.3, 0.7, 0.8))
			var fate2: String = Global.node_fates.get(str(n.id), "")
			if fate2 != "":
				draw_string(f, n.pos + Vector2(-70, r + 20), FATE_NAMES.get(fate2, ""),
					HORIZONTAL_ALIGNMENT_CENTER, 140, 6, Color(1.2, 0.7, 1.5, 0.85))
	draw_string(f, Vector2(0, 334), "choose where the ruin goes next", HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color(0.7, 0.65, 0.7, 0.6))
	# overlays: relic gifts and road events, drawn in the card language
	if picking_relic or in_event:
		draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.0, 0.05, 0.86))
		var oc3 := _overlay_cards()
		if picking_relic:
			draw_string(f, Vector2(0, 78), "THE RUIN LEAVES A GIFT — TAKE ONE", HORIZONTAL_ALIGNMENT_CENTER, 640, 13, Color(1.9, 0.5, 0.55))
			for i in relic_opts.size():
				var rl: Dictionary = relic_opts[i]
				var r: Rect2 = oc3[i]
				var hov: bool = ov_hover == i
				if hov:
					r.position.y -= 4.0
					draw_rect(Rect2(r.position - Vector2(3, 3), r.size + Vector2(6, 6)), Color(1.9, 0.5, 0.5, 0.10))
				_card_frame(r, Color(1.9, 0.6, 0.6) if hov else Color(0.4, 0.32, 0.45))
				draw_string(f, Vector2(r.position.x, r.position.y + 26), rl.name, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, Color(1.7, 1.4, 0.7))
				var words: PackedStringArray = str(rl.desc).split(" ")
				var line := ""
				var ly: float = r.position.y + 52.0
				for w2 in words:
					if line.length() + w2.length() > 19:
						draw_string(f, Vector2(r.position.x + 8, ly), line, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 6, Color("#9ab0d0"))
						ly += 10.0
						line = w2
					else:
						line += (" " if line != "" else "") + w2
				if line != "":
					draw_string(f, Vector2(r.position.x + 8, ly), line, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 6, Color("#9ab0d0"))
		else:
			draw_string(f, Vector2(0, 88), "ON THE ROAD TO " + str(ev_node.get("name", "")), HORIZONTAL_ALIGNMENT_CENTER, 640, 12, Color(1.9, 0.5, 0.55))
			var bw: PackedStringArray = str(ev_cur.get("t", "")).split(" ")
			var bl := ""
			var by: float = 120.0
			for w3 in bw:
				if bl.length() + w3.length() > 52:
					draw_string(f, Vector2(70, by), bl, HORIZONTAL_ALIGNMENT_CENTER, 500, 9, Color(0.9, 0.87, 0.9))
					by += 13.0
					bl = w3
				else:
					bl += (" " if bl != "" else "") + w3
			if bl != "":
				draw_string(f, Vector2(70, by), bl, HORIZONTAL_ALIGNMENT_CENTER, 500, 9, Color(0.9, 0.87, 0.9))
			for i in 2:
				var opt: Array = ev_cur.a if i == 0 else ev_cur.b
				var r2: Rect2 = oc3[i]
				var hov2: bool = ov_hover == i
				if hov2:
					r2.position.y -= 3.0
					draw_rect(Rect2(r2.position - Vector2(3, 3), r2.size + Vector2(6, 6)), Color(1.9, 0.5, 0.5, 0.10))
				_card_frame(r2, Color(1.9, 0.6, 0.6) if hov2 else Color(0.4, 0.32, 0.45))
				draw_string(f, Vector2(r2.position.x, r2.position.y + 27), opt[0], HORIZONTAL_ALIGNMENT_CENTER, r2.size.x, 10,
					Color(1.8, 0.55, 0.55) if hov2 else Color(0.95, 0.9, 1.0))
		return
	# the march: your ruin travels the road, then the night card falls
	if march != null:
		var f2: float = clampf(march.t / 1.1, 0.0, 1.0)
		var mpos: Vector2 = march.from.lerp(march.n.pos, f2)
		draw_line(march.from, mpos, Color(1.6, 0.5, 0.3, 0.9), 2.5)
		draw_circle(mpos, 5.0, Color(1.9, 0.6, 0.4))
		draw_circle(mpos, 8.0 + sin(Time.get_ticks_msec() * 0.01) * 2.0, Color(1.9, 0.6, 0.4, 0.25))
		if march.t > 1.3:
			var ia: float = clampf((march.t - 1.3) / 0.4, 0.0, 1.0)
			draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.0, 0.05, 0.9 * ia))
			draw_string(f, Vector2(0, 160), "NIGHT %d" % (Global.razed.size() + 1),
				HORIZONTAL_ALIGNMENT_CENTER, 640, 16, Color(1.9, 0.5, 0.55, ia))
			draw_string(f, Vector2(0, 184), "THE ROAD TO " + str(march.n.name),
				HORIZONTAL_ALIGNMENT_CENTER, 640, 10, Color(0.9, 0.86, 0.95, ia))
			var flv: String = Global.headline if Global.headline != "" else "The roads empty ahead of you."
			draw_string(f, Vector2(0, 206), flv.to_lower(), HORIZONTAL_ALIGNMENT_CENTER, 640, 7,
				Color(0.6, 0.56, 0.7, ia))

func _card_frame(r: Rect2, bord: Color) -> void:
	draw_rect(r, Color("#151020"))
	for edge in [Rect2(r.position, Vector2(r.size.x, 2)), Rect2(r.position + Vector2(0, r.size.y - 2), Vector2(r.size.x, 2)),
			Rect2(r.position, Vector2(2, r.size.y)), Rect2(r.position + Vector2(r.size.x - 2, 0), Vector2(2, r.size.y))]:
		draw_rect(edge, bord)
	for c in [Vector2.ZERO, Vector2(r.size.x - 6, 0), Vector2(0, r.size.y - 6), Vector2(r.size.x - 6, r.size.y - 6)]:
		draw_rect(Rect2(r.position + c, Vector2(6, 6)), bord)
