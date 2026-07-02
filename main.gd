extends Node2D
# CALAMITY v4 — The Swarm over New Kowloon.
# Artist facades (Warped City, CC0 by ansimuz) + HDR glow + carved destruction.
# 640x360 native. Ground y=0, up negative. Facades sliced from sheet at load.

const WORLD_W := 4600.0
const TIER_NAMES := ["CALM", "POLICE", "GUARD", "ARMY", "AIR STRIKE", "LAST RESORT"]
const TIER_MULT := [1.0, 1.0, 1.5, 2.0, 3.0, 5.0]

var pos := Vector2(560, -80)
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
var cars: Array = []
var spawn_cd := 3.0

var facades: Array = []     # sliced Images from the sheet
var tex_sky_a: Texture2D
var tex_sky_b: Texture2D
var tex_mid: Texture2D
var cam: Camera2D
var swarm_light: PointLight2D
var hud := {}

var _shot_frames := 0

func _ready() -> void:
	randomize()
	_setup_env()
	_slice_facades()
	_build_city()
	for i in 60:
		motes.append({"a": randf() * TAU, "d": randf_range(0.15, 1.0), "s": randf_range(0.8, 3.0), "o": randf() * TAU})
	cam = Camera2D.new()
	cam.position = Vector2(pos.x, -100)
	add_child(cam)
	cam.make_current()
	swarm_light = PointLight2D.new()
	swarm_light.texture = _radial_tex(128)
	swarm_light.color = Color(1.0, 0.25, 0.3)
	swarm_light.energy = 1.1
	swarm_light.texture_scale = 2.2
	add_child(swarm_light)
	_build_hud()

func _setup_env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	we.environment = env
	add_child(we)

func _radial_tex(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := size * 0.5
	for y in size:
		for x in size:
			var d: float = Vector2(x - c, y - c).length() / c
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0) ** 2))
	return ImageTexture.create_from_image(img)

func _slice_facades() -> void:
	var sheet: Image = load("res://art/near-buildings-bg.png").get_image()
	if sheet.is_compressed():
		sheet.decompress()
	sheet.convert(Image.FORMAT_RGBA8)
	var w := sheet.get_width()
	var h := sheet.get_height()
	var run_start := -1
	for x in w + 1:
		var empty := true
		if x < w:
			for y in h:
				if sheet.get_pixel(x, y).a > 0.05:
					empty = false
					break
		if not empty and run_start < 0:
			run_start = x
		elif (empty or x == w) and run_start >= 0:
			if x - run_start > 20:
				var strip := sheet.get_region(Rect2i(run_start, 0, x - run_start, h))
				# trim vertical: find top of content
				var top := 0
				for yy in h:
					var row_empty := true
					for xx in strip.get_width():
						if strip.get_pixel(xx, yy).a > 0.05:
							row_empty = false
							break
					if not row_empty:
						top = yy
						break
				facades.append(strip.get_region(Rect2i(0, top, strip.get_width(), h - top)))
			run_start = -1
	tex_sky_a = load("res://art/skyline-a.png")
	tex_sky_b = load("res://art/skyline-b.png")
	tex_mid = load("res://art/buildings-bg.png")

func _build_city() -> void:
	var x := 380.0
	var i := 0
	while x < WORLD_W - 620.0:
		var f: Image = facades[i % facades.size()]
		var sc: float = 1.0 if _hash(x) < 0.72 else 2.0
		buildings.append(_mk_building(x, f, sc, false))
		x += f.get_width() * sc + randf_range(14, 48)
		i += 1
	# citadel: biggest facade at 2x
	var big_i := 0
	for j in facades.size():
		if facades[j].get_height() > facades[big_i].get_height():
			big_i = j
	buildings.append(_mk_building(x, facades[big_i], 2.0, true))
	for b in buildings:
		total_mass += b.maxhp
	for k in 26:
		cars.append({"x": randf_range(300, WORLD_W - 400), "w": randf_range(14, 19),
			"col": [Color("#20303a"), Color("#3a2030"), Color("#2a2a34"), Color("#1c2426")][randi() % 4]})
	for k in 70:
		people.append({"pos": Vector2(randf_range(320, WORLD_W - 350), 0), "vx": 0.0, "panic": false,
			"o": randf() * TAU, "col": Color(randf_range(0.4, 0.7), randf_range(0.4, 0.6), randf_range(0.5, 0.75))})

func _mk_building(x: float, src: Image, sc: float, cit: bool) -> Dictionary:
	var img := Image.new()
	img.copy_from(src)
	var w: float = img.get_width() * sc
	var h: float = img.get_height() * sc
	var mass: float = w * h * (0.020 if cit else 0.012)
	return {"x": x, "w": w, "h": h, "sc": sc, "img": img,
		"tex": ImageTexture.create_from_image(img),
		"hp": mass, "maxhp": mass, "holes": [], "dead": false, "dying": 0.0, "cit": cit,
		"cur_h": h, "seed": x * 0.77}

func _hash(n: float) -> float:
	return fmod(absf(sin(n * 127.1) * 43758.55), 1.0)

func _carve(b: Dictionary, world: Vector2, r_px: float) -> void:
	var ix := int((world.x - b.x) / b.sc)
	var iy := int((world.y + b.h) / b.sc)
	var r := int(r_px / b.sc)
	var img: Image = b.img
	var w := img.get_width()
	var h := img.get_height()
	for dy in range(-r - 2, r + 3):
		for dx in range(-r - 2, r + 3):
			var px := ix + dx
			var py := iy + dy
			if px < 0 or py < 0 or px >= w or py >= h:
				continue
			var d := Vector2(dx, dy).length()
			if d <= r:
				img.set_pixel(px, py, Color(0, 0, 0, 0))
			elif d <= r + 1.6 and img.get_pixel(px, py).a > 0.05:
				img.set_pixel(px, py, Color(0.10, 0.02, 0.03, 1.0))
	b.tex.update(img)

# ================= update =================
func _process(delta: float) -> void:
	t += delta
	if OS.get_environment("CAL_SHOT") != "":
		_shot_frames += 1
		if _shot_frames == 130:
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
			b.cur_h = maxf(b.h * 0.06, b.cur_h - b.h * 2.2 * delta)
			if randf() < 22.0 * delta:
				_boom(Vector2(b.x + randf() * b.w, -b.cur_h), 3, Color("#5a4a58"), 60.0)
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
	swarm_light.position = pos
	swarm_light.energy = 1.0 + 0.25 * sin(t * 7.0) + hit_flash
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
		if Vector2(p.pos.x, -3).distance_to(pos) < radius + 4.0:
			p.dead = true
			var gain := int(20.0 * combo * TIER_MULT[tier])
			score_f += gain
			combo = minf(9.5, combo + 0.12)
			combo_idle = 0.0
			hp = minf(100.0, hp + 0.8)
			threat = minf(100.0, threat + 0.35)
			_boom(Vector2(p.pos.x, -4), 5, Color("#c02040"), 60.0)
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
				var carve_at := Vector2(clampf(pos.x, b.x + 4, b.x + b.w - 4), clampf(pos.y, -b.cur_h + 4, -6.0))
				_carve(b, carve_at, randf_range(4.0, 8.0))
				b.holes.append({"p": carve_at - Vector2(b.x, -b.h), "o": randf() * TAU})
				_boom(pos + Vector2(randf_range(-8, 8), randf_range(-8, 8)), 3, Color("#7a6a7a"), 70.0)
				if int(t * 7.7) % 3 == 0:
					_pop(Vector2(pos.x, pos.y - 14), "+%d" % int(bite * 1.6 * combo * TIER_MULT[tier] * 8.0), Color("#ffcf8a"))
			if b.hp <= 0.0:
				b.dying = 0.6
				var gain := int(b.maxhp * 8.0 * combo * TIER_MULT[tier] * (4.0 if b.cit else 1.0))
				score_f += gain
				combo = min(9.5, combo + 0.5)
				hp = min(100.0, hp + 5.0)
				shake = 16.0 if b.cit else 8.0
				_boom(Vector2(cx, -b.cur_h * 0.5), 60 if b.cit else 26, Color("#5a4a58"), 110.0)
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
		"life": randf_range(0.3, 0.7), "col": Color(2.2, 1.1, 0.4) if randf() < 0.7 else Color(2.5, 1.9, 0.6), "fire": true})

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

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud.score = _label(layer, Vector2(10, 4), 16, Color("#e8f0ff"))
	hud.combo = _label(layer, Vector2(10, 24), 11, Color("#ff4d78"))
	hud.tier = _label(layer, Vector2(478, 4), 8, Color("#9ab0d0"))
	hud.threat = _bar(layer, Vector2(478, 16), Color("#e08a2b"))
	hud.hplbl = _label(layer, Vector2(478, 26), 8, Color("#9ab0d0"))
	hud.hplbl.text = "INTEGRITY"
	hud.hp = _bar(layer, Vector2(478, 38), Color("#e0455a"))
	hud.citylbl = _label(layer, Vector2(478, 48), 8, Color("#9ab0d0"))
	hud.city = _bar(layer, Vector2(478, 60), Color("#9a5de0"))
	hud.msg = _label(layer, Vector2(0, 140), 28, Color("#ffb08a"))
	hud.msg.size = Vector2(640, 40)
	hud.msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.sub = _label(layer, Vector2(0, 180), 10, Color("#e8f0ff"))
	hud.sub.size = Vector2(640, 20)
	hud.sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var help := _label(layer, Vector2(10, 344), 8, Color(0.85, 0.9, 1, 0.45))
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
	bg.color = Color(0.06, 0.06, 0.12)
	parent.add_child(bg)
	var fg := ColorRect.new()
	fg.size = Vector2(152, 5)
	fg.color = col
	bg.add_child(fg)
	return fg

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
	for b in buildings:
		if b.x + b.w < left or b.x > right:
			continue
		_draw_building(b)
	_draw_street(left, right)
	_draw_actors()
	_draw_swarm()
	for p in pops:
		var a2: float = clampf(p.life, 0.0, 1.0)
		draw_string(ThemeDB.fallback_font, p.pos, p.txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 8,
			Color(p.col.r * 1.4, p.col.g * 1.4, p.col.b * 1.4, a2))
	# atmosphere: ground haze + bottom vignette
	draw_rect(Rect2(left, -30, right - left, 34), Color(0.3, 0.12, 0.3, 0.08))
	draw_rect(Rect2(left, 14, right - left, 400), Color(0.01, 0.0, 0.03, 0.55))

func _draw_sky(left: float, right: float, cx: float) -> void:
	var g := [Color("#0a0d1f"), Color("#1a1440"), Color("#3d1a52"), Color("#7a2244"), Color("#b03840")]
	var top := -380.0
	var rows := 95
	for i in rows:
		var f := float(i) / rows
		var col: Color
		if f < 0.4:
			col = g[0].lerp(g[1], f / 0.4)
		elif f < 0.68:
			col = g[1].lerp(g[2], (f - 0.4) / 0.28)
		elif f < 0.88:
			col = g[2].lerp(g[3], (f - 0.68) / 0.2)
		else:
			col = g[3].lerp(g[4], (f - 0.88) / 0.12)
		draw_rect(Rect2(left, top + f * 380.0, right - left, 380.0 / rows + 1), col)
	for i in 60:
		var sxr := fmod(_hash(i * 3.7) * 4310.0, 1.0) * (right - left) + left
		var syr := -378.0 + _hash(i * 9.1) * 190.0
		if fmod(t * (0.4 + fmod(float(i), 3.0) * 0.3) + i, 2.0) < 1.5:
			draw_rect(Rect2(sxr, syr, 1, 1), Color(0.9, 0.92, 1.0, 0.5 * (1.0 - (syr + 378.0) / 200.0)))
	# blood moon (HDR — blooms)
	var moon := Vector2(cx + 140, -250.0)
	draw_circle(moon, 26, Color(0.6, 0.08, 0.1, 0.35))
	draw_circle(moon, 20, Color(1.55, 0.35, 0.3))
	draw_circle(moon + Vector2(-5, -4), 16, Color(1.7, 0.45, 0.38))
	draw_circle(moon + Vector2(6, 5), 4, Color(1.2, 0.25, 0.22))
	draw_circle(moon + Vector2(-9, 7), 2.5, Color(1.2, 0.25, 0.22))

func _draw_backdrop(left: float, right: float, cx: float) -> void:
	# city glow band on the horizon (blooms slightly)
	draw_rect(Rect2(left, -120, right - left, 60), Color(0.5, 0.16, 0.4, 0.10))
	draw_rect(Rect2(left, -80, right - left, 80), Color(0.85, 0.3, 0.5, 0.14))
	# far skyline: low silhouette strip on the horizon
	var sw: float = tex_sky_a.get_width()
	var sh: float = tex_sky_a.get_height() * 0.45
	var f := 0.15
	var xoff := -cx * f
	var start: float = floor((left - xoff) / sw) * sw + xoff
	var xi := start
	var k := int(floor((left - xoff) / sw))
	while xi < right:
		var tx: Texture2D = tex_sky_a if k % 2 == 0 else tex_sky_b
		draw_texture_rect(tx, Rect2(xi, -sh, sw, sh), false, Color(0.36, 0.3, 0.6, 1))
		xi += sw
		k += 1
	draw_rect(Rect2(left, -sh, right - left, sh), Color(0.12, 0.08, 0.24, 0.45))
	# mid layer: taller, closer, clearer
	var mw: float = tex_mid.get_width() * 1.4
	var mh: float = tex_mid.get_height() * 1.4
	f = 0.4
	xoff = -cx * f
	start = floor((left - xoff) / mw) * mw + xoff
	xi = start
	while xi < right:
		draw_texture_rect(tex_mid, Rect2(xi, -mh, mw, mh), false, Color(0.55, 0.45, 0.8, 1))
		xi += mw
	draw_rect(Rect2(left, -mh, right - left, mh), Color(0.1, 0.06, 0.2, 0.35))

func _draw_building(b: Dictionary) -> void:
	if b.dead:
		draw_rect(Rect2(b.x, -b.cur_h, b.w, b.cur_h), Color("#100a14"))
		draw_rect(Rect2(b.x + b.w * 0.12, -b.cur_h - 4, b.w * 0.32, 4), Color("#181020"))
		draw_rect(Rect2(b.x + b.w * 0.55, -b.cur_h - 7, b.w * 0.28, 7), Color("#181020"))
		if randf() < 0.06:
			_fire(Vector2(b.x + randf() * b.w, -b.cur_h - 2))
		return
	var img_h: float = b.img.get_height()
	var vis_frac: float = b.cur_h / b.h
	var src := Rect2(0, img_h * (1.0 - vis_frac), b.img.get_width(), img_h * vis_frac)
	draw_texture_rect_region(b.tex, Rect2(b.x, -b.cur_h, b.w, b.cur_h), src)
	# embers glowing in fresh holes (HDR)
	for hole in b.holes:
		if randf() < 0.5:
			var hp2: Vector2 = Vector2(b.x, -b.h) + hole.p + Vector2(sin(t * 9 + hole.o) * 2.0, cos(t * 7 + hole.o))
			if hp2.y > -b.cur_h:
				continue
			draw_rect(Rect2(hp2.x, hp2.y, 1.5, 1.5), Color(2.2, 0.9, 0.3, 0.8))
	var dmg: float = 1.0 - b.hp / b.maxhp
	if dmg > 0.45 and randf() < 0.25:
		_fire(Vector2(b.x + randf() * b.w, -b.cur_h + randf() * b.cur_h * 0.4))
	if b.cit:
		var cp := Vector2(b.x + b.w * 0.5, -b.cur_h - 8)
		draw_circle(cp, 5, Color(2.0, 1.6, 0.5, 0.25))
		draw_rect(Rect2(cp.x - 2, cp.y - 2, 4, 4), Color(2.2, 1.8, 0.6))
	if dmg > 0.05:
		draw_rect(Rect2(b.x, -b.cur_h - 3, b.w * minf(1.0, dmg * 1.15), 2), Color(1.6, 0.4, 0.25, 0.9))

func _draw_street(left: float, right: float) -> void:
	draw_rect(Rect2(left, 0, right - left, 2), Color("#383050"))
	draw_rect(Rect2(left, 2, right - left, 6), Color("#1c1830"))
	draw_rect(Rect2(left, 8, right - left, 400), Color("#100c1e"))
	var rx := left - fposmod(left, 26.0)
	while rx < right:
		draw_rect(Rect2(rx, 4, 10, 1), Color(0.8, 0.8, 1.0, 0.10))
		rx += 26.0
	# street lamps with pooled light
	var lx := left - fposmod(left, 96.0)
	while lx < right:
		draw_rect(Rect2(lx, -26, 1, 26), Color("#201830"))
		draw_rect(Rect2(lx - 2, -27, 5, 2), Color("#201830"))
		draw_circle(Vector2(lx + 0.5, -24), 2.2, Color(1.9, 1.5, 0.9))
		draw_circle(Vector2(lx + 0.5, -24), 6.0, Color(1.2, 0.95, 0.6, 0.12))
		draw_colored_polygon(PackedVector2Array([
			Vector2(lx - 1, -24), Vector2(lx + 2, -24), Vector2(lx + 10, 0), Vector2(lx - 9, 0)]),
			Color(1.0, 0.85, 0.5, 0.05))
		draw_rect(Rect2(lx - 9, -1, 19, 2), Color(1.0, 0.85, 0.5, 0.09))
		lx += 96.0
	for c in cars:
		if c.x < left or c.x > right:
			continue
		draw_rect(Rect2(c.x, -5, c.w, 4), c.col)
		draw_rect(Rect2(c.x + 3, -8, c.w - 7, 3), c.col.darkened(0.2))
		draw_rect(Rect2(c.x + 1, -1, 3, 1), Color("#08060c"))
		draw_rect(Rect2(c.x + c.w - 4, -1, 3, 1), Color("#08060c"))
		draw_rect(Rect2(c.x + c.w - 1, -4, 1, 2), Color(1.6, 0.5, 0.3, 0.8))

func _draw_actors() -> void:
	for p in people:
		var run: float = absf(p.vx)
		var leg: float = sin(t * (14.0 if run > 20 else 6.0) + p.o) * (2.0 if run > 5 else 0.6)
		draw_rect(Rect2(p.pos.x - 1, -7, 2, 4), p.col)
		draw_rect(Rect2(p.pos.x - 1, -8.5, 2, 2), Color("#b09080"))
		draw_line(Vector2(p.pos.x, -3), Vector2(p.pos.x - leg, 0), p.col.darkened(0.3), 1)
		draw_line(Vector2(p.pos.x, -3), Vector2(p.pos.x + leg, 0), p.col.darkened(0.3), 1)
	for u in units:
		var p: Vector2 = u.pos
		draw_rect(Rect2(p.x - 9, -1, 18, 2), Color(0, 0, 0, 0.4))
		match u.kind:
			"police":
				draw_rect(Rect2(p.x - 8, p.y - 7, 16, 5), Color("#aab4c4"))
				draw_rect(Rect2(p.x - 5, p.y - 10, 10, 3), Color("#8a94a8"))
				var siren_r: bool = fmod(t, 0.5) < 0.25
				draw_rect(Rect2(p.x - 2, p.y - 11, 4, 1), Color(2.2, 0.3, 0.3) if siren_r else Color(0.4, 0.7, 2.4))
				draw_circle(Vector2(p.x - 2, p.y - 12), 4.0,
					Color(1.5, 0.2, 0.2, 0.15) if siren_r else Color(0.2, 0.4, 1.6, 0.15))
				draw_rect(Rect2(p.x - 6, p.y - 2, 3, 2), Color("#0c0c14"))
				draw_rect(Rect2(p.x + 3, p.y - 2, 3, 2), Color("#0c0c14"))
			"tank":
				draw_rect(Rect2(p.x - 11, p.y - 8, 22, 6), Color("#3c4438"))
				draw_rect(Rect2(p.x - 11, p.y - 8, 22, 2), Color("#4c5648"))
				draw_rect(Rect2(p.x - 6, p.y - 12, 12, 5), Color("#3c4438"))
				draw_line(Vector2(p.x, p.y - 10), Vector2(p.x + signf(pos.x - p.x) * 13, p.y - 14), Color("#3c4438"), 2)
				draw_rect(Rect2(p.x - 12, p.y - 3, 24, 3), Color("#181c16"))
			"heli":
				draw_rect(Rect2(p.x - 8, p.y - 3, 16, 6), Color("#2c3430"))
				draw_rect(Rect2(p.x + (8 if pos.x < p.x else -14), p.y - 1, 6, 2), Color("#2c3430"))
				var rot: float = sin(t * 40.0) * 12.0
				draw_line(p + Vector2(-rot, -5), p + Vector2(rot, -5), Color(0.8, 0.85, 0.8, 0.6), 1)
				# searchlight cone
				var to_swarm := (pos - p).normalized()
				draw_colored_polygon(PackedVector2Array([p, p + to_swarm * 90.0 + to_swarm.orthogonal() * 22.0,
					p + to_swarm * 90.0 - to_swarm.orthogonal() * 22.0]), Color(1.0, 1.0, 0.85, 0.05))
	for s in shells:
		var sc: Color = Color(2.4, 1.9, 0.7) if s.heavy else Color(2.0, 1.6, 0.6)
		draw_rect(Rect2(s.pos.x - 1, s.pos.y - 1, 3 if s.heavy else 2, 3 if s.heavy else 2), sc)
	for p in parts:
		var a: float = clampf(p.life * 2.5, 0.0, 1.0)
		draw_rect(Rect2(p.pos.x, p.pos.y, 2, 2), Color(p.col.r, p.col.g, p.col.b, a))

func _draw_swarm() -> void:
	if pos.y > -120:
		var sa: float = clampf(1.0 + pos.y / 120.0, 0.0, 0.5)
		draw_rect(Rect2(pos.x - radius * 0.7, -1, radius * 1.4, 2), Color(0, 0, 0, sa * 0.5))
	# glow halo (blooms) + dark core
	draw_circle(pos, radius * 1.5, Color(0.9, 0.12, 0.18, 0.10))
	draw_circle(pos, radius * 0.9, Color(1.1, 0.15, 0.2, 0.14))
	draw_circle(pos + Vector2(0, 1), radius * 0.62, Color("#2a0614"))
	draw_circle(pos + Vector2(-3, -2), radius * 0.45, Color("#3a0a16"))
	draw_circle(pos + Vector2(3, 2), radius * 0.4, Color("#1e0510"))
	for m in motes:
		m.a += 0.025 * m.s
		var wob: float = sin(t * 6.5 + m.o) * 3.0
		var px: float = pos.x + cos(m.a) * radius * m.d * (1.0 + 0.3 * sin(t * 3.4 + m.o)) + wob
		var py: float = pos.y + sin(m.a * 1.3) * radius * m.d * 1.4 + cos(t * 5.2 + m.o) * 2.5
		var stx: float = -sin(m.a) * (1.5 + m.s)
		var sty: float = cos(m.a * 1.3) * 1.2
		var bright: bool = hit_flash > 0.5 or fmod(m.o + t, 5.0) < 0.35
		var mc: Color = Color(2.2, 1.4, 1.1) if bright else (Color(1.7, 0.35, 0.4) if m.d < 0.6 else Color("#701018"))
		draw_line(Vector2(px, py), Vector2(px + stx, py + sty), mc, 1.0)
