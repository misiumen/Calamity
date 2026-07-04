extends Node
# menu -> game handoff + crusade campaign state

var character := "swarm"
var city := "kowloon"
var mode := "skirmish"           # "skirmish" | "crusade"
var mutator := ""                # skirmish modifier: midnight | glass | mobilization | famine

# --- crusade state (persists across nodes; saved to disk) ---
var act := 1
var node_i := 0                  # legacy act-1 counter (growth ramp uses razed now)
var province := "kowloon"        # act 1 happens in ONE city's region
var headline := ""               # last front page, shown on the map
var map_pos := 0                 # act 2: current map node id
var razed: Array = []            # act 2: razed map node ids
var tribute := 0
var relics: Array = []
var c_branch := ""
var c_nodes := {}
var c_bio_stage := 0
var c_essence := 0.0
var node_fates := {}             # act 2: node_id -> fate tag, rolled once per crusade
var bypassed: Array = []         # fork roads not taken — closed forever
var alert_discount := 0          # quiet roads earned — lowers effective World Alert
# --- THE ROAR: how loudly you have fed; the void hears round numbers ---
var roar := 0.0
var herald_queue: Array = []     # 3 of 10, rolled per crusade
var heralds_slain: Array = []
var grafts: Array = []           # stolen powers, kept forever
var act3_ready := false
const ROAR_GATES := [1500.0, 3200.0, 5200.0]
# params handed to the next run
var node_params := {}

const SAVE_PATH := "user://crusade.save"

func _ready() -> void:
	if OS.get_environment("CAL_CHAR") != "":
		character = OS.get_environment("CAL_CHAR")
	if OS.get_environment("CAL_CITY") != "":
		city = OS.get_environment("CAL_CITY")
	if OS.get_environment("CAL_KIND") != "":
		mode = "crusade"
		node_params = {"kind": OS.get_environment("CAL_KIND"), "world_w": 2200.0, "tier_cap": 3,
			"militia": OS.get_environment("CAL_MILITIA") != "",
			"objective": OS.get_environment("CAL_OBJ") if OS.get_environment("CAL_OBJ") != "" else "raze"}

# ============ music: threat-layered synth stems, alive across scenes ============
var mus: Array = []                                   # base pad / percussion / dread / panic
var mus_target := [-60.0, -60.0, -60.0, -60.0]

func _process(delta: float) -> void:
	for i in mus.size():
		mus[i].volume_db = lerpf(mus[i].volume_db, mus_target[i], 1.5 * delta)

func music(mode_s: String, tier: int = 0) -> void:
	_mus_init()
	match mode_s:
		"menu":
			mus[0].pitch_scale = 0.8
			mus_target = [-16.0, -60.0, -60.0, -60.0]
		"map":
			mus[0].pitch_scale = 0.9
			mus_target = [-14.0, -26.0, -60.0, -60.0]
		"battle":
			mus[0].pitch_scale = 1.0
			mus_target = [-13.0, (-15.0 if tier >= 2 else -60.0), (-15.0 if tier >= 4 else -60.0), -60.0]
		"doom":
			mus_target = [-13.0, -60.0, -13.0, -10.0]

func _mus_init() -> void:
	if not mus.is_empty():
		return
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.volume_db = -60.0
		add_child(p)
		mus.append(p)
	mus[0].stream = _mloop_pad([55.0, 82.5, 110.0], 6.0, 0.0)      # dark root-fifth-octave pad
	mus[1].stream = _mloop_perc(2.0, 0.5)                          # war drums
	mus[2].stream = _mloop_pad([220.0, 233.0, 311.0], 4.0, 0.12)   # dissonant dread shimmer
	mus[3].stream = _mloop_perc(2.0, 0.25)                         # double-time panic
	for p in mus:
		p.play()

func _mloop_pad(freqs: Array, dur: float, noise_amt: float) -> AudioStreamWAV:
	# freqs*dur must be integers so the loop seam is silent
	var rate := 22050
	var n := int(dur * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var ts: float = float(i) / rate
		var s := 0.0
		for fi in freqs.size():
			var lfo: float = 0.55 + 0.45 * sin(TAU * ts / dur * float(fi + 1))
			s += sin(TAU * float(freqs[fi]) * ts) * lfo / freqs.size()
		if noise_amt > 0.0:
			s += (randf() * 2.0 - 1.0) * noise_amt
		var v := int(clampf(s * 0.8, -1.0, 1.0) * 26000.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	return _mwav(data, rate, n)

func _mloop_perc(dur: float, beat: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var ts: float = float(i) / rate
		var kp: float = fmod(ts, beat * 2.0)
		var s: float = sin(TAU * 58.0 * kp) * exp(-kp * 9.0) * 0.9
		var tp: float = fmod(ts + beat * 0.5, beat)
		s += (randf() * 2.0 - 1.0) * exp(-tp * 60.0) * 0.35
		var v := int(clampf(s, -1.0, 1.0) * 26000.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	return _mwav(data, rate, n)

func _mwav(data: PackedByteArray, rate: int, n: int) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = n
	return wav

const PROVINCE_OF := {"swarm": "ashport", "keraunos": "thornspire", "tzitzimitl": "teotl",
	"drowned": "maren", "rider": "kowloon"}

func reset_crusade(chr: String) -> void:
	character = chr
	province = PROVINCE_OF.get(chr, "kowloon")
	headline = ""
	mode = "crusade"
	act = 1
	node_i = 0
	map_pos = 0
	razed = []
	tribute = 0
	relics = []
	c_branch = ""
	c_nodes = {}
	c_bio_stage = 0
	c_essence = 0.0
	node_fates = {}
	bypassed = []
	alert_discount = 0
	roar = 0.0
	heralds_slain = []
	grafts = []
	act3_ready = false
	var hpool := ["grazer", "stalker", "hollowking", "gatecrash", "echo",
		"seraph", "tide", "rustsaint", "veil", "firstborn"]
	hpool.shuffle()
	herald_queue = hpool.slice(0, 3)
	save_crusade()

func launch_act1() -> void:
	# act 1 lives on its own Rise map now
	mode = "crusade"
	act = 1
	get_tree().change_scene_to_file("res://map.tscn")

func save_crusade() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"character": character, "act": act, "node_i": node_i,
			"map_pos": map_pos, "razed": razed, "tribute": tribute, "relics": relics,
			"c_branch": c_branch, "c_nodes": c_nodes, "c_bio_stage": c_bio_stage, "c_essence": c_essence,
			"node_fates": node_fates, "alert_discount": alert_discount, "province": province, "bypassed": bypassed,
			"roar": roar, "herald_queue": herald_queue, "heralds_slain": heralds_slain,
			"grafts": grafts, "act3_ready": act3_ready}))

func load_crusade() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if d == null:
		return false
	character = d.get("character", "swarm")
	act = int(d.get("act", 1))
	node_i = int(d.get("node_i", 0))
	map_pos = int(d.get("map_pos", 0))
	razed = d.get("razed", [])
	tribute = int(d.get("tribute", 0))
	relics = d.get("relics", [])
	c_branch = d.get("c_branch", "")
	c_nodes = d.get("c_nodes", {})
	c_bio_stage = int(d.get("c_bio_stage", 0))
	c_essence = float(d.get("c_essence", 0.0))
	node_fates = d.get("node_fates", {})
	bypassed = d.get("bypassed", [])
	province = d.get("province", PROVINCE_OF.get(character, "kowloon"))
	alert_discount = int(d.get("alert_discount", 0))
	roar = float(d.get("roar", 0.0))
	herald_queue = d.get("herald_queue", [])
	heralds_slain = d.get("heralds_slain", [])
	grafts = d.get("grafts", [])
	act3_ready = d.get("act3_ready", false)
	mode = "crusade"
	return true
