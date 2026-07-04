extends Node
# CALAMITY autoplayer — inert unless CAL_BOT is set.
# Drives every god with simple policies, clicks through captions, drafts,
# end screens and the crusade map, watches for softlocks, and writes a JSON
# report for the playtest harness.
#
# env: CAL_BOT=1            enable
#      CAL_BOT_TIME=600     total seconds before "timeout" (default 900)
#      CAL_BOT_REPORT=path  report file (default user://bot_report.json)

var active := false
var aim_world := Vector2.ZERO    # main.gd reads this through _mouse_world()

var duration := 900.0
var rpath := "user://bot_report.json"
var report := {"result": "running", "segments": []}
var t_total := 0.0
var fps_min := 9999.0
var last_prog := -1.0
var last_prog_t := 0.0
var target_x := 400.0
var retarget := 0.0
var click_cd := 0.0
var lmb_down := false
var ended_seen := false

func _ready() -> void:
	active = OS.get_environment("CAL_BOT") != ""
	if OS.get_environment("CAL_BOT_TIME") != "":
		duration = float(OS.get_environment("CAL_BOT_TIME"))
	if OS.get_environment("CAL_BOT_REPORT") != "":
		rpath = OS.get_environment("CAL_BOT_REPORT")
	set_process(active)

func _mouse(btn: int, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = btn
	ev.pressed = pressed
	ev.position = get_viewport().get_mouse_position()
	Input.parse_input_event(ev)

func _press(action: String, on: bool) -> void:
	if on:
		if not Input.is_action_pressed(action):
			Input.action_press(action)
	elif Input.is_action_pressed(action):
		Input.action_release(action)

func _find_button(node: Node) -> Button:
	if node is Button:
		return node
	for c in node.get_children():
		var b := _find_button(c)
		if b != null:
			return b
	return null

func _process(delta: float) -> void:
	t_total += delta
	if t_total > 3.0:
		fps_min = minf(fps_min, Engine.get_frames_per_second())
	if t_total > duration:
		_finish("timeout")
		return
	var sc := get_tree().current_scene
	if sc == null:
		return
	if sc.get("prol_beats") != null:
		_drive_battle(sc, delta)
	elif sc.has_method("_launch"):
		_drive_map(sc)
	else:
		# back at the menu — the crusade ended (capital won) or nothing to do
		_finish("crusade_complete" if Global.razed.size() > 0 or Global.act3_ready else "menu")

func _drive_map(map: Node) -> void:
	# overlays first: relic picks and travel events are just buttons
	if map.get("picking_relic") or map.get("in_event"):
		var btn := _find_button(map)
		if btn != null:
			btn.emit_signal("pressed")
		return
	if Engine.get_frames_drawn() % 40 != 0:
		return
	for n in map.ns:
		if map._reachable(n.id):
			if n.kind == "relicsite":
				Global.map_pos = n.id
				Global.razed.append(n.id)
				Global.save_crusade()
				map.picking_relic = true
				map._relic_overlay()
			else:
				_log("map -> %s (%s)" % [n.name, n.kind])
				map._launch(n)
			return
	_finish("map_stuck")

func _drive_battle(m: Node, delta: float) -> void:
	click_cd -= delta
	retarget -= delta
	# skip the arrival cinematic (and reset grip state — scene changes drop real input)
	if m.get("intro_t") != null and m.intro_t > 0.0:
		lmb_down = false
		_mouse(MOUSE_BUTTON_LEFT, true)
		_mouse(MOUSE_BUTTON_LEFT, false)
		return
	# prologue captions — read on
	if m.get("caption_layer") != null:
		if lmb_down:
			_mouse(MOUSE_BUTTON_LEFT, false)
			lmb_down = false
		if Engine.get_frames_drawn() % 20 == 0:
			var cb := _find_button(m.caption_layer)
			if cb != null:
				cb.emit_signal("pressed")
		return
	# evolution drafts — take the first offer (THE MOLT has no buttons)
	if m.get("draft_open"):
		if not m.draft_opts.is_empty():
			m._pick_draft(m.draft_opts[0].id)
		return
	# end screen — advance the crusade, or record the skirmish result
	if m.get("over"):
		if not ended_seen:
			ended_seen = true
			_log("end: %s | %s" % [m.hud.msg.text, m.hud.stats.text])
			report["last_end"] = str(m.hud.msg.text)
			var eb := _find_button(m)
			if eb != null:
				if lmb_down:
					_mouse(MOUSE_BUTTON_LEFT, false)
					lmb_down = false
				eb.emit_signal("pressed")
			else:
				_finish("done")
		return
	ended_seen = false
	# ---- softlock watchdog: some number must keep moving ----
	var prog: float = m._eaten_frac() * 1000.0 + m.score_f * 0.001 + float(m.prol_i) * 50.0 \
		+ float(m.people_killed) + float(m.specials_down) * 10.0 + m.essence_eaten \
		+ (100.0 - m.obj_timer if m.get("obj_started") else 0.0)
	if prog > last_prog + 0.5 or prog < last_prog - 10.0:
		# forward progress, or a scene reset (retry/next node) — both reset the clock
		last_prog = prog
		last_prog_t = t_total
	elif t_total - last_prog_t > 90.0:
		_log("SOFTLOCK: char=%s kind=%s obj=%s eaten=%d%% score=%d" % [m.character, m.node_kind,
			m.objective, int(m._eaten_frac() * 100), int(m.score_f)])
		_finish("softlock")
		return
	# ---- policy: hunt the nearest live building, drift back to it ----
	if retarget <= 0.0:
		retarget = 2.5
		var best = null
		var bd := 1e9
		for b in m.buildings:
			if not b.dead and b.dying <= 0.0 and b.topple == 0.0:
				var d: float = absf(b.x + b.w * 0.5 - m.pos.x)
				if d < bd:
					bd = d
					best = b
		target_x = (best.x + best.w * 0.5) if best != null else m.pos.x + randf_range(-200, 200)
	_press("move_left", m.pos.x > target_x + 26.0)
	_press("move_right", m.pos.x < target_x - 26.0)
	if m.character in ["drowned", "rider"]:
		_press("move_up", randf() < 0.01)
		_press("move_down", false)
	else:
		_press("move_up", m.pos.y > -70.0)
		_press("move_down", m.pos.y < -110.0)
	# aim: buildings for wreckers, minds for the drowned
	aim_world = Vector2(target_x + randf_range(-10, 10), randf_range(-50.0, -15.0))
	if m.character == "drowned":
		for u in m.units:
			if not u.get("mad", false) and not u.kind in ["carcass", "jet", "herald", "news", "brood"]:
				aim_world = u.pos + Vector2(0, -8)
				break
	# attack cadence
	if m.character == "swarm":
		if not lmb_down:
			_mouse(MOUSE_BUTTON_LEFT, true)
			lmb_down = true
	elif click_cd <= 0.0:
		click_cd = randf_range(0.5, 1.1)
		_mouse(MOUSE_BUTTON_LEFT, true)
		_mouse(MOUSE_BUTTON_LEFT, false)
	if m.meter >= 85.0 and randf() < 0.05:
		_mouse(MOUSE_BUTTON_RIGHT, true)
		_mouse(MOUSE_BUTTON_RIGHT, false)

func _log(s: String) -> void:
	report.segments.append({"t": int(t_total), "e": s})
	print("[BOT] ", s)
	_write()

func _finish(result: String) -> void:
	report.result = result
	report.time = int(t_total)
	report.fps_min = int(fps_min)
	report.act = Global.act
	report.roar = int(Global.roar)
	report.razed = Global.razed.size()
	report.grafts = Global.grafts
	report.heralds_slain = Global.heralds_slain
	_write()
	print("[BOT] finished: ", result)
	get_tree().quit()

func _write() -> void:
	var f := FileAccess.open(rpath, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(report, "  "))
