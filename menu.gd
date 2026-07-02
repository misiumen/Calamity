extends Control

const ROSTER := [
	{"id": "swarm", "name": "THE SWARM", "sub": "plague of locusts — tendrils, grabs, evolution tree",
		"col": Color("#ff4d5a")},
	{"id": "keraunos", "name": "KERAUNOS", "sub": "colossal storm hydra — banked lightning, TEMPEST barrage",
		"col": Color("#5ad0ff")},
	{"id": "tzitzimitl", "name": "TZITZIMITL", "sub": "eclipse serpent — lance dives, blot out the sun",
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

var picked_char := ""

func _ready() -> void:
	_build()

func _build() -> void:
	for c in get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.size = Vector2(640, 360)
	bg.color = Color("#0a0714")
	add_child(bg)
	var title := Label.new()
	title.text = "C A L A M I T Y"
	title.position = Vector2(0, 40)
	title.size = Vector2(640, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.8, 0.4, 0.45))
	add_child(title)
	var sub := Label.new()
	sub.position = Vector2(0, 86)
	sub.size = Vector2(640, 20)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Color("#9ab0d0"))
	add_child(sub)
	if picked_char == "":
		sub.text = "you are the apocalypse.  choose which."
		_rows(ROSTER, func(id): picked_char = id; _build())
	else:
		var cname: String = ROSTER.filter(func(r): return r.id == picked_char)[0].name
		sub.text = cname + "  —  now choose the city that dies tonight.   [ESC — back]"
		_rows(CITIES, func(id):
			Global.character = picked_char
			Global.city = id
			get_tree().change_scene_to_file("res://main.tscn"))

func _rows(defs: Array, on_pick: Callable) -> void:
	for i in defs.size():
		var d: Dictionary = defs[i]
		var btn := Button.new()
		btn.text = d.name
		btn.position = Vector2(190, 116 + i * 46)
		btn.size = Vector2(260, 26)
		btn.add_theme_font_size_override("font_size", 13)
		if d.has("col"):
			btn.add_theme_color_override("font_color", d.col)
		btn.pressed.connect(func(): on_pick.call(d.id))
		add_child(btn)
		var l := Label.new()
		l.text = d.sub
		l.position = Vector2(0, 143 + i * 46)
		l.size = Vector2(640, 14)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 8)
		l.add_theme_color_override("font_color", Color("#8890b0"))
		add_child(l)

func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.physical_keycode == KEY_ESCAPE and picked_char != "":
		picked_char = ""
		_build()
