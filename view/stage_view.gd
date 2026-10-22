class_name StageView
extends Node2D
## Сцена: музыкант с гитарой и усилком под светом прожекторов, всё качается в долю.
## Проигрывает факты песни (_on_<факт>): оценку ноты, технику, «не ту ноту», конец песни.
## Огоньки усилка — множитель серии.

const BANNER_TIME := 1.8
const GOLD := Color(1.0, 0.82, 0.3)
const RED := Color(1.0, 0.38, 0.35)
const BODY := Color(0.17, 0.15, 0.24)
const WOOD := Color(0.5, 0.17, 0.14)
const LIGHT := Color(1.0, 0.86, 0.55)
const SWING := {"low": 1.0, "mid": 0.3, "high": -1.0}   ## куда идёт рука при ударе по струне

var _bits: Array[Dictionary] = []      ## искры: {pos, vel, tint, t, dur, size}
var _texts: Array[Dictionary] = []     ## всплывающие надписи: {text, pos, tint, t, dur, size}
var _banner := {}                      ## {text, sub, tint, t}
var _strum := {"t": 9.0, "string": "low"}


func reset() -> void:
	_bits.clear()
	_texts.clear()
	_banner = {"text": "Поехали!", "sub": String(Game.performance.song.get("name", "")) if Game.state == "song" else "джем",
		"tint": Color.WHITE, "t": 0.0}


func on_fact(kind: String, data: Dictionary) -> void:
	var method := "_on_" + kind
	if has_method(method):
		call(method, data)


func on_voiced(_note: String, string: String, _corrected: bool) -> void:
	_strum = {"t": 0.0, "string": string}


func _process(delta: float) -> void:
	_strum["t"] = float(_strum["t"]) + delta
	for list: Array[Dictionary] in [_bits, _texts]:
		var alive: Array[Dictionary] = []
		for item in list:
			item["t"] = float(item["t"]) + delta
			if float(item["t"]) < float(item["dur"]):
				alive.append(item)
		list.assign(alive)
	for bit in _bits:
		bit["pos"] = (bit["pos"] as Vector2) + (bit["vel"] as Vector2) * delta
		bit["vel"] = (bit["vel"] as Vector2) * 0.92 + Vector2(0, 260) * delta
	if not _banner.is_empty():
		_banner["t"] = float(_banner["t"]) + delta
	queue_redraw()


# --- факты песни ------------------------------------------------------------

func _on_hit(data: Dictionary) -> void:
	var judgement: Dictionary = data["judgement"]
	_popup(String(judgement["label"]), Layout.NECK_TIP + Vector2(-40, -48), judgement["tint"], 18, 0.5)
	_sparks(Layout.NECK_TIP, LIGHT, 8)


func _on_miss(_data: Dictionary) -> void:
	_popup(String(Timing.MISS["label"]), Layout.NECK_TIP + Vector2(-40, -48), RED, 18, 0.6)


func _on_wrong(_data: Dictionary) -> void:
	_popup("Не та нота", Layout.NECK_TIP + Vector2(-40, -48), RED, 18, 0.6)


func _on_tech(data: Dictionary) -> void:
	_popup(String(data["label"]), Layout.NECK_TIP + Vector2(90, -20), GOLD, 22, 0.8)
	_sparks(Layout.NECK_TIP, GOLD, 16)


func _on_finish(data: Dictionary) -> void:
	_banner = {"text": "Конец песни", "sub": "%d%% нот" % roundi(float(data["accuracy"]) * 100.0), "tint": GOLD, "t": 0.0}


func _popup(text: String, pos: Vector2, tint: Color, size: int, dur: float) -> void:
	_texts.append({"text": text, "pos": pos, "tint": tint, "t": 0.0, "dur": dur, "size": size})


func _sparks(pos: Vector2, tint: Color, count: int) -> void:
	for i in count:
		var dir := Vector2.from_angle(randf_range(-PI * 0.9, -PI * 0.1))
		_bits.append({"pos": pos, "vel": dir * randf_range(120, 300), "tint": tint, "t": 0.0,
			"dur": randf_range(0.3, 0.6), "size": randf_range(2.0, 4.0)})


# --- рисование --------------------------------------------------------------

func _draw() -> void:
	_draw_backdrop()
	_draw_amp()
	_draw_musician()
	for bit in _bits:
		var fade := 1.0 - float(bit["t"]) / float(bit["dur"])
		draw_circle(bit["pos"], float(bit["size"]) * fade, Color(bit["tint"] as Color, fade), true, -1.0, true)
	for item in _texts:
		var k := float(item["t"]) / float(item["dur"])
		var pos: Vector2 = item["pos"] + Vector2(0, -22.0 * k)
		Glyph.text_center(self, pos.x, pos.y, String(item["text"]), int(item["size"]), Color(item["tint"] as Color, 1.0 - k * k))
	if Game.state in ["song", "jam"]:
		_draw_banner()
	_draw_count_in()


## Пульс на каждую долю, сильнее — на первую долю такта.
func _pulse() -> float:
	if not Game.conductor.running:
		return 0.0
	var beat := Game.conductor.beat_f()
	var strength := 1.0 if posmod(floori(beat), Timing.BEATS_PER_BAR) == 0 else 0.55
	return exp(-(beat - floorf(beat)) * 5.0) * strength


func _draw_backdrop() -> void:
	var pulse := _pulse()
	for x: float in [260.0, 640.0, 1020.0]:
		var cone := PackedVector2Array([Vector2(x - 14, Layout.TOP_H), Vector2(x + 14, Layout.TOP_H),
			Vector2(x + 130, Layout.FLOOR_Y), Vector2(x - 130, Layout.FLOOR_Y)])
		draw_colored_polygon(cone, Color(1.0, 0.85, 0.65, 0.035 + 0.06 * pulse))
	draw_rect(Rect2(0, Layout.FLOOR_Y, Layout.SCREEN.x, Layout.STAGE.end.y - Layout.FLOOR_Y), Color(0.1, 0.08, 0.14))
	draw_line(Vector2(0, Layout.FLOOR_Y), Vector2(Layout.SCREEN.x, Layout.FLOOR_Y), Color(0.55, 0.45, 0.9, 0.35 + 0.5 * pulse), 2.0)


func _draw_amp() -> void:
	var r := Layout.AMP
	draw_rect(r, Color(0.13, 0.11, 0.16))
	draw_rect(r, Color(0.35, 0.3, 0.42), false, 2.0)
	draw_circle(r.get_center() + Vector2(0, 12), 24, Color(0.07, 0.06, 0.09), true, -1.0, true)
	draw_circle(r.get_center() + Vector2(0, 12), 24 + 4.0 * _pulse(), Color(0.3, 0.27, 0.36), false, 2.0, true)
	var lit := Game.performance.multiplier() if Game.state == "song" else 0
	for i in SongJudge.MULT_MAX:
		var led := Vector2(r.position.x + 16 + i * 16, r.position.y + 12)
		draw_circle(led, 4.5, GOLD if i < lit else Color(0.25, 0.2, 0.18), true, -1.0, true)


func _draw_musician() -> void:
	var base := Layout.MUSICIAN
	var bob := 3.0 * _pulse()
	var hip := base + Vector2(2, -58 + bob)
	var neck := base + Vector2(-2, -130 + bob)
	draw_line(hip, base + Vector2(-16, 0), BODY, 9.0, true)
	draw_line(hip, base + Vector2(20, 0), BODY, 9.0, true)
	draw_line(hip, neck, BODY, 20.0, true)
	draw_circle(neck + Vector2(-2, -20), 17, BODY, true, -1.0, true)
	draw_arc(neck + Vector2(-2, -20), 17, -2.6, 0.3, 12, Color(0.6, 0.5, 0.9, 0.6), 2.0, true)
	# гитара: корпус вспыхивает светом при ударе
	var glow := clampf(1.0 - float(_strum["t"]) / 0.18, 0.0, 1.0)
	var wood := WOOD.lerp(LIGHT, glow * 0.6)
	var body := hip + Vector2(10, -6)
	draw_circle(body, 25, wood, true, -1.0, true)
	draw_circle(body + Vector2(18, -12), 19, wood, true, -1.0, true)
	draw_circle(body + Vector2(10, -6), 7, Color(0.08, 0.06, 0.08), true, -1.0, true)
	var tip := Layout.NECK_TIP + Vector2(0, bob)
	draw_line(body + Vector2(26, -16), tip, Color(0.35, 0.24, 0.16), 7.0, true)
	draw_line(tip, tip + Vector2(14, -6), Color(0.2, 0.15, 0.12), 10.0, true)
	if glow > 0.0:
		draw_circle(tip, 10.0 + 10.0 * glow, Color(LIGHT, 0.4 * glow), true, -1.0, true)
	# руки: левая на грифе, правая бьёт по нижней струне вниз, по верхней — вверх
	var shoulder := neck + Vector2(0, 8)
	var fret_hand := body.lerp(tip, 0.72) + Vector2(0, 2)
	var swing := float(SWING.get(_strum["string"], 0.0)) * 9.0 * glow
	var strum_hand := body + Vector2(6, -2 + swing)
	draw_line(shoulder, fret_hand, BODY.lightened(0.15), 6.0, true)
	draw_line(shoulder, strum_hand, BODY.lightened(0.15), 6.0, true)
	draw_circle(fret_hand, 5, Color(0.85, 0.7, 0.6), true, -1.0, true)
	draw_circle(strum_hand, 5, Color(0.85, 0.7, 0.6), true, -1.0, true)


func _draw_banner() -> void:
	if _banner.is_empty() or float(_banner["t"]) > BANNER_TIME:
		return
	var t := float(_banner["t"])
	var alpha := clampf(minf(t / 0.15, (BANNER_TIME - t) / 0.4), 0.0, 1.0)
	Glyph.text_center(self, 640, 150, String(_banner["text"]), 42, Color(_banner["tint"] as Color, alpha))
	Glyph.text_center(self, 640, 182, String(_banner["sub"]), 18, Color(1, 1, 1, 0.75 * alpha))


## Отсчёт перед первым тактом песни: 4 3 2 1.
func _draw_count_in() -> void:
	if Game.state != "song":
		return
	var beats_left := (Songs.LEAD_IN * Timing.SLOTS_PER_BAR - Game.conductor.slot_f()) / Timing.SLOTS_PER_BEAT
	if beats_left <= 0.0 or beats_left > Timing.BEATS_PER_BAR:
		return
	var count := ceili(beats_left)
	var pop := 1.0 - (float(count) - beats_left)
	Glyph.text_center(self, 640, 220, str(count), int(40 + 16 * pop), Color(1, 1, 1, 0.9))
