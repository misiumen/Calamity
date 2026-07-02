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
	character = Global.character
	if character == "tzitzimitl":
		for i in 16:
			segs.append(pos)
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
				if img.get_pixel(px, py).a > 0.05:
					# torn interior, not a see-through hole: dark rooms + beam lines
					var interior := Color(0.09, 0.045, 0.075) if py % 12 < 10 else Color(0.045, 0.02, 0.04)
					if (px + py * 3) % 17 == 0:
						interior = Color(0.14, 0.07, 0.06)
					img.set_pixel(px, py, interior)
			elif d <= r + 1.6 and img.get_pixel(px, py).a > 0.05:
				img.set_pixel(px, py, Color(0.16, 0.05, 0.05, 1.0))
	b.tex.update(img)

# ================= update =================
func _process(delta: float) -> void:
	if draft_open:
		return
	t += delta
	if OS.get_environment("CAL_SHOT") != "":
		_shot_frames += 1
		if _shot_frames == 130:
			get_viewport().get_texture().get_image().save_png(OS.get_environment("CAL_SHOT"))
			get_tree().quit()
	# spore pods gnaw on their own
	for pod in pods:
		pod.t_left -= delta
		pod.tick -= delta
		var b: Dictionary = pod.b
		if pod.tick <= 0.0 and not b.dead and b.dying <= 0.0:
			pod.tick = 0.5
			var world: Vector2 = Vector2(b.x, -b.h) + pod.p + Vector2(randf_range(-4, 4), randf_range(-4, 4))
			_carve(b, world, randf_range(2.0, 4.0))
			b.hp -= 2.0
			score_f += 3.0 * combo * TIER_MULT[tier]
			bio += 0.6
			if b.hp <= 0.0:
				b.dying = 0.6
	for pod in pods:
		if pod.t_left <= 0.0 and nodes.has("creep") and randf() < 0.25 and not pod.b.dead:
			pods.append({"b": pod.b, "p": pod.p + Vector2(randf_range(-14, 14), randf_range(-14, 14)),
				"t_left": 6.0, "tick": 0.5})
	pods = pods.filter(func(p): return p.t_left > 0.0 and not p.b.dead)
	# biomass threshold -> evolution draft (swarm only for now)
	if character == "swarm" and bio_stage < BIO_THRESH.size() and bio >= BIO_THRESH[bio_stage] and not over:
		_open_draft()
	if not over:
		match character:
			"keraunos":
				_move(delta)
				_keraunos(delta)
			"tzitzimitl":
				_tzitzi_move(delta)
				_tzitzi(delta)
			_:
				_move(delta)
				_tendrils(delta)
		lmb_prev = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		_people(delta)
		_army(delta)
		threat = min(100.0, threat + 0.22 * delta)
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
	people = people.filter(func(p): return not p.get("dead", false))

# --- tendril + evolution state ---
const BIO_THRESH := [180.0, 520.0, 1100.0]
var tendril_range := 100.0
var aim := Vector2.ZERO          # clamped world aim point
var aim_clamped := false
var feeding := false             # LMB held
var chew_target = null           # building dict or null
var chewing := false             # actually biting something this frame
# evolution tree: first pick locks the branch, later picks buy nodes inside it
var branch := ""                 # "", "ironmaw", "gorehook", "spore"
var nodes := {}                  # node id -> true
var bio := 0.0
var bio_stage := 0
var draft_open := false
var draft_layer: CanvasLayer = null
var pods: Array = []             # {b, p(local), t_left, tick}
var rmb_cd := 0.0
var lash := {"t_left": 0.0, "ang": 0.0}
var slams: Array = []            # {x, dir, dist}
var aftershock_q: Array = []     # {p, t_left}
var max_grabs := 1
var dmg_taken_mult := 1.0

# --- character dispatch ---
var character := "swarm"
var lmb_prev := false
# keraunos
var bolt_charges := 3.0
var bolts: Array = []            # {from, to, t_left}
# tzitzimitl
var segs: Array = []             # serpent body trail
var dive_t := 0.0
var dive_dir := Vector2.RIGHT
var dive_cd := 0.0
var eclipse_t := 0.0

func _tendrils(delta: float) -> void:
	bite_cd -= delta
	rmb_cd -= delta
	lash.t_left = maxf(0.0, lash.t_left - delta)
	var mouse := get_global_mouse_position()
	var to_m := mouse - pos
	aim_clamped = to_m.length() > tendril_range
	aim = pos + to_m.limit_length(tendril_range)
	feeding = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not over
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and rmb_cd <= 0.0 and not over:
		_rmb_active()
	# queued aftershocks
	for q in aftershock_q:
		q.t_left -= delta
		if q.t_left <= 0.0:
			_shockwave(q.p, 30.0)
	aftershock_q = aftershock_q.filter(func(q): return q.t_left > 0.0)
	# seismic slam waves travel the street
	for s in slams:
		s.dist += 240.0 * delta
		var wx: float = s.x + s.dir * s.dist
		for u in units:
			if u.kind != "heli" and absf(u.pos.x - wx) < 14.0 and not u.get("slammed", false):
				u.slammed = true
				u.hp = u.get("hp", 1) - 2
				u.fall = true
				u.vy = -80.0
				u.pos.y = -20.0
				if u.hp <= 0:
					u.dead = true
					_kill_unit(u)
		for b in buildings:
			if b.dead or b.dying > 0.0:
				continue
			if wx >= b.x and wx <= b.x + b.w and randf() < 0.5:
				_carve(b, Vector2(wx, -randf_range(4, 22)), 5.0)
				b.hp -= 2.0
				if b.hp <= 0.0:
					b.dying = 0.6
		if randf() < 0.8:
			parts.append({"pos": Vector2(wx, -2), "vel": Vector2(0, randf_range(-60, -20)),
				"life": 0.4, "col": Color(0.5, 0.4, 0.45), "size": 2.5})
	slams = slams.filter(func(s): return s.dist < 150.0)
	chewing = false
	chew_target = null
	if not feeding:
		# release: drop everything held (falls, fall damage)
		for u in units:
			if u.get("grab", false):
				u.grab = false
				u.fall = true
				u.vy = 0.0
	else:
		# 1) grab units near the aim point (cap by evolution)
		var grabbed_n := 0
		for u in units:
			if u.get("grab", false):
				grabbed_n += 1
		var grabbed_someone := grabbed_n > 0
		for u in units:
			if grabbed_n >= max_grabs:
				break
			if u.get("grab", false):
				continue
			if (u.pos + Vector2(0, -8)).distance_to(aim) < 17.0:
				u.grab = true
				u.fall = false
				u.thrown = false
				combo_idle = 0.0
				grabbed_someone = true
				grabbed_n += 1
		# 2) snatch a person
		if not grabbed_someone:
			for p in people:
				if Vector2(p.pos.x, -4).distance_to(aim) < 12.0:
					p.dead = true
					var gain := int(20.0 * combo * TIER_MULT[tier])
					score_f += gain
					bio += 2.0
					combo = minf(9.5, combo + 0.12)
					combo_idle = 0.0
					hp = minf(100.0, hp + 0.8)
					threat = minf(100.0, threat + 0.35)
					_mist(Vector2(p.pos.x, -5))
					if randf() < 0.5:
						_pop(Vector2(p.pos.x, -16), "+%d" % gain, Color("#ff8a9a"))
					break
		# 3) chew the building under the aim point
		for b in buildings:
			if b.dead or b.dying > 0.0:
				continue
			if aim.x >= b.x and aim.x <= b.x + b.w and aim.y >= -b.cur_h and aim.y <= 0.0:
				chew_target = b
				chewing = true
				_chew(b, delta)
				break
	# reel / throw / fall — units smashing through buildings on the way
	var crash_dmg: float = 9.0 if nodes.has("flenser") else 4.0
	for u in units:
		if u.get("thrown", false):
			u.pos += u.tvel * delta
			u.tvel.y += 260.0 * delta
			u.crash_cd = maxf(0.0, u.get("crash_cd", 0.0) - delta)
			_unit_crash_buildings(u, crash_dmg * 2.0)
			if u.pos.y >= 0.0 or u.pos.x < 40 or u.pos.x > WORLD_W - 40:
				u.dead = true
				_kill_unit(u)
			continue
		if u.get("fall", false):
			u.vy += 300.0 * delta
			u.pos.y += u.vy * delta
			if u.kind == "heli":
				u.fall = false   # helis recover in the air
				u.vy = 0.0
			elif u.pos.y >= 0.0:
				u.pos.y = 0.0
				u.fall = false
				if u.vy > 130.0:
					u.dead = true
					_kill_unit(u)
				u.vy = 0.0
		if not u.get("grab", false):
			continue
		var reel: float = (60.0 if u.kind == "tank" else 110.0) * (2.2 if branch == "gorehook" else 1.0)
		u.crash_cd = maxf(0.0, u.get("crash_cd", 0.0) - delta)
		var blocked := _unit_crash_buildings(u, crash_dmg)
		u.pos = u.pos.move_toward(pos, reel * delta * (0.45 if blocked else 1.0))
		if u.pos.distance_to(pos) < radius + 2.0:
			u.dead = true
			_kill_unit(u)
	units = units.filter(func(u): return not u.get("dead", false))
	if not chewing:
		combo_idle += delta
		if combo_idle > 1.2 and combo > 1.0:
			combo = max(1.0, combo - 1.6 * delta)

# ================= KERAUNOS =================
func _keraunos(delta: float) -> void:
	bolt_charges = minf(3.0, bolt_charges + delta / 1.2)
	rmb_cd -= delta
	aim = get_global_mouse_position()
	aim_clamped = false
	feeding = false
	for b2 in bolts:
		b2.t_left -= delta
	bolts = bolts.filter(func(b2): return b2.t_left > 0.0)
	var lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if lmb and not lmb_prev and bolt_charges >= 1.0:
		bolt_charges -= 1.0
		_strike(aim)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and rmb_cd <= 0.0 and bio >= 100.0:
		# TEMPEST: barrage across the visible city
		rmb_cd = 2.0
		bio -= 100.0
		for i in 6:
			var tx: float = cam.position.x + randf_range(-300, 300)
			var ty: float = -randf_range(10, 200)
			for b in buildings:
				if b.dead or b.dying > 0.0:
					continue
				if tx >= b.x and tx <= b.x + b.w:
					ty = -b.cur_h + randf_range(2, 30)
					break
			_strike(Vector2(tx, ty))

func _strike(p: Vector2) -> void:
	bolts.append({"from": Vector2(p.x + randf_range(-30, 30), -370), "to": p, "t_left": 0.16})
	parts.append({"pos": p, "vel": Vector2.ZERO, "life": 0.2, "col": Color(1.8, 2.2, 2.6), "flash": true, "size": 14.0})
	shake = maxf(shake, 7.0)
	combo_idle = 0.0
	threat = minf(100.0, threat + 1.2)
	for b in buildings:
		if b.dead or b.dying > 0.0:
			continue
		if p.x >= b.x - 6 and p.x <= b.x + b.w + 6 and p.y >= -b.cur_h - 10:
			var hit := Vector2(clampf(p.x, b.x + 4, b.x + b.w - 4), clampf(p.y, -b.cur_h + 4, -6.0))
			_carve(b, hit, randf_range(7.0, 11.0))
			_carve(b, hit + Vector2(randf_range(-6, 6), randf_range(4, 10)), 5.0)
			b.holes.append({"p": hit - Vector2(b.x, -b.h), "o": randf() * TAU})
			b.hp -= 30.0
			var gain: float = 30.0 * 1.6 * combo * TIER_MULT[tier]
			score_f += gain
			bio += 8.0
			combo = minf(9.5, combo + 0.25)
			_chunks(hit, 4)
			_pop(hit + Vector2(0, -12), "+%d" % int(gain), Color("#aaddff"))
			if b.hp <= 0.0:
				b.dying = 0.6
				score_f += b.maxhp * 8.0 * combo * TIER_MULT[tier]
			break
	for u in units:
		if (u.pos + Vector2(0, -8)).distance_to(p) < 20.0:
			u.dead = true
			_kill_unit(u)
	units = units.filter(func(u): return not u.get("dead", false))
	for pe in people:
		if Vector2(pe.pos.x, -4).distance_to(p) < 16.0:
			pe.dead = true
			score_f += 20.0 * combo * TIER_MULT[tier]
			bio += 2.0
			_mist(Vector2(pe.pos.x, -5))

# ================= TZITZIMITL =================
func _tzitzi_move(delta: float) -> void:
	var mouse := get_global_mouse_position()
	aim = mouse
	aim_clamped = false
	feeding = false
	dive_cd -= delta
	rmb_cd -= delta
	if dive_t > 0.0:
		dive_t -= delta
		pos += dive_dir * 640.0 * delta
	else:
		var des := (mouse - pos)
		vel += des.limit_length(240.0) * 6.0 * delta
		vel *= pow(0.05, delta)
		vel = vel.limit_length(280.0)
		pos += vel * delta
	pos.x = clamp(pos.x, 40, WORLD_W - 40)
	pos.y = clamp(pos.y, -340, -10)
	segs.push_front(pos)
	while segs.size() > 16:
		segs.pop_back()

func _tzitzi(delta: float) -> void:
	if eclipse_t > 0.0:
		eclipse_t -= delta
	var lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var cd_needed: float = 0.25 if eclipse_t > 0.0 else 0.55
	if lmb and not lmb_prev and dive_cd <= 0.0:
		dive_cd = cd_needed
		dive_t = 0.22
		dive_dir = (get_global_mouse_position() - pos).normalized()
		combo_idle = 0.0
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and rmb_cd <= 0.0 and bio >= 80.0 and eclipse_t <= 0.0:
		rmb_cd = 1.0
		bio -= 80.0
		eclipse_t = 10.0
		shake = 8.0
		_pop(pos + Vector2(0, -26), "E C L I P S E", Color(2.0, 1.2, 0.4))
	# diving: pierce everything on the path
	if dive_t > 0.0:
		var mult: float = 1.6 if eclipse_t > 0.0 else 1.0
		for b in buildings:
			if b.dead or b.dying > 0.0:
				continue
			if pos.x >= b.x and pos.x <= b.x + b.w and pos.y >= -b.cur_h and pos.y <= 0.0:
				_carve(b, pos, 7.0)
				b.hp -= 3.2 * mult
				var gain: float = 5.0 * combo * TIER_MULT[tier] * mult
				score_f += gain
				bio += 1.2
				combo = minf(9.5, combo + 0.02)
				if randf() < 0.3:
					b.holes.append({"p": pos - Vector2(b.x, -b.h), "o": randf() * TAU})
					_chunks(pos, 2)
				if b.hp <= 0.0:
					b.dying = 0.6
					score_f += b.maxhp * 8.0 * combo * TIER_MULT[tier]
		for u in units:
			if (u.pos + Vector2(0, -8)).distance_to(pos) < 16.0:
				u.dead = true
				_kill_unit(u)
		units = units.filter(func(u): return not u.get("dead", false))
		for pe in people:
			if Vector2(pe.pos.x, -4).distance_to(pos) < 12.0:
				pe.dead = true
				score_f += 20.0 * combo * TIER_MULT[tier]
				bio += 2.0
				_mist(Vector2(pe.pos.x, -5))
	if dive_t <= 0.0:
		combo_idle += delta
		if combo_idle > 1.4 and combo > 1.0:
			combo = max(1.0, combo - 1.4 * delta)

func _unit_crash_buildings(u: Dictionary, dmg: float) -> bool:
	var upos: Vector2 = u.pos + Vector2(0, -8)
	for b in buildings:
		if b.dead or b.dying > 0.0:
			continue
		if upos.x >= b.x and upos.x <= b.x + b.w and upos.y >= -b.cur_h and upos.y <= 0.0:
			if u.get("crash_cd", 0.0) <= 0.0:
				u.crash_cd = 0.08
				_carve(b, upos, 8.0)
				b.hp -= dmg
				b.holes.append({"p": upos - Vector2(b.x, -b.h), "o": randf() * TAU})
				_chunks(upos, 3)
				_boom(upos, 4, Color("#7a6a7a"), 80.0)
				shake = maxf(shake, 3.0)
				score_f += 6.0 * combo * TIER_MULT[tier]
				if b.hp <= 0.0:
					b.dying = 0.6
			return true
	return false

func _rmb_active() -> void:
	if nodes.has("seismic"):
		rmb_cd = 2.5
		shake = 10.0
		_boom(Vector2(pos.x, -4), 14, Color(0.6, 0.5, 0.55), 90.0)
		slams.append({"x": pos.x, "dir": 1.0, "dist": 0.0})
		slams.append({"x": pos.x, "dir": -1.0, "dist": 0.0})
		for u in units:
			u.slammed = false
	elif nodes.has("sling"):
		var thrown_one := false
		for u in units:
			if u.get("grab", false):
				u.grab = false
				u.thrown = true
				u.tvel = (aim - u.pos).normalized() * 320.0
				thrown_one = true
				break
		if thrown_one:
			rmb_cd = 0.5
			shake = 5.0
		else:
			rmb_cd = 0.9
			vel += (aim - pos).normalized() * 340.0   # grapple zip
	elif nodes.has("burst") and pods.size() > 0:
		rmb_cd = 1.0
		for pod in pods:
			var b: Dictionary = pod.b
			var world: Vector2 = Vector2(b.x, -b.h) + pod.p
			if not b.dead:
				_carve(b, world, 11.0)
				_carve(b, world + Vector2(randf_range(-6, 6), randf_range(-6, 6)), 7.0)
				b.hp -= 22.0
				if b.hp <= 0.0 and b.dying <= 0.0:
					b.dying = 0.6
			_boom(world, 16, Color(0.9, 1.8, 0.5), 100.0)
			_shockwave(world, 34.0)
			score_f += 40.0 * combo * TIER_MULT[tier]
		shake = 8.0
		pods.clear()
	else:
		# base ARC LASH: sweeping tendril fan toward the cursor
		rmb_cd = 1.6
		lash = {"t_left": 0.28, "ang": (aim - pos).angle()}
		var hit_r := 78.0
		for u in units:
			var d: Vector2 = (u.pos + Vector2(0, -8)) - pos
			if d.length() < hit_r and absf(angle_difference(d.angle(), lash.ang)) < 1.1:
				u.hp = u.get("hp", 1) - 1
				u.fall = true
				u.vy = -60.0
				u.pos.y = minf(u.pos.y, -14.0)
				_boom(u.pos + Vector2(0, -8), 8, Color(2.0, 0.8, 0.5), 90.0)
				if u.hp <= 0:
					u.dead = true
					_kill_unit(u)
		for p in people:
			var d: Vector2 = Vector2(p.pos.x, -4) - pos
			if d.length() < hit_r and absf(angle_difference(d.angle(), lash.ang)) < 1.1:
				p.dead = true
				score_f += 20.0 * combo * TIER_MULT[tier]
				bio += 2.0
				_mist(Vector2(p.pos.x, -5))
		for b in buildings:
			if b.dead or b.dying > 0.0:
				continue
			for k in 3:
				var probe: Vector2 = pos + Vector2.from_angle(lash.ang + (k - 1) * 0.5) * hit_r * 0.8
				if probe.x >= b.x and probe.x <= b.x + b.w and probe.y >= -b.cur_h and probe.y <= 0.0:
					_carve(b, probe, 6.0)
					b.hp -= 6.0
					score_f += 8.0 * combo * TIER_MULT[tier]
					bio += 3.0
					if b.hp <= 0.0:
						b.dying = 0.6
		shake = maxf(shake, 4.0)
		combo_idle = 0.0

func _shockwave(p: Vector2, r: float) -> void:
	parts.append({"pos": p, "vel": Vector2.ZERO, "life": 0.2, "col": Color(1.8, 1.4, 0.8), "flash": true, "size": r * 0.5})
	for u in units:
		if (u.pos + Vector2(0, -8)).distance_to(p) < r:
			u.hp = u.get("hp", 1) - 1
			if u.hp <= 0:
				u.dead = true
				_kill_unit(u)

func _chew(b: Dictionary, delta: float) -> void:
	var maul: bool = branch == "ironmaw"
	var bite: float = (11.0 + combo * 3.2) * delta * (1.0 + tier * 0.15) * (1.8 if maul else 1.0)
	b.hp -= bite
	threat = min(100.0, threat + bite * 0.06)
	combo_idle = 0.0
	score_f += bite * 1.6 * combo * TIER_MULT[tier]
	bio += bite * 0.5
	if bite_cd <= 0.0:
		bite_cd = 0.22 if maul else 0.13
		combo = min(9.5, combo + 0.06)
		var r1: float = randf_range(4.0, 8.0) * (2.0 if maul else 1.0)
		_carve(b, aim, r1)
		_carve(b, aim + Vector2(randf_range(-5, 5), randf_range(-5, 5)), r1 * 0.6)
		b.holes.append({"p": aim - Vector2(b.x, -b.h), "o": randf() * TAU})
		_boom(aim, 5 if maul else 3, Color("#7a6a7a"), 90.0 if maul else 70.0)
		_chunks(aim, 4 if maul else 2)
		if maul:
			shake = maxf(shake, 4.0)
			_shockwave(aim, 30.0)
			if nodes.has("aftershock"):
				aftershock_q.append({"p": aim, "t_left": 0.28})
		if branch == "spore" and int(t * 7.7) % 4 == 0:
			pods.append({"b": b, "p": aim - Vector2(b.x, -b.h), "t_left": 6.0, "tick": 0.5})
		if int(t * 7.7) % 3 == 0:
			_pop(aim + Vector2(0, -10), "+%d" % int(bite * 1.6 * combo * TIER_MULT[tier] * 8.0), Color("#ffcf8a"))
	if b.hp <= 0.0:
		b.dying = 0.6
		var gain := int(b.maxhp * 8.0 * combo * TIER_MULT[tier] * (4.0 if b.cit else 1.0))
		score_f += gain
		combo = min(9.5, combo + 0.5)
		hp = min(100.0, hp + 5.0)
		shake = 16.0 if b.cit else 8.0
		_boom(Vector2(b.x + b.w * 0.5, -b.cur_h * 0.5), 60 if b.cit else 26, Color("#5a4a58"), 110.0)
		_pop(Vector2(b.x + b.w * 0.5, -b.h - 14), ("CITADEL FELL  +" if b.cit else "+") + _fmt(gain),
			Color("#ffd75a") if b.cit else Color("#ffb08a"))

const BRANCH_DEFS := [
	{"id": "ironmaw", "name": "IRONMAW", "desc": "chitin mauls — heavier, wider smashes; every smash shockwaves nearby units"},
	{"id": "gorehook", "name": "GOREHOOK", "desc": "barbed hooks — reel everything 2x faster, grind harder through walls"},
	{"id": "spore", "name": "SPORE BLOOM", "desc": "plant pods in wounds — they keep gnawing the building on their own"},
]
const NODE_DEFS := {
	"ironmaw": [
		{"id": "seismic", "name": "SEISMIC SLAM", "kind": "ACTIVE — RMB", "desc": "slam the street: a shockwave rolls both ways, flipping units and cracking foundations"},
		{"id": "chitin", "name": "DENSE CHITIN", "kind": "PASSIVE", "desc": "armored mass — incoming fire deals 35% less damage"},
		{"id": "aftershock", "name": "AFTERSHOCK", "kind": "PASSIVE", "desc": "every maul smash echoes a second, delayed shockwave"},
	],
	"gorehook": [
		{"id": "sling", "name": "SLING", "kind": "ACTIVE — RMB", "desc": "hurl the grabbed unit at the cursor as a wrecking projectile; empty-handed, grapple yourself instead"},
		{"id": "flenser", "name": "FLENSER", "kind": "PASSIVE", "desc": "dragged and thrown bodies tear through buildings for double damage"},
		{"id": "sinew", "name": "LONG SINEW", "kind": "PASSIVE", "desc": "tendrils reach 40% farther and hold two victims at once"},
	],
	"spore": [
		{"id": "burst", "name": "BURST BLOOM", "kind": "ACTIVE — RMB", "desc": "detonate every pod at once — big craters, shockwaves, spores everywhere"},
		{"id": "creep", "name": "CREEP", "kind": "PASSIVE", "desc": "dying pods seed a child pod nearby"},
		{"id": "cloud", "name": "CARRION CLOUD", "kind": "PASSIVE", "desc": "every kill feeds you — bonus healing and combo"},
	],
}

func _open_draft() -> void:
	draft_open = true
	draft_layer = CanvasLayer.new()
	add_child(draft_layer)
	var dim := ColorRect.new()
	dim.size = Vector2(640, 360)
	dim.color = Color(0.02, 0.0, 0.05, 0.78)
	draft_layer.add_child(dim)
	var title := _label(draft_layer, Vector2(0, 52), 20, Color("#ff4d78"))
	title.size = Vector2(640, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var opts: Array
	if branch == "":
		title.text = "THE SWARM EVOLVES — choose your line"
		opts = BRANCH_DEFS
	else:
		title.text = branch.to_upper() + " DEEPENS — choose"
		opts = NODE_DEFS[branch].filter(func(n): return not nodes.has(n.id))
	for i in opts.size():
		var d: Dictionary = opts[i]
		var btn := Button.new()
		btn.text = d.name + ("   [%s]" % d.kind if d.has("kind") else "")
		btn.position = Vector2(70, 100 + i * 64)
		btn.size = Vector2(500, 30)
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(_pick_draft.bind(d.id))
		draft_layer.add_child(btn)
		var desc := _label(draft_layer, Vector2(78, 131 + i * 64), 9, Color("#c8d0e8"))
		desc.text = d.desc

func _pick_draft(id: String) -> void:
	var picked_name := ""
	if branch == "":
		branch = id
		picked_name = BRANCH_DEFS.filter(func(d): return d.id == id)[0].name
	else:
		nodes[id] = true
		picked_name = NODE_DEFS[branch].filter(func(d): return d.id == id)[0].name
		match id:
			"chitin": dmg_taken_mult = 0.65
			"sinew":
				tendril_range = 140.0
				max_grabs = 2
	bio_stage += 1
	draft_open = false
	if draft_layer:
		draft_layer.queue_free()
		draft_layer = null
	_pop(pos + Vector2(0, -24), picked_name, Color(2.0, 0.6, 0.7))
	radius = minf(24.0, radius + 2.0)  # visible growth per evolution

func _kill_unit(u: Dictionary) -> void:
	var base: int
	match u.kind:
		"tank": base = 800
		"heli": base = 600
		_: base = 300
	var gain := int(base * combo * TIER_MULT[tier])
	score_f += gain
	bio += 20.0 if u.kind == "tank" else 12.0
	combo = minf(9.5, combo + (0.6 if nodes.has("cloud") else 0.3))
	combo_idle = 0.0
	hp = minf(100.0, hp + (6.0 if u.kind == "tank" else 4.0) + (6.0 if nodes.has("cloud") else 0.0))
	threat = minf(100.0, threat + 1.5)
	shake = 10.0
	_explode(u.pos + Vector2(0, -8), u.kind)
	_pop(u.pos + Vector2(0, -20), "+%d" % gain, Color("#ffd75a"))

func _explode(p: Vector2, kind: String) -> void:
	parts.append({"pos": p, "vel": Vector2.ZERO, "life": 0.22, "col": Color(2.6, 1.8, 0.9), "flash": true, "size": 16.0})
	for i in 26:
		var a := randf() * TAU
		parts.append({"pos": p, "vel": Vector2(cos(a), sin(a)) * randf_range(20, 120) + Vector2(0, -40),
			"life": randf_range(0.4, 1.0), "col": Color(2.2, randf_range(0.6, 1.2), 0.3) if randf() < 0.7 else Color("#3a3430"),
			"size": randf_range(2.0, 3.5)})
	if kind == "tank":
		for i in 3:
			parts.append({"pos": p, "vel": Vector2(randf_range(-60, 60), randf_range(-140, -80)),
				"life": 1.2, "col": Color("#4a4a3a"), "size": 4.0})
	for i in 8:
		parts.append({"pos": p, "vel": Vector2(randf_range(-15, 15), randf_range(-50, -20)),
			"life": randf_range(0.8, 1.6), "col": Color(0.25, 0.22, 0.24, 0.7), "fire": true, "size": 3.0})

func _mist(p: Vector2) -> void:
	for i in 9:
		var a := randf() * TAU
		parts.append({"pos": p, "vel": Vector2(cos(a), sin(a)) * randf_range(10, 50) + Vector2(0, -20),
			"life": randf_range(0.3, 0.7), "col": Color(1.4, 0.15, 0.25), "size": randf_range(1.5, 2.5)})

func _chunks(p: Vector2, n: int) -> void:
	for i in n:
		parts.append({"pos": p, "vel": Vector2(randf_range(-40, 40), randf_range(-60, -10)),
			"life": randf_range(0.5, 1.1), "col": Color("#4a3a4a"), "size": randf_range(2.5, 4.0)})

func _army(delta: float) -> void:
	spawn_cd -= delta
	if tier >= 1 and spawn_cd <= 0.0 and units.size() < 2 + tier * 3:
		spawn_cd = maxf(0.35, 1.4 - tier * 0.18)
		var side: float = -1.0 if randf() < 0.5 else 1.0
		var x: float = pos.x + side * randf_range(360, 560)
		if x > 30 and x < WORLD_W - 30:
			if tier >= 4 and randf() < 0.45:
				units.append({"kind": "heli", "pos": Vector2(x, randf_range(-220, -150)), "cd": randf_range(0.5, 1.2), "hp": 2})
			elif tier >= 3 and randf() < 0.6:
				units.append({"kind": "tank", "pos": Vector2(x, 0), "cd": randf_range(0.7, 1.5), "hp": 3})
			else:
				units.append({"kind": "police", "pos": Vector2(x, 0), "cd": randf_range(0.6, 1.2), "hp": 1})
	for u in units:
		if u.get("grab", false):
			continue
		var dx: float = pos.x - u.pos.x
		match u.kind:
			"police": u.pos.x += signf(dx) * 34.0 * delta
			"tank": u.pos.x += signf(dx) * 17.0 * delta
			"heli":
				u.pos.x += signf(dx) * 38.0 * delta
				u.pos.y += sin(t * 2.0) * 6.0 * delta
		u.cd -= delta
		u.mf = maxf(0.0, u.get("mf", 0.0) - delta)
		if u.cd <= 0.0 and absf(dx) < 420.0:
			u.cd = maxf(0.5, randf_range(1.1, 2.0) - tier * 0.12)
			u.mf = 0.07
			var origin: Vector2 = u.pos + Vector2(0, -18 if u.kind != "heli" else 4)
			var lead: Vector2 = pos + vel * 0.35
			var speed: float = 120.0 if u.kind == "police" else 165.0
			var dirv := (lead - origin).normalized()
			if eclipse_t > 0.0:
				dirv = dirv.rotated(randf_range(-0.55, 0.55))  # blind in the dark
			shells.append({"pos": origin, "vel": dirv * speed, "life": 4.0,
				"heavy": u.kind != "police"})
	for s in shells:
		s.pos += s.vel * delta
		s.life -= delta
		if s.pos.distance_to(pos) < radius:
			s.life = 0.0
			hp -= (6.0 if s.heavy else 3.0) * dmg_taken_mult
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
	if e is InputEventKey and e.pressed and e.physical_keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://menu.tscn")

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
	hud.biolbl = _label(layer, Vector2(10, 40), 8, Color("#8ad08a"))
	hud.biolbl.text = "BIOMASS"
	hud.bio = _bar(layer, Vector2(10, 52), Color("#5ad06a"))
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
	match character:
		"keraunos":
			help.text = "WASD — fly.  LMB — lightning strike at cursor (3 banked).  RMB — TEMPEST at full storm.  ESC — menu."
		"tzitzimitl":
			help.text = "serpent follows your cursor.  LMB — lance dive (pierces buildings).  RMB — ECLIPSE at full hunger.  ESC — menu."
		_:
			help.text = "WASD — fly.  HOLD LMB — tendrils: chew, snatch, reel.  RMB — arc lash / evolved skill.  R — restart.  ESC — menu."

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
	match character:
		"keraunos":
			hud.biolbl.text = "STORM — RMB TEMPEST at full" if bio < 100.0 else "STORM READY — RMB"
			hud.bio.size.x = 152.0 * clampf(bio / 100.0, 0.0, 1.0)
		"tzitzimitl":
			if eclipse_t > 0.0:
				hud.biolbl.text = "E C L I P S E"
				hud.bio.size.x = 152.0 * eclipse_t / 10.0
			else:
				hud.biolbl.text = "SUN-HUNGER — RMB ECLIPSE at full" if bio < 80.0 else "ECLIPSE READY — RMB"
				hud.bio.size.x = 152.0 * clampf(bio / 80.0, 0.0, 1.0)
		_:
			if bio_stage >= BIO_THRESH.size():
				hud.bio.size.x = 152.0
				hud.biolbl.text = "BIOMASS — MAX"
			else:
				hud.biolbl.text = "BIOMASS"
				var lo: float = 0.0 if bio_stage == 0 else BIO_THRESH[bio_stage - 1]
				hud.bio.size.x = 152.0 * clampf((bio - lo) / (BIO_THRESH[bio_stage] - lo), 0.0, 1.0)

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
	match character:
		"keraunos":
			_draw_keraunos()
		"tzitzimitl":
			_draw_tzitzi()
		_:
			_draw_swarm()
			_draw_tendrils()
	# eclipse: darkness swallows the city
	if eclipse_t > 0.0:
		var ea: float = clampf(eclipse_t / 1.5, 0.0, 1.0) * 0.55
		draw_rect(Rect2(left, -380, right - left, 780), Color(0.01, 0.0, 0.03, ea))
		var moon := Vector2(cam.position.x + 140, -250.0)
		draw_circle(moon, 24, Color(0.02, 0.0, 0.03))
		draw_circle(moon, 26, Color(1.8, 0.9, 0.3, 0.35))
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
	# spore pods pulsing in wounds
	for pod in pods:
		if pod.b == b:
			var pp: Vector2 = Vector2(b.x, -b.h) + pod.p
			if pp.y <= -b.cur_h:
				continue
			var pulse: float = 2.2 + sin(t * 6.0) * 0.8
			draw_circle(pp, pulse + 1.5, Color(0.4, 0.9, 0.3, 0.25))
			draw_circle(pp, pulse, Color(0.9, 1.6, 0.4))
			draw_circle(pp, pulse * 0.5, Color(1.8, 0.6, 0.5))
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
		if p.get("flash", false):
			draw_circle(p.pos, p.size * (1.0 + (0.22 - p.life) * 8.0), Color(p.col.r, p.col.g, p.col.b, a * 0.7))
		else:
			var sz: float = p.get("size", 2.0)
			draw_rect(Rect2(p.pos.x, p.pos.y, sz, sz), Color(p.col.r, p.col.g, p.col.b, a))
	# muzzle flashes
	for u in units:
		if u.get("mf", 0.0) > 0.0:
			draw_circle(u.pos + Vector2(signf(pos.x - u.pos.x) * 12, -22 if u.kind == "tank" else -8),
				3.0, Color(2.4, 2.0, 1.0, 0.8))

func _draw_tendrils() -> void:
	# crosshair
	var ch_col := Color(1.4, 0.5, 0.55, 0.4 if aim_clamped else 0.75)
	draw_line(aim + Vector2(-4, 0), aim + Vector2(-1.5, 0), ch_col, 1)
	draw_line(aim + Vector2(1.5, 0), aim + Vector2(4, 0), ch_col, 1)
	draw_line(aim + Vector2(0, -4), aim + Vector2(0, -1.5), ch_col, 1)
	draw_line(aim + Vector2(0, 1.5), aim + Vector2(0, 4), ch_col, 1)
	# ARC LASH sweep visual (independent of LMB)
	if lash.t_left > 0.0:
		var prog: float = 1.0 - lash.t_left / 0.28
		var sweep_a: float = lash.ang - 1.1 + prog * 2.2
		var lp := pos
		for s3 in range(1, 8):
			var f2 := float(s3) / 7.0
			var wob2: float = sin(f2 * 7.0 + t * 30.0) * 4.0 * f2
			var npt: Vector2 = pos + Vector2.from_angle(sweep_a + wob2 * 0.02) * (78.0 * f2)
			draw_line(lp, npt, Color(0.4, 0.06, 0.1, 1.0 - prog * 0.5), 3.0 * (1.0 - f2) + 1.2)
			draw_line(lp, npt, Color(1.6, 0.3, 0.35, 1.0 - prog * 0.4), 1.8 * (1.0 - f2) + 0.8)
			lp = npt
		draw_circle(lp, 2.5, Color(2.2, 0.7, 0.5, 1.0 - prog))
	if not feeding:
		return
	# three tendrils lashing from body to aim (or to grabbed units)
	var targets: Array = []
	for u in units:
		if u.get("grab", false):
			targets.append(u.pos + Vector2(0, -8))
	if targets.is_empty():
		for i in 3:
			var spread := Vector2(sin(t * 13.0 + i * 2.1) * 5.0, cos(t * 11.0 + i * 1.7) * 5.0)
			targets.append(aim + spread)
	for i in targets.size():
		var tip: Vector2 = targets[i]
		var segs := 9
		var prev := pos
		for s2 in range(1, segs + 1):
			var f := float(s2) / segs
			var base := pos.lerp(tip, f)
			var perp := (tip - pos).normalized().orthogonal()
			var wave: float = sin(f * 9.0 + t * (16.0 + i * 3.0) + i * 2.0) * 6.0 * (1.0 - f) * (0.4 + f)
			var pt := base + perp * wave
			var thick: float = 2.5 * (1.0 - f) + 0.8
			draw_line(prev, pt, Color(0.35, 0.05, 0.1), thick + 1.0)
			draw_line(prev, pt, Color(0.9, 0.15, 0.2), thick)
			prev = pt
		# branch-specific tips
		if branch == "ironmaw":
			draw_circle(prev, 3.6, Color("#2a1420"))
			draw_circle(prev + Vector2(-1, -1), 2.4, Color("#4a2430"))
			draw_circle(prev, 1.2, Color(1.8, 0.5, 0.4))
		elif branch == "gorehook":
			var dirv := (prev - pos).normalized()
			draw_line(prev, prev + dirv.rotated(2.6) * 5.0, Color(1.6, 0.9, 0.8), 1.4)
			draw_line(prev, prev + dirv.rotated(-2.6) * 5.0, Color(1.6, 0.9, 0.8), 1.4)
			draw_circle(prev, 1.4, Color(2.0, 0.5, 0.45))
		elif branch == "spore":
			draw_circle(prev, 2.2, Color(0.6, 1.4, 0.4))
			draw_circle(prev, 1.0, Color(1.8, 0.7, 0.5))
		else:
			draw_circle(prev, 1.8, Color(2.0, 0.5, 0.45))
		if chewing and randf() < 0.4:
			draw_circle(prev, 3.2, Color(1.8, 0.6, 0.4, 0.5))

func _draw_keraunos() -> void:
	# crosshair
	draw_circle(aim, 2.0, Color(0.6, 1.6, 2.0, 0.7))
	draw_arc(aim, 5.0, 0, TAU, 12, Color(0.6, 1.6, 2.0, 0.4), 1.0)
	# bolts
	for b2 in bolts:
		var a: float = b2.t_left / 0.16
		var prev: Vector2 = b2.from
		var segs_n := 7
		for i in range(1, segs_n + 1):
			var f := float(i) / segs_n
			var npt: Vector2 = b2.from.lerp(b2.to, f) + Vector2(randf_range(-9, 9) * (1.0 - f), 0)
			draw_line(prev, npt, Color(1.6, 2.0, 2.6, a), 2.5)
			draw_line(prev, npt, Color(0.7, 1.2, 2.2, a * 0.5), 5.0)
			prev = npt
	# storm cloud body
	for i in 5:
		var off := Vector2(sin(t * 1.3 + i * 2.2) * 8.0, cos(t * 1.7 + i) * 3.0)
		draw_circle(pos + off + Vector2(i * 6 - 12, 0), 9.0, Color(0.09, 0.1, 0.16))
	draw_circle(pos + Vector2(0, -3), 10.0, Color(0.12, 0.13, 0.2))
	# three necks + heads, leaning toward the cursor
	var lean := (aim - pos).normalized() * 10.0
	for h in 3:
		var root := pos + Vector2((h - 1) * 9.0, -4)
		var head := root + Vector2((h - 1) * 13.0, -16) + lean + Vector2(sin(t * 3.0 + h * 2.1) * 3.0, 0)
		var prev := root
		for i in range(1, 5):
			var f := float(i) / 4.0
			var npt := root.lerp(head, f) + Vector2(sin(f * 6.0 + t * 5.0 + h) * 2.5, 0)
			draw_line(prev, npt, Color(0.14, 0.15, 0.24), 3.0 * (1.0 - f) + 1.5)
			prev = npt
		draw_circle(head, 3.0, Color(0.16, 0.18, 0.28))
		draw_circle(head + lean.normalized() * 1.5, 1.2, Color(0.9, 1.9, 2.4))
		if randf() < 0.05:
			var sp := head + Vector2(randf_range(-6, 6), randf_range(-6, 6))
			draw_line(head, sp, Color(1.4, 1.9, 2.4, 0.8), 1.0)
	# charge pips
	for i in 3:
		var lit: bool = bolt_charges >= i + 1
		draw_circle(pos + Vector2(i * 6 - 6, 12), 1.6,
			Color(0.8, 1.8, 2.2) if lit else Color(0.15, 0.2, 0.3))

func _draw_tzitzi() -> void:
	# crosshair
	draw_circle(aim, 2.0, Color(1.8, 1.2, 0.4, 0.7))
	draw_arc(aim, 5.0, 0, TAU, 12, Color(1.8, 1.2, 0.4, 0.4), 1.0)
	var glow := eclipse_t > 0.0
	# body: tapering segments, gold-crested
	for i in range(segs.size() - 1, -1, -1):
		var f := 1.0 - float(i) / segs.size()
		var r: float = 2.0 + f * 5.0
		var p: Vector2 = segs[i]
		var body_c := Color(0.3, 0.08, 0.1) if i % 2 == 0 else Color(0.38, 0.12, 0.08)
		if glow:
			body_c = body_c.lightened(0.15)
		draw_circle(p, r, body_c)
		# feather fins every 3rd segment
		if i % 3 == 0 and i > 1 and (segs[i - 1] - p).length() > 0.8:
			var along: Vector2 = (segs[i - 1] - p).normalized()
			var dirv: Vector2 = along.orthogonal()
			var fin_c := Color(1.7, 1.1, 0.3) if glow else Color(0.9, 0.55, 0.2)
			var tip_len: float = r + 4.0 + f * 3.0
			draw_colored_polygon(PackedVector2Array(
				[p + along * 2.5 + dirv * r * 0.5, p + dirv * tip_len, p - along * 2.5 + dirv * r * 0.5]), fin_c)
			draw_colored_polygon(PackedVector2Array(
				[p + along * 2.5 - dirv * r * 0.5, p - dirv * tip_len, p - along * 2.5 - dirv * r * 0.5]), fin_c)
	# head
	var hd := pos
	var hdir := (aim - pos).normalized()
	draw_circle(hd, 7.5, Color(0.42, 0.13, 0.1))
	draw_circle(hd + hdir * 3.0, 4.5, Color(0.5, 0.18, 0.12))
	# gold crest
	draw_colored_polygon(PackedVector2Array([hd + Vector2(-2, -6), hd + Vector2(2, -13), hd + Vector2(4, -6)]),
		Color(1.9, 1.3, 0.4))
	draw_colored_polygon(PackedVector2Array([hd + Vector2(-6, -4), hd + Vector2(-4, -11), hd + Vector2(0, -5)]),
		Color(1.5, 0.9, 0.3))
	draw_circle(hd + hdir * 4.5, 1.4, Color(2.2, 1.8, 1.0))
	if dive_t > 0.0:
		for i in 4:
			var tp := hd - dive_dir * (i * 8.0 + 6.0) + Vector2(randf_range(-3, 3), randf_range(-3, 3))
			draw_line(tp, tp - dive_dir * 6.0, Color(1.8, 1.0, 0.4, 0.5 - i * 0.1), 1.5)

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
