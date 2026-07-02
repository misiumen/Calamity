extends Node2D
# CALAMITY vertical slice — The Swarm. One file on purpose (ponytail: fewest files).
# World: ground at y=0, buildings extend upward (negative y). Camera side-on.

const WORLD_W := 12000.0
const TIER_NAMES := ["CALM", "POLICE", "GUARD", "ARMY", "AIR STRIKE", "LAST RESORT"]
const TIER_MULT := [1.0, 1.0, 1.5, 2.0, 3.0, 5.0]

# --- swarm state ---
var pos := Vector2(1000, -260)
var vel := Vector2.ZERO
var hp := 100.0
var radius := 52.0
var motes: Array = []

# --- run state ---
var score := 0
var combo := 1.0
var combo_idle := 0.0
var threat := 0.0
var tier := 0
var over := false
var shake := 0.0
var t := 0.0

# --- world ---
var buildings: Array = []
var total_mass := 0.0
var units: Array = []
var shells: Array = []
var parts: Array = []   # {pos, vel, life, col}
var pops: Array = []    # {pos, txt, col, life}
var spawn_cd := 0.0

var cam: Camera2D
var hud := {}

func _ready() -> void:
	randomize()
	_build_city()
	for i in 110:
		motes.append({"a": randf() * TAU, "d": randf_range(0.15, 1.0), "s": randf_range(0.8, 3.0), "o": randf() * TAU})
	cam = Camera2D.new()
	cam.position = pos
	add_child(cam)
	cam.make_current()
	_build_hud()

func _build_city() -> void:
	var x := 1400.0
	while x < WORLD_W - 1800.0:
		var w := randf_range(130, 300)
		var h := randf_range(220, 720)
		var wins: Array = []
		for i in int(w * h / 3200.0):
			wins.append({"p": Vector2(randf_range(8, w - 20), randf_range(14, h - 22)), "on": randf() < 0.55})
		buildings.append({"x": x, "w": w, "h": h, "hp": w * h * 0.010, "maxhp": w * h * 0.010,
			"wins": wins, "dead": false, "cit": false})
		x += w + randf_range(60, 200)
	var cit: Dictionary = buildings[-1]
	cit.cit = true
	cit.w = 340.0
	cit.h = 860.0
	cit.hp = cit.w * cit.h * 0.016
	cit.maxhp = cit.hp
	for b in buildings:
		total_mass += b.maxhp

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud.score = _label(layer, Vector2(24, 14), 34, Color("#e8d5c0"))
	hud.combo = _label(layer, Vector2(24, 56), 22, Color("#ff4d78"))
	hud.tier = _label(layer, Vector2(1240, 14), 14, Color("#c9a68a"))
	hud.threat = _bar(layer, Vector2(1240, 38), Color("#d9822b"))
	hud.hplbl = _label(layer, Vector2(1240, 58), 14, Color("#c9a68a"))
	hud.hplbl.text = "INTEGRITY"
	hud.hp = _bar(layer, Vector2(1240, 82), Color("#e0455a"))
	hud.citylbl = _label(layer, Vector2(1240, 102), 14, Color("#c9a68a"))
	hud.city = _bar(layer, Vector2(1240, 126), Color("#7a4dd8"))
	hud.msg = _label(layer, Vector2(0, 340), 64, Color("#ffb08a"))
	hud.msg.size = Vector2(1600, 100)
	hud.msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.sub = _label(layer, Vector2(0, 430), 20, Color("#e8d5c0"))
	hud.sub.size = Vector2(1600, 40)
	hud.sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var help := _label(layer, Vector2(24, 862), 13, Color(0.9, 0.83, 0.75, 0.55))
	help.text = "CALAMITY — you are the swarm.  WASD / arrows to fly.  devour the city before the army buries you."

func _label(parent: Node, p: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.position = p
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(l)
	return l

func _bar(parent: Node, p: Vector2, col: Color) -> ColorRect:
	var bg := ColorRect.new()
	bg.position = p
	bg.size = Vector2(330, 10)
	bg.color = Color(0.13, 0.06, 0.09)
	parent.add_child(bg)
	var fg := ColorRect.new()
	fg.size = Vector2(330, 10)
	fg.color = col
	bg.add_child(fg)
	return fg

func _process(delta: float) -> void:
	t += delta
	if not over:
		_move(delta)
		_eat(delta)
		_army(delta)
		_escalate(delta)
		_check_end()
	# particles / pops
	for p in parts:
		p.pos += p.vel * delta * 60.0
		p.vel.y += 9.0 * delta
		p.life -= delta
	parts = parts.filter(func(p): return p.life > 0.0)
	for p in pops:
		p.pos.y -= 40.0 * delta
		p.life -= delta
	pops = pops.filter(func(p): return p.life > 0.0)
	shells = shells.filter(func(s): return s.life > 0.0)
	# camera
	shake = max(0.0, shake - 60.0 * delta)
	cam.position = cam.position.lerp(Vector2(pos.x, -300), 6.0 * delta)
	cam.position.x = clamp(cam.position.x, 700, WORLD_W - 700)
	cam.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	_hud_update()
	queue_redraw()

func _move(delta: float) -> void:
	var acc := 2600.0
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	vel += dir * acc * delta
	vel *= pow(0.02, delta)  # heavy damping, floaty swarm feel
	pos += vel * delta
	pos.x = clamp(pos.x, 100, WORLD_W - 100)
	pos.y = clamp(pos.y, -1400, -40)

func _eat(delta: float) -> void:
	for b in buildings:
		if b.dead:
			continue
		var cx: float = b.x + b.w * 0.5
		if absf(pos.x - cx) < b.w * 0.5 + radius and pos.y > -b.h - radius:
			var bite: float = (22.0 + combo * 7.0) * delta * (1.0 + tier * 0.15)
			b.hp -= bite
			threat = min(100.0, threat + bite * 0.011)
			combo_idle = 0.0
			if randf() < 8.0 * delta:
				_boom(pos + Vector2(randf_range(-25, 25), randf_range(-25, 25)), 2, Color("#caa58f"), 3.0)
			combo = min(9.5, combo + 0.25 * delta)
			if b.hp <= 0.0:
				b.dead = true
				var gain := int(b.maxhp * 10.0 * combo * TIER_MULT[tier] * (4.0 if b.cit else 1.0))
				score += gain
				combo = min(9.5, combo + 0.6)
				hp = min(100.0, hp + 6.0)
				shake = 26.0 if b.cit else 12.0
				_boom(Vector2(cx, -b.h * 0.4), 140 if b.cit else 50, Color("#b9967a"), 9.0)
				_boom(Vector2(cx, -b.h * 0.4), 25, Color("#ff4d5a"), 6.0)
				_pop(Vector2(cx, -b.h - 40), ("CITADEL FELL  +" if b.cit else "+") + str(gain),
					Color("#ffd75a") if b.cit else Color("#ffb08a"))
	combo_idle += delta
	if combo_idle > 1.8 and combo > 1.0:
		combo = max(1.0, combo - 1.2 * delta)

func _escalate(delta: float) -> void:
	threat = min(100.0, threat + (0.35 + tier * 0.12) * delta)
	tier = mini(5, int(threat / 17.0))

func _army(delta: float) -> void:
	spawn_cd -= delta
	if tier >= 1 and spawn_cd <= 0.0 and units.size() < 3 + tier * 3:
		spawn_cd = maxf(0.4, 1.6 - tier * 0.2)
		var side: float = -1.0 if randf() < 0.5 else 1.0
		var x: float = pos.x + side * randf_range(900, 1400)
		if x > 60 and x < WORLD_W - 60:
			if tier >= 4 and randf() < 0.45:
				units.append({"kind": "heli", "pos": Vector2(x, randf_range(-560, -380)), "cd": randf_range(0.5, 1.4)})
			else:
				units.append({"kind": "tank", "pos": Vector2(x, 0), "cd": randf_range(0.7, 1.6)})
	for u in units:
		var dx: float = pos.x - u.pos.x
		if u.kind == "tank":
			u.pos.x += signf(dx) * 42.0 * delta
		else:
			u.pos.x += signf(dx) * 85.0 * delta
			u.pos.y += sin(t * 2.0) * 12.0 * delta
		u.cd -= delta
		if u.cd <= 0.0 and absf(dx) < 1100.0:
			u.cd = maxf(0.5, randf_range(1.2, 2.2) - tier * 0.15)
			var origin: Vector2 = u.pos + Vector2(0, -26 if u.kind == "tank" else 0)
			var speed: float = 420.0 if u.kind == "tank" else 560.0
			shells.append({"pos": origin, "vel": (pos - origin).normalized() * speed, "life": 3.5})
	for s in shells:
		s.pos += s.vel * delta
		s.life -= delta
		if s.pos.distance_to(pos) < radius:
			s.life = 0.0
			hp -= 7.0 if tier >= 4 else 4.0
			combo = max(1.0, combo - 1.0)
			shake = 9.0
			_boom(s.pos, 12, Color("#ffd75a"), 5.0)

func _eaten_frac() -> float:
	var eaten := 0.0
	for b in buildings:
		eaten += b.maxhp if b.dead else (b.maxhp - b.hp)
	return eaten / total_mass

func _check_end() -> void:
	var citadel_dead: bool = buildings[-1].dead
	if _eaten_frac() >= 0.9 or citadel_dead:
		_end("CITY RAZED", "the swarm moves on.  score %s  —  press R" % _fmt(score))
	elif hp <= 0.0:
		_end("THE SWARM IS SCATTERED", "the city endures.  score %s  —  press R" % _fmt(score))

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
		parts.append({"pos": p, "vel": Vector2(cos(a), sin(a)) * randf_range(1.0, sp) - Vector2(0, 2),
			"life": randf_range(0.4, 1.1), "col": col})

func _pop(p: Vector2, txt: String, col: Color) -> void:
	pops.append({"pos": p, "txt": txt, "col": col, "life": 1.4})

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
	hud.score.text = _fmt(score)
	hud.combo.text = "×%.1f" % combo
	hud.tier.text = "THREAT — " + TIER_NAMES[tier]
	hud.threat.size.x = 330.0 * threat / 100.0
	hud.hp.size.x = 330.0 * maxf(0.0, hp) / 100.0
	hud.citylbl.text = "CITY DEVOURED — %d%%" % int(_eaten_frac() * 100)
	hud.city.size.x = 330.0 * minf(1.0, _eaten_frac() / 0.9)

# ---------------- render ----------------
func _draw() -> void:
	var cx := cam.position.x
	var vp := Vector2(1600, 900)
	var left := cx - vp.x  # generous bounds
	var right := cx + vp.x
	# sky (drawn in world space, big slab following camera)
	var sky_top := -1700.0
	var g := [Color("#12060f"), Color("#3d0f1e"), Color("#8a2b1e"), Color("#c65a2e")]
	var bands := 36
	for i in bands:
		var f := float(i) / bands
		var col: Color
		if f < 0.45:
			col = g[0].lerp(g[1], f / 0.45)
		elif f < 0.8:
			col = g[1].lerp(g[2], (f - 0.45) / 0.35)
		else:
			col = g[2].lerp(g[3], (f - 0.8) / 0.2)
		var y0 := sky_top + f * 1700.0
		draw_rect(Rect2(left, y0, right - left, 1700.0 / bands + 2), col)
	# sun
	var sun := Vector2(cx + 320, -170.0)
	for i in range(5, 0, -1):
		draw_circle(sun, i * 55.0, Color(1.0, 0.42, 0.2, 0.10))
	draw_circle(sun, 62, Color(1.0, 0.55, 0.28, 0.9))
	# parallax hills
	for layer in [[0.25, Color("#1c0b14"), 210.0], [0.45, Color("#241019"), 130.0]]:
		var f: float = layer[0]
		var col: Color = layer[1]
		var hh: float = layer[2]
		var pts := PackedVector2Array()
		pts.append(Vector2(left, 0))
		var x := left
		while x <= right:
			var wx := x * f + cx * (1.0 - f)
			pts.append(Vector2(x, -hh - sin(wx / 300.0) * 46.0 - sin(wx / 97.0) * 20.0))
			x += 80
		pts.append(Vector2(right, 0))
		draw_colored_polygon(pts, col)
	# buildings
	for b in buildings:
		if b.x + b.w < left or b.x > right:
			continue
		var dmg: float = 1.0 - b.hp / b.maxhp
		var bh: float = b.h * 0.12 if b.dead else b.h * (1.0 - dmg * 0.35)
		var base_col: Color = Color("#170d12") if b.dead else (Color("#26101c") if b.cit else Color("#1e0f16"))
		draw_rect(Rect2(b.x, -bh, b.w, bh), base_col)
		if not b.dead:
			draw_rect(Rect2(b.x, -bh, b.w * 0.18, bh), Color("#3a1626") if b.cit else Color("#2b1520"))
			for w in b.wins:
				var wy: float = w.p.y * (bh / b.h)
				if wy > bh - 16:
					continue
				var wc: Color = (Color("#ffd75a") if b.cit else Color("#ff9b4a")) if w.on else Color("#241019")
				draw_rect(Rect2(b.x + w.p.x, -bh + wy, 8, 10), wc)
			if b.cit:
				draw_colored_polygon(PackedVector2Array([
					Vector2(b.x - 16, -bh), Vector2(b.x + b.w * 0.5, -bh - 110), Vector2(b.x + b.w + 16, -bh)]),
					Color("#3a1626"))
			if dmg > 0.05:
				draw_rect(Rect2(b.x, -bh, b.w, 5), Color(1.0, 0.3, 0.2, dmg * 0.6))
	# ground
	draw_rect(Rect2(left, 0, right - left, 700), Color("#22121a"))
	draw_rect(Rect2(left, 26, right - left, 700), Color("#0c0510"))
	# units
	for u in units:
		var p: Vector2 = u.pos
		if u.kind == "tank":
			draw_rect(Rect2(p.x - 24, p.y - 18, 48, 13), Color("#2e2a24"))
			draw_rect(Rect2(p.x - 13, p.y - 27, 26, 11), Color("#2e2a24"))
			draw_line(Vector2(p.x, p.y - 22), Vector2(p.x + signf(pos.x - p.x) * 30, p.y - 33), Color("#2e2a24"), 5)
		else:
			draw_circle(p, 15, Color("#332e26"))
			draw_line(p + Vector2(-30, -12), p + Vector2(30, -12), Color("#4a443a"), 4)
	# shells
	for s in shells:
		draw_circle(s.pos, 4.0, Color("#ffd75a"))
	# particles
	for p in parts:
		var a: float = clampf(p.life * 2.2, 0.0, 1.0)
		draw_rect(Rect2(p.pos.x, p.pos.y, 5, 5), Color(p.col.r, p.col.g, p.col.b, a))
	# the swarm — glow + motes
	for i in range(10, 0, -1):
		draw_circle(pos, radius * 0.3 * i, Color(1.0, 0.16, 0.24, 0.028 * (11 - i)))
	for m in motes:
		m.a += 0.02 * m.s
		var wob: float = sin(t * 6.5 + m.o) * 8.0
		var px: float = pos.x + cos(m.a) * radius * m.d * (1.1 + 0.3 * sin(t * 3.4 + m.o)) + wob
		var py: float = pos.y + sin(m.a * 1.3) * radius * m.d * 1.5 + cos(t * 5.2 + m.o) * 7.0
		var mc: Color = Color("#ffb0a0") if fmod(m.o + t, 5.0) < 0.4 else Color("#c11f30")
		draw_rect(Rect2(px, py, 3 + m.d * 2.5, 3 + m.d * 2.5), mc)
	# score pops
	for p in pops:
		var a2: float = clampf(p.life, 0.0, 1.0)
		draw_string(ThemeDB.fallback_font, p.pos, p.txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 26,
			Color(p.col.r, p.col.g, p.col.b, a2))
