extends Node2D
# CALAMITY v3 — The Swarm. Rampage-modern pixel art: lighting, atmosphere, texture.
# 640x360 native pixels. Ground y=0, up is negative. Sun sits screen-right.

const WORLD_W := 4200.0
const TIER_NAMES := ["CALM", "POLICE", "GUARD", "ARMY", "AIR STRIKE", "LAST RESORT"]
const TIER_MULT := [1.0, 1.0, 1.5, 2.0, 3.0, 5.0]
# dusk-unified wall palette (muted, warm-shifted)
const WALL_COLS := [Color("#6e4238"), Color("#7d5c42"), Color("#565064"), Color("#63414e"), Color("#4f555c")]

var pos := Vector2(300, -80)
var vel := Vector2.ZERO
var hp := 100.0
var radius := 15.0
var motes: Array = []
var hit_flash := 0.0

var score_f := 0.0
var combo := 1.0
var combo_idle := 0.0
var threat := 0.0
var tier := 0
var over := false
var shake := 0.0
var t := 0.0
var bite_cd := 0.0

var buildings: Array = []
var total_mass := 0.0
var units: Array = []
var shells: Array = []
var parts: Array = []
var pops: Array = []
var people: Array = []
var lamps: Array = []
var cars: Array = []
var spawn_cd := 3.0
var people_cd := 0.0

var cam: Camera2D
var hud := {}

func _ready() -> void:
	randomize()
	_build_city()
	for i in 60:
		motes.append({"a": randf() * TAU, "d": randf_range(0.15, 1.0), "s": randf_range(0.8, 3.0), "o": randf() * TAU})
	cam = Camera2D.new()
	cam.position = Vector2(pos.x, -100)
	add_child(cam)
	cam.make_current()
	_build_hud()

func _hash(n: float) -> float:
	return fmod(absf(sin(n * 127.1) * 43758.55), 1.0)

func _build_city() -> void:
	var x := 380.0
	while x < WORLD_W - 500.0:
		var w := snappedf(randf_range(45, 95), 8.0)
		var h := snappedf(randf_range(70, 230), 11.0)
		buildings.append(_mk_building(x, w, h, false))
		x += w + randf_range(20, 60)
	buildings.append(_mk_building(x, 110.0, 300.0, true))
	for b in buildings:
		total_mass += b.maxhp
	x = 320.0
	while x < WORLD_W - 300.0:
		lamps.append(x)
		x += randf_range(80, 130)
	for i in 26:
		cars.append({"x": randf_range(300, WORLD_W - 400), "w": randf_range(14, 19),
			"col": [Color("#5a3a40"), Color("#3a4a55"), Color("#6a5a3a"), Color("#444")][randi() % 4]})
	for i in 70:
		people.append(_mk_person(randf_range(320, WORLD_W - 350)))

func _mk_person(px: float) -> Dictionary:
	return {"pos": Vector2(px, 0), "vx": 0.0, "panic": false, "o": randf() * TAU,
		"col": Color(randf_range(0.5, 0.8), randf_range(0.4, 0.6), randf_range(0.35, 0.55))}

func _mk_building(x: float, w: float, h: float, cit: bool) -> Dictionary:
	var wins: Array = []
	var wy := 9.0
	while wy < h - 12.0:
		var wx := 5.0
		while wx < w - 10.0:
			wins.append({"p": Vector2(wx, wy), "on": randf() < 0.55, "blind": randf() < 0.2, "dead": false})
			wx += 9.0
		wy += 12.0
	var seed_v := x * 0.77
	return {"x": x, "w": w, "h": h, "hp": w * h * (0.020 if cit else 0.012), "maxhp": w * h * (0.020 if cit else 0.012),
		"wins": wins, "holes": [], "dead": false, "dying": 0.0, "cit": cit,
		"col": WALL_COLS[randi() % WALL_COLS.size()], "cur_h": h, "seed": seed_v,
		"roof": int(_hash(seed_v) * 3.0)}

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud.score = _label(layer, Vector2(10, 4), 16, Color("#ffe8c8"))
	hud.combo = _label(layer, Vector2(10, 24), 11, Color("#ff4d78"))
	hud.tier = _label(layer, Vector2(478, 4), 8, Color("#e8b890"))
	hud.threat = _bar(layer, Vector2(478, 16), Color("#e08a2b"))
	hud.hplbl = _label(layer, Vector2(478, 26), 8, Color("#e8b890"))
	hud.hplbl.text = "INTEGRITY"
	hud.hp = _bar(layer, Vector2(478, 38), Color("#e0455a"))
	hud.citylbl = _label(layer, Vector2(478, 48), 8, Color("#e8b890"))
	hud.city = _bar(layer, Vector2(478, 60), Color("#9a5de0"))
	hud.msg = _label(layer, Vector2(0, 140), 28, Color("#ffb08a"))
	hud.msg.size = Vector2(640, 40)
	hud.msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.sub = _label(layer, Vector2(0, 180), 10, Color("#ffe8c8"))
	hud.sub.size = Vector2(640, 20)
	hud.sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var help := _label(layer, Vector2(10, 344), 8, Color(1, 0.9, 0.8, 0.5))
	help.text = "WASD / arrows — fly.  devour buildings and the fleeing crowds.  R — restart."

func _label(parent: Node, p: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.position = p
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(l)
	return l

func _bar(parent: Node, p: Vector2, col: Color) -> ColorRect:
	var bg := ColorRect.new()
	bg.position = p
	bg.size = Vector2(152, 5)
	bg.color = Color(0.1, 0.04, 0.07)
	parent.add_child(bg)
	var fg := ColorRect.new()
	fg.size = Vector2(152, 5)
	fg.color = col
	bg.add_child(fg)
	return fg

# ================= update =================
var _shot_frames := 0
func _process(delta: float) -> void:
	t += delta
	# dev: CAL_SHOT=<path> -> screenshot at frame 120, then quit
	if OS.get_environment("CAL_SHOT") != "":
		_shot_frames += 1
		if _shot_frames == 120:
			get_viewport().get_texture().get_image().save_png(OS.get_environment("CAL_SHOT"))
			get_tree().quit()
	if not over:
		_move(delta)
		_eat(delta)
		_people(delta)
		_army(delta)
		threat = min(100.0, threat + 0.55 * delta)
		tier = mini(5, int(threat / 17.0))
		_check_end()
	for b in buildings:
		if b.dying > 0.0 and not b.dead:
			b.dying -= delta
			b.cur_h = maxf(b.h * 0.08, b.cur_h - b.h * 2.2 * delta)
			if randf() < 20.0 * delta:
				_boom(Vector2(b.x + randf() * b.w, -b.cur_h), 3, Color("#8a7a68"), 60.0)
			if b.dying <= 0.0:
				b.dead = true
	for p in parts:
		p.pos += p.vel * delta
		if not p.get("fire", false):
			p.vel.y += 300.0 * delta
		p.life -= delta
	parts = parts.filter(func(p): return p.life > 0.0)
	for p in pops:
		p.pos.y -= 18.0 * delta
		p.life -= delta
	pops = pops.filter(func(p): return p.life > 0.0)
	shells = shells.filter(func(s): return s.life > 0.0)
	shake = max(0.0, shake - 30.0 * delta)
	hit_flash = max(0.0, hit_flash - 4.0 * delta)
	cam.position = cam.position.lerp(Vector2(pos.x, -105), 6.0 * delta)
	cam.position.x = clamp(cam.position.x, 320, WORLD_W - 320)
	cam.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	_hud_update()
	queue_redraw()

func _move(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	vel += dir * 900.0 * delta
	vel *= pow(0.02, delta)
	vel = vel.limit_length(220.0)
	pos += vel * delta
	pos.x = clamp(pos.x, 40, WORLD_W - 40)
	pos.y = clamp(pos.y, -340, -12)

func _people(delta: float) -> void:
	for p in people:
		var d: float = pos.x - p.pos.x
		if absf(d) < 90.0 and pos.y > -60.0:
			p.panic = true
		if p.panic:
			p.vx = move_toward(p.vx, -signf(d) * 46.0, 200.0 * delta)
		else:
			p.vx = sin(t * 0.6 + p.o) * 9.0
		p.pos.x = clampf(p.pos.x + p.vx * delta, 300, WORLD_W - 320)
		# eaten
		if Vector2(p.pos.x, -3).distance_to(pos) < radius + 4.0:
			p.dead = true
			var gain := int(10.0 * combo * TIER_MULT[tier] * 2.0)  # crowds = diet, x2
			score_f += gain
			combo = minf(9.5, combo + 0.12)
			combo_idle = 0.0
			hp = minf(100.0, hp + 0.8)
			threat = minf(100.0, threat + 0.35)
			_boom(Vector2(p.pos.x, -4), 5, Color("#a02030"), 60.0)
			if randf() < 0.4:
				_pop(Vector2(p.pos.x, -14), "+%d" % gain, Color("#ff8a9a"))
	people = people.filter(func(p): return not p.get("dead", false))

func _eat(delta: float) -> void:
	bite_cd -= delta
	var chewing := false
	for b in buildings:
		if b.dead or b.dying > 0.0:
			continue
		var cx: float = b.x + b.w * 0.5
		if absf(pos.x - cx) < b.w * 0.5 + radius and pos.y > -b.cur_h - radius:
			chewing = true
			var bite: float = (7.0 + combo * 2.4) * delta * (1.0 + tier * 0.15)
			b.hp -= bite
			threat = min(100.0, threat + bite * 0.06)
			combo_idle = 0.0
			score_f += bite * 1.6 * combo * TIER_MULT[tier]
			if bite_cd <= 0.0:
				bite_cd = 0.13
				combo = min(9.5, combo + 0.06)
				var hole_p := Vector2(clampf(pos.x - b.x, 4, b.w - 4), clampf(-pos.y, 6, b.cur_h - 6))
				b.holes.append({"p": hole_p, "r": randf_range(3.0, 7.0)})
				for w in b.wins:
					if not w.dead and w.p.distance_to(hole_p) < 14.0:
						w.dead = true
				_boom(pos + Vector2(randf_range(-8, 8), randf_range(-8, 8)), 3, b.col.lightened(0.2), 70.0)
				if int(t * 7.7) % 3 == 0:
					_pop(Vector2(pos.x, pos.y - 14), "+%d" % int(bite * 1.6 * combo * TIER_MULT[tier] * 8.0), Color("#ffcf8a"))
			if b.hp <= 0.0:
				b.dying = 0.6
				var gain := int(b.maxhp * 8.0 * combo * TIER_MULT[tier] * (4.0 if b.cit else 1.0))
				score_f += gain
				combo = min(9.5, combo + 0.5)
				hp = min(100.0, hp + 5.0)
				shake = 16.0 if b.cit else 8.0
				_boom(Vector2(cx, -b.cur_h * 0.5), 60 if b.cit else 26, Color("#8a7a68"), 110.0)
				_pop(Vector2(cx, -b.h - 14), ("CITADEL FELL  +" if b.cit else "+") + _fmt(gain),
					Color("#ffd75a") if b.cit else Color("#ffb08a"))
	if not chewing:
		combo_idle += delta
		if combo_idle > 1.2 and combo > 1.0:
			combo = max(1.0, combo - 1.6 * delta)

func _army(delta: float) -> void:
	spawn_cd -= delta
	if tier >= 1 and spawn_cd <= 0.0 and units.size() < 2 + tier * 3:
		spawn_cd = maxf(0.35, 1.4 - tier * 0.18)
		var side: float = -1.0 if randf() < 0.5 else 1.0
		var x: float = pos.x + side * randf_range(360, 560)
		if x > 30 and x < WORLD_W - 30:
			if tier >= 4 and randf() < 0.45:
				units.append({"kind": "heli", "pos": Vector2(x, randf_range(-220, -150)), "cd": randf_range(0.5, 1.2)})
			elif tier >= 3 and randf() < 0.6:
				units.append({"kind": "tank", "pos": Vector2(x, 0), "cd": randf_range(0.7, 1.5)})
			else:
				units.append({"kind": "police", "pos": Vector2(x, 0), "cd": randf_range(0.6, 1.2)})
	for u in units:
		var dx: float = pos.x - u.pos.x
		match u.kind:
			"police": u.pos.x += signf(dx) * 34.0 * delta
			"tank": u.pos.x += signf(dx) * 17.0 * delta
			"heli":
				u.pos.x += signf(dx) * 38.0 * delta
				u.pos.y += sin(t * 2.0) * 6.0 * delta
		u.cd -= delta
		if u.cd <= 0.0 and absf(dx) < 420.0:
			u.cd = maxf(0.5, randf_range(1.1, 2.0) - tier * 0.12)
			var origin: Vector2 = u.pos + Vector2(0, -18 if u.kind != "heli" else 4)
			var lead: Vector2 = pos + vel * 0.35
			var speed: float = 120.0 if u.kind == "police" else 165.0
			shells.append({"pos": origin, "vel": (lead - origin).normalized() * speed, "life": 4.0,
				"heavy": u.kind != "police"})
	for s in shells:
		s.pos += s.vel * delta
		s.life -= delta
		if s.pos.distance_to(pos) < radius:
			s.life = 0.0
			hp -= 6.0 if s.heavy else 3.0
			combo = max(1.0, combo - 1.0)
			shake = 6.0
			hit_flash = 1.0
			vel += s.vel.normalized() * 90.0
			_boom(s.pos, 8, Color("#ffd75a"), 90.0)

func _eaten_frac() -> float:
	var eaten := 0.0
	for b in buildings:
		eaten += b.maxhp if (b.dead or b.dying > 0.0) else (b.maxhp - b.hp)
	return eaten / total_mass

func _check_end() -> void:
	var cit: Dictionary = buildings[-1]
	if _eaten_frac() >= 0.9 or cit.dead or cit.dying > 0.0:
		_end("CITY RAZED", "the swarm moves on.  score %s  —  press R" % _fmt(int(score_f)))
	elif hp <= 0.0:
		_end("THE SWARM IS SCATTERED", "the city endures.  score %s  —  press R" % _fmt(int(score_f)))

func _end(m: String, s: String) -> void:
	over = true
	hud.msg.text = m
	hud.sub.text = s

func _input(e: InputEvent) -> void:
	if over and e.is_action_pressed("restart"):
		get_tree().reload_current_scene()

func _boom(p: Vector2, n: int, col: Color, sp: float) -> void:
	for i in n:
		var a := randf() * TAU
		parts.append({"pos": p, "vel": Vector2(cos(a), sin(a)) * randf_range(0.3, 1.0) * sp + Vector2(0, -30),
			"life": randf_range(0.3, 0.9), "col": col})

func _fire(p: Vector2) -> void:
	parts.append({"pos": p, "vel": Vector2(randf_range(-6, 6), randf_range(-34, -18)),
		"life": randf_range(0.3, 0.7), "col": Color("#ff8a3a") if randf() < 0.7 else Color("#ffd75a"), "fire": true})

func _pop(p: Vector2, txt: String, col: Color) -> void:
	pops.append({"pos": p, "txt": txt, "col": col, "life": 1.1})

func _fmt(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return out

func _hud_update() -> void:
	hud.score.text = _fmt(int(score_f))
	hud.combo.text = "×%.1f" % combo
	hud.tier.text = "THREAT — " + TIER_NAMES[tier]
	hud.threat.size.x = 152.0 * threat / 100.0
	hud.hp.size.x = 152.0 * maxf(0.0, hp) / 100.0
	hud.citylbl.text = "CITY DEVOURED — %d%%" % int(_eaten_frac() * 100)
	hud.city.size.x = 152.0 * minf(1.0, _eaten_frac() / 0.9)

# ================= render =================
func _draw() -> void:
	var cx := cam.position.x
	var left := cx - 340.0
	var right := cx + 340.0
	_draw_sky(left, right, cx)
	_draw_backdrop(left, right, cx)
	# cast shadows on street (sun right -> shadows lean left)
	for b in buildings:
		if b.dead or b.x + b.w < left - 200 or b.x > right:
			continue
		var bh: float = b.cur_h if b.dying > 0.0 else b.h
		var sh_len: float = bh * 0.55
		draw_colored_polygon(PackedVector2Array([
			Vector2(b.x, 0), Vector2(b.x + b.w, 0),
			Vector2(b.x + b.w - sh_len, 7), Vector2(b.x - sh_len, 7)]),
			Color(0.05, 0.01, 0.05, 0.4))
	for b in buildings:
		if b.x + b.w < left or b.x > right:
			continue
		_draw_building(b)
	_draw_street(left, right)
	_draw_actors()
	_draw_swarm()
	# pops
	for p in pops:
		var a2: float = clampf(p.life, 0.0, 1.0)
		draw_string(ThemeDB.fallback_font, p.pos, p.txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 8,
			Color(p.col.r, p.col.g, p.col.b, a2))
	# foreground fog band + vignette bottom
	draw_rect(Rect2(left, -34, right - left, 40), Color(0.35, 0.1, 0.12, 0.10))
	draw_rect(Rect2(left, 14, right - left, 400), Color(0.02, 0.0, 0.03, 0.5))

func _draw_sky(left: float, right: float, cx: float) -> void:
	var g := [Color("#160818"), Color("#451527"), Color("#93321f"), Color("#d96a30"), Color("#f0a04a")]
	var top := -380.0
	var rows := 95   # 4px rows, per-row lerp = no banding
	for i in rows:
		var f := float(i) / rows
		var col: Color
		if f < 0.35:
			col = g[0].lerp(g[1], f / 0.35)
		elif f < 0.62:
			col = g[1].lerp(g[2], (f - 0.35) / 0.27)
		elif f < 0.85:
			col = g[2].lerp(g[3], (f - 0.62) / 0.23)
		else:
			col = g[3].lerp(g[4], (f - 0.85) / 0.15)
		# subtle dither: offset odd rows toward next stop
		if i % 2 == 1:
			col = col.lightened(0.012)
		draw_rect(Rect2(left, top + f * 380.0, right - left, 380.0 / rows + 1), col)
	for i in 46:
		var sxr := fmod(_hash(i * 3.7) * 4310.0, 1.0) * (right - left) + left
		var syr := -378.0 + _hash(i * 9.1) * 150.0
		if fmod(t * (0.4 + fmod(float(i), 3.0) * 0.3) + i, 2.0) < 1.5:
			draw_rect(Rect2(sxr, syr, 1, 1), Color(1, 0.9, 0.82, 0.55 * (1.0 - (syr + 378.0) / 160.0)))
	# sun with layered halo
	var sun := Vector2(cx + 130, -64.0)
	for i in range(6, 0, -1):
		draw_circle(sun, 22 + i * 9.0, Color(1.0, 0.5, 0.22, 0.045))
	draw_circle(sun, 22, Color("#ffb14e"))
	draw_circle(sun, 18, Color("#ffd07a"))
	# cloud strips crossing the sun
	draw_rect(Rect2(sun.x - 40, -60, 80, 2), Color(0.25, 0.06, 0.12, 0.55))
	draw_rect(Rect2(sun.x - 30, -70, 64, 2), Color(0.25, 0.06, 0.12, 0.4))
	draw_rect(Rect2(sun.x - 52, -50, 70, 3), Color(0.25, 0.06, 0.12, 0.6))

func _draw_backdrop(left: float, right: float, cx: float) -> void:
	# far skyline, hazed by dusk fog
	for i in 34:
		var wx := fposmod(i * 149.0 - cx * 0.25, right - left + 240.0) + left - 120.0
		var wh := 34.0 + _hash(i * 31.7) * 78.0
		var ww := 22.0 + _hash(i * 57.1) * 34.0
		draw_rect(Rect2(wx, -wh, ww, wh), Color("#3a1524"))
		# tiny far windows
		if _hash(i * 7.7) > 0.4:
			for j in 4:
				draw_rect(Rect2(wx + 3 + _hash(i * 13.1 + j) * (ww - 6), -wh + 3 + _hash(i * 17.3 + j) * (wh - 8), 1, 2),
					Color(1.0, 0.75, 0.45, 0.35))
	# haze plane between skyline and playfield
	draw_rect(Rect2(left, -46, right - left, 46), Color(0.85, 0.35, 0.2, 0.13))
	draw_rect(Rect2(left, -24, right - left, 24), Color(0.85, 0.4, 0.22, 0.10))

func _draw_street(left: float, right: float) -> void:
	draw_rect(Rect2(left, 0, right - left, 3), Color("#41262c"))     # curb catches dusk
	draw_rect(Rect2(left, 3, right - left, 5), Color("#241318"))
	draw_rect(Rect2(left, 8, right - left, 400), Color("#120810"))
	var rx := left - fposmod(left, 26.0)
	while rx < right:
		draw_rect(Rect2(rx, 4, 10, 1), Color(1, 0.8, 0.6, 0.10))
		rx += 26.0
	# parked cars
	for c in cars:
		if c.x < left or c.x > right:
			continue
		draw_rect(Rect2(c.x, -5, c.w, 4), c.col)
		draw_rect(Rect2(c.x + 3, -8, c.w - 7, 3), c.col.darkened(0.2))
		draw_rect(Rect2(c.x + 1, -1, 3, 1), Color("#181018"))
		draw_rect(Rect2(c.x + c.w - 4, -1, 3, 1), Color("#181018"))
		draw_rect(Rect2(c.x + c.w - 1, -4, 1, 2), Color(1.0, 0.6, 0.3, 0.7))
	# lamps + light pools
	for lx in lamps:
		if lx < left or lx > right:
			continue
		draw_rect(Rect2(lx, -26, 1, 26), Color("#241a20"))
		draw_rect(Rect2(lx - 2, -27, 5, 2), Color("#241a20"))
		draw_circle(Vector2(lx + 0.5, -24), 2.5, Color(1.0, 0.85, 0.55, 0.9))
		draw_circle(Vector2(lx + 0.5, -24), 6.0, Color(1.0, 0.8, 0.5, 0.15))
		draw_colored_polygon(PackedVector2Array([
			Vector2(lx - 1, -24), Vector2(lx + 2, -24), Vector2(lx + 10, 0), Vector2(lx - 9, 0)]),
			Color(1.0, 0.8, 0.5, 0.06))
		draw_rect(Rect2(lx - 9, -1, 19, 2), Color(1.0, 0.8, 0.5, 0.10))

func _draw_actors() -> void:
	# people
	for p in people:
		var run: float = absf(p.vx)
		var leg: float = sin(t * (14.0 if run > 20 else 6.0) + p.o) * (2.0 if run > 5 else 0.6)
		draw_rect(Rect2(p.pos.x - 1, -7, 2, 4), p.col)
		draw_rect(Rect2(p.pos.x - 1, -8.5, 2, 2), Color("#caa58a"))
		draw_line(Vector2(p.pos.x, -3), Vector2(p.pos.x - leg, 0), p.col.darkened(0.3), 1)
		draw_line(Vector2(p.pos.x, -3), Vector2(p.pos.x + leg, 0), p.col.darkened(0.3), 1)
	# units with contact shadows
	for u in units:
		var p: Vector2 = u.pos
		draw_rect(Rect2(p.x - 9, -1, 18, 2), Color(0, 0, 0, 0.35))
		match u.kind:
			"police":
				draw_rect(Rect2(p.x - 8, p.y - 7, 16, 5), Color("#c8ccd4"))
				draw_rect(Rect2(p.x - 5, p.y - 10, 10, 3), Color("#a8b0bc"))
				draw_rect(Rect2(p.x - 2, p.y - 11, 4, 1),
					Color("#ff3a3a") if fmod(t, 0.5) < 0.25 else Color("#3a6aff"))
				draw_circle(Vector2(p.x - 2, p.y - 12), 4.0,
					Color(1, 0.2, 0.2, 0.12) if fmod(t, 0.5) < 0.25 else Color(0.2, 0.4, 1, 0.12))
				draw_rect(Rect2(p.x - 6, p.y - 2, 3, 2), Color("#181820"))
				draw_rect(Rect2(p.x + 3, p.y - 2, 3, 2), Color("#181820"))
			"tank":
				draw_rect(Rect2(p.x - 11, p.y - 8, 22, 6), Color("#4a4a3a"))
				draw_rect(Rect2(p.x - 11, p.y - 8, 22, 2), Color("#5c5c48"))
				draw_rect(Rect2(p.x - 6, p.y - 12, 12, 5), Color("#4a4a3a"))
				draw_line(Vector2(p.x, p.y - 10), Vector2(p.x + signf(pos.x - p.x) * 13, p.y - 14), Color("#4a4a3a"), 2)
				draw_rect(Rect2(p.x - 12, p.y - 3, 24, 3), Color("#242420"))
			"heli":
				draw_rect(Rect2(p.x - 8, p.y - 3, 16, 6), Color("#3a4438"))
				draw_rect(Rect2(p.x - 8, p.y - 3, 16, 2), Color("#4c5648"))
				draw_rect(Rect2(p.x + (8 if pos.x < p.x else -14), p.y - 1, 6, 2), Color("#3a4438"))
				var rot: float = sin(t * 40.0) * 12.0
				draw_line(p + Vector2(-rot, -5), p + Vector2(rot, -5), Color(0.85, 0.85, 0.8, 0.6), 1)
	for s in shells:
		draw_rect(Rect2(s.pos.x - 1, s.pos.y - 1, 3 if s.heavy else 2, 3 if s.heavy else 2), Color("#ffd75a"))
		draw_rect(Rect2(s.pos.x - s.vel.x * 0.02, s.pos.y - s.vel.y * 0.02, 1, 1), Color(1, 0.85, 0.4, 0.5))
	for p in parts:
		var a: float = clampf(p.life * 2.5, 0.0, 1.0)
		draw_rect(Rect2(p.pos.x, p.pos.y, 2, 2), Color(p.col.r, p.col.g, p.col.b, a))

func _draw_swarm() -> void:
	# shadow on street
	if pos.y > -120:
		var sa: float = clampf(1.0 + pos.y / 120.0, 0.0, 0.5)
		draw_rect(Rect2(pos.x - radius * 0.7, -1, radius * 1.4, 2), Color(0, 0, 0, sa * 0.5))
	# soft glow
	for i in range(5, 0, -1):
		draw_circle(pos, radius * 0.45 * i, Color(0.85, 0.12, 0.16, 0.05))
	# dark core mass
	draw_circle(pos + Vector2(0, 1), radius * 0.62, Color("#22060c"))
	draw_circle(pos + Vector2(-3, -2), radius * 0.45, Color("#2c0810"))
	draw_circle(pos + Vector2(3, 2), radius * 0.4, Color("#1c040a"))
	# streaking motes
	for m in motes:
		m.a += 0.025 * m.s
		var wob: float = sin(t * 6.5 + m.o) * 3.0
		var px: float = pos.x + cos(m.a) * radius * m.d * (1.0 + 0.3 * sin(t * 3.4 + m.o)) + wob
		var py: float = pos.y + sin(m.a * 1.3) * radius * m.d * 1.4 + cos(t * 5.2 + m.o) * 2.5
		var stx: float = -sin(m.a) * (1.5 + m.s)
		var sty: float = cos(m.a * 1.3) * 1.2
		var bright: bool = hit_flash > 0.5 or fmod(m.o + t, 5.0) < 0.35
		var mc: Color = Color("#ffe8d8") if bright else (Color("#e04448") if m.d < 0.6 else Color("#8a1220"))
		draw_line(Vector2(px, py), Vector2(px + stx, py + sty), mc, 1.0)

func _draw_building(b: Dictionary) -> void:
	var bh: float = b.cur_h if (b.dying > 0.0 or b.dead) else b.h
	if b.dead:
		draw_rect(Rect2(b.x, -bh, b.w, bh), Color("#241318"))
		draw_rect(Rect2(b.x + b.w * 0.15, -bh - 4, b.w * 0.3, 4), Color("#2c1a20"))
		draw_rect(Rect2(b.x + b.w * 0.55, -bh - 7, b.w * 0.25, 7), Color("#2c1a20"))
		for i in 3:
			if _hash(b.seed + i * 3.3) > 0.5:
				_fire(Vector2(b.x + _hash(b.seed + i) * b.w, -bh - 2))
		return
	var dmg: float = 1.0 - b.hp / b.maxhp
	var wall: Color = b.col if not b.cit else Color("#6a4a2a")
	# facade with vertical light falloff (lit top, darker base) — 3 slabs
	draw_rect(Rect2(b.x, -bh, b.w, bh), wall)
	draw_rect(Rect2(b.x, -bh * 0.55, b.w, bh * 0.55), wall.darkened(0.12))
	draw_rect(Rect2(b.x, -bh * 0.25, b.w, bh * 0.25), wall.darkened(0.22))
	# sun-side rim light (right), shadow side (left)
	draw_rect(Rect2(b.x + b.w - 2, -bh, 2, bh), wall.lightened(0.28))
	draw_rect(Rect2(b.x + b.w - 6, -bh, 4, bh), wall.lightened(0.10))
	draw_rect(Rect2(b.x, -bh, 3, bh), wall.darkened(0.35))
	# floor lines
	var fy := -bh + 12.0
	while fy < -6.0:
		draw_rect(Rect2(b.x, fy, b.w, 1), Color(0, 0, 0, 0.13))
		fy += 12.0
	# roof: parapet + furniture by hash
	draw_rect(Rect2(b.x - 2, -bh - 3, b.w + 4, 3), wall.darkened(0.45))
	draw_rect(Rect2(b.x - 2, -bh - 3, b.w + 4, 1), wall.lightened(0.15))
	match b.roof:
		0:
			draw_rect(Rect2(b.x + b.w * 0.2, -bh - 12, 8, 9), wall.darkened(0.3))
			draw_rect(Rect2(b.x + b.w * 0.2 - 1, -bh - 13, 10, 2), wall.darkened(0.5))
		1:
			draw_rect(Rect2(b.x + b.w * 0.65, -bh - 9, 1, 7), Color("#241a20"))
			draw_rect(Rect2(b.x + b.w * 0.65, -bh - 10, 2, 1),
				Color("#ff4040") if fmod(t, 1.2) < 0.6 else Color("#601818"))
		2:
			draw_rect(Rect2(b.x + b.w * 0.3, -bh - 6, 6, 4), wall.darkened(0.35))
			draw_rect(Rect2(b.x + b.w * 0.55, -bh - 6, 6, 4), wall.darkened(0.35))
	if b.cit:
		draw_rect(Rect2(b.x + b.w * 0.5 - 2, -bh - 22, 4, 19), Color("#3a2018"))
		draw_rect(Rect2(b.x + b.w * 0.5 + 2, -bh - 20, 10, 6), Color("#d0a020"))
		draw_circle(Vector2(b.x + b.w * 0.5, -bh - 21), 6.0, Color(1.0, 0.8, 0.3, 0.12))
	# windows: frame + glass, glow halo on lit
	for w in b.wins:
		if w.p.y > bh - 9:
			continue
		var wx: float = b.x + w.p.x
		var wy2: float = -bh + (bh / b.h) * w.p.y
		draw_rect(Rect2(wx - 0.5, wy2 - 0.5, 6, 8), wall.darkened(0.4))
		if w.dead:
			draw_rect(Rect2(wx, wy2, 5, 7), Color("#150a0e"))
		elif w.on:
			var glow: Color = Color("#ffcf72") if not b.cit else Color("#ffe8a0")
			draw_rect(Rect2(wx, wy2, 5, 7), glow)
			draw_rect(Rect2(wx, wy2 + 4, 5, 3), glow.darkened(0.18))
			if w.blind:
				draw_rect(Rect2(wx, wy2, 5, 3), wall.darkened(0.25))
			draw_rect(Rect2(wx - 1, wy2 - 1, 7, 9), Color(1.0, 0.75, 0.4, 0.10))
		else:
			# unlit glass reflects dusk
			draw_rect(Rect2(wx, wy2, 5, 7), wall.darkened(0.5))
			draw_rect(Rect2(wx, wy2, 5, 2), Color(0.85, 0.4, 0.25, 0.30))
	# bite holes
	for hole in b.holes:
		var hp2: Vector2 = Vector2(b.x + hole.p.x, -bh + (bh / b.h) * hole.p.y)
		draw_circle(hp2, hole.r, Color("#12070c"))
		draw_circle(hp2 + Vector2(hole.r * 0.4, -hole.r * 0.3), hole.r * 0.6, Color("#0c0409"))
		draw_rect(Rect2(hp2.x - hole.r, hp2.y - hole.r * 0.2, hole.r * 0.5, 1), Color(0.9, 0.4, 0.2, 0.3))
	if dmg > 0.25:
		for i in 3:
			var fx: float = b.x + _hash(b.seed + i * 37.0) * b.w
			draw_line(Vector2(fx, -bh + 4), Vector2(fx + (_hash(b.seed + i) - 0.5) * 8.0, -bh + bh * 0.3),
				Color(0, 0, 0, 0.35), 1)
	if dmg > 0.45 and randf() < 0.3:
		_fire(Vector2(b.x + randf() * b.w, -bh + randf() * bh * 0.5))
	if dmg > 0.05:
		draw_rect(Rect2(b.x, -bh, b.w * minf(1.0, dmg * 1.2), 2), Color(1, 0.35, 0.2, 0.8))
