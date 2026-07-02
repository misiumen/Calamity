extends Node2D
# CALAMITY v2 — The Swarm. Rampage-style pixel look (640x360 native, world units = pixels).
# Ground at y=0, buildings extend upward (negative y).

const WORLD_W := 4200.0
const TIER_NAMES := ["CALM", "POLICE", "GUARD", "ARMY", "AIR STRIKE", "LAST RESORT"]
const TIER_MULT := [1.0, 1.0, 1.5, 2.0, 3.0, 5.0]
const WALL_COLS := [Color("#7a4a3a"), Color("#8a6a4a"), Color("#5a5a6a"), Color("#6b4a55"), Color("#4a5a5a")]

# --- swarm ---
var pos := Vector2(300, -80)
var vel := Vector2.ZERO
var hp := 100.0
var radius := 15.0
var motes: Array = []
var hit_flash := 0.0

# --- run ---
var score_f := 0.0
var combo := 1.0
var combo_idle := 0.0
var threat := 0.0
var tier := 0
var over := false
var shake := 0.0
var t := 0.0
var bite_cd := 0.0

# --- world ---
var buildings: Array = []
var total_mass := 0.0
var units: Array = []
var shells: Array = []
var parts: Array = []
var pops: Array = []
var spawn_cd := 3.0

var cam: Camera2D
var hud := {}

func _ready() -> void:
	randomize()
	_build_city()
	for i in 70:
		motes.append({"a": randf() * TAU, "d": randf_range(0.15, 1.0), "s": randf_range(0.8, 3.0), "o": randf() * TAU})
	cam = Camera2D.new()
	cam.position = Vector2(pos.x, -100)
	add_child(cam)
	cam.make_current()
	_build_hud()

func _build_city() -> void:
	var x := 380.0
	while x < WORLD_W - 500.0:
		var w := snappedf(randf_range(45, 95), 8.0)
		var h := snappedf(randf_range(70, 230), 11.0)
		buildings.append(_mk_building(x, w, h, false))
		x += w + randf_range(18, 55)
	var cit := _mk_building(x, 110.0, 300.0, true)
	buildings.append(cit)
	for b in buildings:
		total_mass += b.maxhp

func _mk_building(x: float, w: float, h: float, cit: bool) -> Dictionary:
	var wins: Array = []
	var wy := 8.0
	while wy < h - 12.0:
		var wx := 5.0
		while wx < w - 9.0:
			wins.append({"p": Vector2(wx, wy), "on": randf() < 0.6, "dead": false})
			wx += 9.0
		wy += 12.0
	return {"x": x, "w": w, "h": h, "hp": w * h * (0.020 if cit else 0.012), "maxhp": w * h * (0.020 if cit else 0.012),
		"wins": wins, "holes": [], "dead": false, "dying": 0.0, "cit": cit,
		"col": WALL_COLS[randi() % WALL_COLS.size()], "cur_h": h}

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
	help.text = "WASD / arrows — fly.  latch onto buildings to devour them.  R — restart."

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
func _process(delta: float) -> void:
	t += delta
	if not over:
		_move(delta)
		_eat(delta)
		_army(delta)
		threat = min(100.0, threat + 0.55 * delta)
		tier = mini(5, int(threat / 17.0))
		_check_end()
	for b in buildings:
		if b.dying > 0.0 and not b.dead:
			b.dying -= delta
			b.cur_h = maxf(b.h * 0.08, b.cur_h - b.h * 2.2 * delta)
			if randf() < 20.0 * delta:
				_boom(Vector2(b.x + randf() * b.w, -b.cur_h), 3, Color("#9a8a78"), 60.0)
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
			var tick: float = bite * 1.6 * combo * TIER_MULT[tier]
			score_f += tick
			if bite_cd <= 0.0:
				bite_cd = 0.13
				combo = min(9.5, combo + 0.06)
				var hole_p := Vector2(clampf(pos.x - b.x, 4, b.w - 4), clampf(-pos.y, 6, b.cur_h - 6))
				b.holes.append({"p": hole_p, "r": randf_range(3.0, 7.0)})
				for w in b.wins:
					if not w.dead and w.p.distance_to(hole_p) < 14.0:
						w.dead = true
				_boom(pos + Vector2(randf_range(-8, 8), randf_range(-8, 8)), 3, b.col.lightened(0.15), 70.0)
				if int(t * 7.7) % 3 == 0:
					_pop(Vector2(pos.x, pos.y - 14), "+%d" % int(tick * 8.0), Color("#ffcf8a"))
			if b.hp <= 0.0:
				b.dying = 0.6
				var gain := int(b.maxhp * 8.0 * combo * TIER_MULT[tier] * (4.0 if b.cit else 1.0))
				score_f += gain
				combo = min(9.5, combo + 0.5)
				hp = min(100.0, hp + 5.0)
				shake = 16.0 if b.cit else 8.0
				_boom(Vector2(cx, -b.cur_h * 0.5), 60 if b.cit else 26, Color("#9a8a78"), 110.0)
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
				units.append({"kind": "heli", "pos": Vector2(x, randf_range(-220, -150)), "cd": randf_range(0.5, 1.2), "hp": 3})
			elif tier >= 3 and randf() < 0.6:
				units.append({"kind": "tank", "pos": Vector2(x, 0), "cd": randf_range(0.7, 1.5), "hp": 4})
			else:
				units.append({"kind": "police", "pos": Vector2(x, 0), "cd": randf_range(0.6, 1.2), "hp": 2})
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
	# sky
	var g := [Color("#1a0a18"), Color("#4a1428"), Color("#a03a26"), Color("#e07038")]
	var bands := 24
	var sky_top := -380.0
	for i in bands:
		var f := float(i) / bands
		var col: Color
		if f < 0.4:
			col = g[0].lerp(g[1], f / 0.4)
		elif f < 0.78:
			col = g[1].lerp(g[2], (f - 0.4) / 0.38)
		else:
			col = g[2].lerp(g[3], (f - 0.78) / 0.22)
		draw_rect(Rect2(left, sky_top + f * 380.0, right - left, 380.0 / bands + 1), col)
	# stars
	for i in 40:
		var sxr := fmod(sin(i * 127.3) * 4310.0, 1.0) * (right - left) + left
		var syr := -380.0 + fmod(sin(i * 91.7) * 2170.0, 1.0) * 130.0
		if fmod(t * (0.4 + fmod(float(i), 3.0) * 0.3) + i, 2.0) < 1.4:
			draw_rect(Rect2(sxr, syr, 1, 1), Color(1, 0.9, 0.8, 0.7))
	# sun
	var sun := Vector2(cx + 130, -68.0)
	draw_circle(sun, 34, Color(1.0, 0.45, 0.2, 0.25))
	draw_circle(sun, 24, Color(1.0, 0.62, 0.3, 0.95))
	draw_rect(Rect2(sun.x - 34, -46, 68, 2), Color(0.2, 0.05, 0.1, 0.5))
	draw_rect(Rect2(sun.x - 30, -56, 60, 2), Color(0.2, 0.05, 0.1, 0.35))
	# far skyline (parallax)
	for i in 30:
		var wx := fposmod(i * 173.0 - cx * 0.25, right - left + 200.0) + left - 100.0
		var wh := 40.0 + fmod(sin(i * 31.7) * 913.0, 1.0) * 70.0
		var ww := 24.0 + fmod(sin(i * 57.1) * 517.0, 1.0) * 30.0
		draw_rect(Rect2(wx, -wh, ww, wh), Color("#2a1020"))
	# buildings
	for b in buildings:
		if b.x + b.w < left or b.x > right:
			continue
		_draw_building(b)
	# ground
	draw_rect(Rect2(left, 0, right - left, 8), Color("#3a2028"))
	draw_rect(Rect2(left, 8, right - left, 400), Color("#170a12"))
	var rx := left - fposmod(left, 24.0)
	while rx < right:
		draw_rect(Rect2(rx, 3, 10, 1), Color(1, 0.8, 0.6, 0.12))
		rx += 24.0
	# units
	for u in units:
		var p: Vector2 = u.pos
		match u.kind:
			"police":
				draw_rect(Rect2(p.x - 8, p.y - 7, 16, 5), Color("#dcdce4"))
				draw_rect(Rect2(p.x - 5, p.y - 10, 10, 3), Color("#dcdce4"))
				draw_rect(Rect2(p.x - 2, p.y - 11, 4, 1),
					Color("#ff3a3a") if fmod(t, 0.5) < 0.25 else Color("#3a6aff"))
				draw_rect(Rect2(p.x - 6, p.y - 2, 3, 2), Color("#181820"))
				draw_rect(Rect2(p.x + 3, p.y - 2, 3, 2), Color("#181820"))
			"tank":
				draw_rect(Rect2(p.x - 11, p.y - 8, 22, 6), Color("#4a4a3a"))
				draw_rect(Rect2(p.x - 6, p.y - 12, 12, 5), Color("#4a4a3a"))
				draw_line(Vector2(p.x, p.y - 10), Vector2(p.x + signf(pos.x - p.x) * 13, p.y - 14), Color("#4a4a3a"), 2)
				draw_rect(Rect2(p.x - 12, p.y - 3, 24, 3), Color("#242420"))
			"heli":
				draw_rect(Rect2(p.x - 8, p.y - 3, 16, 6), Color("#3a4438"))
				draw_rect(Rect2(p.x + (8 if pos.x < p.x else -14), p.y - 1, 6, 2), Color("#3a4438"))
				var rot: float = sin(t * 40.0) * 12.0
				draw_line(p + Vector2(-rot, -5), p + Vector2(rot, -5), Color("#c8c8c0"), 1)
	# shells
	for s in shells:
		draw_rect(Rect2(s.pos.x - 1, s.pos.y - 1, 3 if s.heavy else 2, 3 if s.heavy else 2), Color("#ffd75a"))
	# particles
	for p in parts:
		var a: float = clampf(p.life * 2.5, 0.0, 1.0)
		draw_rect(Rect2(p.pos.x, p.pos.y, 2, 2), Color(p.col.r, p.col.g, p.col.b, a))
	# swarm
	draw_circle(pos, radius + 6, Color(0.9, 0.1, 0.15, 0.10))
	draw_circle(pos, radius + 2, Color(0.9, 0.1, 0.15, 0.12))
	for m in motes:
		m.a += 0.025 * m.s
		var wob: float = sin(t * 6.5 + m.o) * 3.0
		var px: float = pos.x + cos(m.a) * radius * m.d * (1.0 + 0.3 * sin(t * 3.4 + m.o)) + wob
		var py: float = pos.y + sin(m.a * 1.3) * radius * m.d * 1.4 + cos(t * 5.2 + m.o) * 2.5
		var bright: bool = hit_flash > 0.5 or fmod(m.o + t, 5.0) < 0.35
		draw_rect(Rect2(px, py, 1 + m.d * 1.5, 1 + m.d * 1.5),
			Color("#fff0e0") if bright else (Color("#e04448") if m.d < 0.6 else Color("#a01828")))
	# pops
	for p in pops:
		var a2: float = clampf(p.life, 0.0, 1.0)
		draw_string(ThemeDB.fallback_font, p.pos, p.txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 8,
			Color(p.col.r, p.col.g, p.col.b, a2))

func _draw_building(b: Dictionary) -> void:
	var bh: float = b.cur_h if (b.dying > 0.0 or b.dead) else b.h
	if b.dead:
		# rubble mound
		draw_rect(Rect2(b.x, -bh, b.w, bh), Color("#241318"))
		draw_rect(Rect2(b.x + b.w * 0.15, -bh - 4, b.w * 0.3, 4), Color("#2c1a20"))
		draw_rect(Rect2(b.x + b.w * 0.55, -bh - 7, b.w * 0.25, 7), Color("#2c1a20"))
		return
	var dmg: float = 1.0 - b.hp / b.maxhp
	var wall: Color = b.col if not b.cit else Color("#6a4a2a")
	# facade + darker side strip (fake depth) + roof
	draw_rect(Rect2(b.x, -bh, b.w, bh), wall)
	draw_rect(Rect2(b.x + b.w - 6, -bh, 6, bh), wall.darkened(0.35))
	draw_rect(Rect2(b.x - 2, -bh - 3, b.w + 4, 3), wall.darkened(0.5))
	if b.cit:
		draw_rect(Rect2(b.x + b.w * 0.5 - 2, -bh - 22, 4, 19), Color("#3a2018"))
		draw_rect(Rect2(b.x + b.w * 0.5 + 2, -bh - 20, 10, 6), Color("#d0a020"))
	# windows
	for w in b.wins:
		if w.p.y > bh - 8:
			continue
		var wc: Color
		if w.dead:
			wc = Color("#1a0c10")
		elif w.on:
			wc = Color("#ffd075") if not b.cit else Color("#ffe8a0")
		else:
			wc = wall.darkened(0.55)
		draw_rect(Rect2(b.x + w.p.x, -bh + (bh / b.h) * w.p.y, 5, 7), wc)
	# bite holes
	for hole in b.holes:
		var hp2: Vector2 = Vector2(b.x + hole.p.x, -bh + (bh / b.h) * hole.p.y)
		draw_circle(hp2, hole.r, Color("#12070c"))
		draw_circle(hp2 + Vector2(hole.r * 0.4, -hole.r * 0.3), hole.r * 0.6, Color("#0c0409"))
	# cracks + fire when hurt
	if dmg > 0.25:
		for i in 3:
			var fx: float = b.x + fmod(sin(i * 37.0 + b.x) * 517.0, 1.0) * b.w
			draw_line(Vector2(fx, -bh + 4), Vector2(fx + randf_range(-3, 3), -bh + bh * 0.3), Color(0, 0, 0, 0.35), 1)
	if dmg > 0.45 and randf() < 0.3:
		_fire(Vector2(b.x + randf() * b.w, -bh + randf() * bh * 0.5))
	if dmg > 0.05:
		draw_rect(Rect2(b.x, -bh, b.w * minf(1.0, dmg * 1.2), 2), Color(1, 0.35, 0.2, 0.8))
