extends Node
# menu -> game handoff + crusade campaign state

var character := "swarm"
var city := "kowloon"
var mode := "skirmish"           # "skirmish" | "crusade"

# --- crusade state (persists across nodes; saved to disk) ---
var act := 1
var node_i := 0                  # act 1 chain position
var map_pos := 0                 # act 2: current map node id
var razed: Array = []            # act 2: razed map node ids
var tribute := 0
var relics: Array = []
var c_branch := ""
var c_nodes := {}
var c_bio_stage := 0
var c_essence := 0.0
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
			"objective": OS.get_environment("CAL_OBJ") if OS.get_environment("CAL_OBJ") != "" else "raze"}

func reset_crusade(chr: String) -> void:
	character = chr
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
	save_crusade()

func launch_act1() -> void:
	mode = "crusade"
	var cities := ["kowloon", "thornspire", "ashport", "teotl", "maren"]
	city = cities[randi() % cities.size()]
	match node_i:
		0: node_params = {"kind": "hamlet", "world_w": 1900.0, "tier_cap": 1, "objective": "raze"}
		1: node_params = {"kind": "town", "world_w": 2900.0, "tier_cap": 3, "objective": "raze"}
		_: node_params = {"kind": "city", "world_w": 4600.0, "tier_cap": 5, "objective": "raze"}
	get_tree().change_scene_to_file("res://main.tscn")

func save_crusade() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"character": character, "act": act, "node_i": node_i,
			"map_pos": map_pos, "razed": razed, "tribute": tribute, "relics": relics,
			"c_branch": c_branch, "c_nodes": c_nodes, "c_bio_stage": c_bio_stage, "c_essence": c_essence}))

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
	mode = "crusade"
	return true
