extends Control

const ROSTER := [
	{"id": "swarm", "name": "THE SWARM", "sub": "plague of locusts — tendrils, grabs, evolution tree",
		"col": Color("#ff4d5a")},
	{"id": "keraunos", "name": "KERAUNOS", "sub": "storm hydra — banked lightning strikes, TEMPEST barrage",
		"col": Color("#5ad0ff")},
	{"id": "tzitzimitl", "name": "TZITZIMITL", "sub": "eclipse serpent — lance dives, blot out the sun",
		"col": Color("#ffb03a")},
]

func _ready() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(640, 360)
	bg.color = Color("#0a0714")
	add_child(bg)
	var title := Label.new()
	title.text = "C A L A M I T Y"
	title.position = Vector2(0, 48)
	title.size = Vector2(640, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.8, 0.4, 0.45))
	add_child(title)
	var sub := Label.new()
	sub.text = "you are the apocalypse.  choose which."
	sub.position = Vector2(0, 92)
	sub.size = Vector2(640, 20)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Color("#9ab0d0"))
	add_child(sub)
	for i in ROSTER.size():
		var c: Dictionary = ROSTER[i]
		var btn := Button.new()
		btn.text = c.name
		btn.position = Vector2(190, 140 + i * 58)
		btn.size = Vector2(260, 28)
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", c.col)
		btn.pressed.connect(_pick.bind(c.id))
		add_child(btn)
		var d := Label.new()
		d.text = c.sub
		d.position = Vector2(0, 169 + i * 58)
		d.size = Vector2(640, 16)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.add_theme_font_size_override("font_size", 8)
		d.add_theme_color_override("font_color", Color("#8890b0"))
		add_child(d)

func _pick(id: String) -> void:
	Global.character = id
	get_tree().change_scene_to_file("res://main.tscn")
