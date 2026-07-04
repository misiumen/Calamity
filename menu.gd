extends Control

const ROSTER := [
	{"id": "swarm", "name": "THE SWARM", "sub": "plague of locusts — tendrils, grabs, evolution tree",
		"col": Color("#ff4d5a")},
	{"id": "keraunos", "name": "KERAUNOS", "sub": "colossal storm hydra — banked lightning, TEMPEST barrage",
		"col": Color("#5ad0ff")},
	{"id": "tzitzimitl", "name": "TZITZIMITL", "sub": "eclipse serpent — lance dives, devour the sun",
		"col": Color("#ffb03a")},
	{"id": "drowned", "name": "THE DROWNED ONE", "sub": "leviathan puppeteer — madden minds, flood streets, call fishmen",
		"col": Color("#4ac8be")},
	{"id": "rider", "name": "THE PALE RIDER", "sub": "pestilence — your fog infects, the dead rise and march for you",
		"col": Color("#cfc48a")},
]
const CITIES := [
	{"id": "kowloon", "name": "NEW KOWLOON", "sub": "neon megacity — the baseline hunt"},
	{"id": "thornspire", "name": "THORNSPIRE", "sub": "cold gothic spires — taller, denser, hardened garrison"},
	{"id": "ashport", "name": "ASHPORT", "sub": "rusting industrial sprawl — soft walls, endless reinforcements"},
	{"id": "teotl", "name": "TEOTL RUINS", "sub": "jungle temple city — ziggurats, torchlight, old gods' ground"},
	{"id": "maren", "name": "PORT MAREN", "sub": "half-drowned harbor — warehouses, containers, standing water"},
]
const PROLOGUE := {
	"swarm": ["The drought year, the villages prayed the locusts would pass them by.",
		"Something in the cloud heard. Something in the cloud answered.",
		"It did not pass by."],
	"keraunos": ["The mountain shrines went cold. No one fed the storm its honors.",
		"High in the anvil clouds, one throat woke. Then another. Then nine.",
		"The thunder remembers every unlit candle."],
	"tzitzimitl": ["They dug the temple out of the jungle and lit it with floodlights.",
		"The seal had one purpose. The archaeologists called it decoration.",
		"On the third night, the lights began to disappear. One by one."],
	"drowned": ["The bay gave them fish for nine generations. They gave it poison.",
		"The lighthouse keeper heard singing under the waterline.",
		"He opened the sea gate. He could not say why."],
	"rider": ["When the plague came, the village burned its sick to save itself.",
		"The ash was still warm when the hoofbeats started.",
		"Nothing that burns is ever really gone."],
}

var ui_font: FontFile
var screen := "root"   # root | char_crusade | char_skirmish | city_skirmish | mutator | prologue
var picked_char := ""
var picked_city := ""

func _ready() -> void:
	Global.music("menu")
	_build()

func _mklabel(txt: String, y: float, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = Vector2(0, y)
	l.size = Vector2(640, sz + 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", ui_font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l

func _mkbtn(txt: String, y: float, cb: Callable, col: Color = Color(0.9, 0.88, 0.95)) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.position = Vector2(190, y)
	btn.size = Vector2(260, 26)
	btn.add_theme_font_override("font", ui_font)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", col)
	btn.pressed.connect(cb)
	add_child(btn)
	return btn

func _build() -> void:
	if ui_font == null:
		ui_font = load("res://art/Silkscreen-Regular.ttf")
	for c in get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.size = Vector2(640, 360)
	bg.color = Color("#0a0714")
	add_child(bg)
	var title := Label.new()
	title.text = "C A L A M I T Y"
	title.position = Vector2(0, 36)
	title.size = Vector2(640, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://art/Silkscreen-Bold.ttf"))
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.8, 0.4, 0.45))
	add_child(title)
	match screen:
		"root":
			_mklabel("you are the apocalypse.", 84, 10, Color("#9ab0d0"))
			_mkbtn("NEW CRUSADE", 130, func():
				screen = "char_crusade"
				_build(), Color(1.7, 0.5, 0.5))
			_mklabel("prologue, three acts, a continent to raze", 158, 8, Color("#8890b0"))
			if FileAccess.file_exists(Global.SAVE_PATH):
				_mkbtn("CONTINUE CRUSADE", 186, func():
					if Global.load_crusade():
						if Global.act == 1:
							Global.launch_act1()
						else:
							get_tree().change_scene_to_file("res://map.tscn"))
			_mkbtn("SKIRMISH", 242, func():
				screen = "char_skirmish"
				_build())
			_mklabel("one god, one city, no stakes", 270, 8, Color("#8890b0"))
		"char_crusade", "char_skirmish":
			_mklabel("choose your calamity   [ESC — back]", 84, 10, Color("#9ab0d0"))
			for i in ROSTER.size():
				var r: Dictionary = ROSTER[i]
				_mkbtn(r.name, 108 + i * 46, func():
					picked_char = r.id
					if screen == "char_crusade":
						screen = "prologue"
					else:
						screen = "city_skirmish"
					_build(), r.col)
				_mklabel(r.sub, 134 + i * 46, 8, Color("#8890b0"))
		"city_skirmish":
			_mklabel("now choose the city that dies tonight   [ESC — back]", 84, 10, Color("#9ab0d0"))
			for i in CITIES.size():
				var ci: Dictionary = CITIES[i]
				_mkbtn(ci.name, 108 + i * 46, func():
					picked_city = ci.id
					screen = "mutator"
					_build())
				_mklabel(ci.sub, 134 + i * 46, 8, Color("#8890b0"))
		"mutator":
			_mklabel("bend the night   [ESC — back]", 84, 10, Color("#9ab0d0"))
			var muts := [["", "NO MUTATOR", "the city as the gods found it"],
				["midnight", "MIDNIGHT", "the sun never shows — permanent night"],
				["glass", "GLASS CITY", "buildings shatter at a touch — 40% weaker"],
				["mobilization", "FULL MOBILIZATION", "the army arrives fast and keeps coming"],
				["famine", "FAMINE", "thin feeding — 25% less essence in everything"]]
			for i in muts.size():
				var mu: Array = muts[i]
				_mkbtn(mu[1], 108 + i * 44, func():
					Global.mode = "skirmish"
					Global.character = picked_char
					Global.city = picked_city
					Global.mutator = mu[0]
					get_tree().change_scene_to_file("res://main.tscn"))
				_mklabel(mu[2], 134 + i * 44, 8, Color("#8890b0"))
		"prologue":
			var lines: Array = PROLOGUE[picked_char]
			for i in lines.size():
				_mklabel(lines[i], 120 + i * 34, 10, Color(0.85, 0.8, 0.85))
			_mkbtn("LIVE IT", 260, func():
				Global.reset_crusade(picked_char)
				Global.node_params = {"kind": "prologue"}
				get_tree().change_scene_to_file("res://main.tscn"), Color(1.7, 0.5, 0.5))
			_mkbtn("SKIP TO ACT I", 296, func():
				Global.reset_crusade(picked_char)
				Global.launch_act1())

func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.physical_keycode == KEY_ESCAPE and screen != "root":
		screen = "root"
		picked_char = ""
		_build()
