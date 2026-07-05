extends Node2D
# CALAMITY v4 — The Swarm over New Kowloon.
# Artist facades (Warped City, CC0 by ansimuz) + HDR glow + carved destruction.
# 640x360 native. Ground y=0, up negative. Facades sliced from sheet at load.

var world_w := 4600.0
const TIER_NAMES := ["CALM", "POLICE", "GUARD", "ARMY", "AIR STRIKE", "LAST RESORT"]
const TIER_MULT := [1.0, 1.0, 1.5, 2.0, 3.0, 5.0]

const CITY_DEFS := {
	"kowloon": {"name": "NEW KOWLOON", "tint": Color(1, 1, 1), "defense": 1.0,
		"sky": [Color("#0a0d1f"), Color("#1a1440"), Color("#3d1a52"), Color("#7a2244"), Color("#b03840")],
		"big_chance": 0.28, "gap_min": 14.0, "gap_max": 48.0, "spawn_mult": 1.0,
		"moon": Color(1.55, 0.35, 0.3), "moon_r": 20.0, "lamp": Color(1.9, 1.5, 0.9),
		"aurora": false, "smog": false, "street": Color("#383050"),
		"mix": {"tower": 0.52, "house": 0.12, "shop": 0.2, "church": 0.03, "school": 0.05, "mall": 0.08},
		"facade_sheet": "res://art/near-buildings-bg.png", "house_art": [],
		"far_tex": "res://art/skyline-a.png", "mid_tex": "res://art/buildings-bg.png",
		"far_scale": 0.45, "mid_scale": 1.4},
	"thornspire": {"name": "THORNSPIRE", "tint": Color(0.85, 0.9, 1.35), "defense": 1.35,
		"sky": [Color("#020308"), Color("#070c22"), Color("#101a40"), Color("#1c2c58"), Color("#2a4470")],
		"big_chance": 0.55, "gap_min": 8.0, "gap_max": 26.0, "spawn_mult": 1.0,
		"moon": Color(1.6, 1.7, 2.0), "moon_r": 30.0, "lamp": Color(1.2, 1.7, 2.0),
		"aurora": true, "smog": false, "street": Color("#2a3450"),
		"mix": {"tower": 0.42, "house": 0.3, "shop": 0.08, "church": 0.1, "school": 0.04, "mall": 0.06},
		"facade_sheet": "res://art/cities/thornspire/church-slabs.png",
		"house_art": ["res://art/cities/thornspire/house-a.png", "res://art/cities/thornspire/house-b.png", "res://art/cities/thornspire/house-c.png"],
		"far_tex": "res://art/cities/thornspire/background.png", "mid_tex": "res://art/cities/thornspire/middleground.png",
		"far_scale": 0.5, "mid_scale": 0.36},
	"teotl": {"name": "TEOTL RUINS", "tint": Color(0.9, 1.05, 0.85), "defense": 0.9,
		"sky": [Color("#04100c"), Color("#0a241a"), Color("#124532"), Color("#1e6a42"), Color("#37945a")],
		"big_chance": 0.2, "gap_min": 26.0, "gap_max": 80.0, "spawn_mult": 0.9,
		"moon": Color(1.2, 1.8, 1.3), "moon_r": 17.0, "lamp": Color(2.0, 1.2, 0.4),
		"aurora": false, "smog": false, "street": Color("#2a3828"),
		"mix": {"ziggurat": 0.26, "shrine": 0.34, "house": 0.4},
		"facade_sheet": "res://art/near-buildings-bg.png", "house_art": [],
		"far_tex": "res://art/cities/teotl/back.png", "mid_tex": "res://art/cities/teotl/middle.png",
		"far_scale": 0.55, "mid_scale": 0.7, "mid_hang": true, "cit_kind": "ziggurat"},
	"maren": {"name": "PORT MAREN", "tint": Color(0.85, 0.95, 1.1), "defense": 1.1,
		"sky": [Color("#0a0e16"), Color("#131c2c"), Color("#22344a"), Color("#3a566a"), Color("#587a8a")],
		"big_chance": 0.2, "gap_min": 18.0, "gap_max": 60.0, "spawn_mult": 1.2,
		"moon": Color(1.5, 1.6, 1.7), "moon_r": 26.0, "lamp": Color(1.4, 1.7, 1.9),
		"aurora": false, "smog": false, "street": Color("#2c3844"),
		"mix": {"warehouse": 0.32, "containers": 0.26, "shop": 0.22, "house": 0.2},
		"facade_sheet": "res://art/near-buildings-bg.png", "house_art": [],
		"far_tex": "res://art/cities/maren/far-grounds.png", "mid_tex": "res://art/cities/maren/sea.png",
		"far_scale": 0.8, "mid_scale": 0.9, "cit_kind": "warehouse"},
	"ashport": {"name": "ASHPORT", "tint": Color(1.18, 0.82, 0.5), "defense": 0.75,
		"sky": [Color("#0f0a06"), Color("#241408"), Color("#42250c"), Color("#663a10"), Color("#8a5416")],
		"big_chance": 0.10, "gap_min": 24.0, "gap_max": 70.0, "spawn_mult": 1.7,
		"moon": Color(1.3, 0.7, 0.25), "moon_r": 13.0, "lamp": Color(1.9, 1.1, 0.4),
		"aurora": false, "smog": true, "street": Color("#403020"),
		"mix": {"tower": 0.42, "house": 0.2, "shop": 0.14, "church": 0.02, "school": 0.06, "mall": 0.16},
		"facade_sheet": "res://art/cities/ashport/factories.png", "house_art": [],
		"far_tex": "res://art/cities/ashport/far.png", "mid_tex": "res://art/cities/ashport/scaffolds.png",
		"far_scale": 0.9, "mid_scale": 1.0},
}
const END_TEXT := {
	"swarm": {"win": "CITY RAZED", "win_s": "the swarm moves on, fat with light and marrow.",
		"lose": "THE SWARM IS SCATTERED", "lose_s": "a million dying embers on the wind."},
	"keraunos": {"win": "THE STORM PASSES", "win_s": "nothing stands. the thunder forgets this place.",
		"lose": "THE STORM IS GROUNDED", "lose_s": "nine throats fall silent."},
	"tzitzimitl": {"win": "THE SUN SETS FOREVER", "win_s": "the serpent coils around a darkened world.",
		"lose": "THE SERPENT IS BROKEN", "lose_s": "dawn crawls back over the wreckage."},
	"drowned": {"win": "THE CITY DROWNS", "win_s": "the water keeps what it takes.",
		"lose": "THE DEEP RECEDES", "lose_s": "the tide goes out and does not return."},
	"rider": {"win": "A HARVEST OF SILENCE", "win_s": "everything that lived here walks behind him now.",
		"lose": "THE RIDER FALLS", "lose_s": "the pale horse wanders on, riderless."},
}

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
var lamps: Array = []            # destructible street lights {x, dead}
var props: Array = []            # destructible street furniture {x, tex, dead}
var critters: Array = []         # pigeons, dogs, pigs {kind, pos, vx, vy, panic, dead, flying}
var prop_texs: Array = []
var banner_imgs: Array = []
var spawn_cd := 3.0

var facades: Array = []     # sliced Images from the sheet
var tex_sky_a: Texture2D
var tex_sky_b: Texture2D
var tex_mid: Texture2D
var cam: Camera2D
var swarm_light: PointLight2D
var hud := {}
# --- premium juice ---
var ui_font: FontFile
var shown_score := 0.0
var disp_hp := 100.0
var combo_pulse := 0.0
var prev_combo := 1.0
var hitstop_until := 0
var letterbox := 0.0
# arrival cinematic
const INTRO_LEN := 2.6
var intro_t := 0.0
var intro_from := Vector2.ZERO
var intro_to := Vector2.ZERO
const ARRIVE_LINES := {
	"swarm": "THE SWARM DESCENDS",
	"keraunos": "KERAUNOS COMES WITH THE STORM",
	"tzitzimitl": "TZITZIMITL UNCOILS ACROSS THE SKY",
	"drowned": "THE DROWNED ONE RISES",
	"rider": "THE PALE RIDER IS AT THE GATES",
}
var ambient: Array = []          # drifting embers/dust
var frags: Array = []            # tumbling building fragments
var flash_t := 0.0               # white screen flash on big events
var impact_frames := 0           # hard white frames on the biggest hits
var milestone_i := 0             # devour milestones fired
var over_t := 0.0                # time since the end screen fell
var end_label := ""              # crusade end-card label (drawn, not a Button)
var end_win := false
var end_pending := false         # clicked before the card armed — fire on arm
var fire_lights: Array = []      # pooled PointLight2D for blazes
var flash_light: PointLight2D
var flak_cd := 3.0
var post_mat: ShaderMaterial
var shock_p := 1.0               # screen ripple progress (>=1 idle)
# --- essence: each god feeds on something different ---
var essence_eaten := 0.0         # lifetime total -> growth
var growth := 1.0                # body scale multiplier
var growth_mult := 1.0           # stage scale: prologue whelp / act-1 ramp / relics
# --- crusade node state ---
var node_kind := "city"          # hamlet | town | city | capital
var node_fate := ""              # act-2 road fate tag
var node_militia := false        # act-1 early nodes: farmers, not armies
var node_place := ""             # named settlement
var lord_name := ""              # decapitation target
var node_arch := "street"        # layout archetype
var night_base := 0.12           # time-of-day roll
var storm_node := false          # weather roll
var plaza_x := -1.0
var tier_cap := 5
var objective := "raze"
var obj_timer := 0.0
var obj_started := false
var people_total := 0
var people_killed := 0
var has_citadel := true
var essence_mult := 1.0
var heal_mult := 1.0
var tribute_mult := 1.0
var specials_total := 0
var specials_down := 0
var essence_start := 0.0
# bonus objective + capital doomsday + prologue
var bonus_obj := ""
var bonus_met := false
var hits_taken := 0
var unit_kills := 0
var run_time := 0.0
var is_capital := false
var doom_cd := 45.0
var doom_p := Vector2.ZERO
var doom_t := 0.0
var prologue := false
var prol_beats: Array = []
var prol_i := 0
var madden_count := 0
var risen_count := 0
var lamps_down := 0
var buildings_razed := 0
var caption_layer: CanvasLayer = null
const DIET := {
	"swarm": {"flesh": 2.0, "fear": 0.2, "light": 0.3, "charge": 0.2, "death": 0.6, "mass": 1.0},
	"keraunos": {"flesh": 0.3, "fear": 0.2, "light": 0.8, "charge": 2.2, "death": 0.2, "mass": 1.0},
	"tzitzimitl": {"flesh": 0.3, "fear": 0.2, "light": 2.4, "charge": 0.8, "death": 0.2, "mass": 0.8},
	"drowned": {"flesh": 0.4, "fear": 2.4, "light": 0.2, "charge": 0.2, "death": 0.8, "mass": 0.7},
	"rider": {"flesh": 0.5, "fear": 0.6, "light": 0.1, "charge": 0.1, "death": 2.6, "mass": 0.6},
}

func _feed(kind: String, amt: float) -> void:
	var mult: float = DIET.get(character, DIET["swarm"]).get(kind, 1.0) * essence_mult
	var gain: float = amt * mult
	bio += gain
	meter = minf(100.0, meter + gain * 0.55)
	essence_eaten += gain
	# DREAD MANTLE graft — fear knits the body
	if kind == "fear" and "dreadmantle" in Global.grafts:
		hp = minf(100.0, hp + gain * 0.25)
	# growth: the more you consume of YOUR hunger, the bigger you get
	growth = minf(growth_cap, growth_mult * (1.0 + minf(0.75, essence_eaten / 900.0)))

var _shot_frames := 0

func _ready() -> void:
	randomize()
	character = Global.character
	city_def = CITY_DEFS.get(Global.city, CITY_DEFS["kowloon"])
	_apply_campaign()
	if character == "tzitzimitl":
		for i in 16:
			segs.append(pos)
		_bake_serpent()
	if Global.mode == "skirmish":
		match Global.mutator:
			"mobilization":
				city_def = city_def.duplicate()
				city_def.spawn_mult *= 1.7
			"famine":
				essence_mult = 0.75
	_setup_env()
	_setup_sfx()
	Global.music("battle", 0)
	_slice_facades()
	_build_city()
	for i in 60:
		motes.append({"a": randf() * TAU, "d": randf_range(0.15, 1.0), "s": randf_range(0.8, 3.0), "o": randf() * TAU})
	cam = Camera2D.new()
	cam.position = Vector2(pos.x, -100)
	add_child(cam)
	cam.make_current()
	match character:
		"keraunos":
			# pull back — he is COLOSSAL. villages vanish at 0.55, so pull back less there
			cam.zoom = Vector2(0.72, 0.72) if node_kind in ["hamlet", "town", "prologue"] else Vector2(0.55, 0.55)
			radius = 52.0
			dmg_taken_mult = 0.7
			pos.y = -190.0
		"tzitzimitl":
			cam.zoom = Vector2(0.78, 0.78)
			radius = 16.0
		"swarm":
			cam.zoom = Vector2(0.85, 0.85)
			radius = 22.0
			for i in 40:
				motes.append({"a": randf() * TAU, "d": randf_range(0.15, 1.0), "s": randf_range(0.8, 3.0), "o": randf() * TAU})
		"drowned":
			cam.zoom = Vector2(0.8, 0.8)
			radius = 24.0
			dmg_taken_mult = 0.6
			pos = Vector2(560, -12)
		"rider":
			cam.zoom = Vector2(0.85, 0.85)
			radius = 18.0
			dmg_taken_mult = 0.85
			pos = Vector2(560, -12)
	swarm_light = PointLight2D.new()
	swarm_light.texture = _radial_tex(128)
	swarm_light.color = Color(1.0, 0.25, 0.3)
	swarm_light.energy = 1.1
	swarm_light.texture_scale = 2.2
	add_child(swarm_light)
	_build_hud()
	if prologue:
		# cold open: the origin lines fall one by one before the first beat
		var op: Array = PROLOGUE_OPEN.get(character, [])
		caption_queue = op.slice(1) + [prol_beats[0].cap]
		_caption(op[0] if not op.is_empty() else prol_beats[0].cap, false)
	elif OS.get_environment("CAL_SHOT") == "" or OS.get_environment("CAL_INTRO") != "":
		_start_intro()

func _bake_serpent() -> void:
	# hand-baked pixel sprites, drawn once — outline + shading like real sheet art
	var OUT := Color("#120810")
	var EM1 := Color("#0e4a4e")   # deep turquoise (aztec jade)
	var EM2 := Color("#1a7a78")   # turquoise
	var EM3 := Color("#3ab8a8")   # bright turquoise
	var GLD := Color("#c86428")   # terracotta
	var GLD2 := Color("#f0e6d0")  # bone white
	var RED := Color("#c02818")   # sacrificial red
	# --- head 26x20, faces +X ---
	var h := Image.create(26, 20, false, Image.FORMAT_RGBA8)
	for px in [[4,8,16,8,EM2],[6,7,14,4,EM3],[4,12,14,4,EM1],[16,9,7,3,EM2],[20,10,4,2,EM1],
			[6,6,10,2,EM3],[8,14,8,3,GLD],[10,16,6,2,GLD2]]:
		h.fill_rect(Rect2i(px[0], px[1], px[2], px[3]), px[4])
	# bone fang mask ringing the jaw — the aztec serpent's teeth
	h.fill_rect(Rect2i(17, 12, 7, 2), GLD2)
	for fx2 in [17, 19, 21, 23]:
		h.set_pixel(fx2, 14, GLD2)
	h.fill_rect(Rect2i(19, 5, 4, 1), GLD2)   # brow bone
	# turquoise mosaic glints
	h.set_pixel(9, 9, EM3)
	h.set_pixel(12, 11, EM3)
	h.set_pixel(7, 12, EM3)
	# eye
	h.fill_rect(Rect2i(14, 9, 3, 3), OUT)
	h.fill_rect(Rect2i(15, 10, 2, 1), Color(2.4, 1.5, 0.3))
	# THE RUFF — radial feather collar behind the skull, Quetzalcoatl's crown
	for c in [[0, 0, 7, 2], [0, 3, 8, 2], [0, 6, 6, 2], [0, 16, 7, 2], [1, 18, 6, 2], [0, 12, 5, 2]]:
		h.fill_rect(Rect2i(c[0], c[1], c[2], c[3]), RED)
		h.fill_rect(Rect2i(c[0], c[1], c[2] - 2, 1), Color(1.3, 0.35, 0.2))
		h.set_pixel(c[0] + c[2] - 1, c[1], EM3)   # turquoise tips
	_outline(h, OUT)
	serp_head = ImageTexture.create_from_image(h)
	# --- body segment 14x16, plume on top ---
	var b := Image.create(14, 16, false, Image.FORMAT_RGBA8)
	b.fill_rect(Rect2i(2, 6, 10, 7), EM2)
	b.fill_rect(Rect2i(3, 6, 8, 2), EM3)
	b.fill_rect(Rect2i(2, 11, 10, 2), EM1)
	b.fill_rect(Rect2i(3, 13, 8, 2), GLD2)    # bone belly scutes
	b.set_pixel(5, 13, GLD)
	b.set_pixel(9, 13, GLD)
	# dorsal plume — red feathers, turquoise tips
	b.fill_rect(Rect2i(5, 1, 2, 5), RED)
	b.set_pixel(5, 1, EM3)
	b.fill_rect(Rect2i(8, 2, 2, 4), RED)
	b.set_pixel(8, 2, EM3)
	b.fill_rect(Rect2i(3, 3, 2, 3), GLD)
	_outline(b, OUT)
	serp_body = ImageTexture.create_from_image(b)
	# --- wing 30x22, root at bottom-left ---
	var w := Image.create(30, 22, false, Image.FORMAT_RGBA8)
	for fb in 4:
		var ang := 0.5 + fb * 0.32
		for L in 22 - fb * 3:
			var px2 := int(2 + cos(ang) * L)
			var py2 := int(19 - sin(ang) * L)
			if px2 >= 0 and px2 < 29 and py2 >= 1 and py2 < 21:
				var fc: Color = GLD if fb % 2 == 0 else EM2
				w.set_pixel(px2, py2, fc)
				w.set_pixel(px2 + 1, py2, fc)
				if L > 14 - fb * 3:
					w.set_pixel(px2, py2 - 1, GLD2 if fb % 2 == 0 else EM3)
	_outline(w, OUT)
	serp_wing = ImageTexture.create_from_image(w)

func _outline(img: Image, col: Color) -> void:
	var wd := img.get_width()
	var ht := img.get_height()
	var src := Image.new()
	src.copy_from(img)
	for y in ht:
		for x in wd:
			if src.get_pixel(x, y).a > 0.1:
				continue
			var edge := false
			for off in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
				var nx: int = x + off[0]
				var ny: int = y + off[1]
				if nx >= 0 and nx < wd and ny >= 0 and ny < ht and src.get_pixel(nx, ny).a > 0.1:
					edge = true
					break
			if edge:
				img.set_pixel(x, y, col)

func _setup_sfx() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		sfx_players.append(p)
	sfx_bank["boom"] = _synth_mix(1.1, [[9.0, 52.0, 0.75, 0.9, 0.0], [30.0, 0.0, 0.0, 0.7, 0.0], [2.4, 0.0, 0.0, 0.35, 0.05]])
	sfx_bank["thunder"] = _synth_mix(1.6, [[3.5, 52.0, 0.65, 0.9, 0.0], [40.0, 0.0, 0.0, 0.8, 0.0], [1.4, 0.0, 0.0, 0.4, 0.25]])
	sfx_bank["skyfall"] = _synth_mix(2.0, [[2.2, 40.0, 0.8, 1.0, 0.0], [24.0, 0.0, 0.0, 0.7, 0.0], [1.1, 0.0, 0.0, 0.45, 0.3]])
	sfx_bank["groan"] = _synth_mix(1.5, [[1.6, 68.0, 0.8, 0.7, 0.0], [8.0, 210.0, 0.5, 0.25, 0.3], [3.0, 0.0, 0.0, 0.3, 0.1]])
	sfx_bank["crush"] = _synth_mix(1.4, [[11.0, 48.0, 0.8, 1.0, 0.0], [26.0, 0.0, 0.0, 0.8, 0.0], [1.8, 0.0, 0.0, 0.45, 0.08]])
	sfx_bank["bite"] = _synth(0.07, 45.0, 0.0, 0.0)
	sfx_bank["lash"] = _synth(0.22, 14.0, 0.0, 0.0)
	sfx_bank["grab"] = _synth(0.1, 30.0, 140.0, 0.3)
	sfx_bank["crumble"] = _synth_mix(1.8, [[3.0, 45.0, 0.4, 0.8, 0.0], [1.6, 0.0, 0.0, 0.5, 0.15], [14.0, 0.0, 0.0, 0.5, 0.0]])
	sfx_bank["pick"] = _synth(0.18, 10.0, 660.0, 0.8)
	sfx_bank["eclipse"] = _synth(1.6, 1.4, 48.0, 0.9)
	sfx_bank["hit"] = _synth(0.13, 22.0, 200.0, 0.5)
	sfx_bank["bell"] = _synth(1.8, 1.2, 190.0, 0.92)
	sfx_bank["glass"] = _synth(0.3, 16.0, 2400.0, 0.25)
	sfx_bank["shing"] = _synth_mix(0.45, [[16.0, 1700.0, 0.85, 0.55, 0.0], [34.0, 0.0, 0.0, 0.4, 0.0], [9.0, 2500.0, 0.6, 0.2, 0.04]])
	sfx_bank["siren"] = _synth_mix(2.4, [[1.0, 640.0, 0.9, 0.3, 0.0], [1.0, 672.0, 0.9, 0.3, 0.0]])
	sfx_bank["gull"] = _synth_mix(0.7, [[6.0, 1040.0, 0.92, 0.28, 0.0], [8.0, 780.0, 0.85, 0.18, 0.22]])
	sfx_bank["chirp"] = _synth_mix(0.25, [[26.0, 2300.0, 0.95, 0.22, 0.0], [30.0, 2600.0, 0.9, 0.15, 0.09]])
	sfx_bank["clank"] = _synth_mix(0.6, [[13.0, 260.0, 0.7, 0.3, 0.0], [22.0, 410.0, 0.6, 0.2, 0.12]])
	sfx_bank["horn"] = _synth_mix(1.1, [[2.6, 186.0, 0.85, 0.26, 0.0], [2.6, 140.0, 0.8, 0.18, 0.05]])
	sfx_bank["scream"] = _synth_mix(0.8, [[5.0, 920.0, 0.9, 0.2, 0.0], [7.0, 1180.0, 0.85, 0.12, 0.1]])
	amb_player = AudioStreamPlayer.new()
	amb_player.volume_db = -20.0
	add_child(amb_player)
	sfx_bank["whisper"] = _synth_mix(0.9, [[4.0, 0.0, 0.0, 0.32, 0.0], [6.0, 340.0, 0.3, 0.18, 0.15], [3.0, 170.0, 0.4, 0.14, 0.3]])
	# the swarm hums — a living buzz that grows with the body
	if character == "swarm":
		buzz_player = AudioStreamPlayer.new()
		var buzz := _synth_loop(2.0)
		buzz_player.stream = buzz
		buzz_player.volume_db = -60.0
		buzz_player.pitch_scale = 2.6
		add_child(buzz_player)
		buzz_player.play()

func _synth_mix(dur: float, layers: Array) -> AudioStreamWAV:
	# layered one-shots: each layer = [decay, tone_hz, tone_mix, gain, delay]
	var rate := 22050
	var n := int(dur * rate)
	var acc := PackedFloat32Array()
	acc.resize(n)
	for L in layers:
		var decay: float = L[0]
		var tone_hz: float = L[1]
		var tone_mix: float = L[2]
		var gain: float = L[3]
		var d0: int = int(float(L[4]) * rate)
		var lp := 0.0
		for i in range(d0, n):
			var ts: float = float(i - d0) / rate
			var env: float = exp(-ts * decay)
			var noise: float = randf() * 2.0 - 1.0
			lp = lp * 0.82 + noise * 0.18
			var s: float = lp * (1.0 - tone_mix)
			if tone_hz > 0.0:
				s += sin(TAU * tone_hz * ts * (1.0 - ts * 0.15)) * tone_mix
			acc[i] += s * env * gain
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var v := int(clampf(acc[i], -1.0, 1.0) * 30000.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

func _synth_loop(dur: float) -> AudioStreamWAV:
	# looped wind: heavy low-passed noise with a slow swell
	var rate := 22050
	var n := int(dur * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	var lp := 0.0
	var lp2 := 0.0
	for i in n:
		var ts: float = float(i) / rate
		var noise: float = randf() * 2.0 - 1.0
		lp = lp * 0.96 + noise * 0.04
		lp2 = lp2 * 0.99 + lp * 0.01
		var swell: float = 0.6 + 0.4 * sin(TAU * ts / dur)   # loops seamlessly
		var v := int(clampf(lp2 * swell * 3.0, -1.0, 1.0) * 22000.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = n
	return wav

func _synth(dur: float, decay: float, tone_hz: float, tone_mix: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	var lp := 0.0
	for i in n:
		var ts: float = float(i) / rate
		var env: float = exp(-ts * decay)
		var noise: float = randf() * 2.0 - 1.0
		lp = lp * 0.82 + noise * 0.18   # cheap low-pass so it rumbles, not hisses
		var s: float = lp * (1.0 - tone_mix)
		if tone_hz > 0.0:
			s += sin(TAU * tone_hz * ts * (1.0 - ts * 0.15)) * tone_mix
		s = clampf(s * env, -1.0, 1.0)
		var v := int(s * 30000.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

var _sfx_i := 0
func _sfx(name: String) -> void:
	if not sfx_bank.has(name):
		return
	var p: AudioStreamPlayer = sfx_players[_sfx_i % sfx_players.size()]
	_sfx_i += 1
	p.stream = sfx_bank[name]
	p.pitch_scale = randf_range(0.88, 1.12)
	p.play()

func _apply_campaign() -> void:
	if Global.mode != "crusade":
		return
	var p: Dictionary = Global.node_params
	node_kind = p.get("kind", "city")
	tier_cap = int(p.get("tier_cap", 5))
	objective = p.get("objective", "raze")
	world_w = float(p.get("world_w", 4600.0))
	threat = float(p.get("alert", 0)) * 7.0
	threat = minf(100.0, threat + float(p.get("threat_bonus", 0.0)))
	is_capital = p.get("capital", false)
	# per-node rolls: same province, different place
	var nseed: int = int(p.get("map_node", 0)) * 31 + Global.razed.size() * 7
	if node_kind in ["town", "city", "capital"]:
		node_arch = ["street", "plaza", "garrison", "warrens"][nseed % 4]
	night_base = [0.12, 0.32, 0.62][nseed % 3]
	storm_node = nseed % 4 == 1
	city_def = city_def.duplicate()
	var tshift: float = 0.94 + float(nseed % 7) * 0.02
	city_def.tint = Color(city_def.tint.r * tshift, city_def.tint.g * (2.0 - tshift) * 0.5 + city_def.tint.g * 0.5, city_def.tint.b * (1.88 - tshift * 0.94))
	# the road's fate colors the battle
	node_fate = p.get("fate", "")
	node_militia = p.get("militia", false)
	node_place = str(p.get("place", ""))
	match node_fate:
		"richfeeding": essence_mult *= 1.5
		"garrisoned":
			city_def = city_def.duplicate()
			city_def.defense *= 1.3
			city_def.spawn_mult *= 1.2
			tribute_mult *= 1.5
		"stormcrossing":
			if character in ["keraunos", "tzitzimitl"]:
				essence_mult *= 1.5
		"titheroad": tribute_mult *= 1.75
		"cache": meter = maxf(meter, 60.0)
	# faithful met on the road march with you
	for i in int(p.get("allies_bonus", 0)):
		allies.append({"kind": "cultist", "pos": Vector2(pos.x + 30.0 + i * 16.0, -4),
			"hp": 3, "cd": 0.0, "life": 1e9})
	# THE ROAR has been heard — something is coming to this battle
	growth_cap = 1.75 + 0.35 * Global.heralds_slain.size()
	if Global.act == 2 and node_kind != "prologue" and Global.heralds_slain.size() < Global.herald_queue.size() \
			and Global.roar >= Global.ROAR_GATES[Global.heralds_slain.size()]:
		herald_due = Global.herald_queue[Global.heralds_slain.size()]
		herald_timer = 40.0
	# stolen powers persist
	for g in Global.grafts:
		match g:
			"oldcrown":
				growth_cap += 0.15
				essence_mult *= 1.15
	if is_capital:
		city_def = city_def.duplicate()
		city_def.defense *= 1.4
		city_def.spawn_mult *= 1.4
	# bonus objective — one extra dare per act-2 node
	if Global.act == 2 and node_kind != "prologue" and objective != "raze":
		var pool := ["untouchable", "warlord", "swift", "pyromaniac"]
		if character in ["drowned", "rider"]:
			pool.append("shepherd")
		bonus_obj = pool[randi() % pool.size()]
	if node_kind == "prologue":
		prologue = true
		has_citadel = false
		tier_cap = 0
		growth_mult = 0.5
		growth = 0.5
		_setup_prologue()
		return
	# carried body: evolutions + growth persist across the crusade
	branch = Global.c_branch
	nodes = Global.c_nodes.duplicate()
	bio_stage = Global.c_bio_stage
	essence_eaten = Global.c_essence
	# act 1 starts you SMALL — a whisper of what you'll be
	if Global.act == 1:
		growth_mult = [0.7, 0.8, 0.88, 0.94, 1.0][mini(4, Global.razed.size())]
	_apply_branch_stats()
	# relics
	for rl in Global.relics:
		match rl:
			"oldhunger":
				if bio_stage == 0:
					bio = BIO_THRESH[0]
			"thickhide": dmg_taken_mult *= 0.85
			"darkomen": meter = 50.0
			"locustyears": essence_mult = 1.25
			"dreadname": threat_mult *= 0.8
			"warfeast": heal_mult = 2.0
			"longshadow": growth_mult += 0.1
			"carrionwind": tribute_mult = 1.3
	growth = minf(growth_cap, growth_mult * (1.0 + minf(0.75, essence_eaten / 900.0)))
	# small settlements: no citadel, gentler mixes
	essence_start = essence_eaten
	if objective == "decapitation":
		obj_timer = 150.0
		lord_name = ["BARON VELK", "DUKE MORRAINE", "MARSHAL KOTT", "LADY VESH",
			"GOVERNOR HALE"][int(p.get("map_node", 0)) % 5]
	if node_kind in ["hamlet", "town"]:
		has_citadel = false
		city_def = city_def.duplicate()
		city_def.mix = {"house": 0.55, "shop": 0.3, "church": 0.08, "school": 0.07} if node_kind == "town" \
			else {"house": 0.75, "shop": 0.25}
		city_def.spawn_mult *= 0.7 if node_kind == "town" else 0.45

const HERALD_DEFS := {
	# ai: eat | hunt | cast | spawn | leech — the verb each outsider breaks the game with
	"grazer": {"name": "THE GRAZER", "hp": 200, "ai": "eat", "scale": 2.2, "col": Color(0.55, 0.5, 0.3),
		"graft": "gravitymaw", "gname": "GRAVITY MAW", "gdesc": "every collapse hurls shrapnel at your enemies"},
	"stalker": {"name": "THE STALKER", "hp": 160, "ai": "hunt", "scale": 1.6, "col": Color(0.25, 0.2, 0.4),
		"spd": 260.0, "graft": "predatorshift", "gname": "PREDATOR SHIFT", "gdesc": "being struck quickens you"},
	"hollowking": {"name": "THE HOLLOW KING", "hp": 220, "ai": "cast", "scale": 2.4, "col": Color(0.45, 0.3, 0.2),
		"from_below": true, "graft": "faultline", "gname": "FAULTLINE", "gdesc": "your razings crack the earth beneath the army"},
	"gatecrash": {"name": "THE GATECRASH", "hp": 170, "ai": "spawn", "scale": 1.8, "col": Color(0.6, 0.25, 0.7),
		"teleports": true, "graft": "riftstep", "gname": "RIFT STEP", "gdesc": "mortal wounds tear you elsewhere instead"},
	"echo": {"name": "THE ECHO", "hp": 190, "ai": "hunt", "scale": 1.0, "col": Color(0.8, 0.3, 0.35),
		"spd": 200.0, "mirror": true, "graft": "paradox", "gname": "PARADOX", "gdesc": "at death's edge, your echo fights beside you"},
	"seraph": {"name": "THE SERAPH ASCENDANT", "hp": 180, "ai": "cast", "scale": 1.9, "col": Color(1.6, 1.5, 1.0),
		"flies": true, "graft": "haloofruin", "gname": "HALO OF RUIN", "gdesc": "a stolen smite falls on the thickest column"},
	"tide": {"name": "THE TIDE OF TEETH", "hp": 210, "ai": "spawn", "scale": 2.0, "col": Color(0.5, 0.15, 0.2),
		"graft": "spawnbrood", "gname": "SPAWN BROOD", "gdesc": "your kills birth broodlings that fight for you"},
	"rustsaint": {"name": "THE RUST SAINT", "hp": 240, "ai": "eat", "scale": 2.1, "col": Color(0.5, 0.35, 0.2),
		"armors": true, "graft": "assimilate", "gname": "ASSIMILATE", "gdesc": "every razing knits your body back together"},
	"veil": {"name": "THE MOURNING VEIL", "hp": 150, "ai": "leech", "scale": 1.7, "col": Color(0.4, 0.45, 0.6),
		"graft": "dreadmantle", "gname": "DREAD MANTLE", "gdesc": "the fear you sow mends your wounds"},
	"firstborn": {"name": "THE FIRSTBORN CALAMITY", "hp": 300, "ai": "hunt", "scale": 3.0, "col": Color(0.2, 0.16, 0.2),
		"spd": 120.0, "slam": true, "graft": "oldcrown", "gname": "OLD CROWN", "gdesc": "the oldest hunger: bigger cap, richer feeding"},
}

const PROLOGUE_OPEN := {
	"swarm": ["The drought year, the villages prayed the locusts would pass them by.",
		"Something in the cloud heard. Something in the cloud answered."],
	"keraunos": ["The mountain shrines went cold. No one fed the storm its honors.",
		"High in the anvil clouds, one throat woke. Then another. Then nine."],
	"tzitzimitl": ["They dug the temple out of the jungle and lit it with floodlights.",
		"The seal had one purpose. The archaeologists called it decoration."],
	"drowned": ["The bay gave them fish for nine generations. They gave it poison.",
		"The lighthouse keeper heard singing under the waterline. He opened the sea gate."],
	"rider": ["When the plague came, the village burned its sick to save itself.",
		"The ash was still warm when the hoofbeats started."],
}
const PROLOGUE_DEFS := {
	"swarm": {"city": "ashport", "beats": [
		{"goal": "people", "n": 8, "cap": "The drought year, the villages prayed the locusts would pass.\nSomething in the cloud heard. EAT."},
		{"goal": "essence", "n": 50, "cap": "The cloud tasted prayer, and found it thin.\nIt tasted the harvest. It tasted THEM."},
		{"goal": "buildings", "n": 2, "cap": "By dawn there was no village.\nBy dusk, no word for what the cloud had become."}]},
	"keraunos": {"city": "thornspire", "beats": [
		{"goal": "buildings", "n": 1, "cap": "The mountain shrines went cold. No one fed the storm.\nSTRIKE the shrine that forgot you."},
		{"goal": "lamps", "n": 3, "cap": "One throat woke. Snuff their little lights —\nlet them remember what light IS."},
		{"goal": "essence", "n": 50, "cap": "Nine throats now. The valley below\nstill owes nine hundred winters of candles."}]},
	"tzitzimitl": {"city": "teotl", "beats": [
		{"goal": "lamps", "n": 4, "cap": "They dug the temple from the jungle and lit it with floodlights.\nThe lights began to disappear. BE WHY."},
		{"goal": "buildings", "n": 1, "cap": "Longer now. Brighter inside.\nThe dig site's generators sing to you. Pierce the camp."},
		{"goal": "essence", "n": 50, "cap": "The seal had one purpose.\nOverhead, the sun has noticed you. Good."}]},
	"drowned": {"city": "maren", "beats": [
		{"goal": "essence", "n": 25, "cap": "Nine generations of fish. One generation of poison.\nRise. Let the harbor SEE you, and drink their fear."},
		{"goal": "madden", "n": 2, "cap": "The harbor watch has come.\nWhisper to them. Break their little minds."},
		{"goal": "kills", "n": 2, "cap": "They turn on each other so easily.\nBelow the waterline, something old approves."}]},
	"rider": {"city": "thornspire", "beats": [
		{"goal": "people", "n": 6, "cap": "They burned their sick to save the village.\nRide through. Your fog does the rest."},
		{"goal": "risen", "n": 4, "cap": "The ash was still warm when the hoofbeats started.\nThe dead hear them too. They RISE."},
		{"goal": "essence", "n": 50, "cap": "Nothing that burns is ever really gone.\nThe village learns this now. The world learns next."}]},
}

func _start_intro() -> void:
	intro_t = INTRO_LEN
	intro_to = pos
	var off := Vector2(-420.0, 0.0)
	match character:
		"keraunos": off = Vector2(-460.0, -110.0)
		"tzitzimitl": off = Vector2(-460.0, -70.0)
		"drowned": off = Vector2(-300.0, 46.0)
		"rider": off = Vector2(-360.0, 0.0)
	intro_from = intro_to + off
	pos = intro_from
	vel = Vector2.ZERO
	letterbox = 1.0
	hud.msg.text = node_place if node_place != "" else city_def.get("name", Global.city.to_upper())
	hud.sub.text = ARRIVE_LINES.get(character, "")
	if Global.mode == "crusade":
		hud.stats.text = {
			"raze": "Leave nothing standing.",
			"blackout": "SIEGEBREAK: the battery, the mast, the armory. Break all three.",
			"extinction": "THE RECKONING: no survivors. They will run for the shelters. Crack them.",
			"decapitation": lord_name + " rules here. End the bloodline before the army ends you.",
			"terror": "Push them to LAST RESORT — then survive what falls.",
			"feast": "Gorge before nightfall or starve in the dark.",
		}.get(objective, "")
	cam.position = Vector2(clampf(intro_from.x, 320.0, world_w - 320.0), -105)

func _setup_prologue() -> void:
	var pd: Dictionary = PROLOGUE_DEFS[character]
	Global.city = pd.city
	city_def = CITY_DEFS[pd.city].duplicate()
	city_def.mix = {"house": 0.62, "shop": 0.24, "shrine": 0.14} if character == "keraunos" \
		else {"house": 0.7, "shop": 0.3}
	city_def.spawn_mult = 0.0
	world_w = 1500.0
	prol_beats = pd.beats
	essence_start = 0.0
	# the drowned one's vignette needs a harbor watch to break
	if character == "drowned":
		meter = 40.0

func _prologue_check() -> void:
	if prol_i >= prol_beats.size() or caption_layer != null:
		return
	var beat: Dictionary = prol_beats[prol_i]
	# madden/kills beats need live minds — if the watch is gone, more come looking
	if beat.goal in ["madden", "kills"]:
		var live := 0
		for u in units:
			if u.kind in ["police", "soldier"] and not u.get("mad", false) and not u.get("dead", false):
				live += 1
		if live == 0:
			for i in 3:
				units.append({"kind": "police", "pos": Vector2(pos.x + 120.0 + i * 26.0, 0),
					"cd": randf_range(0.6, 1.2), "hp": 1})
	var progress: float = 0.0
	match beat.goal:
		"people": progress = people_killed
		"lamps": progress = lamps_down
		"buildings": progress = buildings_razed
		"essence": progress = essence_eaten - essence_start
		"madden": progress = madden_count
		"kills": progress = unit_kills
		"risen": progress = risen_count
	hud.obj.text = "%s — %d / %d" % [beat.goal.to_upper(), int(progress), beat.n]
	if progress >= beat.n:
		prol_i += 1
		growth_mult = minf(1.0, growth_mult + 0.18)
		growth = minf(growth_cap, growth_mult * (1.0 + minf(0.75, essence_eaten / 900.0)))
		_sfx("pick")
		if prol_i < prol_beats.size():
			_caption(prol_beats[prol_i].cap, false)
		else:
			_caption("IT HAS A NAME NOW.\nAnd the world has a problem.", true)

var caption_queue: Array = []
var caption_final := false

func _caption_next() -> void:
	if not caption_queue.is_empty():
		_caption(caption_queue.pop_front(), false)

func _caption(text: String, final: bool) -> void:
	caption_final = final
	caption_layer = CanvasLayer.new()
	caption_layer.layer = 96
	add_child(caption_layer)
	var dim := ColorRect.new()
	dim.size = Vector2(640, 360)
	dim.color = Color(0.02, 0.0, 0.05, 0.82)
	caption_layer.add_child(dim)
	var l := _label(caption_layer, Vector2(60, 140), 12, Color(0.9, 0.85, 0.9))
	l.size = Vector2(520, 80)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.text = text
	var hint := _label(caption_layer, Vector2(0, 250), 8, Color(0.6, 0.55, 0.7))
	hint.size = Vector2(640, 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "SO IT BEGINS — click" if final else "click to continue"

func _caption_advance() -> void:
	if caption_layer == null:
		return
	caption_layer.queue_free()
	caption_layer = null
	if caption_final:
		Global.node_i = 0
		Global.save_crusade()
		Global.launch_act1()
	elif not caption_queue.is_empty():
		call_deferred("_caption_next")

func _apply_branch_stats() -> void:
	# re-apply node effects that normally happen at pick time
	if nodes.has("chitin"):
		dmg_taken_mult = 0.65
	if nodes.has("sinew"):
		max_grabs = 2
	if nodes.has("fourthhead"):
		bolt_max = 4.0 + (1.0 if branch == "manyheads" else 0.0)
	elif branch == "manyheads":
		bolt_max = 4.0
	if nodes.has("voidheart"):
		eclipse_cost = 55.0
	if branch == "suneater":
		eclipse_len = 16.0
	if nodes.has("blackdawn"):
		eclipse_len += 8.0
	# capstone applies last so it stacks on whatever the line set
	if nodes.has("apotheosis"):
		growth_mult += 0.15
		dmg_taken_mult *= 0.8
		essence_mult *= 1.25

func _mouse_world() -> Vector2:
	# the autoplayer steers the cursor when CAL_BOT is set
	if Bot.active:
		return Bot.aim_world
	return get_global_mouse_position()

func _flash(p: Vector2, e: float) -> void:
	flash_light.position = p
	flash_light.energy = maxf(flash_light.energy, e)

func _shockripple(world: Vector2) -> void:
	var rel: Vector2 = ((world - cam.position) * cam.zoom.x + Vector2(320.0, 180.0)) / Vector2(640.0, 360.0)
	if rel.x < -0.1 or rel.x > 1.1 or rel.y < -0.1 or rel.y > 1.1:
		return
	shock_p = 0.0
	post_mat.set_shader_parameter("shock_c", rel)
	post_mat.set_shader_parameter("shock_p", 0.0)

func _hitstop(ms: int, scale: float) -> void:
	Engine.time_scale = scale
	hitstop_until = Time.get_ticks_msec() + ms

func _setup_env() -> void:
	ui_font = load("res://art/Silkscreen-Regular.ttf")
	# post-process stack: vignette + grain + chromatic aberration
	var post_layer := CanvasLayer.new()
	post_layer.layer = 90
	add_child(post_layer)
	var post := ColorRect.new()
	post.size = Vector2(640, 360)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://post.gdshader")
	post.material = mat
	post_mat = mat
	post_layer.add_child(post)
	# firelight pool + one big flash light for strikes
	for i in 6:
		var fl := PointLight2D.new()
		fl.texture = _radial_tex(96)
		fl.color = Color(1.6, 0.75, 0.3)
		fl.energy = 0.0
		fl.texture_scale = 1.6
		add_child(fl)
		fire_lights.append(fl)
	flash_light = PointLight2D.new()
	flash_light.texture = _radial_tex(128)
	flash_light.color = Color(1.5, 1.6, 2.0)
	flash_light.energy = 0.0
	flash_light.texture_scale = 6.0
	add_child(flash_light)
	# wind ambience — a low loop, synthesized; every city breathes differently
	var wind := AudioStreamPlayer.new()
	wind.stream = _synth_loop(3.0)
	wind.pitch_scale = {"maren": 0.7, "thornspire": 0.55, "teotl": 1.3, "ashport": 0.8}.get(Global.city, 1.0)
	wind.volume_db = -22.0
	wind.autoplay = true
	add_child(wind)
	wind.play()
	# drifting ash on the air
	for i in 26:
		ambient.append({"p": Vector2(randf_range(0, 640), randf_range(-340, -10)), "s": randf_range(0.3, 1.0)})
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

var house_imgs: Array = []

func _slice_facades() -> void:
	var sheet: Image = load(city_def.facade_sheet).get_image()
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
				var cut := strip.get_region(Rect2i(0, top, strip.get_width(), h - top))
				if cut.get_width() > 96:
					var nseg: int = int(ceil(cut.get_width() / 72.0))
					var segw: int = cut.get_width() / nseg
					for sgi in nseg:
						facades.append(cut.get_region(Rect2i(sgi * segw, 0, segw, cut.get_height())))
				else:
					facades.append(cut)
			run_start = -1
	tex_sky_a = load(city_def.far_tex)
	tex_sky_b = load("res://art/skyline-b.png")   # only used by kowloon's alternating far layer
	tex_mid = load(city_def.mid_tex)
	# artist houses (thornspire) — scaled to world size, nearest-neighbor
	for hp2 in city_def.house_art:
		var hi: Image = load(hp2).get_image()
		if hi.is_compressed():
			hi.decompress()
		hi.convert(Image.FORMAT_RGBA8)
		var sc := 0.38
		hi.resize(int(hi.get_width() * sc), int(hi.get_height() * sc), Image.INTERPOLATE_NEAREST)
		house_imgs.append(hi)

# ---------- procedural low-rise generator (pack-palette pixel art) ----------
const CITY_PAL := {
	"kowloon": {"wall": [Color("#241726"), Color("#2c1a22"), Color("#1e1c2e"), Color("#2a2030")],
		"lit": [Color("#ffd075"), Color("#ff9bc4"), Color("#7de0e6"), Color("#ffb03a")]},
	"thornspire": {"wall": [Color("#282436"), Color("#302a3e"), Color("#232030")],
		"lit": [Color("#a8c4ff"), Color("#ffd075"), Color("#c4a8ff")]},
	"ashport": {"wall": [Color("#38281c"), Color("#402e1e"), Color("#2e2418")],
		"lit": [Color("#ffb03a"), Color("#ff8a3a"), Color("#ffd075")]},
	"teotl": {"wall": [Color("#4a4638"), Color("#565040"), Color("#3e3a30")],
		"lit": [Color("#ffb03a"), Color("#ff8a3a")]},
	"maren": {"wall": [Color("#2e3a42"), Color("#38424e"), Color("#263038")],
		"lit": [Color("#9adce8"), Color("#ffd075"), Color("#7db8d0")]},
}

func _gen_lowrise(kind: String) -> Image:
	var pal: Dictionary = CITY_PAL.get(Global.city, CITY_PAL["kowloon"])
	var wall: Color = pal.wall[randi() % pal.wall.size()]
	var lit: Color = pal.lit[randi() % pal.lit.size()]
	var dark := wall.darkened(0.4)
	var roof := wall.darkened(0.55)
	var w: int
	var h: int
	match kind:
		"house":
			w = randi_range(30, 42)
			h = randi_range(26, 34)
		"shop":
			w = randi_range(42, 60)
			h = randi_range(22, 30)
		"church":
			w = randi_range(44, 56)
			h = 92
		"wall":
			w = randi_range(16, 20)
			h = randi_range(64, 76)
		"school":
			w = randi_range(70, 92)
			h = randi_range(34, 42)
		"ziggurat":
			w = randi_range(64, 92)
			h = randi_range(52, 72)
		"shrine":
			w = randi_range(26, 38)
			h = randi_range(26, 36)
		"warehouse":
			w = randi_range(62, 92)
			h = randi_range(30, 42)
		"containers":
			w = randi_range(42, 64)
			h = randi_range(22, 34)
		_:  # mall
			w = randi_range(80, 110)
			h = randi_range(38, 50)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	match kind:
		"house":
			var roof_h := 10
			img.fill_rect(Rect2i(0, roof_h, w, h - roof_h), wall)
			for yy in roof_h:   # pitched roof
				var inset := int((roof_h - yy) * (w * 0.5 / roof_h)) - 1
				img.fill_rect(Rect2i(maxi(0, inset), yy, maxi(1, w - inset * 2), 1), roof)
			img.fill_rect(Rect2i(w - 10, 1, 4, roof_h), dark)   # chimney
			img.fill_rect(Rect2i(4, h - 12, 7, 12), dark)       # door
			img.fill_rect(Rect2i(5, h - 11, 5, 9), Color("#120a14"))
			var wx := 15
			while wx < w - 8:   # windows
				img.fill_rect(Rect2i(wx, h - 14, 6, 7), dark)
				img.fill_rect(Rect2i(wx + 1, h - 13, 4, 5), lit if randf() < 0.6 else Color("#151020"))
				wx += 10
		"shop":
			img.fill_rect(Rect2i(0, 0, w, h), wall)
			img.fill_rect(Rect2i(0, 0, w, 8), roof)
			img.fill_rect(Rect2i(2, 1, w - 4, 6), lit)          # sign band
			for sx in range(4, w - 6, 7):                        # sign "letters"
				if randf() < 0.7:
					img.fill_rect(Rect2i(sx, 2, 4, 4), dark)
			var gx := 3
			while gx < w - 8:   # glass front
				img.fill_rect(Rect2i(gx, h - 16, 8, 15), Color("#0e1a24"))
				img.fill_rect(Rect2i(gx + 1, h - 15, 6, 13), Color(0.35, 0.65, 0.7, 1.0) if randf() < 0.7 else Color("#101822"))
				gx += 10
		"church":
			var nave_h := 44
			img.fill_rect(Rect2i(0, h - nave_h, w, nave_h), wall)
			for yy in 8:   # nave roof
				var inset := int((8 - yy) * (w * 0.5 / 8.0))
				img.fill_rect(Rect2i(maxi(0, inset), h - nave_h - 8 + yy, maxi(1, w - inset * 2), 1), roof)
			# spire tower
			var tw := 16
			var tx := 4
			img.fill_rect(Rect2i(tx, 22, tw, h - 22), wall.darkened(0.1))
			for yy in 18:   # spire
				var inset := int(yy * 0.5)
				img.fill_rect(Rect2i(tx + 8 - (9 - inset), 4 + yy, maxi(1, (9 - inset) * 2), 1), roof)
			img.fill_rect(Rect2i(tx + 7, 0, 2, 6), lit)          # glowing cross
			img.fill_rect(Rect2i(tx + 5, 2, 6, 2), lit)
			# rose window
			var cxp := tx + tw + (w - tx - tw) / 2
			for dy in range(-4, 5):
				for dxp in range(-4, 5):
					if Vector2(dxp, dy).length() <= 4.2:
						img.set_pixel(cxp + dxp, h - nave_h + 10 + dy, lit if Vector2(dxp, dy).length() > 2.0 else dark)
			# arched windows
			for ax in range(tx + tw + 4, w - 8, 10):
				img.fill_rect(Rect2i(ax, h - 22, 5, 14), dark)
				img.fill_rect(Rect2i(ax + 1, h - 21, 3, 12), lit if randf() < 0.5 else Color("#151020"))
				img.set_pixel(ax + 2, h - 23, dark)
			img.fill_rect(Rect2i(cxp - 4, h - 14, 9, 14), dark)   # portal
			img.fill_rect(Rect2i(cxp - 3, h - 13, 7, 12), Color("#0c0810"))
		"school":
			img.fill_rect(Rect2i(0, 0, w, h), wall)
			img.fill_rect(Rect2i(0, 0, w, 5), roof)
			for fy in 2:   # two window rows
				for wx2 in range(6, w - 10, 12):
					img.fill_rect(Rect2i(wx2, 9 + fy * 14, 8, 9), dark)
					img.fill_rect(Rect2i(wx2 + 1, 10 + fy * 14, 6, 7), lit if randf() < 0.5 else Color("#141222"))
			var dx2 := w / 2 - 5
			img.fill_rect(Rect2i(dx2, h - 13, 11, 13), dark)      # double door
			img.fill_rect(Rect2i(dx2 + 1, h - 12, 4, 11), Color("#10141c"))
			img.fill_rect(Rect2i(dx2 + 6, h - 12, 4, 11), Color("#10141c"))
			img.fill_rect(Rect2i(2, 0, 2, 14), dark)              # flag pole
			img.fill_rect(Rect2i(4, 1, 6, 4), Color(0.8, 0.3, 0.3))
		"ziggurat":
			# stepped pyramid — five stone terraces and a crowning shrine
			var steps := 5
			for s2 in steps:
				var sw2: int = w - int(float(w) * 0.75 * s2 / steps)
				var sx2: int = (w - sw2) / 2
				var sy2: int = h - (s2 + 1) * (h / steps)
				img.fill_rect(Rect2i(sx2, sy2, sw2, h / steps + 1), wall if s2 % 2 == 0 else wall.darkened(0.12))
				img.fill_rect(Rect2i(sx2, sy2, sw2, 2), wall.lightened(0.15))
			# the great stair
			img.fill_rect(Rect2i(w / 2 - 4, h / steps, 8, h - h / steps), wall.lightened(0.22))
			for st in range(h / steps + 2, h, 3):
				img.fill_rect(Rect2i(w / 2 - 4, st, 8, 1), wall.darkened(0.25))
			# crown shrine + eternal fires
			img.fill_rect(Rect2i(w / 2 - 6, 0, 12, h / steps), dark)
			img.fill_rect(Rect2i(w / 2 - 3, 2, 6, h / steps - 2), Color("#140e0a"))
			img.set_pixel(w / 2 - 5, 1, lit)
			img.set_pixel(w / 2 + 4, 1, lit)
			# carved glyphs
			for gy2 in range(h - 8, h - 2, 3):
				for gx3 in range(4, w - 6, 9):
					if randf() < 0.5:
						img.set_pixel(gx3, gy2, wall.darkened(0.35))
		"shrine":
			img.fill_rect(Rect2i(2, 8, w - 4, h - 8), wall)
			img.fill_rect(Rect2i(0, 5, w, 4), wall.darkened(0.3))   # slab roof
			img.fill_rect(Rect2i(w / 2 - 3, h - 12, 7, 12), Color("#120c08"))  # doorway
			img.set_pixel(3, 7, lit)      # torch
			img.set_pixel(w - 4, 7, lit)
			for gy3 in range(12, h - 4, 4):
				if randf() < 0.6:
					img.set_pixel(randi_range(4, w - 5), gy3, wall.darkened(0.3))
		"warehouse":
			img.fill_rect(Rect2i(0, 4, w, h - 4), wall)
			img.fill_rect(Rect2i(0, 0, w, 5), roof)
			var vx2 := 3
			while vx2 < w - 2:   # corrugated ribs
				img.fill_rect(Rect2i(vx2, 6, 1, h - 7), wall.darkened(0.18))
				vx2 += 4
			img.fill_rect(Rect2i(w / 4, h - 16, w / 2, 16), dark)   # sliding door
			img.fill_rect(Rect2i(w / 4 + 2, h - 14, w / 2 - 4, 12), Color("#101418"))
			img.fill_rect(Rect2i(w / 2 - 1, h - 16, 2, 16), wall.darkened(0.3))
			for wx4 in range(5, w / 4, 8):
				img.fill_rect(Rect2i(wx4, 8, 5, 4), lit if randf() < 0.5 else Color("#12181e"))
			img.fill_rect(Rect2i(w - 14, 8, 5, 4), lit if randf() < 0.5 else Color("#12181e"))
		"containers":
			img.fill(Color(0, 0, 0, 0))
			var cc := [Color("#7a3a30"), Color("#2e5a6a"), Color("#6a6a2e"), Color("#3e5a3a"), Color("#5a3a5e")]
			var rows: int = maxi(2, h / 11)
			for row in rows:
				var cw2 := randi_range(16, 24)
				var cx3 := randi_range(0, 6) if row < rows - 1 else 0
				while cx3 + cw2 <= w:
					var col2: Color = cc[randi() % cc.size()]
					var cy2: int = h - (row + 1) * 11
					img.fill_rect(Rect2i(cx3, cy2, cw2, 11), col2)
					img.fill_rect(Rect2i(cx3, cy2, cw2, 2), col2.lightened(0.15))
					for rib in range(cx3 + 2, cx3 + cw2 - 1, 3):
						img.fill_rect(Rect2i(rib, cy2 + 2, 1, 9), col2.darkened(0.2))
					cx3 += cw2 + randi_range(1, 4)
					cw2 = randi_range(16, 24)
		_:  # mall
			img.fill_rect(Rect2i(0, 0, w, h), wall)
			img.fill_rect(Rect2i(0, 0, w, 7), roof)
			img.fill_rect(Rect2i(w / 4, 1, w / 2, 8), lit)        # big roof sign
			for sx2 in range(w / 4 + 3, w / 4 + w / 2 - 4, 8):
				img.fill_rect(Rect2i(sx2, 3, 5, 4), dark)
			var gy := 12
			while gy < h - 4:   # glass floors
				for gx2 in range(3, w - 8, 9):
					img.fill_rect(Rect2i(gx2, gy, 7, 8), Color("#0e1a24"))
					img.fill_rect(Rect2i(gx2 + 1, gy + 1, 5, 6), Color(0.3, 0.55, 0.62) if randf() < 0.65 else Color("#101822"))
				gy += 11
			img.fill_rect(Rect2i(w / 2 - 8, h - 14, 16, 14), dark)  # entrance
			img.fill_rect(Rect2i(w / 2 - 7, h - 13, 14, 12), Color("#161e2a"))
	return img

func _pick_kind() -> String:
	var mix: Dictionary = city_def.mix
	var r := randf()
	var acc := 0.0
	for k in mix:
		acc += mix[k]
		if r <= acc:
			return k
	return "tower"

func _build_city() -> void:
	# banner art for baking onto tower facades
	for bn in ["banner-big-1", "banner-neon-1", "banner-sushi-1", "banner-coke-1", "banner-side-1", "hotel-sign"]:
		var im: Image = load("res://art/props/%s.png" % bn).get_image()
		if im.is_compressed():
			im.decompress()
		im.convert(Image.FORMAT_RGBA8)
		banner_imgs.append(im)
	var x := 380.0
	var i := 0
	# villages build bigger cottages — 26px shacks vanish at combat zoom
	var vsc: float = 1.6 if node_kind in ["hamlet", "town", "prologue"] else 1.35
	var arch_gap_mult: float = 0.45 if node_arch == "warrens" else 1.0
	if node_arch == "plaza":
		plaza_x = world_w * randf_range(0.4, 0.6)
	while x < world_w - 620.0:
		# the plaza: an open square in the city's heart
		if plaza_x > 0.0 and x > plaza_x - 90.0 and x < plaza_x + 90.0:
			x = plaza_x + 90.0
			continue
		var kind := _pick_kind()
		if kind == "tower":
			var f: Image = facades[i % facades.size()]
			var sc: float = 2.0 if _hash(x) < city_def.big_chance and f.get_height() < 150 else 1.0
			buildings.append(_mk_building(x, f, sc, false, "tower"))
			x += f.get_width() * sc + randf_range(city_def.gap_min, city_def.gap_max) * arch_gap_mult
			i += 1
		elif kind == "house":
			# houses come in rows — artist houses when the city has them
			for hn in randi_range(2, 4):
				var hi: Image
				if house_imgs.is_empty():
					hi = _gen_lowrise("house")
				else:
					hi = house_imgs[randi() % house_imgs.size()]
				buildings.append(_mk_building(x, hi, vsc, false, "house"))
				x += hi.get_width() * vsc + randf_range(4, 10)
			x += randf_range(city_def.gap_min, city_def.gap_max) * arch_gap_mult
		else:
			var li := _gen_lowrise(kind)
			buildings.append(_mk_building(x, li, vsc, false, kind))
			x += li.get_width() * vsc + randf_range(city_def.gap_min, city_def.gap_max) * arch_gap_mult
	# citadel: biggest facade at 2x
	var big_i := 0
	for j in facades.size():
		if facades[j].get_height() > facades[big_i].get_height():
			big_i = j
	if has_citadel:
		if city_def.get("cit_kind", "") != "":
			buildings.append(_mk_building(x, _gen_lowrise(city_def.cit_kind), 2.2, true, city_def.cit_kind))
		else:
			buildings.append(_mk_building(x, facades[big_i], 2.0, true, "tower"))
	# strategic landmarks — destroy them to bend the war
	var n_specials: int = 0 if node_kind in ["hamlet", "prologue"] else (2 if node_kind == "town" else 3)
	var candidates: Array = []
	for bi in buildings.size() - (1 if has_citadel else 0):
		if not buildings[bi].cit and buildings[bi].w > 40.0:
			candidates.append(bi)
	candidates.shuffle()
	var specials := ["aa", "comms", "barracks"]
	for si in mini(n_specials, candidates.size()):
		buildings[candidates[si]].special = specials[si]
		specials_total += 1
	# one landmark per node — the place worth remembering, and razing
	if node_kind in ["town", "city", "capital"] and buildings.size() > 4:
		var lm: Array = {"thornspire": ["church", "THE CATHEDRAL"], "teotl": ["ziggurat", "THE GREAT ZIGGURAT"],
			"maren": ["warehouse", "THE FISH EXCHANGE"], "ashport": ["mall", "THE GASWORKS"],
			"kowloon": ["mall", "THE ARCOLOGY"]}.get(Global.city, ["church", "THE OLD CATHEDRAL"])
		var lmb2 := _mk_building(buildings[buildings.size() / 2].x + 20.0, _gen_lowrise(lm[0]), 2.4, false, lm[0])
		lmb2.landmark_name = lm[1]
		buildings.append(lmb2)
	# garrison: stone gate-walls stand at the approaches
	if node_arch == "garrison":
		for wx4 in [world_w * 0.3, world_w * 0.72]:
			var wall := _mk_building(wx4, _gen_lowrise("wall"), 1.0, false, "wall")
			buildings.append(wall)
			for gi in 3:
				units.append({"kind": "police", "pos": Vector2(wx4 + randf_range(-20, 30), 0),
					"cd": randf_range(0.5, 1.5), "hp": 1})
	for b in buildings:
		total_mass += b.maxhp
	people_total = 130 if node_kind in ["city", "capital"] else 80
	# the reckoning: mark two shelters the crowds will run to
	if objective == "extinction":
		var scand: Array = []
		for bi2 in buildings.size():
			var bb: Dictionary = buildings[bi2]
			if not bb.cit and bb.get("special", "") == "" and bb.w > 30.0:
				scand.append(bb)
		scand.shuffle()
		for si2 in mini(2, scand.size()):
			scand[si2].shelter = true
			scand[si2].inside = 0
	if node_fate == "refugees":
		people_total = int(people_total * 1.6)
	# destructible street furniture
	for pn in ["control-box-1", "control-box-2", "control-box-3", "monitor-face-1"]:
		prop_texs.append(load("res://art/props/%s.png" % pn))
	for k in 40:
		props.append({"x": randf_range(320, world_w - 340), "tex": prop_texs[randi() % prop_texs.size()], "dead": false})
	# critters — pigeons everywhere, dogs in the gutters, pigs in ashport
	for k in 30:
		critters.append({"kind": "pigeon", "pos": Vector2(randf_range(320, world_w - 340), 0), "vx": 0.0, "vy": 0.0,
			"panic": false, "dead": false, "o": randf() * TAU})
	for k in 8:
		critters.append({"kind": "dog", "pos": Vector2(randf_range(320, world_w - 340), 0), "vx": 0.0, "vy": 0.0,
			"panic": false, "dead": false, "o": randf() * TAU})
	if Global.city in ["ashport", "teotl"]:
		for k in 12:
			critters.append({"kind": "pig", "pos": Vector2(randf_range(320, world_w - 340), 0), "vx": 0.0, "vy": 0.0,
				"panic": false, "dead": false, "o": randf() * TAU})
	# the drowned one's origin: a small harbor watch to break
	if prologue and character == "drowned":
		for k in 3:
			units.append({"kind": "police", "pos": Vector2(pos.x + 300.0 + k * 60.0, 0), "cd": randf_range(1.0, 2.0), "hp": 1})
	# Port Maren is already half-drowned — standing water in the streets
	if Global.city == "maren":
		for k in 4:
			var fx0 := randf_range(500, world_w - 700)
			flood.append({"x0": fx0, "x1": fx0 + randf_range(80, 180), "t_left": 1e9, "neutral": true})
	for k in 26:
		cars.append({"x": randf_range(300, world_w - 400), "w": randf_range(14, 19), "dead": false,
			"vx": (randf_range(24.0, 44.0) * (-1.0 if randf() < 0.5 else 1.0)) if randf() < 0.45 else 0.0,
			"col": [Color("#20303a"), Color("#3a2030"), Color("#2a2a34"), Color("#1c2426")][randi() % 4]})
	var lamp_x := 320.0
	while lamp_x < world_w - 300.0:
		lamps.append({"x": lamp_x, "dead": false})
		lamp_x += randf_range(80, 120)
	# crowds gather where crowds gather — markets, stops, plazas
	var hotspots: Array = []
	for hs in 9:
		hotspots.append(randf_range(340.0, world_w - 360.0))
	if plaza_x > 0.0:
		hotspots[0] = plaza_x
		hotspots[1] = plaza_x + 20.0
		for st in 4:
			props.append({"x": plaza_x + (st - 1.5) * 26.0, "tex": prop_texs[randi() % prop_texs.size()], "dead": false})
	for k in people_total:
		var px5: float
		if k % 2 == 0:
			px5 = hotspots[k % hotspots.size()] + randf_range(-36.0, 36.0)
		else:
			px5 = randf_range(320.0, world_w - 350.0)
		people.append({"pos": Vector2(clampf(px5, 320.0, world_w - 350.0), 0), "vx": 0.0, "panic": false,
			"o": randf() * TAU, "col": Color(randf_range(0.4, 0.7), randf_range(0.4, 0.6), randf_range(0.5, 0.75))})

func _mk_building(x: float, src: Image, sc: float, cit: bool, kind: String = "tower") -> Dictionary:
	var img := Image.new()
	img.copy_from(src)
	# bake a neon banner / sign onto tower walls — destruction eats it with the wall
	if kind == "tower" and not cit and randf() < 0.5 and not banner_imgs.is_empty() and Global.city != "thornspire":
		var bn: Image = banner_imgs[randi() % banner_imgs.size()]
		if bn.get_width() < img.get_width() - 8 and bn.get_height() < img.get_height() - 20:
			var bx := randi_range(4, img.get_width() - bn.get_width() - 4)
			var by := randi_range(10, img.get_height() - bn.get_height() - 10)
			img.blend_rect(bn, Rect2i(0, 0, bn.get_width(), bn.get_height()), Vector2i(bx, by))
	var w: float = img.get_width() * sc
	var h: float = img.get_height() * sc
	var mass: float = w * h * (0.020 if cit else 0.012)
	if Global.mode == "skirmish" and Global.mutator == "glass":
		mass *= 0.6
	return {"x": x, "w": w, "h": h, "sc": sc, "img": img,
		"tex": ImageTexture.create_from_image(img),
		"hp": mass, "maxhp": mass, "holes": [], "dead": false, "dying": 0.0, "cit": cit,
		"cur_h": h, "seed": x * 0.77, "burn": 0.0, "kind": kind, "flames": [],
		"topple": 0.0, "top_dir": 0.0, "top_chain": 0, "base_carve": 0.0, "carve_bias": 0.0}

func _hash(n: float) -> float:
	return fmod(absf(sin(n * 127.1) * 43758.55), 1.0)

const MAX_PARTS := 900
const MAX_HOLES := 44

func _carve(b: Dictionary, world: Vector2, r_px: float) -> void:
	if b.holes.size() > MAX_HOLES:
		b.holes = b.holes.slice(b.holes.size() - MAX_HOLES)
	# structural ledger: wounds in the bottom quarter undermine the whole tower
	if world.y > -b.h * 0.28:
		b.base_carve += r_px
		b.carve_bias += signf(world.x - (b.x + b.w * 0.5)) * r_px
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
	t += delta
	if OS.get_environment("CAL_SHOT") != "":
		_shot_frames += 1
		if OS.get_environment("CAL_TEST").begins_with("herald:") and _shot_frames == 60:
			if not herald_alive:
				_spawn_herald(OS.get_environment("CAL_TEST").get_slice(":", 1))
		if OS.get_environment("CAL_TEST") == "draft" and _shot_frames == 60 and not draft_open:
			_open_draft()
		if OS.get_environment("CAL_TEST") == "topple" and _shot_frames == 85:
			for b in buildings:
				if not b.dead and b.h > b.w and absf(b.x - pos.x) < 320.0 \
						and b.get("special", "") == "" and not b.cit:
					_topple(b, 1.0)
					break
		if _shot_frames == 130:
			get_viewport().get_texture().get_image().save_png(OS.get_environment("CAL_SHOT"))
			get_tree().quit()
	if draft_open:
		return
	# arrival — the calamity walks in before the war starts
	if intro_t > 0.0:
		intro_t -= delta
		var kk: float = clampf(1.0 - intro_t / INTRO_LEN, 0.0, 1.0)
		pos = intro_from.lerp(intro_to, 1.0 - pow(1.0 - kk, 3.0))
		if character == "tzitzimitl":
			for i in segs.size():
				segs[i] = pos + Vector2(-(i + 1) * 9.0, sin(t * 2.0 + i * 0.6) * 4.0)
		cam.position = cam.position.lerp(Vector2(pos.x, -105), 4.0 * delta)
		cam.position.x = clampf(cam.position.x, 320, world_w - 320)
		swarm_light.position = pos
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or intro_t <= 0.0:
			intro_t = 0.0
			pos = intro_to
			letterbox = 0.0
			hud.msg.text = ""
			hud.sub.text = ""
			lmb_prev = true
		_hud_update()
		queue_redraw()
		return
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
			_feed("mass", 0.6)
			if b.hp <= 0.0:
				_collapse(b)
	var spawn_pods: Array = []
	for pod in pods:
		if pod.t_left <= 0.0 and nodes.has("creep") and randf() < 0.25 and not pod.b.dead:
			spawn_pods.append({"b": pod.b, "p": pod.p + Vector2(randf_range(-14, 14), randf_range(-14, 14)),
				"t_left": 6.0, "tick": 0.5})
	pods = pods.filter(func(p): return p.t_left > 0.0 and not p.b.dead)
	pods.append_array(spawn_pods)
	# biomass threshold -> evolution draft (all calamities; not during origin vignettes)
	if bio_stage < BIO_THRESH.size() and bio >= BIO_THRESH[bio_stage] and not over and not prologue:
		_open_draft()
	# hit-stop release (real-time clock, immune to the frozen timescale)
	if hitstop_until > 0 and Time.get_ticks_msec() > hitstop_until:
		Engine.time_scale = 1.0
		hitstop_until = 0
	flash_t = maxf(0.0, flash_t - 2.5 * delta)
	# growth reshapes the body
	match character:
		"swarm":
			radius = 22.0 * growth
			tendril_range = (140.0 if nodes.has("sinew") else 100.0) * growth
		"keraunos": radius = 52.0 * growth
		"tzitzimitl": radius = 16.0 * growth
		"drowned": radius = 24.0 * growth
		"rider": radius = 18.0 * growth
	# tumbling masonry
	for fr in frags:
		fr.vel.y += 260.0 * delta
		fr.pos += fr.vel * delta
		fr.rot += fr.rotv * delta
		fr.life -= delta
		# flying masonry is not decoration
		if not fr.get("spent", false) and fr.vel.length_squared() > 3600.0:
			for u in units:
				if not u.get("dead", false) and u.kind != "jet" \
						and (u.pos + Vector2(0, -6) - fr.pos).length() < maxf(fr.w, fr.h) * 0.5 + 6.0:
					u.hp = u.get("hp", 1) - 1
					fr.spent = true
					_boom(fr.pos, 4, Color(0.55, 0.45, 0.45), 55.0)
					if u.hp <= 0:
						u.dead = true
						_kill_unit(u)
					break
			if not fr.get("spent", false) and fr.pos.y > -14.0:
				for pe in people:
					if not pe.get("dead", false) and absf(pe.pos.x - fr.pos.x) < fr.w * 0.5 + 4.0:
						pe.dead = true
						fr.spent = true
						score_f += 20.0 * combo * TIER_MULT[tier]
						_mist(Vector2(pe.pos.x, -5))
						break
		if fr.pos.y >= -2.0 and fr.vel.y > 0.0:
			if fr.vel.y > 60.0:
				fr.vel.y *= -0.3
				fr.rotv *= 0.5
				_boom(fr.pos, 5, Color(0.4, 0.35, 0.4), 60.0)
				shake = maxf(shake, 2.0)
			else:
				fr.vel = Vector2.ZERO
				fr.rotv = 0.0
				fr.life = minf(fr.life, 0.6)
	frags = frags.filter(func(fr): return fr.life > 0.0)
	# dusk falls into night with time and violence; a devoured sun ends the argument
	night_f = 1.0 if (sun_eaten or Global.mutator == "midnight") \
		else clampf(maxf(t / 160.0, threat / 75.0) + 0.12, 0.12, 1.0)
	run_time += delta
	if prologue:
		people_killed = people_total - people.size()
		_prologue_check()
		if caption_layer != null:
			return
	# THE CAPITAL answers with its own apocalypse
	if is_capital and not over and threat >= 99.0:
		doom_cd -= delta
		if doom_t > 0.0:
			doom_t -= delta
			if doom_t <= 0.0:
				flash_t = 1.0
				shake = 30.0
				impact_frames = 3
				_flash(doom_p, 4.0)
				_shockripple(doom_p)
				_hitstop(200, 0.2)
				_sfx("skyfall")
				parts.append({"pos": doom_p, "vel": Vector2.ZERO, "life": 0.5, "col": Color(2.6, 2.2, 1.4), "flash": true, "size": 60.0})
				parts.append({"pos": doom_p, "vel": Vector2.ZERO, "life": 0.5, "col": Color(2.4, 1.8, 0.8), "ring": true, "size": 12.0})
				if pos.distance_to(doom_p) < 120.0:
					hp -= 40.0 * dmg_taken_mult
					hit_flash = 1.0
				for b in buildings:
					if not b.dead and b.dying <= 0.0 and absf(b.x + b.w * 0.5 - doom_p.x) < 100.0:
						_collapse(b)
				_hit_props(doom_p, 110.0)
		elif doom_cd <= 0.0:
			doom_cd = 45.0
			doom_t = 3.0
			doom_p = pos
			Global.music("doom")
			_pop(pos + Vector2(0, -40), "!! LAST RESORT INBOUND — MOVE !!", Color(2.4, 0.4, 0.3))
			_sfx("thunder")
	if not over:
		match character:
			"keraunos":
				_move(delta)
				_keraunos(delta)
			"tzitzimitl":
				_tzitzi_move(delta)
				_tzitzi(delta)
			"drowned":
				_ground_move(delta, 115.0)
				_drowned(delta)
			"rider":
				_ground_move(delta, 95.0)
				_rider(delta)
			_:
				_move(delta)
				_tendrils(delta)
		if not allies.is_empty() or not flood.is_empty():
			_allies_update(delta)
		lmb_prev = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		_people(delta)
		_army(delta)
		threat = min(100.0, threat + 0.22 * delta * threat_mult)
		tier = mini(tier, tier_cap)
		# evac buses run the gauntlet — mobile feasts
		bus_cd -= delta
		if bus_cd <= 0.0 and buses.size() < 2:
			bus_cd = randf_range(18.0, 30.0)
			var side: float = -1.0 if randf() < 0.5 else 1.0
			buses.append({"x": cam.position.x - side * 500.0, "vx": side * 55.0, "hp": 3})
		for bus in buses:
			bus.x += bus.vx * delta
			if absf(bus.x - cam.position.x) > 900.0:
				bus.dead = true
		buses = buses.filter(func(bus): return not bus.get("dead", false))
		# traffic drives until terror stops it — then the gridlock honks
		for c in cars:
			if c.get("dead", false) or c.get("gone", false) or c.get("vx", 0.0) == 0.0:
				continue
			if absf(c.x + c.w * 0.5 - pos.x) < 180.0 or threat > 45.0:
				c.vx = 0.0
				if randf() < 0.35 and amb_player != null and sfx_bank.has("horn"):
					amb_player.stream = sfx_bank["horn"]
					amb_player.pitch_scale = randf_range(1.3, 1.9)
					amb_player.play()
				continue
			c.x += c.vx * delta
			if c.x < 300.0 or c.x > world_w - 330.0:
				c.vx = -c.vx
		# the void's answer arrives mid-war
		# the AA battery contests the sky while it stands
		flak_cd -= delta
		if flak_cd <= 0.0 and pos.y < -70.0 and _aa_alive():
			flak_cd = 2.6
			var fp := pos + Vector2(randf_range(-26, 26), randf_range(-22, 22))
			parts.append({"pos": fp, "vel": Vector2.ZERO, "life": 0.3, "col": Color(1.9, 1.4, 0.7), "flash": true, "size": 10.0})
			_boom(fp, 8, Color(0.6, 0.55, 0.5), 70.0)
			_sfx("boom")
			if fp.distance_to(pos) < 20.0:
				hp -= 5.0 * dmg_taken_mult
				hit_flash = 0.7
		if herald_due != "" and not herald_alive:
			herald_timer -= delta
			if herald_timer <= 0.0:
				_spawn_herald(herald_due)
		# a news chopper circles the story of the century
		news_cd -= delta
		if news_cd <= 0.0 and tier >= 1:
			news_cd = randf_range(35.0, 60.0)
			var nside: float = -1.0 if randf() < 0.5 else 1.0
			units.append({"kind": "news", "pos": Vector2(cam.position.x - nside * 420.0, -175.0),
				"cd": 999.0, "hp": 1, "side": nside})
		tier = mini(5, int(threat / 17.0))
		if tier != prev_tier_s:
			if tier > prev_tier_s:
				_sfx("siren" if tier >= 3 else "bell")
			prev_tier_s = tier
			Global.music("battle", tier)
		_check_end()
	for b in buildings:
		if b.holes.size() > 40:
			b.holes = b.holes.slice(b.holes.size() - 40)
		# undermined base → structural failure toward the wound
		if not b.dead and b.dying <= 0.0 and b.topple == 0.0 and b.base_carve * b.sc > b.w * 5.0 \
				and b.h > b.w * 0.9 and b.get("special", "") == "" and not b.cit:
			_topple(b, signf(b.carve_bias) if b.carve_bias != 0.0 else signf(b.x + b.w * 0.5 - pos.x))
		# the long fall
		if b.topple > 0.0 and not b.dead:
			var prev_a: float = minf(b.topple, 1.0) * PI * 0.5
			b.topple = minf(1.0, b.topple + delta * (0.45 + b.topple * 2.6))
			var ang3: float = minf(b.topple, 1.0) * PI * 0.5
			var pvx: float = b.x + (b.w if b.top_dir > 0.0 else 0.0)
			var lo2: float = minf(pvx + b.top_dir * b.cur_h * sin(prev_a), pvx + b.top_dir * b.cur_h * sin(ang3))
			var hi2: float = maxf(pvx + b.top_dir * b.cur_h * sin(prev_a), pvx + b.top_dir * b.cur_h * sin(ang3))
			# the sweeping shadow — everything under the falling mass
			for pe in people:
				if pe.pos.x >= lo2 and pe.pos.x <= hi2:
					pe.dead = true
					score_f += 20.0 * combo * TIER_MULT[tier]
					_gout(Vector2(pe.pos.x, -6), "flesh", 1.4, 1)
					_mist(Vector2(pe.pos.x, -5))
			for u in units:
				if not u.get("dead", false) and u.kind != "jet" and u.pos.y > -40.0 \
						and u.pos.x >= lo2 and u.pos.x <= hi2:
					u.hp = u.get("hp", 1) - 3
					_boom(u.pos + Vector2(0, -8), 6, Color(0.5, 0.42, 0.45), 70.0)
					if u.hp <= 0:
						u.dead = true
						_kill_unit(u)
			if randf() < 0.6:
				parts.append({"pos": Vector2(pvx + b.top_dir * b.cur_h * sin(ang3), -randf_range(2.0, 10.0)),
					"vel": Vector2(b.top_dir * 30.0, -20.0), "life": 0.7,
					"col": Color(0.35, 0.3, 0.33), "size": 4.0})
			if b.topple >= 1.0:
				_topple_land(b)
		if b.dying > 0.0 and not b.dead:
			b.dying -= delta
			b.cur_h = maxf(b.h * 0.06, b.cur_h - b.h * 2.2 * delta)
			if randf() < 22.0 * delta:
				_boom(Vector2(b.x + randf() * b.w, -b.cur_h), 3, Color("#5a4a58"), 60.0)
			if b.dying <= 0.0:
				b.dead = true
				_sfx("crumble")
		# fire damage over time: burning buildings waste away
		if b.burn > 0.0 and not b.dead and b.dying <= 0.0 and b.topple == 0.0:
			b.hp -= b.burn * 1.6 * delta
			b.burn = maxf(0.0, b.burn - 0.35 * delta)
			score_f += b.burn * 0.4 * delta * combo * TIER_MULT[tier]
			if randf() < b.burn * 0.4 * delta:
				_carve(b, Vector2(b.x + randf_range(4, b.w - 4), -randf_range(6, b.cur_h - 6)), 3.0)
			if b.hp <= 0.0:
				_collapse(b)
	# firelight — the strongest blazes cast real light; ruins glow at night
	var fi := 0
	for b in buildings:
		if fi >= fire_lights.size():
			break
		if b.burn > 0.4 and not b.dead:
			var fl: PointLight2D = fire_lights[fi]
			fl.position = Vector2(b.x + b.w * 0.5, -b.cur_h * 0.55)
			fl.energy = minf(1.1, b.burn * 0.35) * (0.85 + 0.3 * sin(t * 11.0 + b.seed))
			fl.texture_scale = 1.2 + b.w * 0.012
			fi += 1
		elif night_f > 0.5 and b.dead and t < b.get("smolder", 0.0):
			var fl2: PointLight2D = fire_lights[fi]
			fl2.position = Vector2(b.x + b.w * 0.5, -6.0)
			fl2.energy = 0.25 + 0.1 * sin(t * 5.0 + b.seed)
			fl2.texture_scale = 1.0
			fi += 1
	for j in range(fi, fire_lights.size()):
		fire_lights[j].energy = 0.0
	flash_light.energy = maxf(0.0, flash_light.energy - 9.0 * delta)
	# the swarm's hum swells with size and speed
	if buzz_player != null:
		buzz_player.volume_db = lerpf(buzz_player.volume_db,
			-26.0 + growth * 8.0 + minf(6.0, vel.length() * 0.02), 2.0 * delta)
	# the city's own voice, now and then
	amb_cd -= delta
	if amb_cd <= 0.0:
		amb_cd = randf_range(7.0, 16.0)
		var amb_s: String = {"maren": "gull", "teotl": "chirp", "ashport": "clank",
			"thornspire": "bell"}.get(Global.city, "horn")
		if sfx_bank.has(amb_s):
			amb_player.stream = sfx_bank[amb_s]
			amb_player.pitch_scale = randf_range(0.9, 1.1)
			amb_player.play()
	# grafts — the stolen powers act on their own
	shift_t = maxf(0.0, shift_t - delta)
	if hp < prev_hp - 0.5:
		if "predatorshift" in Global.grafts:
			shift_t = 1.5
		if "riftstep" in Global.grafts and hp < 30.0 and t > rift_cd:
			rift_cd = t + 20.0
			pos = Vector2(clampf(aim.x, 60.0, world_w - 60.0), minf(aim.y, -20.0))
			_boom(pos, 16, Color(1.4, 0.5, 1.8), 100.0)
			_pop(pos + Vector2(0, -20), "RIFT STEP", Color(1.6, 0.8, 1.8))
	prev_hp = hp
	if "paradox" in Global.grafts and not paradox_used and hp < 30.0 and hp > 0.0:
		paradox_used = true
		allies.append({"kind": "echoself", "pos": Vector2(pos.x - 30.0, -4), "hp": 12, "cd": 0.0, "life": 15.0})
		_pop(pos + Vector2(0, -34), "YOUR ECHO STEPS OUT OF TIME", Color(1.8, 0.6, 0.7))
	if "haloofruin" in Global.grafts and not over:
		halo_cd -= delta
		if halo_cd <= 0.0:
			halo_cd = 25.0
			var best = null
			var bn := -1
			for u in units:
				if u.get("dead", false) or u.kind in ["jet", "news", "herald", "carcass"]:
					continue
				var cnt := 0
				for u2 in units:
					if absf(u2.pos.x - u.pos.x) < 90.0:
						cnt += 1
				if cnt > bn:
					bn = cnt
					best = u
			if best != null and bn >= 2:
				var cp2: Vector2 = best.pos
				_shockwave(cp2 + Vector2(0, -6), 36.0)
				_flash(cp2, 3.0)
				parts.append({"pos": Vector2(cp2.x, -50), "vel": Vector2.ZERO, "life": 0.3,
					"col": Color(2.4, 2.2, 1.4), "flash": true, "size": 26.0})
				_pop(cp2 + Vector2(0, -40), "HALO OF RUIN", Color(2.2, 2.0, 1.1))
	# essence orbs fly home
	for o in eorbs:
		o.t += delta
		if o.t < 0.25:
			o.vel *= pow(0.12, delta)
		else:
			o.vel = o.vel.lerp((pos - o.pos).normalized() * (240.0 + o.t * 280.0), 8.0 * delta)
		o.pos += o.vel * delta
		if o.pos.distance_to(pos) < maxf(14.0, radius * 0.8):
			_feed(o.kind, o.val)
			o.dead = true
			if randf() < 0.5:
				var oc2: Color = EORB_COLS.get(o.kind, Color(1.6, 1.2, 0.9))
				parts.append({"pos": o.pos, "vel": (o.pos - pos).normalized() * -30.0,
					"life": 0.3, "col": oc2, "size": 1.5})
		elif o.t > 5.0:
			_feed(o.kind, o.val)
			o.dead = true
	eorbs = eorbs.filter(func(o2): return not o2.get("dead", false))
	# devour milestones — the city audibly loses
	if not prologue and not over and total_mass > 0.0:
		var ms := [0.25, 0.5, 0.75, 0.999]
		if milestone_i < 4 and _eaten_frac() >= ms[milestone_i]:
			milestone_i += 1
			var plc: String = (node_place if node_place != "" else str(city_def.get("name", "THE CITY"))).to_upper()
			var msn: String = ["%s BLEEDS — A QUARTER DEVOURED", "%s BREAKS — HALF DEVOURED",
				"%s KNEELS — THREE QUARTERS GONE", "%s IS NO MORE"][milestone_i - 1] % plc
			_pop(Vector2(cam.position.x, -170), msn, Color(2.0, 1.6, 0.6))
			score_f += 4000.0 * milestone_i * combo
			flash_t = maxf(flash_t, 0.25)
			_sfx("siren" if milestone_i < 3 else "bell")
			for pp in people:
				pp.panic = true
	# smoldering ruins are feeding grounds
	if not over:
		for b in buildings:
			if b.dead and t < b.get("smolder", 0.0) and absf(b.x + b.w * 0.5 - pos.x) < 70.0 and pos.y > -90.0:
				_feed("mass", 1.1 * delta)
				if randf() < 2.0 * delta:
					parts.append({"pos": Vector2(b.x + randf() * b.w, -6.0),
						"vel": (pos - Vector2(b.x + b.w * 0.5, -10)).normalized() * 40.0,
						"life": 0.5, "col": Color(1.2, 1.0, 1.4, 0.8), "size": 1.2})
				break
	# combo heat — the screen itself warms up
	post_mat.set_shader_parameter("heat", clampf((combo - 3.0) / 6.0, 0.0, 1.0) * 0.8)
	# screen ripple rolls outward
	if shock_p < 1.0:
		shock_p = minf(1.0, shock_p + delta * 1.8)
		post_mat.set_shader_parameter("shock_p", shock_p)
	if parts.size() > MAX_PARTS:
		parts = parts.slice(parts.size() - MAX_PARTS)
	for p in parts:
		p.pos += p.vel * delta
		if not p.get("fire", false) and not p.get("bird", false):
			p.vel.y += 300.0 * delta
		p.life -= delta
		# debris chunks bounce off the street
		if p.get("chunk", false) and p.pos.y >= -1.0 and p.vel.y > 0.0:
			p.pos.y = -1.0
			p.vel.y *= -0.45
			p.vel.x *= 0.7
			if absf(p.vel.y) > 40.0:
				for u in units:
					if not u.get("dead", false) and absf(u.pos.x - p.pos.x) < 8.0 and u.kind != "heli" and u.kind != "jet":
						u.hp = u.get("hp", 1) - 1
						if u.hp <= 0:
							u.dead = true
							_kill_unit(u)
	parts = parts.filter(func(p): return p.life > 0.0)
	units = units.filter(func(u): return not u.get("dead", false))
	if parts.size() > 1600:
		parts = parts.slice(parts.size() - 1600)
	for p in pops:
		p.pos.y -= 18.0 * delta
		p.life -= delta
	pops = pops.filter(func(p): return p.life > 0.0)
	shells = shells.filter(func(s): return s.life > 0.0)
	shake = max(0.0, shake - 30.0 * delta)
	hit_flash = max(0.0, hit_flash - 4.0 * delta)
	cam.position = cam.position.lerp(Vector2(pos.x, -105), 6.0 * delta)
	cam.position.x = clamp(cam.position.x, 320, world_w - 320)
	cam.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	swarm_light.position = pos
	swarm_light.energy = 1.0 + 0.25 * sin(t * 7.0) + hit_flash
	_hud_update()
	queue_redraw()

func _move(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	vel += dir * 900.0 * (1.6 if shift_t > 0.0 else 1.0) * delta
	vel *= pow(0.02, delta)
	vel = vel.limit_length(220.0)
	pos += vel * delta
	pos.x = clamp(pos.x, 40, world_w - 40)
	pos.y = clamp(pos.y, -340, -12)

func _people(delta: float) -> void:
	for p in people:
		# the plague blossoms
		if p.has("inf") and t > p.inf:
			p.dead = true
			_rise(Vector2(p.pos.x, -4), false)
			score_f += 20.0 * combo * TIER_MULT[tier]
			continue
		# rioters tear at the nearest walls
		if p.get("riot", false):
			var rb = null
			var rd := 1e9
			for b in buildings:
				if b.dead or b.dying > 0.0:
					continue
				var dbx: float = absf(b.x + b.w * 0.5 - p.pos.x)
				if dbx < rd:
					rd = dbx
					rb = b
			if rb != null:
				p.vx = move_toward(p.vx, signf(rb.x + rb.w * 0.5 - p.pos.x) * 30.0, 100.0 * delta)
				p.pos.x += p.vx * delta
				if rd < rb.w * 0.5 + 6.0:
					rb.hp -= 1.6 * delta
					score_f += 1.2 * delta * combo * TIER_MULT[tier]
					_feed("fear", 0.7 * delta)
					if randf() < 0.5 * delta:
						_boom(Vector2(p.pos.x, -6), 2, Color(1.4, 0.6, 1.2), 40.0)
					if rb.hp <= 0.0:
						_collapse(rb)
			continue
		var d: float = pos.x - p.pos.x
		if absf(d) < 90.0 and pos.y > -60.0 and not character in ["drowned", "rider"]:
			p.panic = true
		if blackout_t > 0.0:
			p.panic = true   # the sun is gone — everyone runs
		if p.panic:
			if objective == "extinction":
				# they run for the shelters — hunt the convoys, crack the doors
				var sb = null
				var sd := 1e9
				for b in buildings:
					if b.get("shelter", false) and not b.dead and b.dying <= 0.0:
						var dsx: float = absf(b.x + b.w * 0.5 - p.pos.x)
						if dsx < sd:
							sd = dsx
							sb = b
				if sb != null:
					p.vx = move_toward(p.vx, signf(sb.x + sb.w * 0.5 - p.pos.x) * 52.0, 200.0 * delta)
					if sd < 6.0:
						p.dead = true
						sb.inside = sb.get("inside", 0) + 1
				else:
					p.vx = move_toward(p.vx, -signf(d) * 46.0, 200.0 * delta)
			else:
				p.vx = move_toward(p.vx, -signf(d) * 46.0, 200.0 * delta)
		else:
			p.vx = sin(t * 0.6 + p.o) * 9.0
		p.pos.x = clampf(p.pos.x + p.vx * delta, 300, world_w - 320)
	# terror is a meal — panicking minds bleed fear
	var afraid := 0
	for p in people:
		if p.get("panic", false) and absf(p.pos.x - pos.x) < 280.0:
			afraid += 1
	if afraid > 0:
		_feed("fear", afraid * 0.12 * delta)
		if afraid > 12 and randf() < 0.015 and amb_player != null and sfx_bank.has("scream"):
			amb_player.stream = sfx_bank["scream"]
			amb_player.pitch_scale = randf_range(0.85, 1.25)
			amb_player.play()
	people = people.filter(func(p): return not p.get("dead", false))
	# critters scatter
	for cr in critters:
		var d2: float = pos.x - cr.pos.x
		if (absf(d2) < 110.0 and pos.y > -80.0) or blackout_t > 0.0:
			cr.panic = true
		match cr.kind:
			"pigeon":
				if cr.panic:
					cr.vy = move_toward(cr.vy, -70.0, 300.0 * delta)
					cr.vx = move_toward(cr.vx, -signf(d2) * 50.0, 200.0 * delta)
					cr.pos += Vector2(cr.vx, cr.vy) * delta
					if cr.pos.y < -260.0:
						cr.dead = true   # flew away
				else:
					cr.pos.x += sin(t * 1.2 + cr.o) * 4.0 * delta
			"dog":
				if cr.panic:
					cr.vx = move_toward(cr.vx, -signf(d2) * 62.0, 260.0 * delta)
				else:
					cr.vx = sin(t * 0.5 + cr.o) * 14.0
				cr.pos.x = clampf(cr.pos.x + cr.vx * delta, 300, world_w - 320)
			"pig":
				if cr.panic:
					cr.vx = move_toward(cr.vx, -signf(d2) * 34.0, 160.0 * delta)
				else:
					cr.vx = sin(t * 0.35 + cr.o) * 7.0
				cr.pos.x = clampf(cr.pos.x + cr.vx * delta, 300, world_w - 320)
	critters = critters.filter(func(cr): return not cr.dead)

# --- tendril + evolution state ---
const BIO_THRESH := [180.0, 520.0, 1100.0, 1900.0, 2800.0]
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
var draft_ui: Control = null
var pods: Array = []             # {b, p(local), t_left, tick}
var rmb_cd := 0.0
var threat_mult := 1.0
var buses: Array = []            # evac buses {x, vx, hp}
var bus_cd := 14.0
var lash := {"t_left": 0.0, "ang": 0.0}
var slams: Array = []            # {x, dir, dist}
var aftershock_q: Array = []     # {p, t_left}
var max_grabs := 1
var dmg_taken_mult := 1.0

# --- character dispatch ---
var character := "swarm"
var city_def: Dictionary = CITY_DEFS["kowloon"]
var lmb_prev := false
var meter := 0.0                 # special resource (storm / sun-hunger); bio stays for evolutions
# keraunos
var bolt_charges := 3.0
var bolt_max := 3.0
var bolts: Array = []            # {from, to, t_left}
var orbs: Array = []             # ball lightning {pos, t_left, zap}
var stun_t := 0.0                # thunderclap
var dark_perm := 0.0             # black dawn residual darkness
# tzitzimitl
var segs: Array = []             # serpent body trail
var dive_t := 0.0
var dive_dir := Vector2.RIGHT
var dive_cd := 0.0
# --- day-night arc + the devoured sun ---
var night_f := 0.0               # 0 = dusk, 1 = full night (advances with time + threat)
var sun_eaten := false           # permanent — the serpent swallowed the light
var blackout_t := 0.0            # deep-dark shock window right after the devouring
var devour_anim := 0.0
var eclipse_len := 10.0          # length of the blackout shock (SUN-EATER: 16)
var eclipse_cost := 80.0
var pierced_this_dive := 0
var pierce_id := 0
var feathers: Array = []         # {pos, vy, t_left}
# sfx
var sfx_players: Array = []
var sfx_bank := {}
var buzz_player: AudioStreamPlayer
var amb_player: AudioStreamPlayer
var amb_cd := 6.0
var news_cd := 25.0
var prev_tier_s := 0
var champ_spawned := false
# heralds — the void's answer to THE ROAR
var herald_due := ""             # htype that will interrupt this battle
var herald_timer := 45.0
var herald_alive := false
var growth_cap := 1.75
var shift_t := 0.0               # predator shift burst
var paradox_used := false
var halo_cd := 25.0
var prev_hp := 100.0
var rift_cd := 0.0
var serp_head: Texture2D
var serp_body: Texture2D
var serp_wing: Texture2D
# --- allies (fishmen, risen) + the two ground gods ---
var allies: Array = []           # {kind, pos, hp, cd, life}
var lmb_cd := 0.0
var rally := Vector2.ZERO
var has_rally := false
var e_prev := false
var scythe_t := 0.0
var scythe_ang := 0.0
var flood: Array = []            # water zones {x0, x1, t_left}
var trail_cd := 0.0

func _tendrils(delta: float) -> void:
	bite_cd -= delta
	rmb_cd -= delta
	lash.t_left = maxf(0.0, lash.t_left - delta)
	var mouse := _mouse_world()
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
					_collapse(b)
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
			if u.get("grab", false) or u.kind == "herald":
				continue
			if (u.pos + Vector2(0, -8)).distance_to(aim) < 17.0:
				u.grab = true
				u.fall = false
				u.thrown = false
				combo_idle = 0.0
				grabbed_someone = true
				grabbed_n += 1
				_sfx("grab")
		# 1b) rip parked cars off the street — they become wrecking mass
		if grabbed_n < max_grabs:
			for c in cars:
				if c.get("gone", false) or c.dead:
					continue
				if Vector2(c.x + c.w * 0.5, -5).distance_to(aim) < 15.0:
					c.gone = true
					c.dead = true
					units.append({"kind": "carcass", "pos": Vector2(c.x + c.w * 0.5, -5), "cd": 1e9,
						"hp": 1, "grab": true, "col": c.col, "w": c.w})
					grabbed_someone = true
					grabbed_n += 1
					_sfx("grab")
					break
		# 2) snatch a person
		if not grabbed_someone:
			for p in people:
				if Vector2(p.pos.x, -4).distance_to(aim) < 12.0:
					p.dead = true
					var gain := int(20.0 * combo * TIER_MULT[tier])
					score_f += gain
					_feed("flesh", 2.5)
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
			if u.pos.y >= 0.0 or u.pos.x < 40 or u.pos.x > world_w - 40:
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
	bolt_charges = minf(bolt_max, bolt_charges + delta / 1.0)
	rmb_cd -= delta
	stun_t = maxf(0.0, stun_t - delta)
	aim = _mouse_world()
	aim_clamped = false
	feeding = false
	for b2 in bolts:
		b2.t_left -= delta
	bolts = bolts.filter(func(b2): return b2.t_left > 0.0)
	# ball lightning orbs
	for o in orbs:
		o.t_left -= delta
		o.zap -= delta
		if nodes.has("magnetize"):
			var best = null
			var bd := 1e9
			for b in buildings:
				if b.dead or b.dying > 0.0:
					continue
				var d: float = absf(b.x + b.w * 0.5 - o.pos.x)
				if d < bd:
					bd = d
					best = b
			if best != null:
				o.pos.x = move_toward(o.pos.x, best.x + best.w * 0.5, 22.0 * delta)
		if o.zap <= 0.0:
			o.zap = randf_range(0.35, 1.3)   # erratic — lightning has moods
			# gather everything in reach, lash out at ONE random victim
			var cands: Array = []
			for u in units:
				if (u.pos + Vector2(0, -8)).distance_to(o.pos) < 50.0:
					cands.append(u)
			var b_cand = null
			for b in buildings:
				if b.dead or b.dying > 0.0:
					continue
				if o.pos.x >= b.x - 24 and o.pos.x <= b.x + b.w + 24:
					b_cand = b
					break
			if b_cand != null:
				cands.append(b_cand)
			for l in lamps:
				if not l.dead and absf(l.x - o.pos.x) < 50.0:
					cands.append(l)
					break
			if not cands.is_empty():
				var pick = cands[randi() % cands.size()]
				if pick is Dictionary and pick.has("kind"):
					pick.hp = pick.get("hp", 1) - 1
					bolts.append({"from": o.pos, "to": pick.pos + Vector2(0, -8), "t_left": 0.1})
					if pick.hp <= 0:
						pick.dead = true
						_kill_unit(pick)
				elif pick is Dictionary and pick.has("maxhp"):
					var hit := Vector2(clampf(o.pos.x, pick.x + 4, pick.x + pick.w - 4),
						clampf(o.pos.y, -pick.cur_h + 4, -6.0))
					_carve(pick, hit, 5.0)
					pick.hp -= 8.0
					score_f += 8.0 * combo * TIER_MULT[tier]
					bolts.append({"from": o.pos, "to": hit, "t_left": 0.1})
					if pick.hp <= 0.0:
						_collapse(pick)
				elif pick is Dictionary and pick.has("x"):
					bolts.append({"from": o.pos, "to": Vector2(pick.x, -24), "t_left": 0.1})
					_hit_props(Vector2(pick.x, -20), 6.0)
		# resonance: orbs arc to each other
		if nodes.has("resonance"):
			for o2 in orbs:
				if o2 != o and o.pos.distance_to(o2.pos) < 90.0 and randf() < delta * 2.0:
					bolts.append({"from": o.pos, "to": o2.pos, "t_left": 0.08})
					for u in units:
						var up: Vector2 = u.pos + Vector2(0, -8)
						if _seg_dist(o.pos, o2.pos, up) < 8.0:
							u.hp = u.get("hp", 1) - 1
							if u.hp <= 0:
								u.dead = true
								_kill_unit(u)
	orbs = orbs.filter(func(o): return o.t_left > 0.0)
	units = units.filter(func(u): return not u.get("dead", false))
	var lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if lmb and not lmb_prev and bolt_charges >= 1.0:
		bolt_charges -= 1.0
		_strike(aim)
		# manyheads: fork to a second nearby target
		if branch == "manyheads":
			var fork := aim + Vector2(randf_range(-70, 70), randf_range(-20, 20))
			for b in buildings:
				if b.dead or b.dying > 0.0 or absf(b.x + b.w * 0.5 - aim.x) > 100:
					continue
				fork = Vector2(b.x + b.w * 0.5, -b.cur_h + randf_range(4, 30))
				break
			_strike(fork, 0.5)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and rmb_cd <= 0.0:
		var sf_cost: float = 25.0 if nodes.has("conductor") else 40.0
		if branch == "skyfall" and meter >= sf_cost:
			rmb_cd = 1.2
			meter -= sf_cost
			_skyfall(aim)
		elif meter >= (70.0 if nodes.has("stormfront") else 100.0):
			# TEMPEST barrage
			rmb_cd = 2.0
			meter -= 70.0 if nodes.has("stormfront") else 100.0
			var n_strikes: int = 9 if nodes.has("stormfront") else 7
			for i in n_strikes:
				var tx: float = cam.position.x + randf_range(-320, 320)
				var ty: float = -randf_range(10, 200)
				for b in buildings:
					if b.dead or b.dying > 0.0:
						continue
					if tx >= b.x and tx <= b.x + b.w:
						ty = -b.cur_h + randf_range(2, 30)
						break
				_strike(Vector2(tx, ty))

func _seg_dist(a: Vector2, b: Vector2, p: Vector2) -> float:
	var ab := b - a
	var f: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return (a + ab * f).distance_to(p)

func _strike(p: Vector2, power: float = 1.0) -> void:
	bolts.append({"from": Vector2(p.x + randf_range(-30, 30), -370), "to": p, "t_left": 0.16})
	parts.append({"pos": p, "vel": Vector2.ZERO, "life": 0.22, "col": Color(1.8, 2.2, 2.6), "flash": true, "size": 18.0 * power})
	shake = maxf(shake, 9.0 * power)
	combo_idle = 0.0
	threat = minf(100.0, threat + 1.2 * power)
	_flash(p, 2.4 * power)
	_sfx("thunder")
	if branch == "ball" or nodes.has("twincast"):
		var n_orbs: int = 2 if nodes.has("twincast") else 1
		for i in n_orbs:
			orbs.append({"pos": p + Vector2(randf_range(-12, 12), randf_range(-14, -4)), "t_left": 6.0, "zap": 0.4})
	for b in buildings:
		if b.dead or b.dying > 0.0:
			continue
		if p.x >= b.x - 6 and p.x <= b.x + b.w + 6 and p.y >= -b.cur_h - 10:
			var hit := Vector2(clampf(p.x, b.x + 4, b.x + b.w - 4), clampf(p.y, -b.cur_h + 4, -6.0))
			_carve(b, hit, randf_range(11.0, 15.0) * power)
			_carve(b, hit + Vector2(randf_range(-8, 8), randf_range(5, 13)), 7.0 * power)
			b.holes.append({"p": hit - Vector2(b.x, -b.h), "o": randf() * TAU})
			b.hp -= 75.0 * power
			_ignite(b, (4.5 if nodes.has("overcharge") else 2.5) * power)
			var gain: float = 75.0 * power * 1.6 * combo * TIER_MULT[tier]
			score_f += gain
			_feed("charge", 9.0 * power)
			pass
			combo = minf(9.5, combo + 0.3)
			_chunks(hit, 6)
			_pop(hit + Vector2(0, -12), "+%d" % int(gain), Color("#aaddff"))
			if b.hp <= 0.0:
				_collapse(b)
				score_f += b.maxhp * 8.0 * combo * TIER_MULT[tier]
			break
	for u in units:
		if (u.pos + Vector2(0, -8)).distance_to(p) < 30.0 * power:
			u.dead = true
			_kill_unit(u)
	units = units.filter(func(u): return not u.get("dead", false))
	for pe in people:
		if Vector2(pe.pos.x, -4).distance_to(p) < 24.0 * power:
			pe.dead = true
			score_f += 20.0 * combo * TIER_MULT[tier]
			_feed("flesh", 2.5)
			pass
			_mist(Vector2(pe.pos.x, -5))
	_hit_props(p, 26.0 * power)

func _skyfall(p: Vector2) -> void:
	# charged mega-bolt: deletes a vertical slice of whatever it hits
	var w_col: float = 26.0 if nodes.has("annihilate") else 16.0
	bolts.append({"from": Vector2(p.x, -370), "to": Vector2(p.x, 0), "t_left": 0.3})
	parts.append({"pos": Vector2(p.x, -60), "vel": Vector2.ZERO, "life": 0.3, "col": Color(2.2, 2.4, 2.8), "flash": true, "size": 34.0})
	parts.append({"pos": Vector2(p.x, -8), "vel": Vector2.ZERO, "life": 0.5, "col": Color(1.6, 2.0, 2.6), "ring": true, "size": 8.0})
	flash_t = maxf(flash_t, 0.5)
	shake = 18.0
	_flash(Vector2(p.x, -80.0), 3.5)
	_shockripple(Vector2(p.x, -40.0))
	impact_frames = 2
	_sfx("skyfall")
	threat = minf(100.0, threat + 4.0)
	for b in buildings:
		if b.dead or b.dying > 0.0:
			continue
		if p.x + w_col * 0.5 >= b.x and p.x - w_col * 0.5 <= b.x + b.w:
			var yy: float = -b.cur_h + 4.0
			while yy < -4.0:
				_carve(b, Vector2(p.x + randf_range(-3, 3), yy), w_col * 0.55)
				yy += w_col * 0.8
			b.hp -= 260.0
			_ignite(b, 5.0)
			score_f += 260.0 * combo * TIER_MULT[tier]
			_feed("charge", 20.0)
			if b.hp <= 0.0:
				_collapse(b)
	for u in units:
		if absf(u.pos.x - p.x) < w_col:
			u.dead = true
			_kill_unit(u)
	units = units.filter(func(u): return not u.get("dead", false))
	_hit_props(Vector2(p.x, -5), w_col)
	if nodes.has("thunderclap"):
		stun_t = 2.0

# ================= TZITZIMITL =================
func _tzitzi_move(delta: float) -> void:
	var mouse := _mouse_world()
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
	pos.x = clamp(pos.x, 40, world_w - 40)
	pos.y = clamp(pos.y, -340, -10)
	_hit_props(pos, 12.0)   # the serpent's passage devours light and crushes steel
	if segs.is_empty() or segs[0].distance_to(pos) > 3.0:
		segs.push_front(pos)
		while segs.size() > int(44.0 * growth):
			segs.pop_back()

func _tzitzi(delta: float) -> void:
	if blackout_t > 0.0:
		blackout_t -= delta
	devour_anim = maxf(0.0, devour_anim - delta)
	if sun_eaten:
		if branch == "suneater":
			# the army wilts in the endless dark
			for u in units:
				if randf() < (0.9 if blackout_t > 0.0 else 0.3) * delta:
					u.hp = u.get("hp", 1) - 1
					if u.hp <= 0:
						u.dead = true
						_kill_unit(u)
			units = units.filter(func(u): return not u.get("dead", false))
		if nodes.has("rain") and blackout_t > 0.0 and feathers.size() < 60 and randf() < 6.0 * delta:
			feathers.append({"pos": Vector2(cam.position.x + randf_range(-320, 320), -randf_range(200, 340)),
				"vy": randf_range(40, 90), "t_left": 6.0})
	# feathers fall and cut
	for f2 in feathers:
		f2.pos.y += f2.vy * delta
		f2.t_left -= delta
		if f2.pos.y >= -2.0:
			f2.t_left = 0.0
			continue
		for u in units:
			if (u.pos + Vector2(0, -8)).distance_to(f2.pos) < 10.0:
				u.hp = u.get("hp", 1) - 1
				f2.t_left = 0.0
				_boom(f2.pos, 5, Color(1.8, 1.2, 0.4), 60.0)
				if u.hp <= 0:
					u.dead = true
					_kill_unit(u)
				break
	feathers = feathers.filter(func(f2): return f2.t_left > 0.0)
	units = units.filter(func(u): return not u.get("dead", false))
	var lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var cd_base: float = 0.72 * (0.6 if nodes.has("serration") else 1.0)
	var cd_needed: float = cd_base * (0.5 if (blackout_t > 0.0 or sun_eaten) else 1.0)
	if lmb and not lmb_prev and dive_cd <= 0.0:
		dive_cd = cd_needed
		dive_t = 0.22
		dive_dir = (get_global_mouse_position() - pos).normalized()
		pierced_this_dive = 0
		pierce_id += 1
		combo_idle = 0.0
		_sfx("lash")
		if branch == "feather":
			var n_f: int = 6 if nodes.has("molt") else 3
			for i in n_f:
				feathers.append({"pos": pos + Vector2(randf_range(-14, 14), randf_range(-10, 10)),
					"vy": randf_range(14, 30), "t_left": 7.0})
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and rmb_cd <= 0.0 and meter >= eclipse_cost and not sun_eaten:
		# THE SERPENT DEVOURS THE SUN — once, forever
		rmb_cd = 1.0
		meter -= eclipse_cost
		sun_eaten = true
		blackout_t = eclipse_len
		devour_anim = 1.4
		shake = 14.0
		_sfx("eclipse")
		_pop(pos + Vector2(0, -26),
			"THE SUN IS DEVOURED" if night_f < 0.75 else "THE PALE WITNESS DIES", Color(2.0, 1.2, 0.4))
	# diving: pierce everything on the path
	if dive_t > 0.0:
		var mult: float = 1.6 if blackout_t > 0.0 else (1.3 if sun_eaten else 1.0)
		mult *= 1.0 + minf(0.6, 0.1 * pierced_this_dive)   # chain bonus, capped
		var carve_r: float = 10.0 if branch == "obsidian" else 7.0
		for b in buildings:
			if b.dead or b.dying > 0.0:
				continue
			if pos.x >= b.x and pos.x <= b.x + b.w and pos.y >= -b.cur_h and pos.y <= 0.0:
				if b.get("pierce_id", 0) != pierce_id:
					b.pierce_id = pierce_id
					pierced_this_dive += 1
				if b.get("carve_at", 0.0) > t:   # per-tick carving, not per-frame
					continue
				b.carve_at = t + 0.07
				_carve(b, pos, carve_r)
				b.hp -= 3.4 * mult
				if nodes.has("cleave"):
					_ignite(b, 1.2 * delta * 3.0)
				var gain: float = 5.0 * combo * TIER_MULT[tier] * mult
				score_f += gain
				_feed("light", 1.5)
				pass
				combo = minf(9.5, combo + 0.02)
				if randf() < 0.3:
					b.holes.append({"p": pos - Vector2(b.x, -b.h), "o": randf() * TAU})
					_chunks(pos, 2)
				if b.hp <= 0.0:
					_collapse(b)
					score_f += b.maxhp * 8.0 * combo * TIER_MULT[tier]
		for u in units:
			if (u.pos + Vector2(0, -8)).distance_to(pos) < 16.0:
				u.dead = true
				if nodes.has("gorger") and (blackout_t > 0.0 or sun_eaten):
					hp = minf(100.0, hp + 3.0)
				_kill_unit(u)
		units = units.filter(func(u): return not u.get("dead", false))
		for pe in people:
			if Vector2(pe.pos.x, -4).distance_to(pos) < 12.0:
				pe.dead = true
				score_f += 20.0 * combo * TIER_MULT[tier]
				_feed("flesh", 2.5)
				pass
				_mist(Vector2(pe.pos.x, -5))
		_hit_props(pos, 18.0)
	else:
		# sonic boom: shockwave when the dive ends
		if nodes.has("sonicboom") and dive_cd > cd_needed - 0.05 and dive_t <= 0.0 and dive_t > -0.05:
			_shockwave(pos, 34.0)
	if dive_t <= 0.0:
		dive_t -= delta
		combo_idle += delta
		if combo_idle > 1.4 and combo > 1.0:
			combo = max(1.0, combo - 1.4 * delta)

# ================= DROWNED ONE + PALE RIDER (ground gods) =================
func _ground_move(delta: float, top_speed: float) -> void:
	if shift_t > 0.0:
		top_speed *= 1.5
	var dir := Input.get_axis("move_left", "move_right")
	vel.x += dir * 700.0 * (1.6 if shift_t > 0.0 else 1.0) * delta
	vel.x = clampf(vel.x * pow(0.03, delta) if dir == 0 else vel.x, -top_speed, top_speed)
	vel.y += 500.0 * delta
	if Input.is_action_pressed("move_up") and pos.y >= -14.0:
		vel.y = -170.0   # heavy lurch upward
	pos += vel * delta
	if pos.y > -12.0:
		pos.y = -12.0
		vel.y = 0.0
	pos.x = clamp(pos.x, 40, world_w - 40)
	aim = _mouse_world()
	aim_clamped = false
	feeding = false

func _drowned(delta: float) -> void:
	lmb_cd -= delta
	rmb_cd -= delta
	var lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	# MADDEN — click a mind and it breaks
	if lmb and not lmb_prev and lmb_cd <= 0.0:
		lmb_cd = 1.2 if nodes.has("echoes") else 2.4
		var hit := false
		for u in units:
			if u.get("mad", false) or u.kind in ["carcass", "jet"]:
				continue
			if (u.pos + Vector2(0, -8)).distance_to(aim) < 20.0:
				_madden(u)
				hit = true
				break
		if not hit:
			for pe in people:
				if Vector2(pe.pos.x, -4).distance_to(aim) < 22.0:
					pe.riot = true
					_pop(Vector2(pe.pos.x, -14), "RIOT", Color(1.4, 0.5, 1.2))
			_sfx("grab")
	# THE DEEP ANSWERS — fishmen crawl out
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and rmb_cd <= 0.0 and meter >= 80.0:
		rmb_cd = 1.5
		meter -= 80.0
		_sfx("eclipse")
		var n_fish: int = 6 if branch == "father" else 4
		for i in n_fish:
			var fx: float = clampf(aim.x + randf_range(-30, 30), 60, world_w - 60)
			var kind := "brute" if (branch == "father" and i % 2 == 0) else "fishman"
			if nodes.has("priests") and i == 0:
				kind = "priest"
			allies.append({"kind": kind, "pos": Vector2(fx, -4), "hp": 6 if kind == "brute" else 3,
				"cd": 0.0, "life": 30.0})
			_boom(Vector2(fx, -4), 8, Color(0.3, 0.8, 0.8), 70.0)
		_pop(aim + Vector2(0, -20), "THE DEEP ANSWERS", Color(0.5, 1.6, 1.5))
	# BLACK TIDE — floodwater follows your wake
	if branch == "tide":
		trail_cd -= delta
		if trail_cd <= 0.0 and absf(vel.x) > 20.0:
			trail_cd = 0.4
			flood.append({"x0": pos.x - 18.0, "x1": pos.x + 18.0, "t_left": 1e9 if nodes.has("depths") else 20.0})
	# whelp rises in deep flood
	if nodes.has("whelp") and not allies.any(func(a): return a.kind == "whelp") and not flood.is_empty():
		var fz: Dictionary = flood[randi() % flood.size()]
		allies.append({"kind": "whelp", "pos": Vector2((fz.x0 + fz.x1) * 0.5, -4), "hp": 20, "cd": 0.0, "life": 1e9})
	if nodes.has("tideborn"):
		if t - float(get_meta("last_tideborn", 0.0)) > 30.0:
			set_meta("last_tideborn", t)
			allies.append({"kind": "fishman", "pos": Vector2(pos.x + randf_range(-40, 40), -4), "hp": 3, "cd": 0.0, "life": 30.0})

var spawn_q: Array = []
var eorbs: Array = []            # essence orbs in flight toward the god
const EORB_COLS := {"flesh": Color(1.9, 0.5, 0.6), "charge": Color(0.6, 1.6, 2.2),
	"light": Color(2.0, 1.6, 0.5), "fear": Color(1.4, 0.6, 1.8),
	"death": Color(0.8, 1.6, 0.9), "mass": Color(1.2, 1.0, 1.4)}

func _gout(p: Vector2, kind: String, amt: float, n: int = 3) -> void:
	# the meal made visible — orbs burst out, then fly home to the god
	if eorbs.size() > 110:
		_feed(kind, amt)
		return
	for i in n:
		var a := randf() * TAU
		eorbs.append({"pos": p + Vector2(cos(a), sin(a)) * randf_range(2.0, 8.0),
			"vel": Vector2(cos(a), sin(a)) * randf_range(50.0, 120.0) + Vector2(0, -50),
			"kind": kind, "val": amt / n, "t": 0.0})

func _spawn_herald(htype: String) -> void:
	herald_alive = true
	var hd: Dictionary = HERALD_DEFS[htype]
	var hx: float = clampf(pos.x + (400.0 if randf() < 0.5 else -400.0), 100.0, world_w - 100.0)
	units.append({"kind": "herald", "htype": htype, "pos": Vector2(hx, -200.0 if hd.get("flies", false) else 0.0),
		"cd": 2.0, "hp": hd.hp, "maxhp": hd.hp, "ht": 0.0, "vx": 0.0, "name": hd.name})
	impact_frames = 3
	shake = 20.0
	_shockripple(Vector2(hx, -40.0))
	_hitstop(220, 0.2)
	_sfx("skyfall")
	Global.music("doom")
	_pop(Vector2(hx, -90), hd.name + " HAS COME FOR YOU", Color(2.4, 0.6, 0.9))
	_pop(Vector2(hx, -74), "your roar carried too far. something answered.", Color(1.4, 0.9, 1.2))

func _herald_ai(u: Dictionary, delta: float, dx: float) -> void:
	var hd: Dictionary = HERALD_DEFS[u.htype]
	u.ht += delta
	var sc: float = hd.scale
	# contact — standing beside a catastrophe hurts
	if pos.distance_to(u.pos + Vector2(0, -14.0 * sc)) < 26.0 * sc and shift_t <= 0.0:
		hp -= (9.0 if hd.ai == "hunt" else 5.0) * delta * dmg_taken_mult
		if randf() < 2.0 * delta:
			hit_flash = 0.7
	match hd.ai:
		"eat":
			var tb = null
			var td := 1e9
			for b in buildings:
				if not b.dead and b.dying <= 0.0 and b.topple == 0.0:
					var dd: float = absf(b.x + b.w * 0.5 - u.pos.x)
					if dd < td:
						td = dd
						tb = b
			if tb == null:
				u.pos.x = move_toward(u.pos.x, pos.x, 30.0 * delta)
			elif td > tb.w * 0.5 + 12.0:
				u.pos.x = move_toward(u.pos.x, tb.x + tb.w * 0.5, 34.0 * delta)
			elif hd.get("armors", false):
				if not tb.get("rusted", false):
					tb.rusted = true
					tb.hp = tb.maxhp * 1.5
					_pop(Vector2(tb.x + tb.w * 0.5, -tb.cur_h - 10), "CONSECRATED IN RUST", Color(1.6, 1.0, 0.4))
				u.pos.x += randf_range(-40.0, 40.0)
			else:
				tb.hp -= 15.0 * delta
				if randf() < 3.0 * delta:
					_carve(tb, Vector2(u.pos.x + randf_range(-12, 12), -randf_range(8, 44)), 4.0)
				if tb.hp <= 0.0:
					_collapse(tb)
		"hunt":
			if u.cd <= 0.0:
				u.cd = 2.4
				u.vx = signf(dx) * float(hd.get("spd", 200.0))
				if hd.get("slam", false):
					_shockwave(u.pos + Vector2(0, -6), 40.0)
			u.pos.x += u.vx * delta
			u.vx = move_toward(u.vx, 0.0, 260.0 * delta)
		"cast":
			u.pos.x = move_toward(u.pos.x, pos.x + 160.0 * signf(u.pos.x - pos.x + 0.1), 26.0 * delta)
			if u.cd <= 0.0:
				u.cd = 3.4
				u.cast_p = pos.x
				u.cast_t = 1.1
				_sfx("groan")
			if u.get("cast_t", 0.0) > 0.0:
				u.cast_t -= delta
				if u.cast_t <= 0.0:
					var cp := Vector2(u.cast_p, -6.0)
					_shockwave(cp, 34.0)
					_flash(cp, 2.5)
					_shockripple(cp)
					if hd.get("from_below", false):
						for b in buildings:
							if not b.dead and b.dying <= 0.0 and absf(b.x + b.w * 0.5 - u.cast_p) < 40.0:
								_collapse(b)
								break
					if pos.distance_to(cp) < 46.0:
						hp -= 16.0 * dmg_taken_mult
						hit_flash = 1.0
		"spawn":
			if hd.get("teleports", false) and u.ht > 4.0:
				u.ht = 0.0
				u.pos.x = clampf(pos.x + randf_range(-260, 260), 80.0, world_w - 80.0)
				_boom(u.pos + Vector2(0, -16), 14, Color(1.4, 0.5, 1.8), 90.0)
			if u.cd <= 0.0:
				u.cd = 3.0
				for i in 2:
					spawn_q.append({"kind": "brood", "pos": u.pos + Vector2(randf_range(-20, 20), 0), "cd": 1.0, "hp": 1})
		"leech":
			u.pos.x = move_toward(u.pos.x, pos.x, 44.0 * delta)
			if absf(dx) < 150.0:
				meter = maxf(0.0, meter - 6.0 * delta)
				essence_eaten = maxf(0.0, essence_eaten - 3.0 * delta)
				if randf() < 0.8 * delta:
					_pop(u.pos + Vector2(0, -30.0 * sc), "IT DRINKS YOUR NAME", Color(0.7, 0.75, 1.4))

func _madden(u: Dictionary) -> void:
	if u.kind in ["herald", "brood"]:
		return
	# a priest's ward turns the whisper away
	for u2 in units:
		if u2.kind == "priest" and not u2.get("dead", false) and not u2.get("mad", false) \
				and absf(u2.pos.x - u.pos.x) < 90.0 and u != u2:
			_pop(u.pos + Vector2(0, -16), "WARDED", Color(1.8, 1.6, 1.0))
			return
	madden_count += 1
	_sfx("whisper")
	u.mad = true
	u.mad_t = 12.0 + (8.0 if nodes.has("hollowing") else 0.0)
	combo = minf(9.5, combo + 0.2)
	combo_idle = 0.0
	_feed("fear", 7.0)
	pass
	score_f += 60.0 * combo * TIER_MULT[tier]
	_pop(u.pos + Vector2(0, -18), "MADNESS", Color(1.6, 0.5, 1.5))
	_boom(u.pos + Vector2(0, -10), 6, Color(1.4, 0.5, 1.4), 60.0)
	_sfx("hit")

func _rider(delta: float) -> void:
	lmb_cd -= delta
	rmb_cd -= delta
	scythe_t = maxf(0.0, scythe_t - delta)
	# infection aura — the fog takes them
	var fog_r: float = 55.0 * growth
	for pe in people:
		if not pe.has("inf") and Vector2(pe.pos.x, -4).distance_to(pos) < fog_r:
			pe.inf = t + 4.0
	for u in units:
		if u.kind in ["police", "soldier"] and not u.has("inf") and not u.get("mad", false):
			if (u.pos + Vector2(0, -8)).distance_to(pos) < fog_r * 0.76:
				u.inf = t + 8.0
	# blightlord: painted plague ground
	if branch == "blight":
		trail_cd -= delta
		if trail_cd <= 0.0 and absf(vel.x) > 10.0:
			trail_cd = 0.5
			flood.append({"x0": pos.x - (26.0 if nodes.has("miasma") else 16.0),
				"x1": pos.x + (26.0 if nodes.has("miasma") else 16.0),
				"t_left": (40.0 if nodes.has("spores") else 20.0), "plague": true})
	# E — rally the dead
	var ek := Input.is_physical_key_pressed(KEY_E)
	if ek and not e_prev:
		rally = aim
		has_rally = true
		_pop(aim, "^", Color(1.5, 1.4, 0.8))
	e_prev = ek
	# SCYTHE — the pale blade arcs where you point
	var lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if lmb and not lmb_prev and lmb_cd <= 0.0:
		lmb_cd = 0.7
		var o: Vector2 = pos + Vector2(0, -10)
		var reach: float = 68.0 * growth
		scythe_ang = (aim - o).angle()
		scythe_t = 0.18
		_sfx("shing")
		shake = maxf(shake, 3.0)
		for u in units:
			if u.kind == "carcass":
				continue
			var d2: Vector2 = u.pos + Vector2(0, -8) - o
			if d2.length() < reach and absf(angle_difference(d2.angle(), scythe_ang)) < 1.1:
				u.hp = u.get("hp", 1) - 2
				_boom(u.pos + Vector2(0, -8), 6, Color(0.85, 0.9, 0.65), 70.0)
				if u.hp <= 0:
					u.dead = true
					_kill_unit(u)
					_rise(u.pos, branch == "crown")
				else:
					u.inf = t + 3.0
		units = units.filter(func(u2): return not u2.get("dead", false))
		for pe in people:
			var dp: Vector2 = Vector2(pe.pos.x, -4) - o
			if dp.length() < reach and absf(angle_difference(dp.angle(), scythe_ang)) < 1.1:
				pe.dead = true
				score_f += 20.0 * combo * TIER_MULT[tier]
				_gout(Vector2(pe.pos.x, -6), "death", 2.0, 1)
				_mist(Vector2(pe.pos.x, -5))
				_rise(Vector2(pe.pos.x, -4), false)
		people = people.filter(func(pe2): return not pe2.get("dead", false))
		# the blade carves masonry too
		for b in buildings:
			if b.dead or b.dying > 0.0:
				continue
			var tip: Vector2 = o + Vector2.from_angle(scythe_ang) * reach * 0.8
			if tip.x > b.x - 4.0 and tip.x < b.x + b.w + 4.0 and tip.y > -b.cur_h - 8.0:
				b.hp -= 9.0
				for k in 4:
					_carve(b, o + Vector2.from_angle(scythe_ang + (k - 1.5) * 0.3) * reach * randf_range(0.5, 0.95),
						randf_range(3.0, 5.0))
				_feed("mass", 1.2)
				score_f += 6.0 * combo * TIER_MULT[tier]
				shake = maxf(shake, 5.0)
				if b.hp <= 0.0:
					_collapse(b)
				break
		_hit_props(o + Vector2.from_angle(scythe_ang) * reach * 0.6, reach * 0.55)
	# REAPING — every infected thing dies and rises NOW
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and rmb_cd <= 0.0 and meter >= 80.0:
		rmb_cd = 1.5
		meter -= 80.0
		_sfx("bell")
		var reaped := 0
		for pe in people:
			if pe.has("inf"):
				pe.dead = true
				_rise(Vector2(pe.pos.x, -4), false)
				reaped += 1
		for u in units:
			if u.has("inf"):
				u.dead = true
				_kill_unit(u)
				_rise(u.pos, branch == "crown")
				reaped += 1
		units = units.filter(func(u): return not u.get("dead", false))
		people = people.filter(func(pe): return not pe.get("dead", false))
		if reaped > 0:
			shake = 10.0
			_pop(pos + Vector2(0, -26), "R E A P I N G  ×%d" % reaped, Color(1.8, 1.6, 0.7))

func _rise(p: Vector2, armed: bool) -> void:
	var cap: int = 16 if branch == "legion" else 8
	if allies.size() >= cap:
		return
	risen_count += 1
	allies.append({"kind": "risen_soldier" if armed else "risen", "pos": Vector2(p.x, -4),
		"hp": 4 if armed else 2, "cd": 0.0,
		"life": 1e9 if nodes.has("endless") else 25.0})
	_mist(p)
	_feed("death", 4.5)
	pass

func _allies_update(delta: float) -> void:
	for a in allies:
		a.life -= delta
		a.cd -= delta
		var speed: float = 90.0 if nodes.has("drill") else 46.0
		if a.kind == "whelp":
			speed = 26.0
		# find prey — the risen are a demolition crew first, soldiers second
		var prey = null
		var pd: float = 90.0 if a.kind in ["risen", "cultist"] else (200.0 if a.kind == "risen_soldier" else 320.0)
		for u in units:
			if u.get("mad", false) or u.kind == "carcass":
				continue
			var d: float = (u.pos - a.pos).length()
			if d < pd:
				pd = d
				prey = u
		var goto: Vector2
		# idle risen tear the town down (near the rally point if one is set)
		var raze_b = null
		if prey == null and a.kind in ["risen", "risen_soldier"] \
				and (not has_rally or absf(a.pos.x - rally.x) <= 60.0):
			var rbd := 1e9
			for b in buildings:
				if b.dead or b.dying > 0.0:
					continue
				var dbx: float = absf(b.x + b.w * 0.5 - a.pos.x)
				if dbx < rbd:
					rbd = dbx
					raze_b = b
		if prey != null:
			goto = prey.pos
		elif raze_b != null:
			goto = Vector2(raze_b.x + raze_b.w * 0.5, -4)
		elif has_rally:
			goto = rally
		else:
			goto = pos
		a.pos.x = move_toward(a.pos.x, goto.x, speed * delta)
		# flood empowers the deep-born
		var in_flood := false
		for fz in flood:
			if not fz.get("plague", false) and a.pos.x >= fz.x0 and a.pos.x <= fz.x1:
				in_flood = true
				break
		if prey != null and a.cd <= 0.0:
			match a.kind:
				"risen_soldier":
					if pd < 180.0:
						a.cd = 1.5
						shells.append({"pos": a.pos + Vector2(0, -8), "vel": (prey.pos + Vector2(0, -8) - a.pos).normalized() * 130.0,
							"life": 3.0, "heavy": false, "friendly": true})
				"priest":
					if pd < 60.0:
						a.cd = 6.0
						_madden(prey)
				_:
					if pd < 15.0:
						a.cd = 0.8 if a.kind != "whelp" else 1.6
						var dmg: int = 1
						if a.kind == "brute":
							dmg = 2
						elif a.kind == "whelp":
							dmg = 4
						elif a.kind == "echoself":
							dmg = 3
						if in_flood and character == "drowned":
							dmg += 1
						prey.hp = prey.get("hp", 1) - dmg
						_boom(prey.pos + Vector2(0, -8), 5, Color(0.4, 1.0, 0.9) if character == "drowned" else Color(0.7, 0.75, 0.6), 60.0)
						if prey.hp <= 0:
							prey.dead = true
							_kill_unit(prey)
		# dead hands against the walls
		if raze_b != null and a.cd <= 0.0 and absf(a.pos.x - (raze_b.x + raze_b.w * 0.5)) < raze_b.w * 0.5 + 8.0:
			a.cd = 0.75
			raze_b.hp -= 2.6
			_carve(raze_b, Vector2(a.pos.x + randf_range(-5, 5), randf_range(-16.0, -4.0)), randf_range(2.0, 3.5))
			score_f += 2.0 * combo * TIER_MULT[tier]
			_feed("death", 0.35)
			if randf() < 0.4:
				_boom(Vector2(a.pos.x, -10), 3, Color(0.7, 0.75, 0.6), 50.0)
			if raze_b.hp <= 0.0:
				_collapse(raze_b)
		# risen martyrs detonate
		if a.life <= 0.0 and nodes.has("martyrs") and a.kind in ["risen", "risen_soldier"]:
			_shockwave(a.pos + Vector2(0, -6), 26.0)
			_mist(a.pos)
	allies = allies.filter(func(a): return a.life > 0.0 and a.hp > 0)
	units = units.filter(func(u): return not u.get("dead", false))
	# flood zones act
	for fz in flood:
		fz.t_left -= delta
		for u in units:
			if u.pos.x >= fz.x0 and u.pos.x <= fz.x1 and u.kind in ["police", "soldier", "tank", "arty"]:
				u.slow = 0.5
				if fz.get("plague", false) and not u.has("inf") and u.kind in ["police", "soldier"]:
					u.inf = t + 6.0
				elif nodes.has("leviathan") and randf() < 0.06 * delta * 60.0 * 0.02:
					u.dead = true
					_kill_unit(u)
					_boom(u.pos, 10, Color(0.3, 0.9, 0.9), 80.0)
		for pe in people:
			if pe.pos.x >= fz.x0 and pe.pos.x <= fz.x1:
				if fz.get("neutral", false):
					continue
				if fz.get("plague", false):
					if not pe.has("inf"):
						pe.inf = t + 3.0
				elif randf() < 0.5 * delta:
					pe.dead = true
					score_f += 15.0 * combo * TIER_MULT[tier]
					_feed("fear", 2.0)
					_mist(Vector2(pe.pos.x, -4))
	flood = flood.filter(func(fz): return fz.t_left > 0.0)
	people = people.filter(func(pe): return not pe.get("dead", false))

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
					_collapse(b)
			return true
	return false

func _rmb_active() -> void:
	# holding something? base instinct: THROW it at the cursor (Sling node does it harder)
	if not nodes.has("sling"):
		for u in units:
			if u.get("grab", false):
				u.grab = false
				u.thrown = true
				u.tvel = (aim - u.pos).normalized() * 250.0
				rmb_cd = 0.8
				shake = 4.0
				_sfx("lash")
				return
	if nodes.has("seismic"):
		rmb_cd = 2.5
		shake = 10.0
		_sfx("boom")
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
		_sfx("boom")
		for pod in pods:
			var b: Dictionary = pod.b
			var world: Vector2 = Vector2(b.x, -b.h) + pod.p
			if not b.dead:
				_carve(b, world, 11.0)
				_carve(b, world + Vector2(randf_range(-6, 6), randf_range(-6, 6)), 7.0)
				b.hp -= 22.0
				if b.hp <= 0.0 and b.dying <= 0.0:
					_collapse(b)
			_boom(world, 16, Color(0.9, 1.8, 0.5), 100.0)
			_shockwave(world, 34.0)
			score_f += 40.0 * combo * TIER_MULT[tier]
		shake = 8.0
		pods.clear()
	else:
		# base ARC LASH: sweeping tendril fan toward the cursor
		rmb_cd = 1.6
		_sfx("lash")
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
				_feed("flesh", 2.5)
				_mist(Vector2(p.pos.x, -5))
		for k in 3:
			_hit_props(pos + Vector2.from_angle(lash.ang + (k - 1) * 0.5) * hit_r * 0.8, 12.0)
		for b in buildings:
			if b.dead or b.dying > 0.0:
				continue
			for k in 3:
				var probe: Vector2 = pos + Vector2.from_angle(lash.ang + (k - 1) * 0.5) * hit_r * 0.8
				if probe.x >= b.x and probe.x <= b.x + b.w and probe.y >= -b.cur_h and probe.y <= 0.0:
					_carve(b, probe, 8.0)
					b.hp -= 8.0
					score_f += 8.0 * combo * TIER_MULT[tier]
					_feed("flesh", 2.5)
					if b.hp <= 0.0:
						_collapse(b)
		shake = maxf(shake, 4.0)
		combo_idle = 0.0

func _ignite(b: Dictionary, amt: float) -> void:
	var had: float = b.burn
	b.burn = minf(8.0, b.burn + amt)
	if not b.has("flames"):
		b.flames = []
	# each full point of burn plants a flame anchor (roofline or wound)
	while b.flames.size() < int(b.burn) and b.flames.size() < 6:
		var fx: float = randf_range(4.0, b.w - 4.0)
		var fy: float = -b.cur_h + randf_range(0.0, b.cur_h * 0.4)
		if not b.holes.is_empty() and randf() < 0.5:
			var hole: Dictionary = b.holes[randi() % b.holes.size()]
			var hp3: Vector2 = hole.p + Vector2(0, -b.h)
			fx = clampf(hp3.x, 4.0, b.w - 4.0)
			fy = clampf(hp3.y, -b.h, -2.0)
		b.flames.append({"p": Vector2(fx, fy), "s": randf_range(0.8, 1.6), "o": randf() * TAU})
	if had < 0.2 and b.burn >= 0.2:
		_sfx("boom")

func _topple(b: Dictionary, dir: float, chain: int = 0) -> void:
	# the tower doesn't crumble — it FALLS, and the street beneath is a shadow
	if b.dead or b.dying > 0.0 or b.topple > 0.0:
		return
	b.topple = 0.001
	b.top_dir = dir if dir != 0.0 else (1.0 if randf() < 0.5 else -1.0)
	b.top_chain = chain
	buildings_razed += 1
	if b.get("special", "") != "":
		specials_down += 1
	_sfx("groan")
	_hitstop(90, 0.4)
	shake = maxf(shake, 8.0)
	_pop(Vector2(b.x + b.w * 0.5, -b.cur_h - 10), "IT FALLS", Color(1.8, 1.2, 0.6))

func _topple_land(b: Dictionary) -> void:
	var pivot_x: float = b.x + (b.w if b.top_dir > 0.0 else 0.0)
	var span_lo: float = minf(pivot_x, pivot_x + b.top_dir * b.cur_h)
	var span_hi: float = maxf(pivot_x, pivot_x + b.top_dir * b.cur_h)
	b.dead = true
	b.smolder = t + 40.0
	impact_frames = 2
	shake = maxf(shake, 16.0)
	flash_t = maxf(flash_t, 0.3)
	_shockripple(Vector2(pivot_x + b.top_dir * b.cur_h * 0.5, -10.0))
	_sfx("crush")
	_hitstop(120, 0.25)
	# masonry strewn along the whole fall line
	var img_h3: float = b.img.get_height()
	for i in 5 + int(b.cur_h / 26.0):
		var fx: float = randf_range(span_lo, span_hi)
		frags.append({"tex": b.tex,
			"src": Rect2(randf() * b.img.get_width() * 0.6, randf() * img_h3 * 0.6,
				b.img.get_width() * 0.3, img_h3 * 0.25),
			"pos": Vector2(fx, -randf_range(4.0, 22.0)),
			"vel": Vector2(randf_range(-50, 50), randf_range(-120, -30)),
			"rot": 0.0, "rotv": randf_range(-3.0, 3.0),
			"w": randf_range(8.0, 20.0), "h": randf_range(6.0, 14.0), "life": randf_range(1.2, 2.0)})
	for side in [-1.0, 1.0]:
		for i in 9:
			parts.append({"pos": Vector2(clampf(pivot_x + b.top_dir * b.cur_h * 0.5 + side * i * 14.0, span_lo, span_hi), -3.0),
				"vel": Vector2(side * randf_range(30, 80), randf_range(-20, -6)),
				"life": randf_range(0.6, 1.4), "col": Color(0.35, 0.3, 0.33), "size": randf_range(3.0, 7.0)})
	_hit_props(Vector2((span_lo + span_hi) * 0.5, -4), (span_hi - span_lo) * 0.5)
	# the neighbor takes the blow — and maybe follows
	for b2 in buildings:
		if b2 == b or b2.dead or b2.dying > 0.0 or b2.topple > 0.0:
			continue
		if b2.x < span_hi and b2.x + b2.w > span_lo:
			var dmg2: float = b.maxhp * 0.45 * pow(0.55, b.top_chain)
			b2.hp -= dmg2
			for k in 3:
				_carve(b2, Vector2(clampf(randf_range(span_lo, span_hi), b2.x + 3.0, b2.x + b2.w - 3.0),
					-randf_range(b2.cur_h * 0.4, b2.cur_h * 0.95)), randf_range(3.0, 6.0))
			if b2.hp <= 0.0:
				if b.top_chain < 2 and b2.h > b2.w * 1.1 and randf() < 0.65:
					_topple(b2, b.top_dir, b.top_chain + 1)
				else:
					_collapse(b2)
	_sfx("crumble")

func _collapse(b: Dictionary) -> void:
	if b.dying > 0.0 or b.dead or b.topple > 0.0:
		return
	# tall stock prefers the sideways death — away from the killing blow
	# (specials keep the straight-down death so their payoff effects always fire)
	if b.h > b.w * 1.25 and not b.cit and b.get("special", "") == "" and b.topple == 0.0 and randf() < 0.55:
		var dir: float = signf(b.x + b.w * 0.5 - pos.x)
		_topple(b, dir)
		return
	b.dying = 0.28
	b.smolder = t + 40.0
	buildings_razed += 1
	# the rooftop birds explode into the sky
	for i in 6:
		parts.append({"pos": Vector2(b.x + randf() * b.w, -b.cur_h - 2.0),
			"vel": Vector2(randf_range(-45, 45), randf_range(-60, -30)),
			"life": randf_range(1.3, 2.2), "col": Color(0.72, 0.7, 0.78), "bird": true})
	_shockripple(Vector2(b.x + b.w * 0.5, -b.cur_h * 0.4))
	_gout(Vector2(b.x + b.w * 0.5, -b.cur_h * 0.4), "mass", minf(26.0, b.maxhp * 0.05), 5)
	# named payoffs: the lord's keep and the province landmark
	var bcx: float = b.x + b.w * 0.5
	if b.cit and lord_name != "":
		_pop(Vector2(bcx, -b.h - 40), lord_name + " IS DEAD — THE CITY IS HEADLESS", Color(2.2, 1.7, 0.6))
		for i in 8:
			people.append({"pos": Vector2(clampf(bcx + randf_range(-30, 30), 310.0, world_w - 330.0), 0),
				"vx": 0.0, "panic": true, "o": randf() * TAU, "col": Color(0.8, 0.6, 0.9)})
		people_total += 8
	if b.get("landmark_name", "") != "":
		_pop(Vector2(bcx, -b.h - 40), "THE " + str(b.landmark_name) + " FALLS", Color(1.8, 1.5, 2.0))
		score_f += 8000.0 * combo
		_gout(Vector2(bcx, -b.cur_h * 0.5), "mass", 30.0, 8)
	if b.cit:
		impact_frames = 3
	if b.get("shelter", false) and b.get("inside", 0) > 0:
		_pop(Vector2(b.x + b.w * 0.5, -b.cur_h - 24), "THE SHELTER CRACKS — %d SOULS" % b.inside, Color(2.0, 0.6, 0.5))
		score_f += b.inside * 60.0 * combo * TIER_MULT[tier]
		_gout(Vector2(b.x + b.w * 0.5, -10.0), "flesh", b.inside * 1.2, 6)
		b.inside = 0
	# the crowd beneath does not escape
	for pe in people:
		if pe.pos.x > b.x - 12.0 and pe.pos.x < b.x + b.w + 12.0:
			pe.dead = true
			score_f += 20.0 * combo * TIER_MULT[tier]
			_gout(Vector2(pe.pos.x, -6), "flesh", 1.4, 1)
			_mist(Vector2(pe.pos.x, -5))
	_hitstop(300 if b.cit else 110, 0.15 if b.cit else 0.3)
	flash_t = maxf(flash_t, 0.55 if b.cit else 0.3)
	var cx: float = b.x + b.w * 0.5
	# the building BREAKS — great slabs of it tumble out
	var img_h2: float = b.img.get_height()
	var n_frag: int = 3 + int(b.w / 30.0)
	for i in n_frag:
		var fw: float = b.w / n_frag
		var fh: float = b.cur_h * randf_range(0.25, 0.5)
		var fy: float = randf_range(0.0, b.cur_h - fh)
		frags.append({"tex": b.tex,
			"src": Rect2(fw / b.sc * i, (img_h2 - (fy + fh) / b.sc), fw / b.sc, fh / b.sc),
			"pos": Vector2(b.x + fw * (i + 0.5), -(fy + fh * 0.5)),
			"vel": Vector2((i - n_frag * 0.5) * randf_range(18, 42), randf_range(-70, -10)),
			"rot": 0.0, "rotv": randf_range(-2.5, 2.5), "w": fw, "h": fh, "life": randf_range(1.4, 2.2)})
	# expanding shockwave ring
	parts.append({"pos": Vector2(cx, -4), "vel": Vector2.ZERO, "life": 0.5, "col": Color(1.6, 1.3, 1.0),
		"ring": true, "size": 6.0})
	# heavy masonry flung out — physical chunks that bounce and crush
	for i in 3 + int(b.w / 18.0):
		parts.append({"pos": Vector2(b.x + randf() * b.w, -b.cur_h * randf_range(0.3, 0.9)),
			"vel": Vector2(randf_range(-90, 90), randf_range(-60, 10)),
			"life": randf_range(1.2, 2.4), "col": Color("#3a2c3a"), "size": randf_range(3.5, 6.0), "chunk": true})
	# dust wave rolling out from the base
	for side in [-1.0, 1.0]:
		for i in 7:
			parts.append({"pos": Vector2(cx + side * i * b.w * 0.12, -2 - randf() * 4),
				"vel": Vector2(side * randf_range(40, 90), randf_range(-16, -4)),
				"life": randf_range(0.5, 1.2), "col": Color(0.35, 0.3, 0.33), "size": randf_range(3.0, 6.0)})
	# glass shower
	var glass_n: int = 24 if b.kind in ["mall", "shop", "tower"] else 8
	for i in glass_n:
		var a := randf() * TAU
		parts.append({"pos": Vector2(b.x + randf() * b.w, -randf() * b.cur_h),
			"vel": Vector2(cos(a) * randf_range(20, 70), randf_range(-80, -20)),
			"life": randf_range(0.4, 1.0), "col": Color(0.7, 1.5, 1.8), "size": 1.5})
	match b.kind:
		"church":
			_sfx("bell")
			_pop(Vector2(cx, -b.h - 16), "THE BELL FALLS SILENT", Color(1.8, 1.4, 0.6))
		"school":
			threat = minf(100.0, threat + 6.0)   # the world does not forgive this
			_pop(Vector2(cx, -b.h - 16), "ATROCITY  — THREAT SURGES", Color(2.0, 0.4, 0.4))
		"mall":
			_sfx("glass")
	match b.get("special", ""):
		"aa":
			_pop(Vector2(cx, -b.h - 26), "AA BATTERY DOWN — THE SKY IS YOURS", Color(0.6, 1.8, 2.2))
			score_f += 2000.0 * combo
			for u in units:
				if u.kind == "jet":
					u.dead = true
		"barracks":
			city_def = city_def.duplicate()
			city_def.spawn_mult *= 0.55
			_pop(Vector2(cx, -b.h - 26), "THE ARMORY BURNS — THEIR STEEL IS ASH", Color(2.0, 0.9, 0.4))
			score_f += 2000.0 * combo
		"comms":
			threat_mult = 0.5
			city_def = city_def.duplicate()
			city_def.spawn_mult *= 0.7
			_pop(Vector2(cx, -b.h - 26), "RADIO MAST DOWN — REINFORCEMENTS FALTER", Color(0.5, 1.6, 2.0))
			score_f += 2000.0 * combo
		"fuel":
			_flash(Vector2(cx, -30.0), 3.0)
			_pop(Vector2(cx, -b.h - 26), "FUEL DEPOT IGNITES", Color(2.2, 0.8, 0.2))
			score_f += 1500.0 * combo
			for i in 6:
				var bp := Vector2(cx + randf_range(-70, 70), -randf_range(4, 40))
				aftershock_q.append({"p": bp, "t_left": 0.15 + i * 0.18})
				parts.append({"pos": bp, "vel": Vector2.ZERO, "life": 0.3, "col": Color(2.6, 1.6, 0.6), "flash": true, "size": 20.0})
			for b2 in buildings:
				if b2 != b and not b2.dead and absf(b2.x - b.x) < 130.0:
					_ignite(b2, 3.0)
			shake = 22.0
	if b.get("special", "") != "":
		specials_down += 1
	# stolen powers answer every razing
	if "gravitymaw" in Global.grafts:
		for u in units:
			if not u.get("dead", false) and not u.kind in ["jet", "herald"] and absf(u.pos.x - cx) < 170.0:
				u.hp = u.get("hp", 1) - 1
				_boom(u.pos + Vector2(0, -8), 5, Color(1.5, 1.0, 0.6), 70.0)
				if u.hp <= 0:
					u.dead = true
					_kill_unit(u)
	if "faultline" in Global.grafts:
		for u in units:
			if not u.get("dead", false) and u.kind in ["police", "soldier", "tank", "arty", "flamer", "priest"] \
					and absf(u.pos.x - cx) < 80.0:
				u.hp = u.get("hp", 1) - 2
				u.fall = true
				u.vy = -70.0
				if u.hp <= 0:
					u.dead = true
					_kill_unit(u)
		parts.append({"pos": Vector2(cx, -2), "vel": Vector2.ZERO, "life": 0.4, "col": Color(1.6, 0.9, 0.4), "ring": true, "size": 8.0})
	if "assimilate" in Global.grafts:
		hp = minf(100.0, hp + 8.0)
	# ruptured gas main — the street answers in fire
	if node_kind in ["city", "capital"] and b.get("special", "") == "" and randf() < 0.15:
		var gdir: float = 1.0 if randf() < 0.5 else -1.0
		for gi in 3:
			aftershock_q.append({"p": Vector2(cx + gdir * (30.0 + gi * 34.0), -6.0), "t_left": 0.25 + gi * 0.22})
		_pop(Vector2(cx, -18), "GAS MAIN RUPTURES", Color(2.2, 1.2, 0.3))
	_sfx("crumble")

func _hit_props(p: Vector2, r: float) -> void:
	# no creature is exempt
	for cr in critters:
		if not cr.dead and absf(cr.pos.x - p.x) < r and p.y > -34.0:
			cr.dead = true
			_boom(cr.pos + Vector2(0, -3), 4, Color(0.8, 0.4, 0.4), 40.0)
			score_f += 5.0 * combo
	# evac buses — three hits of armor, a feast inside
	for bus in buses:
		if bus.get("dead", false) or absf(bus.x - p.x) > r + 14.0 or p.y < -22.0:
			continue
		bus.hp -= 1
		_boom(Vector2(bus.x, -8), 6, Color(1.8, 1.4, 0.6), 70.0)
		if bus.hp <= 0:
			bus.dead = true
			var gain := int(300.0 * combo * TIER_MULT[tier] * 2.0)
			score_f += gain
			_feed("flesh", 14.0)
			pass
			hp = minf(100.0, hp + 4.0)
			for i in 8:
				_mist(Vector2(bus.x + randf_range(-10, 10), -6))
			_explode(Vector2(bus.x, -7), "car")
			_pop(Vector2(bus.x, -22), "EVAC BUS DOWN  +%d" % gain, Color(1.9, 1.2, 0.5))
	for pr in props:
		if pr.dead or absf(pr.x - p.x) > r + 10.0 or p.y < -26.0:
			continue
		pr.dead = true
		score_f += 25.0 * combo * TIER_MULT[tier]
		_boom(Vector2(pr.x, -8), 10, Color(1.6, 1.4, 1.8), 80.0)
		_sfx("glass")
	for cr in critters:
		if cr.dead or absf(cr.pos.x - p.x) > r or p.y < -30.0:
			continue
		cr.dead = true
		score_f += 12.0 * combo * TIER_MULT[tier]
		_feed("flesh", 1.5)
		if cr.kind == "pigeon":
			for i in 6:
				parts.append({"pos": cr.pos + Vector2(0, -3), "vel": Vector2(randf_range(-30, 30), randf_range(-40, -8)),
					"life": randf_range(0.4, 0.9), "col": Color(0.7, 0.68, 0.72), "size": 1.5})
		else:
			_mist(cr.pos + Vector2(0, -3))
	# lamps and cars are destructible — everything is
	for l in lamps:
		if l.dead or absf(l.x - p.x) > r or p.y < -34.0:
			continue
		l.dead = true
		lamps_down += 1
		score_f += 15.0 * combo * TIER_MULT[tier]
		_boom(Vector2(l.x, -24), 8, Color(2.0, 1.7, 0.9), 80.0)
		_feed("light", 8.0)
		if character == "tzitzimitl":
			_pop(Vector2(l.x, -30), "LIGHT DEVOURED", Color(1.9, 1.4, 0.5))
	for c in cars:
		if c.dead or absf(c.x + c.w * 0.5 - p.x) > r + c.w * 0.5 or p.y < -20.0:
			continue
		c.dead = true
		score_f += 40.0 * combo * TIER_MULT[tier]
		_feed("charge", 3.0)
		_explode(Vector2(c.x + c.w * 0.5, -5), "car")
		for b in buildings:
			if not b.dead and b.dying <= 0.0 and c.x + c.w * 0.5 >= b.x and c.x <= b.x + b.w:
				_ignite(b, 0.8)
				break

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
	_feed("mass", bite * 0.5)
	if bite_cd <= 0.0:
		# slower, heavier bites — each one tears a real wound
		bite_cd = 0.42 if maul else 0.32
		_sfx("bite")
		combo = min(9.5, combo + 0.12)
		var r1: float = randf_range(9.0, 14.0) * (1.6 if maul else 1.0)
		_carve(b, aim, r1)
		_carve(b, aim + Vector2(randf_range(-7, 7), randf_range(-7, 7)), r1 * 0.65)
		_carve(b, aim + Vector2(randf_range(-9, 9), randf_range(-4, 10)), r1 * 0.4)
		b.hp -= 9.0 * (1.6 if maul else 1.0)
		b.holes.append({"p": aim - Vector2(b.x, -b.h), "o": randf() * TAU})
		_boom(aim, 9 if maul else 6, Color("#7a6a7a"), 110.0 if maul else 90.0)
		_chunks(aim, 7 if maul else 5)
		shake = maxf(shake, 5.0 if maul else 3.0)
		_hit_props(aim, 14.0)
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
		_collapse(b)
		var gain := int(b.maxhp * 8.0 * combo * TIER_MULT[tier] * (4.0 if b.cit else 1.0))
		score_f += gain
		combo = min(9.5, combo + 0.5)
		hp = min(100.0, hp + 5.0)
		shake = 16.0 if b.cit else 8.0
		_boom(Vector2(b.x + b.w * 0.5, -b.cur_h * 0.5), 60 if b.cit else 26, Color("#5a4a58"), 110.0)
		_pop(Vector2(b.x + b.w * 0.5, -b.h - 14), ("CITADEL FELL  +" if b.cit else "+") + _fmt(gain),
			Color("#ffd75a") if b.cit else Color("#ffb08a"))

const BRANCH_DEFS := {
	"swarm": [
		{"id": "ironmaw", "name": "IRONMAW", "desc": "chitin mauls — heavier, wider smashes; every smash shockwaves nearby units"},
		{"id": "gorehook", "name": "GOREHOOK", "desc": "barbed hooks — reel everything 2x faster, grind harder through walls"},
		{"id": "spore", "name": "SPORE BLOOM", "desc": "plant pods in wounds — they keep gnawing the building on their own"},
	],
	"keraunos": [
		{"id": "manyheads", "name": "MANYHEADS", "desc": "a fourth throat wakes — every strike forks to a second target nearby"},
		{"id": "ball", "name": "BALL LIGHTNING", "desc": "strikes leave living orbs that keep zapping whatever comes close"},
		{"id": "skyfall", "name": "SKYFALL", "desc": "RMB becomes the mega-bolt: a column of ruin that deletes a vertical slice"},
	],
	"tzitzimitl": [
		{"id": "suneater", "name": "SUN-EATER", "desc": "eclipse lasts 16s and the army wilts and dies in your darkness"},
		{"id": "obsidian", "name": "OBSIDIAN FANGS", "desc": "wider lance wounds; each building pierced in one dive hits +15% harder"},
		{"id": "feather", "name": "FEATHER STORM", "desc": "every dive molts razor feathers that drift down and cut what they touch"},
	],
	"drowned": [
		{"id": "choir", "name": "ABYSSAL CHOIR", "desc": "madness is contagious — when the maddened burn out, it leaps to whoever stands closest"},
		{"id": "tide", "name": "BLACK TIDE", "desc": "floodwater rises in your wake — slows the army, drowns the crowds, feeds your spawn"},
		{"id": "father", "name": "FATHER OF THE DEEP", "desc": "the deep answers with brutes — bigger squads, twice the muscle"},
	],
	"rider": [
		{"id": "legion", "name": "LEGION", "desc": "the horde doubles — sixteen dead walk behind you"},
		{"id": "blight", "name": "BLIGHTLORD", "desc": "your passage paints plague ground that infects all who stand on it"},
		{"id": "crown", "name": "CARRION CROWN", "desc": "fallen soldiers rise still holding their guns — your dead shoot back"},
	],
}
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
	"manyheads": [
		{"id": "fourthhead", "name": "FIFTH THROAT", "kind": "PASSIVE", "desc": "+1 banked bolt and faster recharge"},
		{"id": "overcharge", "name": "OVERCHARGE", "kind": "PASSIVE", "desc": "strikes set buildings properly ablaze and tear wider craters"},
		{"id": "stormfront", "name": "STORMFRONT", "kind": "ACTIVE — RMB", "desc": "TEMPEST costs less and rains nine bolts instead of seven"},
	],
	"ball": [
		{"id": "twincast", "name": "TWIN CAST", "kind": "PASSIVE", "desc": "every strike leaves two orbs"},
		{"id": "magnetize", "name": "MAGNETIZE", "kind": "PASSIVE", "desc": "orbs drift to the nearest building and gnaw at it"},
		{"id": "resonance", "name": "RESONANCE", "kind": "PASSIVE", "desc": "orbs near each other arc — the arcs fry anything crossing them"},
	],
	"skyfall": [
		{"id": "annihilate", "name": "ANNIHILATE", "kind": "PASSIVE", "desc": "the column is nearly twice as wide"},
		{"id": "thunderclap", "name": "THUNDERCLAP", "kind": "PASSIVE", "desc": "skyfall stuns every unit on the field for 2 seconds"},
		{"id": "conductor", "name": "CONDUCTOR", "kind": "PASSIVE", "desc": "skyfall costs 25 storm instead of 40"},
	],
	"suneater": [
		{"id": "blackdawn", "name": "APHOTIC", "kind": "PASSIVE", "desc": "the devouring's blackout shock lasts 8 seconds longer"},
		{"id": "gorger", "name": "STAR GORGER", "kind": "PASSIVE", "desc": "kills in the dark knit your body back together"},
		{"id": "voidheart", "name": "VOIDHEART", "kind": "PASSIVE", "desc": "devouring the sun costs 55 hunger instead of 80"},
	],
	"obsidian": [
		{"id": "sonicboom", "name": "SONIC BOOM", "kind": "PASSIVE", "desc": "every dive ends in a concussive shockwave"},
		{"id": "serration", "name": "SERRATION", "kind": "PASSIVE", "desc": "dive cooldown cut nearly in half"},
		{"id": "cleave", "name": "CLEAVE", "kind": "PASSIVE", "desc": "pierced buildings catch fire and keep burning"},
	],
	"feather": [
		{"id": "molt", "name": "HEAVY MOLT", "kind": "PASSIVE", "desc": "six feathers per dive instead of three"},
		{"id": "rain", "name": "FEATHER RAIN", "kind": "PASSIVE", "desc": "during eclipse, blades rain across the whole sky"},
		{"id": "keen", "name": "KEEN EDGE", "kind": "PASSIVE", "desc": "feathers also gouge the buildings they brush"},
	],
	"choir": [
		{"id": "echoes", "name": "ECHOES", "kind": "PASSIVE", "desc": "madden twice as often"},
		{"id": "hollowing", "name": "HOLLOWING", "kind": "PASSIVE", "desc": "the maddened last 8 seconds longer before burning out"},
		{"id": "dirge", "name": "DIRGE", "kind": "PASSIVE", "desc": "your presence alone frays their aim"},
	],
	"tide": [
		{"id": "depths", "name": "THE DEPTHS", "kind": "PASSIVE", "desc": "floodwater never drains"},
		{"id": "leviathan", "name": "LEVIATHAN", "kind": "PASSIVE", "desc": "things in the flood get pulled under"},
		{"id": "tideborn", "name": "TIDEBORN", "kind": "PASSIVE", "desc": "a fishman crawls ashore every 30 seconds, free"},
	],
	"father": [
		{"id": "priests", "name": "DEEP PRIESTS", "kind": "PASSIVE", "desc": "each calling brings a priest who maddens the enemy"},
		{"id": "whelp", "name": "LEVIATHAN WHELP", "kind": "PASSIVE", "desc": "something enormous rises in your floodwater"},
		{"id": "tideborn", "name": "TIDEBORN", "kind": "PASSIVE", "desc": "a fishman crawls ashore every 30 seconds, free"},
	],
	"legion": [
		{"id": "martyrs", "name": "MARTYRS", "kind": "PASSIVE", "desc": "risen burst on death"},
		{"id": "drill", "name": "DEATH MARCH", "kind": "PASSIVE", "desc": "the horde moves twice as fast"},
		{"id": "endless", "name": "ENDLESS", "kind": "PASSIVE", "desc": "the risen never crumble on their own"},
	],
	"blight": [
		{"id": "miasma", "name": "MIASMA", "kind": "PASSIVE", "desc": "plague ground spreads wider"},
		{"id": "spores", "name": "SPORE WIND", "kind": "PASSIVE", "desc": "plague ground lasts twice as long"},
		{"id": "endless", "name": "ENDLESS", "kind": "PASSIVE", "desc": "the risen never crumble on their own"},
	],
	"crown": [
		{"id": "martyrs", "name": "MARTYRS", "kind": "PASSIVE", "desc": "risen burst on death"},
		{"id": "drill", "name": "DEATH MARCH", "kind": "PASSIVE", "desc": "the horde moves twice as fast"},
		{"id": "endless", "name": "ENDLESS", "kind": "PASSIVE", "desc": "the risen never crumble on their own"},
	],
}

const DELTA := {
	"ironmaw": ["smash damage +60%", "smash arc +40% wider", "smashes shockwave nearby"],
	"gorehook": ["reel speed x2", "drag damage +100%", "grabs grind through walls"],
	"spore": ["wounds seed living pods", "each pod gnaws 2/s", "pods stack per building"],
	"manyheads": ["banked bolts 3 > 4", "strikes fork to 2nd target"],
	"ball": ["strikes leave a live orb", "orbs zap whatever comes close"],
	"skyfall": ["RMB = vertical ruin column", "deletes a full slice", "cost 40 storm"],
	"suneater": ["eclipse 8s > 16s", "army wilts in your dark"],
	"obsidian": ["lance wounds +50% wider", "+15% dmg per building pierced"],
	"feather": ["dives molt 3 razor feathers", "feathers cut on contact"],
	"choir": ["madness leaps on burnout", "spread radius 60px"],
	"tide": ["your wake floods streets", "flood slows army 50%", "crowds drown in it"],
	"father": ["the deep sends brutes", "squads x2 size", "brute damage x2"],
	"legion": ["horde cap 8 > 16"],
	"blight": ["passage paints plague ground", "standing on it infects"],
	"crown": ["fallen soldiers rise ARMED", "your dead shoot back"],
	"seismic": ["NEW: RMB street shockwave", "flips units both ways", "cracks foundations"],
	"chitin": ["damage taken -35%"],
	"aftershock": ["every smash echoes", "2nd shockwave at 0.4s"],
	"sling": ["NEW: RMB hurl grabbed unit", "empty-handed: self grapple"],
	"flenser": ["thrown bodies dmg x2"],
	"sinew": ["reach +40%", "hold 2 victims at once"],
	"burst": ["NEW: RMB detonate all pods", "craters + shockwaves"],
	"creep": ["dying pods seed a child"],
	"cloud": ["kills heal +6", "kills combo +0.3"],
	"fourthhead": ["+1 banked bolt", "recharge faster"],
	"overcharge": ["strikes truly ignite", "craters +50% wider"],
	"stormfront": ["TEMPEST: 7 > 9 bolts", "cost -30%"],
	"twincast": ["2 orbs per strike"],
	"magnetize": ["orbs seek buildings", "orbs gnaw walls"],
	"resonance": ["orb pairs arc together", "arcs fry crossers"],
	"annihilate": ["column ~2x wide"],
	"thunderclap": ["skyfall stuns ALL 2s"],
	"conductor": ["skyfall 40 > 25 storm"],
	"blackdawn": ["blackout +8s"],
	"gorger": ["kills in the dark heal you"],
	"voidheart": ["devour cost 80 > 55"],
	"sonicboom": ["dives end in shockwave"],
	"serration": ["dive cooldown -45%"],
	"cleave": ["pierced buildings burn on"],
	"molt": ["3 > 6 feathers per dive"],
	"echoes": ["madden cooldown halved"],
	"hollowing": ["madness lasts +8s"],
	"leviathan": ["flood drowns soldiers"],
	"miasma": ["plague ground wider"],
	"spores": ["plague ground lasts x2"],
	"endless": ["risen never crumble"],
	"drill": ["horde moves x2 speed"],
	"martyrs": ["risen burst on death"],
	"dirge": ["near you, their aim frays"],
	"apotheosis": ["size +15%", "damage taken -20%", "all essence +25%"],
}
var draft_opts: Array = []
var draft_title := ""

func _open_draft() -> void:
	draft_open = true
	if branch == "":
		draft_title = "THE MOLT — CHOOSE YOUR LINE"
		draft_opts = BRANCH_DEFS[character].duplicate()
	else:
		draft_title = "THE MOLT — " + branch.to_upper() + " DEEPENS"
		draft_opts = NODE_DEFS[branch].filter(func(n): return not nodes.has(n.id))
		if draft_opts.is_empty():
			draft_title = "THE LINE IS COMPLETE"
			draft_opts = [{"id": "apotheosis", "name": "APOTHEOSIS", "kind": "CAPSTONE",
				"desc": "become the thing the myths warned about"}]
	_sfx("pick")
	if draft_ui != null:
		draft_ui.visible = true

func _pick_draft(id: String) -> void:
	var picked_name := ""
	if id == "apotheosis":
		nodes["apotheosis"] = true
		growth_mult += 0.15
		dmg_taken_mult *= 0.8
		essence_mult *= 1.25
		bio_stage += 1
		draft_open = false
		if draft_ui != null:
			draft_ui.visible = false
		impact_frames = 2
		_pop(pos + Vector2(0, -24), "APOTHEOSIS", Color(2.4, 1.8, 0.8))
		return
	if branch == "":
		branch = id
		picked_name = BRANCH_DEFS[character].filter(func(d): return d.id == id)[0].name
		match id:
			"manyheads": bolt_max = 4.0
			"suneater": eclipse_len = 16.0
	else:
		nodes[id] = true
		picked_name = NODE_DEFS[branch].filter(func(d): return d.id == id)[0].name
		match id:
			"chitin": dmg_taken_mult = 0.65
			"sinew":
				tendril_range = 140.0
				max_grabs = 2
			"fourthhead": bolt_max += 1.0
			"voidheart": eclipse_cost = 55.0
			"blackdawn": eclipse_len += 8.0
	bio_stage += 1
	draft_open = false
	if draft_ui != null:
		draft_ui.visible = false
	_boom(pos, 20, Color(1.8, 0.6, 0.6), 90.0)
	_pop(pos + Vector2(0, -24), picked_name, Color(2.0, 0.6, 0.7))
	radius = minf(24.0, radius + 2.0)  # visible growth per evolution

class DraftUI extends Control:
	var m: Node2D   # main
	var hover := -1
	func _init(main_ref: Node2D) -> void:
		m = main_ref
		size = Vector2(640, 360)
		mouse_filter = Control.MOUSE_FILTER_STOP
		visible = false
	func _process(_d: float) -> void:
		visible = m.draft_open or (m.over and m.end_label != "")
		if visible:
			queue_redraw()
	func _card_rect(i: int, n: int) -> Rect2:
		var w := 140.0
		var gap := 14.0
		var total: float = n * w + (n - 1) * gap
		var x0: float = (640.0 - total) * 0.5
		return Rect2(x0 + i * (w + gap), 74.0 + (-8.0 if hover == i else 0.0), w, 218.0)
	func _gui_input(e: InputEvent) -> void:
		if not visible:
			return
		if not m.draft_open:
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				m._end_click()
				accept_event()
			return
		if e is InputEventMouseMotion:
			hover = -1
			for i in m.draft_opts.size():
				if _card_rect(i, m.draft_opts.size()).has_point(e.position):
					hover = i
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			for i in m.draft_opts.size():
				if _card_rect(i, m.draft_opts.size()).has_point(e.position):
					m._pick_draft(m.draft_opts[i].id)
					accept_event()
					return
	func _draw() -> void:
		var f: FontFile = m.ui_font
		var tt: float = Time.get_ticks_msec() * 0.001
		if not m.draft_open:
			# the crusade end-card, in the card language
			var armed: bool = m.over_t >= 0.8
			var r0 := Rect2(220, 222, 200, 40)
			var bord0: Color = Color(1.9, 0.6, 0.6) if armed else Color(0.35, 0.3, 0.4)
			draw_rect(r0, Color("#151020"))
			for edge0 in [Rect2(r0.position, Vector2(r0.size.x, 2)), Rect2(r0.position + Vector2(0, r0.size.y - 2), Vector2(r0.size.x, 2)),
					Rect2(r0.position, Vector2(2, r0.size.y)), Rect2(r0.position + Vector2(r0.size.x - 2, 0), Vector2(2, r0.size.y))]:
				draw_rect(edge0, bord0)
			for c0 in [Vector2.ZERO, Vector2(r0.size.x - 6, 0), Vector2(0, r0.size.y - 6), Vector2(r0.size.x - 6, r0.size.y - 6)]:
				draw_rect(Rect2(r0.position + c0, Vector2(6, 6)), bord0)
			draw_string(f, Vector2(r0.position.x, r0.position.y + 25), m.end_label, HORIZONTAL_ALIGNMENT_CENTER, r0.size.x, 12,
				Color(1.8, 0.55, 0.55) if armed else Color(0.6, 0.55, 0.65))
			return
		draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.0, 0.05, 0.93))
		draw_string(f, Vector2(0, 36), m.draft_title, HORIZONTAL_ALIGNMENT_CENTER, 640, 17, Color(1.9, 0.5, 0.55))
		draw_string(f, Vector2(0, 52), "what is shed does not return", HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color("#8890b0"))
		# ---- left: the god on its essence pedestal ----
		var gp := Vector2(46, 168)
		draw_arc(gp + Vector2(0, 52), 36.0, PI, TAU, 26, Color(1.6, 0.4, 0.4, 0.4 + 0.15 * sin(tt * 2.0)), 1.5)
		draw_circle(gp + Vector2(0, 52), 36.0, Color(0.5, 0.1, 0.15, 0.14))
		for e2 in 7:
			var ey: float = fmod(e2 * 19.7 + tt * 22.0, 78.0)
			draw_rect(Rect2(gp.x - 26 + fmod(e2 * 31.3, 52.0), gp.y + 52 - ey, 1.5, 1.5),
				Color(1.8, 0.6, 0.5, 0.8 - ey * 0.01))
		match m.character:
			"swarm":
				draw_circle(gp, 26.0, Color(0.9, 0.12, 0.18, 0.14))
				draw_circle(gp, 17.0, Color("#2a0614"))
				for mm in 24:
					var ma: float = mm * 2.4 + tt * 0.6
					var mp := gp + Vector2(cos(ma), sin(ma * 1.3)) * (10.0 + fmod(mm * 7.7, 14.0))
					draw_line(mp, mp + Vector2(2.5, 1), Color(1.7, 0.4, 0.4), 1.0)
				draw_circle(gp + Vector2(8, -5), 4.0, Color(1.8, 1.1, 0.3))
			"keraunos":
				draw_circle(gp, 16.0, Color(0.10, 0.11, 0.18))
				for h2 in 3:
					var hh := gp + Vector2((h2 - 1) * 12.0, -22.0 + sin(tt * 2.0 + h2) * 2.0)
					draw_line(gp + Vector2((h2 - 1) * 4.0, -8), hh, Color(0.10, 0.11, 0.18), 3.0)
					draw_circle(hh, 3.5, Color(0.16, 0.18, 0.28))
					draw_circle(hh + Vector2(2, 0), 1.2, Color(1.2, 2.0, 2.6))
				if randf() < 0.1:
					draw_line(gp + Vector2(randf_range(-14, 14), -20), gp + Vector2(randf_range(-18, 18), 8), Color(1.4, 1.9, 2.4, 0.7), 1.0)
			"tzitzimitl":
				var prev := gp + Vector2(-22, 14)
				for s2 in 9:
					var f4: float = s2 / 8.0
					var npt := gp + Vector2(-22 + f4 * 44.0, 14.0 - sin(f4 * PI) * 26.0 + sin(tt * 2.0 + f4 * 5.0) * 2.0)
					draw_line(prev, npt, Color(0.10, 0.48, 0.47), 5.0 * (1.0 - absf(f4 - 0.5)))
					prev = npt
				draw_circle(prev, 4.5, Color(0.23, 0.72, 0.66))
				draw_circle(prev + Vector2(2, -1), 1.3, Color(2.4, 1.5, 0.3))
			"drowned":
				draw_colored_polygon(PackedVector2Array([gp + Vector2(-14, 30), gp + Vector2(-12, -6),
					gp + Vector2(-4, -24), gp + Vector2(5, -23), gp + Vector2(12, -4), gp + Vector2(14, 30)]),
					Color(0.02, 0.08, 0.10))
				for tn in 5:
					draw_line(gp + Vector2((tn - 2) * 3.5, -12), gp + Vector2((tn - 2) * 4.5 + sin(tt * 2.0 + tn) * 2.0, -2 + (tn % 2) * 4), Color(0.04, 0.13, 0.15), 2.0)
				draw_circle(gp + Vector2(-4, -17), 1.6, Color(1.3, 2.4, 2.2))
				draw_circle(gp + Vector2(4, -17), 1.6, Color(1.3, 2.4, 2.2))
			"rider":
				draw_colored_polygon(PackedVector2Array([gp + Vector2(16, 26), gp + Vector2(18, -2),
					gp + Vector2(6, -22), gp + Vector2(-4, -26), gp + Vector2(-16, -14 + sin(tt * 2.0) * 2.0),
					gp + Vector2(-24, 8), gp + Vector2(-18, 26)]), Color(0.075, 0.06, 0.09))
				draw_circle(gp + Vector2(-2, -20), 3.5, Color(0.88, 0.83, 0.66))
				draw_circle(gp + Vector2(-1, -21), 0.9, Color(1.9, 1.6, 0.6))
				draw_arc(gp + Vector2(2, -30), 12.0, -0.4, 1.5, 12, Color(0.97, 0.93, 0.78), 2.2)
		draw_string(f, Vector2(0, 244), m.character.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 92, 10, Color(1.7, 0.5, 0.5))
		var stage_s: String = ("stage %d" % (m.bio_stage + 1)) + ("" if m.branch == "" else " - " + m.branch.to_upper())
		draw_string(f, Vector2(0, 256), stage_s, HORIZONTAL_ALIGNMENT_CENTER, 92, 7, Color("#8890b0"))
		# ---- the cards ----
		for i in m.draft_opts.size():
			var d: Dictionary = m.draft_opts[i]
			var r := _card_rect(i, m.draft_opts.size())
			var hovered: bool = hover == i
			var bord: Color = Color(1.9, 0.6, 0.6) if hovered else Color(0.4, 0.32, 0.45)
			if hovered:
				draw_rect(Rect2(r.position - Vector2(4, 4), r.size + Vector2(8, 8)), Color(1.9, 0.6, 0.6, 0.10))
			draw_rect(r, Color("#151020"))
			for edge in [Rect2(r.position, Vector2(r.size.x, 2)), Rect2(r.position + Vector2(0, r.size.y - 2), Vector2(r.size.x, 2)),
					Rect2(r.position, Vector2(2, r.size.y)), Rect2(r.position + Vector2(r.size.x - 2, 0), Vector2(2, r.size.y))]:
				draw_rect(edge, bord)
			for corner in [Vector2.ZERO, Vector2(r.size.x - 6, 0), Vector2(0, r.size.y - 6), Vector2(r.size.x - 6, r.size.y - 6)]:
				draw_rect(Rect2(r.position + corner, Vector2(6, 6)), bord)
			var cxx: float = r.position.x + r.size.x * 0.5
			# kind ribbon
			var kind_s: String = d.get("kind", "LINE")
			var rib: Color = Color(0.9, 0.4, 0.2) if "ACTIVE" in kind_s else (Color(0.8, 0.65, 0.25) if kind_s == "CAPSTONE" else Color(0.35, 0.5, 0.75))
			draw_rect(Rect2(r.position.x + 8, r.position.y + 8, r.size.x - 16, 12), Color(rib.r, rib.g, rib.b, 0.22))
			draw_string(f, Vector2(r.position.x, r.position.y + 17), kind_s, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 6, rib.lightened(0.4))
			# name
			draw_string(f, Vector2(r.position.x, r.position.y + 38), d.name, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, Color(0.95, 0.9, 1.0))
			# flavor, wrapped at ~25 chars
			var words: PackedStringArray = str(d.get("desc", "")).split(" ")
			var line := ""
			var ly: float = r.position.y + 54.0
			for w2 in words:
				if line.length() + w2.length() > 22:
					draw_string(f, Vector2(r.position.x, ly), line, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 6, Color("#8890b0"))
					ly += 9.0
					line = w2
				else:
					line += (" " if line != "" else "") + w2
				if ly > r.position.y + 98.0:
					break
			if line != "" and ly <= r.position.y + 98.0:
				draw_string(f, Vector2(r.position.x, ly), line, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 6, Color("#8890b0"))
			# WHAT CHANGES
			draw_rect(Rect2(r.position.x + 8, r.position.y + 112, r.size.x - 16, 1), Color(bord.r, bord.g, bord.b, 0.5))
			draw_string(f, Vector2(r.position.x, r.position.y + 124), "WHAT CHANGES", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 6, Color(1.6, 1.3, 0.6))
			var dls: Array = m.DELTA.get(d.id, [])
			for dl in dls.size():
				draw_string(f, Vector2(r.position.x + 12, r.position.y + 138 + dl * 11), "- " + str(dls[dl]),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.72, 0.88, 0.72))
			draw_string(f, Vector2(r.position.x, r.position.y + r.size.y - 10), "[%d]" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 7, Color(0.6, 0.55, 0.7))
		draw_string(f, Vector2(0, 348), "1 / 2 / 3 or click - the unpicked wither away", HORIZONTAL_ALIGNMENT_CENTER, 640, 7, Color(0.6, 0.55, 0.7))

func _aa_alive() -> bool:
	for b in buildings:
		if b.get("special", "") == "aa" and not b.dead and b.dying <= 0.0 and b.topple == 0.0:
			return true
	return false

func _kill_unit(u: Dictionary) -> void:
	var base: int
	match u.kind:
		"tank": base = 800
		"heli": base = 600
		"arty": base = 900
		"jet": base = 1200
		"news":
			base = 800
			threat = minf(100.0, threat + 8.0)
			_pop(u.pos + Vector2(0, -14), "LIVE FEED SEVERED — THE WORLD SAW", Color(2.0, 0.5, 0.4))
		"flamer": base = 350
		"militia": base = 100
		"brood": base = 150
		"herald":
			base = 20000
			var hd: Dictionary = HERALD_DEFS[u.htype]
			herald_alive = false
			herald_due = ""
			Global.heralds_slain.append(u.htype)
			Global.grafts.append(hd.graft)
			Global.roar += 150.0
			if Global.heralds_slain.size() >= 3:
				Global.act3_ready = true
			Global.save_crusade()
			growth_cap = 1.75 + 0.35 * Global.heralds_slain.size()
			impact_frames = 4
			shake = 26.0
			_shockripple(u.pos)
			Global.music("battle", tier)
			hp = minf(100.0, hp + 40.0)
			_pop(u.pos + Vector2(0, -60), hd.name + " IS DEVOURED", Color(2.4, 1.2, 0.9))
			_pop(pos + Vector2(0, -30), "GRAFT SEIZED: " + hd.gname, Color(1.8, 1.9, 1.0))
			_pop(pos + Vector2(0, -18), hd.gdesc, Color(1.3, 1.4, 0.9))
			if Global.act3_ready:
				_pop(Vector2(pos.x, -110), "THE STARS ARE LISTENING NOW", Color(2.0, 1.4, 2.2))
		"priest":
			base = 500
			_pop(u.pos + Vector2(0, -14), "THE PRAYER ENDS", Color(1.8, 1.6, 1.0))
		"champ":
			base = 5000
			threat = maxf(0.0, threat - 12.0)
			impact_frames = 2
			_pop(u.pos + Vector2(0, -30), u.get("name", "THE CHAMPION") + " HAS FALLEN — THE ARMY REELS", Color(2.2, 1.7, 0.6))
			_sfx("bell")
		"soldier": base = 120
		"carcass": base = 150
		_: base = 300
	unit_kills += 1
	var gain := int(base * combo * TIER_MULT[tier])
	score_f += gain
	_gout(u.pos + Vector2(0, -8), "death", 20.0 if u.kind == "tank" else 12.0, 4)
	combo = minf(9.5, combo + (0.6 if nodes.has("cloud") else 0.3))
	combo_idle = 0.0
	hp = minf(100.0, hp + ((6.0 if u.kind == "tank" else 4.0) + (6.0 if nodes.has("cloud") else 0.0)) * heal_mult)
	threat = minf(100.0, threat + 1.5)
	shake = 10.0
	# SPAWN BROOD graft — your kills birth fighters
	if "spawnbrood" in Global.grafts and randf() < 0.25 and allies.size() < 14:
		allies.append({"kind": "risen", "pos": Vector2(u.pos.x, -4), "hp": 2, "cd": 0.0, "life": 20.0})
	if u.kind in ["tank", "heli", "jet", "arty"]:
		_hitstop(60, 0.4)
	_explode(u.pos + Vector2(0, -8), u.kind)
	_pop(u.pos + Vector2(0, -20), "+%d" % gain, Color("#ffd75a"))

func _explode(p: Vector2, kind: String) -> void:
	_sfx("boom")
	parts.append({"pos": p, "vel": Vector2.ZERO, "life": 0.22, "col": Color(2.6, 1.8, 0.9), "flash": true, "size": 16.0})
	parts.append({"pos": p, "vel": Vector2.ZERO, "life": 0.5, "col": Color(2.0, 1.4, 0.7), "ring": true, "size": 4.0})
	flash_t = maxf(flash_t, 0.15)
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
		parts.append({"pos": p, "vel": Vector2(randf_range(-50, 50), randf_range(-80, -10)),
			"life": randf_range(0.9, 1.9), "col": Color("#4a3a4a"), "size": randf_range(2.5, 4.5),
			"chunk": true, "rot": randf() * TAU, "rotv": randf_range(-6.0, 6.0)})

func _army(delta: float) -> void:
	var defense: float = city_def.defense
	spawn_cd -= delta
	var cap: int = int((2 + tier * 3) * city_def.spawn_mult)
	if tier >= 1 and spawn_cd <= 0.0 and units.size() < cap and stun_t <= 0.0 and blackout_t <= 0.0:
		spawn_cd = maxf(0.3, (1.4 - tier * 0.18) / city_def.spawn_mult)
		var side: float = -1.0 if randf() < 0.5 else 1.0
		var x: float = pos.x + side * randf_range(360, 560)
		if x > 30 and x < world_w - 30:
			var roll := randf()
			if node_militia:
				# the army has not come yet — the province defends itself
				if roll < 0.3:
					units.append({"kind": "police", "pos": Vector2(x, 0), "cd": randf_range(0.8, 1.4), "hp": 1})
				else:
					for i in 2:
						units.append({"kind": "militia", "pos": Vector2(x + i * 9.0, 0), "cd": randf_range(1.2, 2.4), "hp": 1})
			elif tier >= 5 and not champ_spawned and not prologue:
				# the world sends its best — a named champion, once per battle
				champ_spawned = true
				var cname: String = ["COL. VASHKO", "MARSHAL HELVIG", "CMDR. OKONKWO", "GEN. THARN"][randi() % 4]
				units.append({"kind": "champ", "pos": Vector2(x, 0), "cd": 2.0, "hp": 14, "name": cname})
				_pop(Vector2(x, -40), cname + " TAKES THE FIELD", Color(2.2, 1.6, 0.5))
				_sfx("horn")
			elif tier >= 5 and roll < 0.15 and not units.any(func(u): return u.kind == "jet"):
				units.append({"kind": "jet", "pos": Vector2(pos.x - side * 700.0, -250), "cd": 0.0,
					"hp": 2, "vx": side * 300.0, "bombs": 3})
			elif tier >= 4 and roll < 0.45:
				units.append({"kind": "heli", "pos": Vector2(x, randf_range(-220, -150)), "cd": randf_range(0.5, 1.2), "hp": 2})
			elif tier >= 3 and roll < 0.62:
				if randf() < 0.22:
					units.append({"kind": "arty", "pos": Vector2(x, 0), "cd": randf_range(1.5, 2.5), "hp": 2})
				elif randf() < 0.2:
					# a priest walks with the column, warding minds and blessing guns
					units.append({"kind": "priest", "pos": Vector2(x, 0), "cd": 1.0, "hp": 2})
				else:
					units.append({"kind": "tank", "pos": Vector2(x, 0), "cd": randf_range(0.7, 1.5), "hp": 3})
			elif tier >= 2 and roll < 0.5:
				if randf() < 0.25:
					units.append({"kind": "flamer", "pos": Vector2(x, 0), "cd": randf_range(0.5, 1.0), "hp": 2})
				else:
					for i in 3:
						units.append({"kind": "soldier", "pos": Vector2(x + i * 8.0, 0), "cd": randf_range(0.4, 1.4), "hp": 1})
			else:
				units.append({"kind": "police", "pos": Vector2(x, 0), "cd": randf_range(0.6, 1.2), "hp": 1})
	for u in units:
		if u.get("grab", false) or u.get("thrown", false) or u.kind == "carcass":
			continue
		if stun_t > 0.0 and u.kind != "jet":
			continue
		# plague takes its due
		if u.has("inf") and t > u.inf:
			u.dead = true
			_kill_unit(u)
			_rise(u.pos, branch == "crown")
			continue
		# the maddened turn on their own
		if u.get("mad", false):
			u.mad_t -= delta
			if u.mad_t <= 0.0:
				u.dead = true
				_boom(u.pos + Vector2(0, -8), 8, Color(1.4, 0.5, 1.4), 70.0)
				if branch == "choir":
					for u2 in units:
						if u2 != u and not u2.get("mad", false) and not u2.get("dead", false) \
								and (u2.pos - u.pos).length() < 60.0 and not u2.kind in ["carcass", "jet"]:
							_madden(u2)
							break
				continue
			var prey = null
			var pd := 300.0
			for u2 in units:
				if u2 == u or u2.get("mad", false) or u2.get("dead", false) or u2.kind == "carcass":
					continue
				var d2m: float = (u2.pos - u.pos).length()
				if d2m < pd:
					pd = d2m
					prey = u2
			if prey != null:
				u.pos.x += signf(prey.pos.x - u.pos.x) * 30.0 * delta
				u.cd -= delta
				if u.cd <= 0.0 and pd < 260.0:
					u.cd = 1.0
					u.mf = 0.07
					shells.append({"pos": u.pos + Vector2(0, -12),
						"vel": (prey.pos + Vector2(0, -8) - u.pos).normalized() * 140.0,
						"life": 3.0, "heavy": u.kind == "tank", "friendly": true})
			continue
		var dx: float = pos.x - u.pos.x
		var slow: float = u.get("slow", 1.0)
		u.slow = 1.0
		# rubble is bad ground — the army climbs your leavings
		if u.kind in ["police", "soldier", "tank", "arty"]:
			for b in buildings:
				if b.dead and u.pos.x > b.x and u.pos.x < b.x + b.w:
					slow = minf(slow, 0.55)
					break
		match u.kind:
			"police": u.pos.x += signf(dx) * 34.0 * delta * slow
			"soldier": u.pos.x += signf(dx) * 24.0 * delta * slow
			"tank": u.pos.x += signf(dx) * 17.0 * delta * slow
			"arty":
				# artillery keeps its distance
				if absf(dx) < 260.0:
					u.pos.x -= signf(dx) * 20.0 * delta
			"heli":
				u.pos.x += signf(dx) * 38.0 * delta
				u.pos.y += sin(t * 2.0) * 6.0 * delta
			"news":
				# holds station off your shoulder, broadcasting terror
				var want_x: float = pos.x + u.get("side", 1.0) * 130.0
				u.pos.x = move_toward(u.pos.x, want_x, 44.0 * delta)
				u.pos.y = -170.0 + sin(t * 1.4) * 10.0
				if absf(dx) < 280.0:
					_feed("fear", 0.5 * delta)
			"militia":
				# farmers with rifles — brave until it looks at them
				if absf(dx) < 75.0:
					u.pos.x -= signf(dx) * 34.0 * delta * slow
				else:
					u.pos.x += signf(dx) * 20.0 * delta * slow
			"flamer":
				# closes in and hoses the low air with fire
				if absf(dx) > 55.0:
					u.pos.x += signf(dx) * 40.0 * delta * slow
				elif pos.y > -85.0:
					if randf() < 12.0 * delta:
						parts.append({"pos": u.pos + Vector2(signf(dx) * 6.0, -7.0),
							"vel": Vector2(signf(dx) * randf_range(60, 110), randf_range(-50, -15)),
							"life": randf_range(0.3, 0.6), "col": Color(2.2, 1.1, 0.3), "fire": true})
					if pos.distance_to(u.pos + Vector2(0, -8)) < 80.0:
						hp -= 4.5 * delta * dmg_taken_mult
						if randf() < 2.0 * delta:
							hit_flash = 0.6
			"priest":
				# keeps to the column and prays — nearby guns bless-fire faster
				u.pos.x += signf(dx) * 18.0 * delta * slow
				for u2 in units:
					if u2 != u and not u2.get("mad", false) and absf(u2.pos.x - u.pos.x) < 90.0:
						u2.cd -= delta * 0.4
			"champ":
				# the champion advances like a tank and answers in salvos
				u.pos.x += signf(dx) * 22.0 * delta * slow
			"herald":
				_herald_ai(u, delta, dx)
			"brood":
				u.pos.x += signf(dx) * 55.0 * delta * slow
				if absf(dx) < 16.0 and pos.y > -40.0 and u.cd <= 0.0:
					u.cd = 0.9
					hp -= 3.0 * dmg_taken_mult
					hit_flash = 0.6
			"jet":
				u.pos.x += u.vx * delta
				if absf(dx) < 90.0 and u.bombs > 0:
					u.bombs -= 1
					shells.append({"pos": u.pos, "vel": Vector2(u.vx * 0.4, 40.0), "life": 6.0,
						"heavy": true, "arc": true, "splash": true})
				if absf(u.pos.x - cam.position.x) > 900.0:
					u.dead = true
		u.cd -= delta
		u.mf = maxf(0.0, u.get("mf", 0.0) - delta)
		var fire_range: float = 700.0 if u.kind == "arty" else 420.0
		if u.cd <= 0.0 and absf(dx) < fire_range and not u.kind in ["jet", "news", "flamer", "priest", "herald", "brood"]:
			u.cd = maxf(0.4, (randf_range(1.1, 2.0) - tier * 0.12) / defense)
			u.mf = 0.07
			var origin: Vector2 = u.pos + Vector2(0, -18 if u.kind != "heli" else 4)
			# aim at the nearest threat — the god or its spawn
			var tgt := pos
			var tvel := vel
			var tdist: float = (pos - u.pos).length()
			for a in allies:
				var da: float = (a.pos - u.pos).length()
				if da < tdist:
					tdist = da
					tgt = a.pos + Vector2(0, -6)
					tvel = Vector2.ZERO
			# the army fights the war on two fronts — heralds draw fire too
			for u2 in units:
				if u2.kind == "herald":
					var dh: float = (u2.pos - u.pos).length()
					if dh < tdist:
						tdist = dh
						tgt = u2.pos + Vector2(0, -22)
						tvel = Vector2.ZERO
			var lead: Vector2 = tgt + tvel * 0.35
			if u.kind == "champ":
				# a fan of three heavy shells
				for si in 3:
					var cdir := (lead - origin).normalized().rotated((si - 1) * 0.18)
					shells.append({"pos": origin, "vel": cdir * 175.0, "life": 4.0, "heavy": true})
				u.cd = randf_range(2.6, 3.6) / defense
			elif u.kind == "arty":
				# ballistic lob
				var fl := (lead - origin)
				shells.append({"pos": origin, "vel": Vector2(fl.x * 0.55, -190.0), "life": 6.0,
					"heavy": true, "arc": true, "splash": true})
				u.cd = randf_range(2.2, 3.4) / defense
			else:
				var speed: float = 120.0 if u.kind in ["police", "soldier", "militia"] else 165.0
				var dirv := (lead - origin).normalized()
				if blackout_t > 0.0:
					dirv = dirv.rotated(randf_range(-0.55, 0.55))  # blind in the dark
				elif sun_eaten or dark_perm > 0.0:
					dirv = dirv.rotated(randf_range(-0.3, 0.3))
				if nodes.has("dirge") and (u.pos - pos).length() < 220.0:
					dirv = dirv.rotated(randf_range(-0.28, 0.28))  # the choir frays their nerve
				shells.append({"pos": origin, "vel": dirv * speed, "life": 4.0,
					"heavy": not (u.kind in ["police", "soldier"])})
	units.append_array(spawn_q)
	spawn_q.clear()
	units = units.filter(func(u): return not u.get("dead", false))
	for s in shells:
		if s.get("arc", false):
			s.vel.y += 230.0 * delta
		# stray ordnance finds the other monster
		if not s.get("friendly", false) and s.life > 0.0:
			for u2 in units:
				if u2.kind == "herald" and (u2.pos + Vector2(0, -22) - s.pos).length() < 30.0:
					u2.hp -= 2
					s.life = 0.0
					_boom(s.pos, 5, Color(1.6, 0.9, 0.5), 60.0)
					if u2.hp <= 0:
						u2.dead = true
						_kill_unit(u2)
					break
		s.pos += s.vel * delta
		s.life -= delta
		if s.get("splash", false) and s.pos.y >= 0.0:
			s.life = 0.0
			_boom(Vector2(s.pos.x, -2), 14, Color(2.0, 1.2, 0.5), 90.0)
			_sfx("boom")
			shake = maxf(shake, 5.0)
			_hit_props(Vector2(s.pos.x, -4), 22.0)
			if Vector2(s.pos.x, -6).distance_to(pos) < 34.0:
				hp -= 9.0 * dmg_taken_mult * defense
				hit_flash = 1.0
				combo = max(1.0, combo - 1.0)
			for pe in people:
				if absf(pe.pos.x - s.pos.x) < 20.0:
					pe.dead = true
					_mist(Vector2(pe.pos.x, -5))
			continue
		if s.get("friendly", false):
			# turned guns hit the army, never the god
			for u in units:
				if u.get("mad", false) or u.get("dead", false) or u.kind == "carcass":
					continue
				if s.pos.distance_to(u.pos + Vector2(0, -8)) < 9.0:
					s.life = 0.0
					u.hp = u.get("hp", 1) - (2 if s.heavy else 1)
					_boom(s.pos, 5, Color("#ffd75a"), 70.0)
					if u.hp <= 0:
						u.dead = true
						_kill_unit(u)
					break
			continue
		# enemy fire can cut down your spawn
		var hit_ally := false
		for a in allies:
			if s.pos.distance_to(a.pos + Vector2(0, -6)) < 7.0:
				s.life = 0.0
				a.hp -= 2 if s.heavy else 1
				_boom(s.pos, 4, Color("#ffd75a"), 60.0)
				hit_ally = true
				break
		if hit_ally:
			continue
		if s.pos.distance_to(pos) < radius:
			s.life = 0.0
			hp -= (6.0 if s.heavy else 3.0) * dmg_taken_mult * defense
			hits_taken += 1
			combo = max(1.0, combo - 1.0)
			shake = 6.0
			hit_flash = 1.0
			_sfx("hit")
			vel += s.vel.normalized() * 90.0
			_boom(s.pos, 8, Color("#ffd75a"), 90.0)

func _eaten_frac() -> float:
	var eaten := 0.0
	for b in buildings:
		eaten += b.maxhp if (b.dead or b.dying > 0.0 or b.topple > 0.0) else (b.maxhp - b.hp)
	return eaten / total_mass

func _inside_alive() -> int:
	var n := 0
	for b in buildings:
		if b.get("shelter", false) and not b.dead and b.dying <= 0.0:
			n += b.get("inside", 0)
	return n

func _check_end() -> void:
	if prologue:
		return
	var et: Dictionary = END_TEXT[character]
	people_killed = people_total - people.size() - _inside_alive()
	# bonus dare tracking
	match bonus_obj:
		"untouchable": bonus_met = hits_taken <= 3
		"warlord": bonus_met = unit_kills >= 8
		"swift": bonus_met = run_time <= 180.0
		"shepherd": bonus_met = allies.size() >= 6
		"pyromaniac":
			var burning := 0
			for b in buildings:
				if b.burn > 0.5 and not b.dead:
					burning += 1
			if burning >= 6:
				bonus_met = true   # latches once achieved
	var cit_down := false
	if has_citadel:
		var cit: Dictionary = buildings[-1]
		cit_down = cit.dead or cit.dying > 0.0
	if hp <= 0.0:
		_finish(false, et)
		return
	var won := false
	match objective:
		"decapitation":
			obj_timer -= get_process_delta_time()
			if cit_down:
				won = true
			elif obj_timer <= 0.0:
				_finish(false, et)
				return
		"extinction":
			won = people_killed >= int(people_total * 0.85)
		"blackout":
			won = specials_total > 0 and specials_down >= specials_total
		"terror":
			if tier >= tier_cap and not obj_started:
				obj_started = true
				obj_timer = 90.0
				_pop(pos + Vector2(0, -30), "NOW SURVIVE", Color(2.0, 0.5, 0.4))
			if obj_started:
				obj_timer -= get_process_delta_time()
				won = obj_timer <= 0.0
		"feast":
			if essence_eaten - essence_start >= 250.0:
				won = true
			elif night_f >= 1.0 and not sun_eaten:
				_finish(false, et)
				return
		_:
			won = _eaten_frac() >= 0.9 or cit_down
	if won:
		_finish(true, et)

func _finish(win: bool, et: Dictionary) -> void:
	if over:
		return
	if Global.mode != "crusade":
		if win:
			_end(et.win, "%s  score %s  —  R restart / ESC menu" % [et.win_s, _fmt(int(score_f))])
		else:
			_end(et.lose, "%s  score %s  —  R restart / ESC menu" % [et.lose_s, _fmt(int(score_f))])
		return
	# --- crusade flow ---
	# every meal makes the roar louder — and the void keeps count
	Global.roar += maxf(0.0, essence_eaten - essence_start)
	if win:
		var award := int(score_f / 1000.0 * tribute_mult)
		if bonus_obj != "" and bonus_met:
			award = int(award * 1.5)
		Global.tribute += award
		Global.c_branch = branch
		Global.c_nodes = nodes
		Global.c_bio_stage = bio_stage
		Global.c_essence = essence_eaten
		var bt := ""
		Global.razed.append(Global.node_params.get("map_node", Global.map_pos))
		var place_s: String = node_place if node_place != "" else str(city_def.get("name", "THE CITY"))
		var reactions := ["THE PROVINCE PRAYS", "THE GUARD MOBILIZES", "MARTIAL LAW DECLARED",
			"THE CAPITAL IS WATCHING", "NOTHING ANSWERS ANYMORE"]
		Global.headline = "%s IS ASH — %s" % [place_s.to_upper(), reactions[mini(4, Global.razed.size() - 1)]]
		if Global.act == 1:
			if Global.node_params.get("provcity", false):
				Global.act = 2
				Global.razed = []
				Global.map_pos = 0
				Global.headline = ""
				bt = "THE CRUSADE BEGINS"
			else:
				bt = "MARCH ON"
		else:
			if Global.node_params.get("capital", false):
				bt = "THE CONTINENT IS ASH"
			else:
				bt = "TO THE MAP"
		Global.save_crusade()
		var bonus_line := ""
		if bonus_obj != "":
			bonus_line = "   dare %s: %s" % [bonus_obj.to_upper(), "MET +50%" if bonus_met else "failed"]
		_end(et.win, "%s   tribute +%d%s" % [et.win_s, award, bonus_line])
		_crusade_button(bt, win)
	else:
		Global.tribute = int(Global.tribute * 0.8)
		Global.save_crusade()
		_end(et.lose, "%s   the crusade endures — tribute wanes." % et.lose_s)
		_crusade_button("RISE AGAIN", win)

func _crusade_button(label: String, win: bool) -> void:
	end_label = label
	end_win = win

func _end_click() -> void:
	if over_t >= 0.8:
		_end_advance()
	else:
		end_pending = true

func _end_advance() -> void:
	if end_label == "" or over_t < 0.8:
		return
	Engine.time_scale = 1.0
	var lbl := end_label
	end_label = ""
	if not end_win:
		Global.goto("res://main.tscn")
	elif Global.act == 1:
		Global.launch_act1()
	elif Global.node_params.get("capital", false):
		Global.goto("res://menu.tscn")
	else:
		Global.node_params = {"offer_relic": true}
		Global.goto("res://map.tscn")

func _end(m: String, s: String) -> void:
	over = true
	over_t = 0.0
	hud.msg.text = m
	hud.sub.text = s
	people_killed = people_total - people.size()
	hud.stats.text = "razed %d   ·   devoured %d souls   ·   broke %d war machines   ·   %d:%02d" \
		% [buildings_razed, people_killed, unit_kills, int(run_time) / 60, int(run_time) % 60]

func _input(e: InputEvent) -> void:
	if caption_layer != null and ((e is InputEventMouseButton and e.pressed) 			or (e is InputEventKey and e.pressed and e.physical_keycode in [KEY_SPACE, KEY_ENTER])):
		_caption_advance()
		return
	if over and end_label != "" and e is InputEventKey and e.pressed and e.physical_keycode == KEY_ENTER:
		_end_advance()
		return
	if draft_open and e is InputEventKey and e.pressed:
		var ki: int = e.physical_keycode - KEY_1
		if ki >= 0 and ki < draft_opts.size():
			_pick_draft(draft_opts[ki].id)
			return
	if over and e.is_action_pressed("restart"):
		Global.goto("res://main.tscn")
	if e is InputEventKey and e.pressed and e.physical_keycode == KEY_ESCAPE:
		Global.goto("res://menu.tscn")

func _boom(p: Vector2, n: int, col: Color, sp: float) -> void:
	for i in n:
		var a := randf() * TAU
		parts.append({"pos": p, "vel": Vector2(cos(a), sin(a)) * randf_range(0.3, 1.0) * sp + Vector2(0, -30),
			"life": randf_range(0.3, 0.9), "col": col})

func _fire(p: Vector2) -> void:
	parts.append({"pos": p, "vel": Vector2(randf_range(-4, 4), randf_range(-26, -12)),
		"life": randf_range(0.4, 0.9), "col": Color(2.2, 1.1, 0.4), "fire": true})
	if randf() < 0.35:
		parts.append({"pos": p + Vector2(0, -3), "vel": Vector2(randf_range(-5, 5), randf_range(-30, -16)),
			"life": randf_range(0.8, 1.6), "col": Color(0.2, 0.18, 0.2), "fire": true, "smoke": true, "size": 3.0})

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
	var dlayer := CanvasLayer.new()
	dlayer.layer = 97
	add_child(dlayer)
	draft_ui = DraftUI.new(self)
	dlayer.add_child(draft_ui)
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
	hud.hpchip = ColorRect.new()
	hud.hpchip.color = Color(1, 1, 1, 0.85)
	hud.hpchip.size = Vector2(0, 5)
	hud.hp.get_parent().add_child(hud.hpchip)
	# letterbox bars for the ending
	hud.lb_top = ColorRect.new()
	hud.lb_top.color = Color(0, 0, 0)
	hud.lb_top.size = Vector2(640, 0)
	layer.add_child(hud.lb_top)
	hud.lb_bot = ColorRect.new()
	hud.lb_bot.color = Color(0, 0, 0)
	hud.lb_bot.position = Vector2(0, 360)
	hud.lb_bot.size = Vector2(640, 0)
	layer.add_child(hud.lb_bot)
	hud.citylbl = _label(layer, Vector2(478, 48), 8, Color("#9ab0d0"))
	hud.city = _bar(layer, Vector2(478, 60), Color("#9a5de0"))
	hud.obj = _label(layer, Vector2(0, 4), 9, Color("#ffd75a"))
	hud.obj.size = Vector2(640, 14)
	hud.obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.msg = _label(layer, Vector2(0, 140), 28, Color("#ffb08a"))
	hud.msg.size = Vector2(640, 40)
	hud.msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.sub = _label(layer, Vector2(0, 180), 10, Color("#e8f0ff"))
	hud.sub.size = Vector2(640, 20)
	hud.sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.stats = _label(layer, Vector2(0, 204), 9, Color("#b8a8d8"))
	hud.stats.size = Vector2(640, 16)
	hud.stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var help := _label(layer, Vector2(10, 344), 8, Color(0.85, 0.9, 1, 0.45))
	match character:
		"keraunos":
			help.text = "WASD — fly.  LMB — lightning strike at cursor (3 banked).  RMB — TEMPEST at full storm.  ESC — menu."
		"tzitzimitl":
			help.text = "serpent follows your cursor.  LMB — lance dive (pierces buildings).  RMB — DEVOUR THE SUN at full hunger.  ESC — menu."
		"drowned":
			help.text = "A/D — wade, W — lurch.  LMB — madden a mind (units turn, crowds riot).  RMB — call the fishmen.  ESC — menu."
		"rider":
			help.text = "A/D — ride, W — leap.  fog infects all near.  LMB — scythe (wide).  E — rally the dead.  RMB — REAPING.  ESC — menu."
		_:
			help.text = "WASD — fly.  HOLD LMB — tendrils: chew, snatch, reel.  RMB — arc lash / evolved skill.  R — restart.  ESC — menu."

func _label(parent: Node, p: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.position = p
	l.add_theme_font_override("font", ui_font)
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
	# rolling score
	shown_score = lerpf(shown_score, score_f, 0.12)
	if score_f - shown_score < 2.0:
		shown_score = score_f
	hud.score.text = _fmt(int(shown_score))
	# combo pulse on gain
	if combo > prev_combo + 0.05:
		combo_pulse = 1.0
	prev_combo = combo
	combo_pulse = maxf(0.0, combo_pulse - 0.08)
	hud.combo.scale = Vector2.ONE * (1.0 + combo_pulse * 0.35)
	hud.combo.text = "×%.1f" % combo
	hud.tier.text = "THREAT — " + TIER_NAMES[tier]
	hud.threat.size.x = 152.0 * threat / 100.0
	# damage chip: white segment drains toward the real value
	disp_hp = maxf(hp, disp_hp - 0.6)
	if hp > disp_hp:
		disp_hp = hp
	hud.hpchip.position.x = 152.0 * maxf(0.0, hp) / 100.0
	hud.hpchip.size.x = maxf(0.0, 152.0 * (disp_hp - maxf(0.0, hp)) / 100.0)
	hud.hp.size.x = 152.0 * maxf(0.0, hp) / 100.0
	# letterboxed endings
	if over:
		letterbox = minf(1.0, letterbox + 0.03)
	hud.lb_top.size.y = 44.0 * letterbox
	hud.lb_bot.position.y = 360.0 - 44.0 * letterbox
	hud.lb_bot.size.y = 44.0 * letterbox
	if over:
		hud.stats.visible = over_t > 0.6
		hud.sub.visible = over_t > 0.25
	hud.citylbl.text = "CITY DEVOURED — %d%%" % int(_eaten_frac() * 100)
	hud.city.size.x = 152.0 * minf(1.0, _eaten_frac() / 0.9)
	if Global.mode == "crusade" and not prologue:
		match objective:
			"decapitation": hud.obj.text = "OBJECTIVE: %s — %ds" % [lord_name if lord_name != "" else "THE CITADEL", int(maxf(0, obj_timer))]
			"extinction": hud.obj.text = "THE RECKONING — %d / %d souls" % [people_killed, int(people_total * 0.85)]
			"blackout": hud.obj.text = "SIEGEBREAK — installations %d / %d" % [specials_down, specials_total]
			"terror": hud.obj.text = ("OBJECTIVE: SURVIVE — %ds" % int(maxf(0, obj_timer))) if obj_started else "OBJECTIVE: TERROR — reach LAST RESORT"
			"feast": hud.obj.text = "OBJECTIVE: FEAST — %d / 250 before nightfall" % int(essence_eaten - essence_start)
			_: hud.obj.text = "OBJECTIVE: RAZE — devour 90%% or the citadel"
		if bonus_obj != "":
			hud.obj.text += "    ·    DARE: %s%s" % [bonus_obj.to_upper(), " ✓" if bonus_met else ""]
	match character:
		"keraunos":
			var need: float = 25.0 if nodes.has("conductor") else (40.0 if branch == "skyfall" else (70.0 if nodes.has("stormfront") else 100.0))
			hud.biolbl.text = ("STORM READY — RMB" if meter >= need else "STORM — RMB at %d" % int(need))
			hud.bio.size.x = 152.0 * clampf(meter / 100.0, 0.0, 1.0)
		"tzitzimitl":
			if blackout_t > 0.0:
				hud.biolbl.text = "T H E   D E V O U R I N G"
				hud.bio.size.x = 152.0 * blackout_t / eclipse_len
			elif sun_eaten:
				hud.biolbl.text = "THE SUN IS DEAD — the dark is yours"
				hud.bio.size.x = 152.0
			else:
				hud.biolbl.text = "SUN-HUNGER — RMB devours the sun" if meter < eclipse_cost else "RMB — DEVOUR THE SUN"
				hud.bio.size.x = 152.0 * clampf(meter / eclipse_cost, 0.0, 1.0)
		"drowned":
			hud.biolbl.text = "THE DEEP — RMB calls fishmen at full" if meter < 80.0 else "THE DEEP ANSWERS — RMB"
			hud.bio.size.x = 152.0 * clampf(meter / 80.0, 0.0, 1.0)
		"rider":
			hud.biolbl.text = "HARVEST — RMB reaps all infected at full" if meter < 80.0 else "REAPING READY — RMB"
			hud.bio.size.x = 152.0 * clampf(meter / 80.0, 0.0, 1.0)
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
	# view half-width depends on camera zoom (keraunos 0.55 sees ~620px) + shake margin
	var half: float = 330.0 / cam.zoom.x + 24.0
	var left := cx - half
	var right := cx + half
	_draw_sky(left, right, cx)
	_draw_backdrop(left, right, cx)
	for b in buildings:
		if b.x + b.w < left or b.x > right:
			continue
		_draw_building(b)
	# floodwater / plague ground
	for fz in flood:
		if fz.x1 < left or fz.x0 > right:
			continue
		if fz.get("plague", false):
			draw_rect(Rect2(fz.x0, -3, fz.x1 - fz.x0, 5), Color(0.5, 0.7, 0.2, 0.28))
			if randf() < 0.1:
				parts.append({"pos": Vector2(randf_range(fz.x0, fz.x1), -3), "vel": Vector2(0, -8),
					"life": 0.8, "col": Color(0.7, 1.0, 0.3, 0.5), "size": 1.5, "fire": true, "smoke": true})
		else:
			draw_rect(Rect2(fz.x0, -6, fz.x1 - fz.x0, 8), Color(0.15, 0.5, 0.6, 0.5))
			var wx2: float = fz.x0
			while wx2 < fz.x1:
				draw_rect(Rect2(wx2, -7 + sin(t * 3.0 + wx2 * 0.2) * 1.5, 6, 1.5), Color(0.4, 0.9, 0.95, 0.5))
				wx2 += 9.0
	_draw_street(left, right)
	# eclipse gloom sits UNDER the living things — fires, beasts and armies stay vivid
	var dark_a: float = maxf(clampf(blackout_t / 1.5, 0.0, 1.0) * 0.5, (0.3 if sun_eaten else 0.0))
	if dark_a > 0.0:
		draw_rect(Rect2(left, -540, right - left, 940), Color(0.01, 0.0, 0.03, dark_a))
		if blackout_t > 0.0:
			var moon2 := Vector2(cam.position.x + 140, -250.0)
			draw_circle(moon2, city_def.moon_r + 4.0, Color(0.02, 0.0, 0.03))
			draw_circle(moon2, city_def.moon_r + 6.0, Color(1.8, 0.9, 0.3, 0.35))
	_draw_actors()
	_draw_allies()
	match character:
		"keraunos":
			_draw_keraunos()
		"tzitzimitl":
			_draw_tzitzi()
		"drowned":
			_draw_drowned()
		"rider":
			_draw_rider()
		_:
			_draw_swarm()
			_draw_tendrils()
	# hanging razor feathers
	for f2 in feathers:
		var fd := Vector2(sin(t * 3.0 + f2.pos.x), 1.0).normalized()
		draw_line(f2.pos - fd * 4.0, f2.pos + fd * 4.0, Color(1.7, 1.15, 0.35), 1.5)
		draw_line(f2.pos - fd * 2.0, f2.pos + fd * 2.0, Color(2.0, 1.6, 0.7), 0.8)
	# ball lightning orbs
	for o in orbs:
		var rr: float = 3.0 + sin(t * 9.0 + o.pos.x) * 0.8
		draw_circle(o.pos, rr + 3.0, Color(0.5, 1.2, 2.0, 0.18))
		draw_circle(o.pos, rr, Color(1.2, 1.9, 2.5))
		draw_circle(o.pos, rr * 0.5, Color(2.2, 2.4, 2.8))
	for o in eorbs:
		var oc: Color = EORB_COLS.get(o.kind, Color(1.6, 1.2, 0.9))
		draw_circle(o.pos, 3.4, Color(oc.r, oc.g, oc.b, 0.18))
		draw_circle(o.pos, 1.6, oc)
	for p in pops:
		var a2: float = clampf(p.life, 0.0, 1.0)
		draw_string(ui_font, p.pos + Vector2(-160, 0), p.txt, HORIZONTAL_ALIGNMENT_CENTER, 320, 8,
			Color(p.col.r * 1.4, p.col.g * 1.4, p.col.b * 1.4, a2))
	# drifting ash on the wind
	var ash_c: Color = city_def.lamp
	for am in ambient:
		am.p.y -= am.s * 0.9
		am.p.x += sin(t * 0.8 + am.s * 20.0) * 0.3
		if am.p.y < -350.0:
			am.p.y = -5.0
			am.p.x = randf_range(0, 680)
		var wp := Vector2(left + fposmod(am.p.x, right - left), am.p.y)
		draw_rect(Rect2(wp.x, wp.y, 1.2, 1.2), Color(ash_c.r * 0.5, ash_c.g * 0.45, ash_c.b * 0.4, 0.25 * am.s))
	# weather — each city has its own sky-mood
	var wcity: String = "maren" if storm_node else Global.city
	match wcity:
		"maren":
			for i in 46:
				var si: float = _hash(float(i))
				var rx: float = left + fposmod(si * 1997.0 + t * 30.0, right - left)
				var ry: float = fposmod(si * 700.0 + t * (280.0 + si * 120.0), 370.0) - 360.0
				draw_line(Vector2(rx, ry), Vector2(rx - 3.0, ry + 9.0), Color(0.55, 0.7, 0.9, 0.30), 1.0)
			if randf() < 0.5:
				draw_arc(Vector2(left + randf() * (right - left), -1.0), randf_range(1.0, 2.5),
					PI, TAU, 6, Color(0.6, 0.8, 0.95, 0.4), 1.0)
		"thornspire":
			for i in 3:
				var fx2: float = left + fposmod(i * 420.0 + t * (4.0 + i * 2.0), right - left + 300.0) - 150.0
				var fy2: float = -22.0 - i * 26.0
				draw_circle(Vector2(fx2, fy2), 90.0 + i * 30.0, Color(0.5, 0.6, 0.8, 0.05))
				draw_circle(Vector2(fx2 + 70.0, fy2 + 8.0), 60.0, Color(0.5, 0.6, 0.8, 0.04))
		"teotl":
			for i in 14:
				if fmod(t * 0.7 + _hash(float(i)) * 9.0, 3.0) < 1.2:
					var gx: float = left + fposmod(_hash(i + 31.0) * 2000.0 + sin(t * 0.5 + i) * 30.0, right - left)
					var gy: float = -8.0 - _hash(i + 17.0) * 130.0 + sin(t * 1.1 + i * 2.0) * 9.0
					draw_circle(Vector2(gx, gy), 1.0, Color(0.9, 1.8, 0.5, 0.8))
					draw_circle(Vector2(gx, gy), 2.6, Color(0.6, 1.4, 0.3, 0.2))
	# foreground silhouettes — closer than the war
	var fgo: float = cx * 0.22
	if not node_kind in ["hamlet", "town", "prologue"]:
		var s3: float = floor((left + fgo) / 210.0) * 210.0
		while s3 < right + fgo + 210.0:
			var px3: float = s3 - fgo
			draw_rect(Rect2(px3, -74.0, 2.5, 74.0), Color(0.02, 0.01, 0.04, 0.6))
			draw_rect(Rect2(px3 - 5.0, -74.0, 13.0, 2.0), Color(0.02, 0.01, 0.04, 0.6))
			var nx: float = px3 + 210.0
			var mid := Vector2((px3 + nx) * 0.5, -63.0)
			draw_line(Vector2(px3, -72.0), mid, Color(0.02, 0.01, 0.04, 0.5), 1.2)
			draw_line(mid, Vector2(nx, -72.0), Color(0.02, 0.01, 0.04, 0.5), 1.2)
			s3 += 210.0
	else:
		var s4: float = floor((left + fgo) / 34.0) * 34.0
		while s4 < right + fgo + 34.0:
			draw_rect(Rect2(s4 - fgo, -12.0, 1.5, 12.0), Color(0.02, 0.01, 0.04, 0.5))
			s4 += 34.0
	# atmosphere: ground haze + bottom vignette
	draw_rect(Rect2(left, -30, right - left, 34), Color(0.3, 0.12, 0.3, 0.08))
	draw_rect(Rect2(left, 14, right - left, 400), Color(0.01, 0.0, 0.03, 0.55))
	# impact flash — the whole world blinks white
	if flash_t > 0.0:
		draw_rect(Rect2(left, -540, right - left, 940), Color(1.0, 0.97, 0.9, flash_t * 0.3))
	if impact_frames > 0:
		impact_frames -= 1
		draw_rect(Rect2(left, -540, right - left, 940), Color(1.0, 1.0, 0.98, 0.85))

const DUSK_SKY := [Color("#3a2a50"), Color("#7a3a50"), Color("#c05a3c"), Color("#e8924e"), Color("#f8c877")]

func _draw_sky(left: float, right: float, cx: float) -> void:
	var g: Array = city_def.sky
	var top := -540.0
	var rows := 108
	for i in rows:
		var f := float(i) / rows
		var col: Color
		var dcol: Color
		if f < 0.4:
			col = g[0].lerp(g[1], f / 0.4)
			dcol = DUSK_SKY[0].lerp(DUSK_SKY[1], f / 0.4)
		elif f < 0.68:
			col = g[1].lerp(g[2], (f - 0.4) / 0.28)
			dcol = DUSK_SKY[1].lerp(DUSK_SKY[2], (f - 0.4) / 0.28)
		elif f < 0.88:
			col = g[2].lerp(g[3], (f - 0.68) / 0.2)
			dcol = DUSK_SKY[2].lerp(DUSK_SKY[3], (f - 0.68) / 0.2)
		else:
			col = g[3].lerp(g[4], (f - 0.88) / 0.12)
			dcol = DUSK_SKY[3].lerp(DUSK_SKY[4], (f - 0.88) / 0.12)
		draw_rect(Rect2(left, top + f * 540.0, right - left, 540.0 / rows + 1), dcol.lerp(col, night_f))
	for i in 60:
		var sxr := fmod(_hash(i * 3.7) * 4310.0, 1.0) * (right - left) + left
		var syr := -535.0 + _hash(i * 9.1) * 300.0
		if fmod(t * (0.4 + fmod(float(i), 3.0) * 0.3) + i, 2.0) < 1.5:
			draw_rect(Rect2(sxr, syr, 1, 1),
				Color(0.9, 0.92, 1.0, 0.5 * night_f * (1.0 - (syr + 535.0) / 320.0)))
	# THE SUN — low, dying, and edible
	if not sun_eaten or devour_anim > 0.0:
		var sun := Vector2(cx - 150, lerpf(-190.0, 25.0, clampf(night_f / 0.92, 0.0, 1.0)))
		if sun.y < 20.0:
			var sr := 26.0
			for gi in range(5, 0, -1):
				draw_circle(sun, sr + gi * 9.0, Color(1.4, 0.7, 0.3, 0.05))
			draw_circle(sun, sr, Color(1.9, 1.05, 0.4))
			draw_circle(sun + Vector2(-6, -5), sr * 0.75, Color(2.1, 1.3, 0.55))
			if devour_anim > 0.0:
				# the serpent's shadow closes around the sun
				var prog: float = 1.0 - devour_anim / 1.4
				draw_circle(sun, sr * 1.15 * prog, Color(0.03, 0.01, 0.05))
				draw_circle(sun, sr * 1.15 * prog + 2.0, Color(1.9, 1.2, 0.4, 0.5 * prog))
	# slow clouds crossing the sky
	for i in 3:
		var cxx: float = left + fposmod(i * 251.0 + t * (3.0 + i), right - left + 160.0) - 80.0
		var cyy: float = -300.0 + i * 44.0
		for seg in 4:
			draw_circle(Vector2(cxx + seg * 18.0, cyy + sin(seg * 1.7) * 3.0), 14.0 - seg * 2.0,
				Color(0.06, 0.05, 0.1, 0.35))
	# city aurora / smog signatures
	if city_def.aurora:
		for i in 3:
			var ay: float = -330.0 + i * 26.0
			var pts := PackedVector2Array()
			var xx := left
			while xx <= right:
				pts.append(Vector2(xx, ay + sin(xx * 0.012 + t * 0.5 + i * 2.0) * 14.0))
				xx += 40.0
			for j in pts.size() - 1:
				draw_line(pts[j], pts[j + 1], Color(0.3, 1.2, 0.8, 0.10 - i * 0.02), 10.0 - i * 2.0)
	if city_def.smog:
		for i in 4:
			draw_rect(Rect2(left, -180.0 + i * 34.0 + sin(t * 0.3 + i) * 6.0, right - left, 16.0),
				Color(0.28, 0.2, 0.12, 0.13))
	# the moon rises as night falls — unless the serpent already ate the sky
	if night_f > 0.55 and not sun_eaten:
		var ma: float = clampf((night_f - 0.55) / 0.3, 0.0, 1.0)
		var mc: Color = city_def.moon
		var mr: float = city_def.moon_r
		var moon := Vector2(cx + 140, lerpf(-190.0, -250.0, ma))
		draw_circle(moon, mr * 1.3, Color(mc.r * 0.4, mc.g * 0.25, mc.b * 0.25, 0.35 * ma))
		draw_circle(moon, mr, Color(mc.r, mc.g, mc.b, ma))
		draw_circle(moon + Vector2(-mr * 0.25, -mr * 0.2), mr * 0.8, Color(mc.lightened(0.1).r, mc.lightened(0.1).g, mc.lightened(0.1).b, ma))
		draw_circle(moon + Vector2(mr * 0.3, mr * 0.25), mr * 0.2, Color(mc.darkened(0.2).r, mc.darkened(0.2).g, mc.darkened(0.2).b, ma))

func _draw_backdrop(left: float, right: float, cx: float) -> void:
	# villages get hills and pines behind them, not a metropolis skyline
	if node_kind in ["hamlet", "town", "prologue"]:
		# the province city waits on the horizon — closer after every ruin
		if Global.mode == "crusade" and Global.act == 1 and tex_sky_a != null and node_kind != "prologue":
			var hprog: float = 0.22 + minf(1.0, Global.razed.size() * 0.22) * 0.55
			var cw2: float = tex_sky_a.get_width() * hprog
			var ch2: float = tex_sky_a.get_height() * hprog
			var hx0: float = world_w * 0.85 - cx * 0.06
			draw_texture_rect(tex_sky_a, Rect2(hx0 - cw2 * 0.5, -60.0 - ch2, cw2, ch2), false, Color(0.32, 0.26, 0.4, 0.9))
			draw_rect(Rect2(hx0 - cw2 * 0.5, -60.0 - ch2, cw2, ch2), Color(0.1, 0.07, 0.18, 0.35))
		# region palette: each province's countryside is its own
		var rcols: Array = {
			"thornspire": [Color(0.13, 0.13, 0.24), Color(0.08, 0.08, 0.16)],
			"teotl": [Color(0.10, 0.17, 0.12), Color(0.06, 0.12, 0.08)],
			"maren": [Color(0.14, 0.15, 0.20), Color(0.10, 0.11, 0.15)],
			"ashport": [Color(0.16, 0.12, 0.10), Color(0.11, 0.08, 0.07)],
		}.get(Global.city, [Color(0.15, 0.13, 0.20), Color(0.10, 0.09, 0.15)])
		var ridge_h: Array = [78.0, 44.0]
		if Global.city == "maren":
			# the sea lies flat behind the dunes
			draw_rect(Rect2(left, -66.0, right - left, 66.0), Color(0.08, 0.16, 0.20, 0.8))
			draw_rect(Rect2(left, -66.0, right - left, 2.0), Color(0.3, 0.5, 0.55, 0.6))
			for bt in 3:
				var bx2: float = left + fposmod(bt * 300.0 + cx * 0.06, right - left)
				draw_rect(Rect2(bx2, -70.0, 10.0, 3.0), Color(0.05, 0.07, 0.1))
				draw_line(Vector2(bx2 + 5, -70.0), Vector2(bx2 + 5, -78.0), Color(0.05, 0.07, 0.1), 1.0)
			ridge_h = [26.0, 16.0]
		for li2 in 2:
			var f2: float = [0.12, 0.3][li2]
			var hgt: float = ridge_h[li2]
			var col: Color = rcols[li2]
			var jag: float = 0.6 if Global.city == "ashport" else 0.18
			var pts := PackedVector2Array([Vector2(left, 0)])
			var x2: float = left
			while x2 <= right + 16.0:
				var sxx: float = x2 - cx * f2
				pts.append(Vector2(x2, -hgt - sin(sxx * 0.011) * hgt * 0.35 - sin(sxx * 0.031 + 2.0) * hgt * jag))
				x2 += 16.0
			pts.append(Vector2(right + 16.0, 0))
			draw_colored_polygon(pts, col)
		# region furniture seated on the near ridge
		var f3 := 0.3
		var s2: float = floor((left - cx * f3) / 26.0) * 26.0
		while s2 < right - cx * f3 + 26.0:
			var px2: float = s2 + cx * f3
			var by: float = -ridge_h[1] - sin(s2 * 0.011) * ridge_h[1] * 0.35 - sin(s2 * 0.031 + 2.0) * ridge_h[1] * 0.18
			var hsh: float = fmod(absf(sin(s2 * 0.717)) * 13.7, 6.0)
			match Global.city:
				"thornspire":
					# black pines + the odd wayside spire
					draw_colored_polygon(PackedVector2Array([
						Vector2(px2 - 4.5, by), Vector2(px2, by - 9.0 - hsh), Vector2(px2 + 4.5, by)]),
						Color(0.07, 0.08, 0.13))
					if int(s2 / 26.0) % 9 == 0:
						draw_rect(Rect2(px2 - 1.0, by - 20.0, 2.0, 20.0), Color(0.10, 0.10, 0.17))
						draw_colored_polygon(PackedVector2Array([Vector2(px2 - 2.5, by - 20.0),
							Vector2(px2, by - 27.0), Vector2(px2 + 2.5, by - 20.0)]), Color(0.10, 0.10, 0.17))
				"teotl":
					# canopy mounds, a distant stepped shrine
					draw_circle(Vector2(px2, by - 3.0), 7.0 + hsh * 0.6, Color(0.07, 0.13, 0.09))
					if int(s2 / 26.0) % 11 == 0:
						for stp in 3:
							draw_rect(Rect2(px2 - 6.0 + stp * 2.0, by - 6.0 - stp * 4.0, 12.0 - stp * 4.0, 4.0),
								Color(0.12, 0.14, 0.11))
				"maren":
					# dune grass tufts + nets on poles
					draw_line(Vector2(px2, by), Vector2(px2 - 2.0, by - 5.0 - hsh * 0.4), Color(0.18, 0.20, 0.16), 1.0)
					draw_line(Vector2(px2, by), Vector2(px2 + 2.0, by - 4.0), Color(0.18, 0.20, 0.16), 1.0)
					if int(s2 / 26.0) % 8 == 0:
						draw_rect(Rect2(px2, by - 12.0, 1.5, 12.0), Color(0.12, 0.10, 0.09))
				"ashport":
					# slag stacks + mine headframes
					if int(s2 / 26.0) % 3 == 0:
						draw_rect(Rect2(px2 - 2.0, by - 8.0 - hsh, 4.0, 8.0 + hsh), Color(0.10, 0.08, 0.07))
					if int(s2 / 26.0) % 10 == 0:
						draw_line(Vector2(px2 - 5.0, by), Vector2(px2, by - 16.0), Color(0.12, 0.09, 0.08), 1.5)
						draw_line(Vector2(px2 + 5.0, by), Vector2(px2, by - 16.0), Color(0.12, 0.09, 0.08), 1.5)
						draw_circle(Vector2(px2, by - 16.0), 2.0, Color(0.12, 0.09, 0.08))
				_:
					# kowloon fringe: pylons marching to the city
					if int(s2 / 26.0) % 6 == 0:
						draw_line(Vector2(px2 - 4.0, by), Vector2(px2, by - 18.0), Color(0.11, 0.10, 0.15), 1.2)
						draw_line(Vector2(px2 + 4.0, by), Vector2(px2, by - 18.0), Color(0.11, 0.10, 0.15), 1.2)
						draw_line(Vector2(px2 - 5.0, by - 12.0), Vector2(px2 + 5.0, by - 12.0), Color(0.11, 0.10, 0.15), 1.0)
					else:
						draw_colored_polygon(PackedVector2Array([
							Vector2(px2 - 3.5, by), Vector2(px2, by - 5.0 - hsh * 0.5), Vector2(px2 + 3.5, by)]),
							Color(0.09, 0.09, 0.13))
			s2 += 26.0
		return
	# city glow band on the horizon (blooms slightly)
	draw_rect(Rect2(left, -120, right - left, 60), Color(0.5, 0.16, 0.4, 0.10))
	draw_rect(Rect2(left, -80, right - left, 80), Color(0.85, 0.3, 0.5, 0.14))
	# far layer, seated on the horizon
	var kowloon := Global.city == "kowloon"
	var far_tint := Color(0.36, 0.3, 0.6, 1) if kowloon else Color(0.5, 0.45, 0.62, 1)
	var sw: float = tex_sky_a.get_width() * city_def.far_scale
	var sh: float = tex_sky_a.get_height() * city_def.far_scale
	var f := 0.15
	var xoff := -cx * f
	var start: float = floor((left - xoff) / sw) * sw + xoff
	var xi := start
	var k := int(floor((left - xoff) / sw))
	while xi < right:
		var tx: Texture2D = (tex_sky_a if k % 2 == 0 else tex_sky_b) if kowloon else tex_sky_a
		draw_texture_rect(tx, Rect2(xi, -sh, sw, sh), false, far_tint)
		xi += sw
		k += 1
	draw_rect(Rect2(left, -sh, right - left, sh), Color(0.12, 0.08, 0.24, 0.45))
	# haze band separates the layers — distance you can feel
	draw_rect(Rect2(left, -sh * 0.7, right - left, sh * 0.7), Color(0.5, 0.3, 0.45, 0.10))
	# mid layer: taller, closer, clearer (or a canopy hanging from the sky)
	var mw: float = tex_mid.get_width() * city_def.mid_scale
	var mh: float = tex_mid.get_height() * city_def.mid_scale
	var hang: bool = city_def.get("mid_hang", false)
	var mtop: float = (cam.position.y - 190.0 / cam.zoom.y - mh * 0.45) if hang else -mh
	f = 0.4
	xoff = -cx * f
	start = floor((left - xoff) / mw) * mw + xoff
	xi = start
	while xi < right:
		draw_texture_rect(tex_mid, Rect2(xi, mtop, mw, mh), false, Color(0.55, 0.48, 0.75, 1))
		xi += mw
	if not hang:
		draw_rect(Rect2(left, -mh, right - left, mh), Color(0.1, 0.06, 0.2, 0.35))

func _draw_building(b: Dictionary) -> void:
	if b.dead:
		# a jagged heap, not a flat stump
		var mh: float = minf(22.0, 6.0 + b.w * 0.14)
		var pts := PackedVector2Array([Vector2(b.x - 4, 0)])
		var n: int = maxi(4, int(b.w / 14.0))
		for i in n + 1:
			pts.append(Vector2(b.x + b.w * float(i) / n,
				-mh * (0.35 + _hash(b.seed + i) * 0.65) * (1.0 if i % 2 == 0 else 0.6)))
		pts.append(Vector2(b.x + b.w + 4, 0))
		draw_colored_polygon(pts, Color("#141018"))
		for i in 4:
			draw_rect(Rect2(b.x + _hash(b.seed + 9 + i) * b.w * 0.85,
				-mh * 0.5 - _hash(b.seed + 20 + i) * 4.0,
				5.0 + _hash(b.seed + 30 + i) * 6.0, 4.0), Color("#1c1622"))
		if night_f > 0.4 and randf() < 0.35:
			draw_rect(Rect2(b.x + randf() * b.w, -randf() * mh * 0.6 - 1.0, 1.5, 1.5),
				Color(2.0, 0.8, 0.25, 0.7))
		# the ruin smolders for a long while
		if t < b.get("smolder", 0.0):
			if randf() < 0.10:
				parts.append({"pos": Vector2(b.x + randf() * b.w, -mh * 0.6),
					"vel": Vector2(randf_range(-4, 4), randf_range(-24, -12)),
					"life": randf_range(1.2, 2.6), "col": Color(0.2, 0.18, 0.2),
					"fire": true, "smoke": true, "size": randf_range(2.5, 4.5)})
			if randf() < 0.05:
				_fire(Vector2(b.x + randf() * b.w, -mh * 0.5))
		return
	var img_h: float = b.img.get_height()
	var vis_frac: float = b.cur_h / b.h
	var src := Rect2(0, img_h * (1.0 - vis_frac), b.img.get_width(), img_h * vis_frac)
	# mid-fall: the whole body rotates around its base corner
	if b.topple > 0.0:
		var ang: float = minf(b.topple, 1.0) * PI * 0.5 * b.top_dir
		var pivot := Vector2(b.x + (b.w if b.top_dir > 0.0 else 0.0), 0.0)
		draw_set_transform(pivot, ang, Vector2.ONE)
		draw_texture_rect_region(b.tex, Rect2(b.x - pivot.x, -b.cur_h, b.w, b.cur_h), src, city_def.tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var tint: Color = city_def.tint
	if blackout_t > 0.0:
		tint = tint * Color(0.2, 0.18, 0.28)   # the serpent ate the light — windows die
	elif sun_eaten or dark_perm > 0.0:
		tint = tint * Color(0.45, 0.42, 0.55)
	elif night_f < 1.0:
		tint = tint * Color(1, 1, 1).lerp(Color(1.14, 1.02, 0.88), 1.0 - night_f)
	# fear turns the lights down, street by street
	var fearf: float = minf(0.20, threat * 0.002) * _hash(b.seed + 3.0)
	tint = tint * Color(1.0 - fearf, 1.0 - fearf, 1.0 - fearf * 0.7)
	draw_texture_rect_region(b.tex, Rect2(b.x, -b.cur_h, b.w, b.cur_h), src, tint)
	# anchored flames — fire lives ON the building
	if b.burn > 0.2:
		for fa in b.get("flames", []):
			var fp: Vector2 = Vector2(b.x, 0) + fa.p
			if fp.y < -b.cur_h:
				fp.y = -b.cur_h
			var fs: float = fa.s * minf(1.0, b.burn * 0.4)
			var wob: float = sin(t * 9.0 + fa.o) * 0.3 + sin(t * 23.0 + fa.o * 2.0) * 0.15
			var h1: float = fs * (9.0 + sin(t * 7.0 + fa.o) * 2.5)
			draw_circle(fp + Vector2(0, -2), fs * 5.0, Color(1.3, 0.4, 0.1, 0.13))
			draw_colored_polygon(PackedVector2Array([
				fp + Vector2(-fs * 3.2, 0), fp + Vector2(wob * h1 * 0.5 - fs, -h1),
				fp + Vector2(wob * h1, -h1 * 1.25), fp + Vector2(wob * h1 * 0.5 + fs, -h1 * 0.8),
				fp + Vector2(fs * 3.2, 0)]), Color(1.7, 0.55, 0.1, 0.9))
			draw_colored_polygon(PackedVector2Array([
				fp + Vector2(-fs * 1.8, 0), fp + Vector2(wob * h1 * 0.4, -h1 * 0.65),
				fp + Vector2(fs * 1.8, 0)]), Color(2.2, 1.2, 0.3))
			draw_colored_polygon(PackedVector2Array([
				fp + Vector2(-fs * 0.9, 0), fp + Vector2(wob * h1 * 0.3, -h1 * 0.32),
				fp + Vector2(fs * 0.9, 0)]), Color(2.6, 2.1, 0.9))
			if randf() < 0.06:
				parts.append({"pos": fp + Vector2(randf_range(-3, 3), -h1), "vel": Vector2(randf_range(-8, 8), randf_range(-30, -14)),
					"life": randf_range(0.3, 0.8), "col": Color(2.2, 1.2, 0.4), "size": 1.5})
			if randf() < 0.04:
				parts.append({"pos": fp + Vector2(0, -h1 - 2), "vel": Vector2(randf_range(-6, 6), randf_range(-26, -14)),
					"life": randf_range(1.0, 2.0), "col": Color(0.2, 0.18, 0.2), "fire": true, "smoke": true, "size": 3.5})
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
	var spname: String = {"aa": "AA BATTERY", "comms": "RADIO MAST", "barracks": "ARMORY",
		"fuel": "FUEL DEPOT"}.get(b.get("special", ""), "")
	if spname != "":
		var spy: float = -b.cur_h - 12.0
		draw_string(ui_font, Vector2(b.x + b.w * 0.5 - 60, spy), spname, HORIZONTAL_ALIGNMENT_CENTER, 120, 6,
			Color(1.7, 1.5, 0.7, 0.75 + 0.25 * sin(t * 4.0)))
		if objective == "blackout":
			draw_colored_polygon(PackedVector2Array([Vector2(b.x + b.w * 0.5 - 3, spy - 12),
				Vector2(b.x + b.w * 0.5 + 3, spy - 12), Vector2(b.x + b.w * 0.5, spy - 7)]),
				Color(2.0, 1.6, 0.5, 0.6 + 0.3 * sin(t * 5.0)))
	if b.get("landmark_name", "") != "" and not b.dead:
		draw_string(ui_font, Vector2(b.x + b.w * 0.5 - 70, -b.cur_h - 10), b.landmark_name,
			HORIZONTAL_ALIGNMENT_CENTER, 140, 6, Color(1.4, 1.2, 1.6, 0.6))
	if b.cit:
		var cp := Vector2(b.x + b.w * 0.5, -b.cur_h - 8)
		draw_circle(cp, 5, Color(2.0, 1.6, 0.5, 0.25))
		draw_rect(Rect2(cp.x - 2, cp.y - 2, 4, 4), Color(2.2, 1.8, 0.6))
	# landmark beacons — worth hunting
	var spec: String = b.get("special", "")
	if spec != "":
		var mp2 := Vector2(b.x + b.w * 0.5, -b.cur_h - 12 + sin(t * 3.0) * 2.0)
		var mcol: Color
		var label: String
		match spec:
			"barracks":
				mcol = Color(2.0, 0.9, 0.4)
				label = "BARRACKS"
			"comms":
				mcol = Color(0.5, 1.6, 2.0)
				label = "COMMS"
			_:
				mcol = Color(2.2, 0.8, 0.2)
				label = "FUEL"
		draw_colored_polygon(PackedVector2Array([mp2 + Vector2(0, -4), mp2 + Vector2(3, 0), mp2 + Vector2(0, 4), mp2 + Vector2(-3, 0)]), mcol)
		draw_string(ui_font, mp2 + Vector2(0, -8), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 8,
			Color(mcol.r, mcol.g, mcol.b, 0.8))
	if dmg > 0.05:
		draw_rect(Rect2(b.x, -b.cur_h - 3, b.w * minf(1.0, dmg * 1.15), 2), Color(1.6, 0.4, 0.25, 0.9))

func _draw_street(left: float, right: float) -> void:
	var lights_out: bool = blackout_t > 0.0 or sun_eaten or night_f < 0.5
	draw_rect(Rect2(left, 0, right - left, 2), city_def.street)
	draw_rect(Rect2(left, 2, right - left, 6), Color("#1c1830"))
	draw_rect(Rect2(left, 8, right - left, 400), Color("#100c1e"))
	var rx := left - fposmod(left, 26.0)
	while rx < right:
		draw_rect(Rect2(rx, 4, 10, 1), Color(0.8, 0.8, 1.0, 0.10))
		rx += 26.0
	# street lamps — destructible, dead during eclipse
	var lamp_c: Color = city_def.lamp
	for l in lamps:
		if l.x < left or l.x > right:
			continue
		draw_rect(Rect2(l.x, -26, 1, 26), Color("#201830"))
		draw_rect(Rect2(l.x - 2, -27, 5, 2), Color("#201830"))
		if l.dead:
			draw_line(Vector2(l.x - 2, -27), Vector2(l.x + 4, -23), Color("#141020"), 2)
			if randf() < 0.02:
				draw_line(Vector2(l.x, -25), Vector2(l.x + randf_range(-3, 3), -21), Color(1.6, 1.8, 2.2, 0.8), 1)
			continue
		if lights_out:
			draw_circle(Vector2(l.x + 0.5, -24), 2.2, Color(0.1, 0.09, 0.14))
			continue
		draw_circle(Vector2(l.x + 0.5, -24), 2.2, lamp_c)
		draw_circle(Vector2(l.x + 0.5, -24), 6.0, Color(lamp_c.r, lamp_c.g, lamp_c.b, 0.12))
		draw_colored_polygon(PackedVector2Array([
			Vector2(l.x - 1, -24), Vector2(l.x + 2, -24), Vector2(l.x + 10, 0), Vector2(l.x - 9, 0)]),
			Color(lamp_c.r * 0.55, lamp_c.g * 0.55, lamp_c.b * 0.55, 0.05))
		draw_rect(Rect2(l.x - 9, -1, 19, 2), Color(lamp_c.r * 0.55, lamp_c.g * 0.55, lamp_c.b * 0.55, 0.09))
	# evac buses
	for bus in buses:
		if bus.x < left - 30 or bus.x > right + 30:
			continue
		draw_rect(Rect2(bus.x - 14, -10, 28, 9), Color("#c8b45a"))
		draw_rect(Rect2(bus.x - 12, -8, 24, 4), Color("#2a2418"))
		for wx3 in 4:
			draw_rect(Rect2(bus.x - 10 + wx3 * 6, -7.5, 4, 3), Color(0.9, 0.85, 0.6))
		draw_rect(Rect2(bus.x - 12, -1, 4, 2), Color("#141210"))
		draw_rect(Rect2(bus.x + 8, -1, 4, 2), Color("#141210"))
		if bus.hp < 3:
			draw_rect(Rect2(bus.x - 6, -10, 12, 3), Color(0.2, 0.1, 0.1, 0.6))
	# cars — destructible
	for c in cars:
		if c.x < left or c.x > right:
			continue
		if c.dead:
			draw_rect(Rect2(c.x + 1, -4, c.w - 2, 3), Color("#0e0a10"))
			draw_rect(Rect2(c.x + 4, -6, c.w - 9, 2), Color("#141018"))
			if randf() < 0.06:
				_fire(Vector2(c.x + randf() * c.w, -5))
			continue
		draw_rect(Rect2(c.x, -5, c.w, 4), c.col)
		draw_rect(Rect2(c.x + 3, -8, c.w - 7, 3), c.col.darkened(0.2))
		draw_rect(Rect2(c.x + 1, -1, 3, 1), Color("#08060c"))
		draw_rect(Rect2(c.x + c.w - 4, -1, 3, 1), Color("#08060c"))
		if not lights_out:
			draw_rect(Rect2(c.x + c.w - 1, -4, 1, 2), Color(1.6, 0.5, 0.3, 0.8))

func _draw_actors() -> void:
	# street furniture
	for pr in props:
		if pr.dead:
			draw_rect(Rect2(pr.x - 4, -4, 10, 4), Color("#120c14"))
			continue
		var tx: Texture2D = pr.tex
		draw_texture(tx, Vector2(pr.x - tx.get_width() * 0.35, -tx.get_height() * 0.7), Color(0.8, 0.75, 0.9))
	# critters
	for cr in critters:
		if cr.dead:
			continue
		var cp: Vector2 = cr.pos
		match cr.kind:
			"pigeon":
				var wing: float = sin(t * 18.0 + cr.o) * 2.0 if cr.panic else 0.0
				draw_rect(Rect2(cp.x - 1.5, cp.y - 3, 3, 2), Color(0.6, 0.58, 0.64))
				draw_rect(Rect2(cp.x, cp.y - 4, 1.5, 1.5), Color(0.5, 0.48, 0.56))
				if cr.panic:
					draw_line(cp + Vector2(-1, -3), cp + Vector2(-4, -3 - wing), Color(0.65, 0.62, 0.68), 1)
					draw_line(cp + Vector2(1, -3), cp + Vector2(4, -3 - wing), Color(0.65, 0.62, 0.68), 1)
			"dog":
				var lope: float = sin(t * 12.0 + cr.o) * 1.5 if cr.panic else 0.0
				draw_rect(Rect2(cp.x - 4, cp.y - 4, 8, 3), Color(0.32, 0.26, 0.22))
				draw_rect(Rect2(cp.x + 3 * signf(cr.vx + 0.1), cp.y - 6, 3, 3), Color(0.32, 0.26, 0.22))
				draw_line(cp + Vector2(-3, -1), cp + Vector2(-3 - lope, 0), Color(0.26, 0.2, 0.18), 1)
				draw_line(cp + Vector2(3, -1), cp + Vector2(3 + lope, 0), Color(0.26, 0.2, 0.18), 1)
			"pig":
				draw_rect(Rect2(cp.x - 4, cp.y - 5, 9, 4), Color(0.85, 0.6, 0.6))
				draw_rect(Rect2(cp.x + 4 * signf(cr.vx + 0.1), cp.y - 6, 3, 3), Color(0.8, 0.55, 0.55))
				draw_rect(Rect2(cp.x - 3, cp.y - 1, 2, 1), Color(0.7, 0.45, 0.45))
				draw_rect(Rect2(cp.x + 2, cp.y - 1, 2, 1), Color(0.7, 0.45, 0.45))
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
		if u.get("mad", false):
			var sw := sin(t * 7.0) * 3.0
			draw_arc(p + Vector2(0, -22), 3.0 + sw * 0.4, t * 4.0, t * 4.0 + 4.0, 8, Color(1.5, 0.5, 1.6, 0.8), 1.0)
		elif u.has("inf"):
			draw_circle(p + Vector2(0, -20 + sin(t * 5.0)), 1.5, Color(0.8, 1.4, 0.3, 0.8))
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
			"herald":
				var hd: Dictionary = HERALD_DEFS[u.htype]
				var hsc: float = hd.scale
				var hcol: Color = hd.col
				var flies: bool = hd.get("flies", false)
				var hp0: Vector2 = p + Vector2(0, -14.0 * hsc + (sin(t * 2.0) * 6.0 if flies else 0.0))
				# aura — the wrongness bleeds into the air
				draw_circle(hp0, 20.0 * hsc, Color(hcol.r, hcol.g, hcol.b, 0.10))
				# mass
				draw_circle(hp0, 14.0 * hsc, hcol.darkened(0.35))
				draw_circle(hp0 + Vector2(4.0 * hsc, -4.0 * hsc), 10.0 * hsc, hcol)
				draw_circle(hp0 + Vector2(-6.0 * hsc, 2.0 * hsc), 8.0 * hsc, hcol.darkened(0.2))
				# spines
				for si in 4:
					var sa: float = -PI * 0.5 + (si - 1.5) * 0.5 + sin(t * 1.5 + si) * 0.1
					draw_line(hp0, hp0 + Vector2.from_angle(sa) * 22.0 * hsc, hcol.darkened(0.45), 2.5)
				# eyes — a hungry constellation, watching you
				var fdir: float = signf(pos.x - p.x)
				for ei in 3:
					draw_circle(hp0 + Vector2((ei - 1) * 4.0 * hsc * fdir + 5.0 * hsc * fdir, -2.0 * hsc),
						1.6, Color(2.2, 0.6, 0.8))
				# caster telegraph
				if u.get("cast_t", 0.0) > 0.0:
					draw_line(Vector2(u.cast_p, -300), Vector2(u.cast_p, 0),
						Color(2.0, 0.5, 0.4, 0.5 + 0.3 * sin(t * 20.0)), 3.0)
					draw_circle(Vector2(u.cast_p, -4), 40.0, Color(1.8, 0.4, 0.3, 0.15))
				draw_string(ui_font, hp0 + Vector2(0, -26.0 * hsc - 8.0), u.name,
					HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(2.2, 0.7, 1.0))
				draw_rect(Rect2(hp0.x - 30, hp0.y - 26.0 * hsc, 60, 3), Color(0.08, 0.05, 0.1))
				draw_rect(Rect2(hp0.x - 30, hp0.y - 26.0 * hsc, 60.0 * u.hp / float(u.maxhp), 3), Color(2.0, 0.5, 0.8))
			"brood":
				draw_circle(p + Vector2(0, -5 + sin(t * 8.0 + p.x) * 2.0), 3.0, Color(0.55, 0.2, 0.6))
				draw_circle(p + Vector2(1, -6), 1.0, Color(1.8, 0.6, 1.2))
			"flamer":
				draw_rect(Rect2(p.x - 2, p.y - 7, 4, 5), Color("#5a4430"))
				draw_rect(Rect2(p.x - 2, p.y - 9, 4, 2), Color("#403020"))
				draw_rect(Rect2(p.x - 4, p.y - 6, 2, 4), Color("#803020"))   # tank on the back
				var pil: float = 0.5 + 0.5 * sin(t * 12.0 + p.x)
				draw_circle(p + Vector2(signf(pos.x - p.x) * 5.0, -6), 1.2, Color(2.2, 1.2, 0.3, pil))
			"priest":
				draw_rect(Rect2(p.x - 2, p.y - 8, 4, 6), Color("#d8d0c0"))
				draw_rect(Rect2(p.x - 2, p.y - 10, 4, 2), Color("#b0a890"))
				draw_line(Vector2(p.x, p.y - 13), Vector2(p.x, p.y - 10), Color(1.9, 1.7, 1.0), 1)
				draw_line(Vector2(p.x - 1.5, p.y - 12), Vector2(p.x + 1.5, p.y - 12), Color(1.9, 1.7, 1.0), 1)
				draw_arc(p + Vector2(0, -8), 90.0, 0, TAU, 40, Color(1.8, 1.6, 0.9, 0.05 + 0.02 * sin(t * 3.0)), 1.0)
			"champ":
				# the champion's command tank — bannered, armored, named
				draw_rect(Rect2(p.x - 13, p.y - 9, 26, 7), Color("#4a3c2c"))
				draw_rect(Rect2(p.x - 13, p.y - 9, 26, 2), Color("#5c4c38"))
				draw_rect(Rect2(p.x - 7, p.y - 14, 14, 6), Color("#4a3c2c"))
				draw_line(Vector2(p.x, p.y - 12), Vector2(p.x + signf(pos.x - p.x) * 15, p.y - 16), Color("#4a3c2c"), 2.5)
				draw_rect(Rect2(p.x - 14, p.y - 3, 28, 3), Color("#1c1812"))
				draw_line(Vector2(p.x - 10, p.y - 14), Vector2(p.x - 10, p.y - 22), Color("#2c2418"), 1)
				draw_rect(Rect2(p.x - 10, p.y - 22, 6, 4), Color(1.9, 1.5, 0.4))
				draw_string(ui_font, p + Vector2(0, -26), u.get("name", "CHAMPION"),
					HORIZONTAL_ALIGNMENT_CENTER, -1, 7, Color(2.0, 1.7, 0.8))
				# health bar
				draw_rect(Rect2(p.x - 12, p.y - 25, 24, 2), Color(0.1, 0.08, 0.1))
				draw_rect(Rect2(p.x - 12, p.y - 25, 24.0 * u.hp / 14.0, 2), Color(1.9, 0.5, 0.4))
			"news":
				draw_rect(Rect2(p.x - 8, p.y - 3, 16, 6), Color("#c8ccd4"))
				draw_rect(Rect2(p.x + (8 if pos.x < p.x else -14), p.y - 1, 6, 2), Color("#c8ccd4"))
				draw_rect(Rect2(p.x - 4, p.y - 2, 8, 3), Color(1.8, 0.3, 0.3))
				var nrot: float = sin(t * 40.0) * 12.0
				draw_line(p + Vector2(-nrot, -5), p + Vector2(nrot, -5), Color(0.85, 0.88, 0.9, 0.6), 1)
				# camera lens glint toward the story
				var lens := (pos - p).normalized()
				draw_circle(p + lens * 9.0, 1.2, Color(1.6, 1.6, 2.2, 0.7 + 0.3 * sin(t * 6.0)))
			"militia":
				var mleg: float = sin(t * 9.0 + p.x * 0.8) * 1.4
				draw_rect(Rect2(p.x - 1, p.y - 7, 3, 5), Color("#6a5638"))
				draw_rect(Rect2(p.x - 1, p.y - 9, 3, 2), Color("#caa87a"))
				draw_rect(Rect2(p.x - 2.5, p.y - 10, 6, 1), Color("#a08a50"))
				draw_line(Vector2(p.x, p.y - 2), Vector2(p.x - mleg, p.y), Color("#4a3c28"), 1)
				draw_line(Vector2(p.x, p.y - 2), Vector2(p.x + mleg, p.y), Color("#4a3c28"), 1)
				draw_line(Vector2(p.x, p.y - 5), Vector2(p.x + signf(pos.x - p.x) * 5, p.y - 7), Color("#2c2418"), 1)
			"soldier":
				var sleg: float = sin(t * 10.0 + p.x * 0.7) * 1.6
				draw_rect(Rect2(p.x - 1, p.y - 7, 3, 5), Color("#3a4432"))
				draw_rect(Rect2(p.x - 1, p.y - 9, 3, 2), Color("#2c3428"))
				draw_line(Vector2(p.x, p.y - 2), Vector2(p.x - sleg, p.y), Color("#2c3428"), 1)
				draw_line(Vector2(p.x, p.y - 2), Vector2(p.x + sleg, p.y), Color("#2c3428"), 1)
				draw_line(Vector2(p.x, p.y - 5), Vector2(p.x + signf(pos.x - p.x) * 5, p.y - 6), Color("#20261c"), 1)
			"arty":
				draw_rect(Rect2(p.x - 13, p.y - 7, 26, 6), Color("#3c4034"))
				draw_rect(Rect2(p.x - 13, p.y - 3, 26, 3), Color("#20241c"))
				draw_line(Vector2(p.x + 2, p.y - 7), Vector2(p.x + signf(pos.x - p.x) * 16, p.y - 20), Color("#3c4034"), 3)
				if u.get("mf", 0.0) > 0.0:
					draw_circle(Vector2(p.x + signf(pos.x - p.x) * 16, p.y - 20), 4.0, Color(2.4, 1.8, 0.8))
			"jet":
				var jd: float = signf(u.vx)
				draw_colored_polygon(PackedVector2Array([p + Vector2(jd * 12, 0), p + Vector2(-jd * 8, -4), p + Vector2(-jd * 8, 4)]),
					Color("#3a4048"))
				draw_colored_polygon(PackedVector2Array([p + Vector2(0, 0), p + Vector2(-jd * 6, -7), p + Vector2(-jd * 2, 0)]),
					Color("#2c3238"))
				draw_line(p + Vector2(-jd * 8, 0), p + Vector2(-jd * 20, 0), Color(1.6, 1.2, 0.6, 0.5), 2)
			"carcass":
				var cw: float = u.get("w", 16.0)
				var ccol: Color = u.get("col", Color("#2a2a34"))
				draw_rect(Rect2(p.x - cw * 0.5, p.y - 3, cw, 4), ccol)
				draw_rect(Rect2(p.x - cw * 0.5 + 3, p.y - 6, cw - 7, 3), ccol.darkened(0.2))
	for s in shells:
		var sc: Color = Color(2.4, 1.9, 0.7) if s.heavy else Color(2.0, 1.6, 0.6)
		draw_rect(Rect2(s.pos.x - 1, s.pos.y - 1, 3 if s.heavy else 2, 3 if s.heavy else 2), sc)
	# tumbling building fragments — behind particles, over buildings
	for fr in frags:
		var fa: float = clampf(fr.life * 1.8, 0.0, 1.0)
		draw_set_transform(fr.pos, fr.rot, Vector2.ONE)
		draw_texture_rect_region(fr.tex, Rect2(-fr.w * 0.5, -fr.h * 0.5, fr.w, fr.h), fr.src,
			Color(0.9, 0.85, 0.9, fa))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for p in parts:
		var a: float = clampf(p.life * 2.5, 0.0, 1.0)
		if p.get("ring", false):
			var rr2: float = p.size + (0.5 - p.life) * 160.0
			draw_arc(p.pos, maxf(1.0, rr2), 0, TAU, 40, Color(p.col.r, p.col.g, p.col.b, a * 0.5), 2.5)
			draw_arc(p.pos, maxf(1.0, rr2 * 0.8), 0, TAU, 40, Color(p.col.r, p.col.g, p.col.b, a * 0.25), 4.0)
		elif p.get("flash", false):
			draw_circle(p.pos, p.size * (1.0 + (0.22 - p.life) * 8.0), Color(p.col.r, p.col.g, p.col.b, a * 0.7))
		elif p.get("bird", false):
			var wf3: float = 2.5 if fmod(p.life * 9.0, 2.0) < 1.0 else 0.5
			draw_line(p.pos + Vector2(-3, -wf3), p.pos, Color(p.col.r, p.col.g, p.col.b, a), 1.0)
			draw_line(p.pos, p.pos + Vector2(3, -wf3), Color(p.col.r, p.col.g, p.col.b, a), 1.0)
		elif p.get("fire", false) and not p.get("smoke", false):
			# real flame: glow + tongue that flickers and tapers as it dies
			var fl: float = p.life
			var flick: float = sin(t * 23.0 + p.pos.x * 3.0) * 1.2
			draw_circle(p.pos + Vector2(1, 0), 3.5 * fl + 1.0, Color(1.2, 0.45, 0.1, 0.16 * a))
			draw_colored_polygon(PackedVector2Array([
				p.pos + Vector2(-1.8, 1.5), p.pos + Vector2(flick * 0.5, -4.5 * fl - 1.5),
				p.pos + Vector2(1.8, 1.5)]), Color(1.9, 0.75, 0.15, a))
			draw_colored_polygon(PackedVector2Array([
				p.pos + Vector2(-0.9, 1.0), p.pos + Vector2(flick * 0.4, -2.6 * fl - 0.8),
				p.pos + Vector2(0.9, 1.0)]), Color(2.3, 1.6, 0.5, a))
		elif p.get("smoke", false):
			draw_circle(p.pos, p.get("size", 2.0) * (1.6 - p.life * 0.5), Color(0.16, 0.14, 0.16, a * 0.35))
		elif p.get("chunk", false):
			var sz: float = p.get("size", 2.0)
			p.rot = p.get("rot", 0.0) + p.get("rotv", 0.0) * 0.016
			draw_set_transform(p.pos, p.rot, Vector2.ONE)
			draw_rect(Rect2(-sz * 0.5, -sz * 0.5, sz, sz), Color(p.col.r, p.col.g, p.col.b, a))
			draw_rect(Rect2(-sz * 0.5, -sz * 0.5, sz, sz * 0.35), Color(p.col.lightened(0.2).r, p.col.lightened(0.2).g, p.col.lightened(0.2).b, a))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
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
	# the stormfront travels WITH him — his own weather
	for i in 5:
		var cp := pos + Vector2(sin(t * 0.3 + i * 2.3) * 60.0 + (i - 2) * 38.0, -95.0 - (i % 3) * 10.0)
		draw_circle(cp, (20.0 + (i % 3) * 7.0) * growth, Color(0.05, 0.06, 0.1, 0.5))
		draw_circle(cp + Vector2(9, 5), 14.0 * growth, Color(0.08, 0.09, 0.14, 0.45))
		if randf() < 0.012:
			draw_line(cp + Vector2(randf_range(-10, 10), 6), cp + Vector2(randf_range(-16, 16), 30.0 + randf() * 20.0),
				Color(1.2, 1.8, 2.4, 0.55), 1.0)
	# ===== the colossus: Ghidorah-scale storm hydra (1.5x transform) =====
	draw_set_transform(pos * (1.0 - 1.5 * growth), 0.0, Vector2(1.5 * growth, 1.5 * growth))
	var facing: float = signf(aim.x - pos.x)
	if facing == 0.0:
		facing = 1.0
	var body_c := Color(0.10, 0.11, 0.18)
	var body_hi := Color(0.16, 0.18, 0.28)
	var flap: float = sin(t * 4.5)
	# WINGS — vast, storm-membrane
	for side in [-1.0, 1.0]:
		var wr := pos + Vector2(side * 14.0, -22)
		var tipy: float = -68.0 + flap * 22.0
		var wing := PackedVector2Array([
			wr,
			wr + Vector2(side * 36.0, tipy * 0.4),
			wr + Vector2(side * 78.0, tipy),
			wr + Vector2(side * 64.0, tipy * 0.55 + 16.0),
			wr + Vector2(side * 30.0, 6.0)])
		draw_colored_polygon(wing, Color(0.07, 0.08, 0.14, 0.92))
		draw_line(wr, wr + Vector2(side * 78.0, tipy), body_hi, 2.0)
		draw_line(wr, wr + Vector2(side * 64.0, tipy * 0.55 + 16.0), body_hi, 1.5)
		# crackle veins in the membrane
		if randf() < 0.12:
			var v0 := wr + Vector2(side * randf_range(20, 60), tipy * randf_range(0.3, 0.8))
			draw_line(v0, v0 + Vector2(randf_range(-8, 8), randf_range(-8, 8)), Color(1.2, 1.8, 2.4, 0.7), 1.0)
	# TAIL — long, spiked, trailing away from facing
	var tp := pos + Vector2(-facing * 16.0, 8.0)
	var tprev := tp
	for i in range(1, 9):
		var f := float(i) / 8.0
		var seg := tp + Vector2(-facing * 52.0 * f, 10.0 * f + sin(t * 3.0 + f * 5.0) * 6.0 * f)
		draw_line(tprev, seg, body_c, 9.0 * (1.0 - f) + 2.0)
		if i % 2 == 0:
			draw_colored_polygon(PackedVector2Array([seg + Vector2(-2, 0), seg + Vector2(0, -6.0 * (1.0 - f) - 2.0), seg + Vector2(2, 0)]),
				body_hi)
		tprev = seg
	# BODY — massive chest
	draw_circle(pos + Vector2(0, 4), 20.0, body_c)
	draw_circle(pos + Vector2(facing * 6.0, -4), 17.0, body_c)
	draw_circle(pos + Vector2(-facing * 8.0, 2), 15.0, Color(0.08, 0.09, 0.15))
	draw_circle(pos + Vector2(facing * 4.0, -8), 10.0, body_hi)
	# chest glow — the storm heart
	draw_circle(pos + Vector2(facing * 4.0, 0), 6.0 + sin(t * 6.0) * 1.5, Color(0.5, 1.4, 2.2, 0.5))
	draw_circle(pos + Vector2(facing * 4.0, 0), 3.0, Color(1.4, 2.0, 2.6))
	# LEGS — talons hanging
	for side in [-1.0, 1.0]:
		var lroot := pos + Vector2(side * 8.0, 18.0)
		var knee := lroot + Vector2(side * 4.0, 10.0 + sin(t * 2.0 + side) * 2.0)
		draw_line(lroot, knee, body_c, 6.0)
		draw_line(knee, knee + Vector2(side * 3.0, 8.0), body_c, 4.0)
		for c2 in 3:
			draw_line(knee + Vector2(side * 3.0, 8.0),
				knee + Vector2(side * 3.0 + (c2 - 1) * 3.0, 13.0), body_hi, 1.5)
	# THREE NECKS — long serpent throats, leaning at the cursor
	var lean := (aim - pos).normalized() * 26.0
	var n_heads: int = 4 if bolt_max >= 4.0 else 3
	for h in n_heads:
		var hf: float = (float(h) / maxf(1.0, n_heads - 1.0)) - 0.5
		var root := pos + Vector2(hf * 16.0, -14)
		var head := root + Vector2(hf * 34.0, -46) + lean + Vector2(sin(t * 2.6 + h * 2.1) * 5.0, cos(t * 3.1 + h) * 3.0)
		var prev := root
		for i in range(1, 7):
			var f := float(i) / 6.0
			var npt := root.lerp(head, f) + Vector2(sin(f * 7.0 + t * 4.0 + h * 2.0) * 5.0 * (1.0 - f * 0.5), 0)
			draw_line(prev, npt, body_c, 7.0 * (1.0 - f) + 2.5)
			prev = npt
		# head: wedge skull + horns + burning eye
		var hdir := (aim - head).normalized()
		draw_circle(head, 5.0, body_c)
		draw_colored_polygon(PackedVector2Array([head + hdir.orthogonal() * 3.0, head + hdir * 9.0, head - hdir.orthogonal() * 3.0]), body_c)
		draw_colored_polygon(PackedVector2Array([head + Vector2(-2, -4), head + Vector2(-5, -11), head + Vector2(1, -5)]), body_hi)
		draw_colored_polygon(PackedVector2Array([head + Vector2(2, -4), head + Vector2(6, -10), head + Vector2(4, -3)]), body_hi)
		draw_circle(head + hdir * 3.0, 1.6, Color(1.2, 2.0, 2.6))
		# jaw crackle
		if randf() < 0.08:
			draw_line(head + hdir * 8.0, head + hdir * (14.0 + randf() * 8.0) + Vector2(randf_range(-4, 4), randf_range(-4, 4)),
				Color(1.4, 1.9, 2.4, 0.8), 1.2)
	# charge pips
	for i in int(bolt_max):
		var lit: bool = bolt_charges >= i + 1
		draw_circle(pos + Vector2(i * 7 - (bolt_max - 1.0) * 3.5, 34), 2.0,
			Color(0.8, 1.8, 2.2) if lit else Color(0.15, 0.2, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_tzitzi() -> void:
	# molting feathers drift from the long body
	if randf() < 0.18 and segs.size() > 4:
		var sp: Vector2 = segs[randi() % segs.size()]
		parts.append({"pos": sp, "vel": Vector2(randf_range(-8, 8), randf_range(6, 16)),
			"life": randf_range(1.0, 2.2), "col": Color(1.6, 1.1, 0.3), "size": 1.5})
	# crosshair
	draw_circle(aim, 2.0, Color(1.8, 1.2, 0.4, 0.7))
	draw_arc(aim, 5.0, 0, TAU, 12, Color(1.8, 1.2, 0.4, 0.4), 1.0)
	var glow := blackout_t > 0.0 or sun_eaten
	var n := segs.size()
	if n < 3:
		return
	# ===== QUETZALCOATL — baked pixel sprites along the trail =====
	var body_mod := Color(1.35, 1.35, 1.2) if glow else Color(1, 1, 1)
	# wings first (behind body), at segment ~5, flapping
	if n > 8:
		var wroot: Vector2 = segs[5]
		var walong: Vector2 = (segs[3] - segs[7])
		var wang: float = walong.angle() if walong.length() > 0.5 else 0.0
		var flap: float = sin(t * 5.5) * 0.55
		draw_set_transform(wroot, wang - 1.1 + flap, Vector2(1.3, 1.3))
		draw_texture(serp_wing, Vector2(-3, -20), body_mod)
		draw_set_transform(wroot, wang + PI + 1.1 - flap, Vector2(1.3, -1.3))
		draw_texture(serp_wing, Vector2(-3, -20), body_mod)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# body segments tail -> neck, scaled by taper
	for i in range(n - 1, 0, -2):
		var p: Vector2 = segs[i]
		var pn: Vector2 = segs[maxi(0, i - 2)]
		var seg_ang: float = (pn - p).angle() if pn.distance_to(p) > 0.3 else 0.0
		var f := 1.0 - float(i) / n
		var s := (0.55 + sin(f * PI) ** 0.8 * 0.75) * growth
		draw_set_transform(p, seg_ang, Vector2(s, s))
		draw_texture(serp_body, Vector2(-7, -9), body_mod)
	# head
	var hang := (aim - pos).angle()
	var hflip: float = 1.0 if absf(angle_difference(hang, 0.0)) < PI * 0.5 else -1.0
	draw_set_transform(pos, hang, Vector2(1.25 * growth, 1.25 * growth * hflip))
	draw_texture(serp_head, Vector2(-11, -10), body_mod)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if dive_t > 0.0:
		for i in 5:
			var tp := pos - dive_dir * (i * 10.0 + 10.0) + Vector2(randf_range(-4, 4), randf_range(-4, 4))
			draw_line(tp, tp - dive_dir * 8.0, Color(1.8, 1.2, 0.4, 0.55 - i * 0.1), 2.0)
	if glow:
		draw_circle(pos, 14.0, Color(1.6, 1.1, 0.3, 0.12))
	return
	# ===== legacy polygon serpent (unused) =====
	var emerald := Color(0.07, 0.32, 0.2)
	var emerald_hi := Color(0.12, 0.5, 0.3)
	var belly := Color(0.85, 0.68, 0.3)
	if glow:
		emerald = emerald.lightened(0.2)
		emerald_hi = Color(0.3, 1.0, 0.6)
		belly = Color(1.6, 1.2, 0.5)
	# dorsal plume feathers first (behind the body) — a mane down the whole spine
	for i in range(n - 1, 0, -1):
		if i % 3 != 0:
			continue
		var p: Vector2 = segs[i]
		var pn: Vector2 = segs[i - 1]
		if pn.distance_to(p) < 0.5:
			continue
		var f := 1.0 - float(i) / n
		var body_r: float = 3.0 + sin(f * PI) ** 0.7 * 9.0
		var along := (pn - p).normalized()
		var up := along.orthogonal()
		if up.y > 0:
			up = -up
		var sway: float = sin(t * 3.0 + i * 0.7) * 0.25
		var plume_len: float = body_r * (1.8 + sin(f * PI) * 0.8)
		var base1 := p + along * 2.0
		var base2 := p - along * 2.0
		var tip := p + (up + along * sway).normalized() * (body_r + plume_len)
		draw_colored_polygon(PackedVector2Array([base1 + up * body_r * 0.5, tip, base2 + up * body_r * 0.5]),
			Color(1.5, 0.35, 0.25) if not glow else Color(2.0, 0.5, 0.3))
		var tip2 := p + (up + along * (sway + 0.15)).normalized() * (body_r + plume_len * 0.6)
		draw_colored_polygon(PackedVector2Array([base1 + up * body_r * 0.4, tip2, base2 + up * body_r * 0.4]),
			Color(1.7, 1.15, 0.3) if not glow else Color(2.2, 1.6, 0.5))
	# great feathered wings near the head — five blades each, flapping
	if n > 8:
		var wing_root: Vector2 = segs[5]
		var w_along: Vector2 = (segs[3] - segs[7]).normalized()
		var w_up: Vector2 = w_along.orthogonal()
		if w_up.y > 0:
			w_up = -w_up
		var flap: float = sin(t * 5.0) * 0.5
		for side in [-1.0, 1.0]:
			for fb in 5:
				var fang: float = (-0.5 + fb * 0.22 + flap * 0.4) * side
				var fdir: Vector2 = (w_up.rotated(fang * 0.9) + w_along * 0.2 * side).normalized()
				var flen: float = 34.0 - fb * 4.0
				var w_tip := wing_root + fdir * flen
				var w_side := fdir.orthogonal() * 3.0
				var fc := Color(1.6, 1.1, 0.3) if fb % 2 == 0 else Color(0.15, 0.65, 0.4)
				if glow:
					fc = fc.lightened(0.3)
				draw_colored_polygon(PackedVector2Array([wing_root + w_side, w_tip, wing_root - w_side]), fc)
	# body — tapering coils, emerald scales with gold belly
	for i in range(n - 1, -1, -1):
		var f := 1.0 - float(i) / n
		var r: float = 3.0 + sin(f * PI) ** 0.7 * 9.0
		var p: Vector2 = segs[i]
		draw_circle(p, r, emerald if i % 2 == 0 else emerald.darkened(0.15))
		draw_circle(p + Vector2(0, r * 0.35), r * 0.5, belly)
		if i % 4 == 0:
			draw_circle(p + Vector2(0, -r * 0.4), r * 0.35, emerald_hi)
	# head — crowned, jawed, burning-eyed
	var hd := pos
	var hdir := (aim - pos).normalized()
	var hup := hdir.orthogonal()
	if hup.y > 0:
		hup = -hup
	draw_circle(hd, 10.0, emerald)
	draw_circle(hd + hdir * 5.0, 7.0, emerald)
	# open jaw
	draw_colored_polygon(PackedVector2Array([hd + hdir * 6.0 + hup * 3.0, hd + hdir * 16.0 + hup * 5.0, hd + hdir * 9.0]), emerald_hi)
	draw_colored_polygon(PackedVector2Array([hd + hdir * 6.0 - hup * 3.0, hd + hdir * 15.0 - hup * 6.0, hd + hdir * 9.0]), emerald.darkened(0.1))
	draw_circle(hd + hdir * 6.0 + hup * 1.0, 1.5, Color(2.4, 1.9, 1.0))   # fang glint
	# crest fan — five great feathers arcing back off the skull
	for fb in 5:
		var cang: float = 0.5 + fb * 0.3
		var cdir := (-hdir).rotated((cang - 1.1) * 1.0)
		var clen: float = 22.0 - absf(fb - 2.0) * 3.0
		var c_tip := hd + cdir * clen + hup * 6.0
		var c_side := cdir.orthogonal() * 2.5
		var cc := Color(1.8, 0.4, 0.3) if fb % 2 == 0 else Color(1.7, 1.2, 0.35)
		if glow:
			cc = cc.lightened(0.25)
		draw_colored_polygon(PackedVector2Array([hd + c_side, c_tip, hd - c_side]), cc)
	# the eye
	draw_circle(hd + hdir * 2.0 + hup * 2.5, 2.2, Color(0.05, 0.02, 0.05))
	draw_circle(hd + hdir * 2.0 + hup * 2.5, 1.2, Color(2.4, 1.4, 0.3))
	if dive_t > 0.0:
		for i in 5:
			var tp := hd - dive_dir * (i * 10.0 + 8.0) + Vector2(randf_range(-4, 4), randf_range(-4, 4))
			draw_line(tp, tp - dive_dir * 8.0, Color(1.8, 1.2, 0.4, 0.55 - i * 0.1), 2.0)

func _draw_allies() -> void:
	for a in allies:
		var p: Vector2 = a.pos
		draw_rect(Rect2(p.x - 4, -1, 8, 2), Color(0, 0, 0, 0.35))
		match a.kind:
			"fishman":
				draw_rect(Rect2(p.x - 2, p.y - 9, 4, 7), Color("#2e7a72"))
				draw_rect(Rect2(p.x - 2, p.y - 12, 4, 3), Color("#3a968a"))
				draw_rect(Rect2(p.x - 1, p.y - 11, 1, 1), Color(0.8, 1.6, 1.4))
				draw_line(p + Vector2(-2, -6), p + Vector2(-4, -3), Color("#255f5a"), 1)
				draw_line(p + Vector2(2, -6), p + Vector2(4, -3), Color("#255f5a"), 1)
			"brute":
				draw_rect(Rect2(p.x - 4, p.y - 12, 8, 10), Color("#2e6a72"))
				draw_rect(Rect2(p.x - 3, p.y - 15, 6, 4), Color("#3a8a8a"))
				draw_rect(Rect2(p.x - 2, p.y - 14, 2, 1), Color(0.8, 1.6, 1.4))
				draw_rect(Rect2(p.x - 6, p.y - 10, 2, 6), Color("#255f66"))
				draw_rect(Rect2(p.x + 4, p.y - 10, 2, 6), Color("#255f66"))
			"priest":
				draw_rect(Rect2(p.x - 3, p.y - 12, 6, 10), Color("#3a4a7a"))
				draw_rect(Rect2(p.x - 2, p.y - 14, 4, 3), Color("#2e3a62"))
				draw_circle(p + Vector2(0, -16), 2.5 + sin(t * 4.0) * 0.6, Color(1.2, 0.5, 1.6, 0.4))
			"whelp":
				draw_circle(p + Vector2(0, -6), 9.0, Color("#1e4a52"))
				draw_circle(p + Vector2(-2, -8), 6.0, Color("#2e6a6e"))
				for tb in 4:
					var tx2: float = p.x - 7 + tb * 4.5
					draw_line(Vector2(tx2, p.y - 2), Vector2(tx2 + sin(t * 5.0 + tb) * 3.0, p.y + 1), Color("#1e4a52"), 2)
				draw_circle(p + Vector2(1, -9), 1.2, Color(0.8, 1.6, 1.4))
			_:
				# risen shambler / soldier
				var rc := Color("#5a6456") if a.kind == "risen_soldier" else Color("#6a6a62")
				draw_rect(Rect2(p.x - 2, p.y - 8, 4, 6), rc)
				draw_rect(Rect2(p.x - 2, p.y - 10.5, 4, 3), Color("#8a887a"))
				draw_rect(Rect2(p.x - 1, p.y - 10, 1, 1), Color(1.5, 1.3, 0.5))
				if a.kind == "risen_soldier":
					draw_line(p + Vector2(0, -6), p + Vector2(5, -7), Color("#20261c"), 1)

func _draw_drowned() -> void:
	draw_circle(aim, 2.0, Color(0.6, 1.6, 1.5, 0.7))
	draw_arc(aim, 5.0, 0, TAU, 12, Color(0.6, 1.6, 1.5, 0.4), 1.0)
	var facing: float = signf(aim.x - pos.x)
	if facing == 0.0:
		facing = 1.0
	_drowned_priest(facing)
	# the bay follows him — fish leap in his wake
	if randf() < 0.06:
		parts.append({"pos": pos + Vector2(randf_range(-60, 60), -2), "vel": Vector2(randf_range(-20, 20), randf_range(-95, -55)),
			"life": 0.9, "col": Color(0.5, 0.95, 0.85), "size": 2.0})

func _drowned_priest(facing: float) -> void:
	# V1 — THE TIDE PRIEST: a hooded colossus, its face a fall of tentacles
	var g: float = 2.9 * growth
	var o: Vector2 = pos
	var H: float = 38.0 * g
	var sway: float = sin(t * 1.3) * 2.0
	var DKW := Color(0.02, 0.08, 0.10)
	var DKW2 := Color(0.04, 0.13, 0.15)
	# the robe — one solid hooded silhouette, hem breaking into the sea
	var robe := PackedVector2Array()
	robe.append(o + Vector2(-13.0 * g * 0.5, 0))
	robe.append(o + Vector2(-11.0 * g * 0.5 + sway * 0.4, -H * 0.35))
	robe.append(o + Vector2(-14.0 * g * 0.5 + sway * 0.6, -H * 0.62))       # hunched shoulder L
	robe.append(o + Vector2(-8.0 * g * 0.5 + sway, -H * 0.86))
	robe.append(o + Vector2(-3.5 * g * 0.5 + sway, -H))                     # hood peak
	robe.append(o + Vector2(3.5 * g * 0.5 + sway, -H * 0.98))
	robe.append(o + Vector2(9.0 * g * 0.5 + sway, -H * 0.84))
	robe.append(o + Vector2(15.0 * g * 0.5 + sway * 0.6, -H * 0.6))         # shoulder R
	robe.append(o + Vector2(12.0 * g * 0.5 + sway * 0.4, -H * 0.33))
	robe.append(o + Vector2(14.0 * g * 0.5, 0))
	# ragged hem
	for i in 6:
		var f: float = 1.0 - float(i) / 5.0
		robe.append(o + Vector2((14.0 - 28.0 * (1.0 - f)) * g * 0.5 * -1.0 + 28.0 * f * g * 0.5,
			-fmod(sin((f + t * 0.1) * 23.0) * 4.0, 3.5) * g * 0.4))
	draw_colored_polygon(robe, DKW)
	var rim := robe.duplicate()
	rim.append(robe[0])
	draw_polyline(rim, Color(0.16, 0.45, 0.45, 0.6), 1.3)
	# robe sheen folds
	draw_circle(o + Vector2(sway - 3.0 * g * 0.5, -H * 0.5), 6.0 * g * 0.5, DKW2)
	draw_circle(o + Vector2(sway + 5.0 * g * 0.5, -H * 0.42), 4.5 * g * 0.5, DKW2)
	# barnacle clusters on the shoulders
	for bc in [[-11.0, 0.64], [11.5, 0.62], [-6.0, 0.8]]:
		var bp := o + Vector2(bc[0] * g * 0.5 + sway * 0.7, -H * bc[1])
		draw_circle(bp, 1.8, Color(0.25, 0.5, 0.48))
		draw_circle(bp + Vector2(2.0, 1.0), 1.1, Color(0.2, 0.42, 0.4))
	# THE FACE — a hanging fall of tentacles where a face should be
	var fc := o + Vector2(sway + facing * 1.0 * g * 0.5, -H * 0.84)
	for tn in 7:
		var tx0: float = (tn - 3.0) * 1.9 * g * 0.4
		var ph: float = t * 1.6 + tn * 1.1
		var prev := fc + Vector2(tx0, 1.0)
		var tlen: float = (7.0 + (tn % 3) * 2.5 + 2.0 * sin(ph * 0.6)) * g * 0.45
		for s in 4:
			var f2: float = float(s + 1) / 4.0
			var npt := fc + Vector2(tx0 + sin(ph + f2 * 2.6) * 2.6 * f2, 1.0 + tlen * f2)
			draw_line(prev, npt, DKW2 if tn % 2 == 0 else Color(0.06, 0.18, 0.19), 2.6 * (1.0 - f2 * 0.6) + 0.8)
			prev = npt
	# eyes burning deep in the hood, above the tentacle-fall
	for side in [-1.0, 1.0]:
		var ep := fc + Vector2(side * 2.6 * g * 0.4, -3.2 * g * 0.4)
		draw_circle(ep, 6.0, Color(0.5, 1.4, 1.3, 0.12))
		draw_circle(ep, 2.2, Color(0.5, 1.4, 1.3, 0.35))
		draw_circle(ep, 1.1, Color(1.3, 2.4, 2.2))
	# water sheeting off the shoulders, foam at the hem
	if randf() < 0.6:
		var wside: float = -1.0 if randf() < 0.5 else 1.0
		parts.append({"pos": o + Vector2(wside * randf_range(8.0, 13.0) * g * 0.5, -H * randf_range(0.55, 0.62)),
			"vel": Vector2(wside * randf_range(2, 8), randf_range(35, 65)), "life": randf_range(0.35, 0.7),
			"col": Color(0.4, 0.8, 0.85, 0.5), "size": 1.3})
	for fm in 6:
		var fx2: float = o.x + (fm - 2.5) * 5.0 * g * 0.5 + sin(t * 4.0 + fm * 1.7) * 2.0
		draw_circle(Vector2(fx2, -1.0 + sin(t * 6.0 + fm) * 0.8), 2.0 + (fm % 2), Color(0.55, 0.85, 0.85, 0.22))

func _draw_rider() -> void:
	draw_circle(aim, 2.0, Color(1.6, 1.5, 0.7, 0.7))
	draw_arc(aim, 5.0, 0, TAU, 12, Color(1.6, 1.5, 0.7, 0.4), 1.0)
	if has_rally:
		draw_line(rally + Vector2(0, -8), rally, Color(1.6, 1.5, 0.7, 0.5), 1.0)
		draw_circle(rally + Vector2(0, -10), 2.0, Color(1.8, 1.6, 0.7, 0.4 + sin(t * 5.0) * 0.2))
	var facing: float = signf(aim.x - pos.x)
	if facing == 0.0:
		facing = 1.0
	# plague fog rolls with him — the aura made visible
	var fog_r: float = 55.0 * growth
	for i in 7:
		var a3: float = t * 0.4 + i * TAU / 7.0
		var fo := Vector2(cos(a3) * fog_r * 0.7, -6.0 + sin(t * 0.9 + i * 1.7) * 6.0 - i * 1.5)
		draw_circle(pos + fo, 12.0 + 4.0 * sin(t * 1.3 + i), Color(0.5, 0.6, 0.28, 0.09))
	draw_arc(pos + Vector2(0, -8), fog_r, 0, TAU, 42, Color(0.7, 0.8, 0.45, 0.10 + 0.04 * sin(t * 2.0)), 1.0)
	# the scythe flash
	if scythe_t > 0.0:
		var o2: Vector2 = pos + Vector2(0, -10)
		var al: float = scythe_t / 0.18
		var reach2: float = 68.0 * growth
		draw_arc(o2, reach2 * 0.85, scythe_ang - 0.95, scythe_ang + 0.95, 18, Color(1.8, 1.7, 1.2, al * 0.8), 3.0)
		draw_arc(o2, reach2 * 0.65, scythe_ang - 0.7, scythe_ang + 0.7, 14, Color(1.4, 1.4, 1.0, al * 0.4), 2.0)
	if randf() < 0.2:
		parts.append({"pos": pos + Vector2(randf_range(-30, 30), randf_range(-8, -2)), "vel": Vector2(randf_range(-4, 4), -6),
			"life": 1.4, "col": Color(0.55, 0.7, 0.3, 0.4), "size": 2.5, "fire": true, "smoke": true})
	# ============ THE PALE RIDER: a mountain of shroud, bone riding on it ============
	var g: float = 2.7 * growth
	var gait: float = absf(sin(t * 7.0)) * 2.0 if absf(vel.x) > 10.0 else sin(t * 1.6) * 0.8
	var o: Vector2 = pos + Vector2(0, -gait)
	var fx: float = facing
	var BONE := Color(0.88, 0.83, 0.66)
	var BONE2 := Color(0.97, 0.93, 0.78)
	var DK := Color(0.075, 0.06, 0.09)
	var DK2 := Color(0.12, 0.095, 0.13)
	# skeletal legs FIRST — the shroud hangs over them
	var stride: float = sin(t * 9.0) * 5.0 * g * 0.3 if absf(vel.x) > 10.0 else 0.0
	for leg in [[9.0, stride], [4.0, -stride], [-6.0, stride * 0.8], [-11.0, -stride * 0.8]]:
		var hipx: float = leg[0]
		var sw: float = leg[1]
		var hip := o + Vector2(fx * hipx * g * 0.5, -10.0 * g * 0.5)
		var knee := hip + Vector2(fx * sw * 0.5, 5.5 * g * 0.5)
		var hoof := knee + Vector2(fx * sw, 5.5 * g * 0.5)
		hoof.y = minf(hoof.y, -1.0)
		draw_line(hip, knee, BONE, 2.2)
		draw_line(knee, hoof, BONE, 1.7)
		draw_line(hoof, hoof + Vector2(fx * 2.0, 0), BONE2, 2.0)
	# THE SHROUD — one ragged black mass, horse and rider drowned in it
	var shr := PackedVector2Array()
	shr.append(o + Vector2(fx * 14.0 * g * 0.5, -8.0 * g * 0.5))            # breast
	shr.append(o + Vector2(fx * 16.0 * g * 0.5, -20.0 * g * 0.5))           # neck base
	shr.append(o + Vector2(fx * 10.0 * g * 0.5, -26.0 * g * 0.5))           # withers
	shr.append(o + Vector2(fx * 5.0 * g * 0.5, -37.0 * g * 0.5))            # rider chest
	shr.append(o + Vector2(fx * -1.0 * g * 0.5, -41.0 * g * 0.5))           # hood peak
	shr.append(o + Vector2(fx * -7.0 * g * 0.5, -37.0 * g * 0.5 + sin(t * 2.2) * 1.5))
	# the cloak billows back and shreds into the wind
	for i in 5:
		var f: float = float(i) / 4.0
		shr.append(o + Vector2(fx * (-12.0 - f * 20.0) * g * 0.5 + sin(t * 2.0 + f * 4.0) * 3.0 * (0.4 + f),
			(-30.0 + f * 22.0) * g * 0.5 + sin(t * 2.6 + f * 5.0) * 2.5))
	# ragged hem crawling back to the breast
	for i in 6:
		var f2: float = float(i) / 5.0
		shr.append(o + Vector2(fx * (-28.0 + f2 * 40.0) * g * 0.5,
			(-2.0 - fmod(sin((f2 + t * 0.13) * 31.0) * 7.0, 5.0)) * g * 0.5))
	draw_colored_polygon(shr, DK)
	# inner shroud sheen
	draw_circle(o + Vector2(fx * 2.0 * g * 0.5, -24.0 * g * 0.5), 9.0 * g * 0.5, DK2)
	draw_circle(o + Vector2(fx * -8.0 * g * 0.5, -18.0 * g * 0.5), 7.0 * g * 0.5, DK2)
	# cloak wisps tear off into the fog
	if randf() < 0.3:
		parts.append({"pos": o + Vector2(fx * randf_range(-30.0, -14.0) * g * 0.5, -randf_range(4.0, 26.0) * g * 0.5),
			"vel": Vector2(-fx * randf_range(6, 16), randf_range(-6, 2)), "life": randf_range(0.5, 1.1),
			"col": Color(0.08, 0.065, 0.1, 0.8), "size": randf_range(2.0, 3.5)})
	# HORSE SKULL — bone-white, thrust from the shroud
	var sk := o + Vector2(fx * 20.0 * g * 0.5, -24.0 * g * 0.5)
	draw_colored_polygon(PackedVector2Array([
		sk + Vector2(-fx * 4.0, -3.5 * g * 0.4), sk + Vector2(fx * 9.0 * g * 0.4, -2.0 * g * 0.4),
		sk + Vector2(fx * 12.0 * g * 0.4, 2.0 * g * 0.4), sk + Vector2(fx * 7.0 * g * 0.4, 4.5 * g * 0.4),
		sk + Vector2(-fx * 3.0, 3.0 * g * 0.4)]), BONE)
	draw_colored_polygon(PackedVector2Array([
		sk + Vector2(fx * 7.0 * g * 0.4, 4.5 * g * 0.4), sk + Vector2(fx * 11.0 * g * 0.4, 7.5 * g * 0.4),
		sk + Vector2(fx * 5.0 * g * 0.4, 6.5 * g * 0.4)]), BONE2)   # jaw
	draw_circle(sk + Vector2(fx * 5.0 * g * 0.4, -0.5), 1.6, Color(0.05, 0.02, 0.04))
	draw_circle(sk + Vector2(fx * 5.0 * g * 0.4, -0.5), 0.7, Color(1.7, 0.35, 0.25))   # ember in the socket
	for br in 2:   # bridle horns
		draw_line(sk + Vector2(-fx * 2.0, -3.0 - br * 1.5), sk + Vector2(-fx * 5.0, -6.0 - br * 2.5), BONE2, 1.2)
	# RIDER SKULL + horn crown, high on the mass
	var rs := o + Vector2(fx * -1.0 * g * 0.5, -38.5 * g * 0.5)
	draw_circle(rs, 3.2 * g * 0.4, BONE)
	draw_rect(Rect2(rs.x - 2.0, rs.y + 1.0, 4.0, 2.2), BONE2)   # teeth row
	draw_circle(rs + Vector2(fx * 1.2, -0.6), 0.9, Color(0.05, 0.02, 0.04))
	draw_circle(rs + Vector2(fx * 1.2, -0.6), 0.45, Color(1.9, 1.6, 0.6))
	for hn in [-1.0, 1.0]:
		var hb := rs + Vector2(hn * 2.6, -2.0)
		draw_line(hb, hb + Vector2(hn * 3.5, -3.5), BONE2, 1.4)
		draw_line(hb + Vector2(hn * 3.5, -3.5), hb + Vector2(hn * 4.2, -6.5), BONE2, 1.0)
	# ribs surfacing through the shroud
	for rb in 3:
		draw_arc(o + Vector2(fx * 2.0 * g * 0.5, (-32.0 + rb * 2.6) * g * 0.5), (4.0 + rb) * g * 0.35,
			PI * 0.15, PI * 0.85, 8, Color(BONE.r, BONE.g, BONE.b, 0.55 - rb * 0.12), 1.2)
	# THE SCYTHE — a pale moon over everything
	var haft_a := o + Vector2(fx * -6.0 * g * 0.5, -14.0 * g * 0.5)
	var haft_b := o + Vector2(fx * 6.0 * g * 0.5, -48.0 * g * 0.5)
	draw_line(haft_a, haft_b, Color(0.16, 0.13, 0.16), 1.8)
	draw_arc(haft_b + Vector2(fx * -6.0, 3.0), 11.0 * g * 0.45,
		(-0.5 if fx > 0 else PI - 1.4), (1.4 if fx > 0 else PI + 0.5), 14, BONE2, 2.6)
	draw_arc(haft_b + Vector2(fx * -6.0, 3.0), 9.4 * g * 0.45,
		(-0.35 if fx > 0 else PI - 1.2), (1.2 if fx > 0 else PI + 0.35), 12, Color(BONE.r, BONE.g, BONE.b, 0.5), 1.4)

func _draw_swarm() -> void:
	if pos.y > -120:
		var sa: float = clampf(1.0 + pos.y / 120.0, 0.0, 0.5)
		draw_rect(Rect2(pos.x - radius * 0.7, -1, radius * 1.4, 2), Color(0, 0, 0, sa * 0.5))
	# ============ THE SWARM: a locust colossus — head of chitin on a body of billions ============
	var facing: float = signf(aim.x - pos.x)
	if facing == 0.0:
		facing = 1.0
	# ROOT TENDRILS — streams of insects trailing to the earth like the thing has grown roots
	for tn in 4:
		var ph: float = t * 0.7 + tn * 1.7
		var bx: float = pos.x + (tn - 1.5) * radius * 0.5
		var reach_y: float = minf(-2.0, pos.y + radius * 0.4)
		var steps := 8
		var prev := Vector2(bx, pos.y + radius * 0.5)
		for s in steps:
			var f: float = float(s + 1) / steps
			var npt := Vector2(bx + sin(ph + f * 4.0) * (6.0 + f * 14.0), lerpf(pos.y + radius * 0.5, -2.0, f))
			if npt.y < reach_y:
				continue
			# the stream is dashes of insects, not a line
			var seg := (npt - prev)
			for d in 3:
				var dp := prev + seg * (d / 3.0) + Vector2(randf_range(-2, 2), randf_range(-2, 2))
				draw_line(dp, dp + Vector2(2.0, 1.0), Color(0.55, 0.1, 0.12, 0.8 - f * 0.3), 1.0)
			prev = npt
		# where the roots feed, the ground crawls
		draw_circle(Vector2(prev.x, -2.0), 4.0 + sin(t * 5.0 + tn) * 1.5, Color(0.4, 0.08, 0.1, 0.3))
	# glow halo (blooms) + dark boiling core
	draw_circle(pos, radius * 1.5, Color(0.9, 0.12, 0.18, 0.10))
	draw_circle(pos, radius * 0.9, Color(1.1, 0.15, 0.2, 0.14))
	draw_circle(pos + Vector2(0, 1), radius * 0.62, Color("#2a0614"))
	draw_circle(pos + Vector2(-3, -2), radius * 0.45, Color("#3a0a16"))
	draw_circle(pos + Vector2(3, 2), radius * 0.4, Color("#1e0510"))
	# THE HEAD — hard chitin surfacing from the cloud, watching where you point
	var hp2 := pos + Vector2(facing * radius * 0.42, -radius * 0.3 + sin(t * 2.4) * 1.5)
	var CH := Color(0.42, 0.28, 0.14)
	var CH2 := Color(0.55, 0.4, 0.2)
	var hs: float = radius * 0.4
	draw_colored_polygon(PackedVector2Array([
		hp2 + Vector2(-facing * hs * 0.9, -hs * 0.5), hp2 + Vector2(facing * hs * 0.3, -hs * 0.75),
		hp2 + Vector2(facing * hs * 1.15, -hs * 0.1), hp2 + Vector2(facing * hs * 0.9, hs * 0.5),
		hp2 + Vector2(-facing * hs * 0.3, hs * 0.65), hp2 + Vector2(-facing * hs * 1.0, hs * 0.1)]), CH)
	draw_colored_polygon(PackedVector2Array([
		hp2 + Vector2(-facing * hs * 0.6, -hs * 0.45), hp2 + Vector2(facing * hs * 0.2, -hs * 0.6),
		hp2 + Vector2(facing * hs * 0.5, -hs * 0.2), hp2 + Vector2(-facing * hs * 0.4, -hs * 0.1)]), CH2)
	# mandibles working
	var mnd: float = sin(t * 8.0) * 1.5 + 1.5
	draw_line(hp2 + Vector2(facing * hs * 1.0, hs * 0.2), hp2 + Vector2(facing * (hs * 1.3 + mnd), hs * 0.55), CH2, 1.6)
	draw_line(hp2 + Vector2(facing * hs * 0.85, hs * 0.45), hp2 + Vector2(facing * (hs * 1.15 + mnd), hs * 0.8), CH2, 1.4)
	# compound eye — amber, hungry, brightens as you feed
	var eb: float = 1.0 + (0.6 if feeding else 0.0) + hit_flash * 0.5
	draw_circle(hp2 + Vector2(facing * hs * 0.45, -hs * 0.15), hs * 0.34, Color(0.1, 0.04, 0.02))
	draw_circle(hp2 + Vector2(facing * hs * 0.45, -hs * 0.15), hs * 0.26, Color(1.6 * eb, 0.9 * eb, 0.2))
	draw_circle(hp2 + Vector2(facing * hs * 0.52, -hs * 0.2), hs * 0.1, Color(2.4, 1.8, 0.7))
	# antennae swept back
	for an in 2:
		var ab := hp2 + Vector2(-facing * hs * 0.2, -hs * (0.5 + an * 0.15))
		var prev2 := ab
		for s2 in 4:
			var f6: float = float(s2 + 1) / 4.0
			var npt2 := ab + Vector2(-facing * f6 * hs * (1.3 + an * 0.3),
				-f6 * hs * 0.5 + sin(t * 3.0 + f6 * 4.0 + an) * 2.0)
			draw_line(prev2, npt2, CH2, 1.4 - f6 * 0.8)
			prev2 = npt2
	for m in motes:
		m.a += 0.025 * m.s
		var wob: float = sin(t * 6.5 + m.o) * 3.0
		# the cloud recoils and boils outward when struck
		var scat: float = 1.0 + 0.3 * sin(t * 3.4 + m.o) + hit_flash * 0.9
		var px: float = pos.x + cos(m.a) * radius * m.d * scat + wob
		var py: float = pos.y + sin(m.a * 1.3) * radius * m.d * 1.4 * scat + cos(t * 5.2 + m.o) * 2.5
		var stx: float = -sin(m.a) * (1.5 + m.s)
		var sty: float = cos(m.a * 1.3) * 1.2
		var bright: bool = hit_flash > 0.5 or fmod(m.o + t, 5.0) < 0.35
		var mc: Color = Color(2.2, 1.4, 1.1) if bright else (Color(1.7, 0.35, 0.4) if m.d < 0.6 else Color("#701018"))
		draw_line(Vector2(px, py), Vector2(px + stx, py + sty), mc, 1.0)
		# near locusts show beating wings
		if m.d < 0.75 and m.s > 1.6:
			var wf: float = 2.0 if fmod(t * 16.0 + m.o, 2.0) < 1.0 else -1.0
			draw_line(Vector2(px, py), Vector2(px - stx * 0.4, py - wf - 1.5), Color(1.3, 0.55, 0.5, 0.7), 0.8)
			draw_line(Vector2(px + stx * 0.5, py), Vector2(px + stx * 0.9, py - wf - 1.2), Color(1.1, 0.45, 0.45, 0.5), 0.8)
