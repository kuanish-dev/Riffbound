class_name StageView
extends Node2D

const BANNER_TIME := 2.6
const START_HINT := {"keys": "держи A S D F и бей J K L, когда нота у белой линии",
	"touch": "держи цифру и бей по струне, когда нота у белой линии"}
const GOLD := Color(1.0, 0.86, 0.3)
const RED := Color(1.0, 0.3, 0.35)
const PALETTE := [Color(1.0, 0.16, 0.55), Color(0.55, 0.12, 0.9), Color(0.1, 0.65, 1.0), Color(0.15, 0.95, 0.85),
	Color(1.0, 0.8, 0.2)]
const CYCLE_SPEED := 0.05
const DIM := 0.42
const STRIPES := {"step": 84.0, "width": 34.0, "skew": 130.0, "speed": 32.0}
const WAVES := 3
const SHADOWS := [{"shift": Vector2(10, 8), "tint": Color(1.0, 0.16, 0.55, 0.85)},
	{"shift": Vector2(-6, -5), "tint": Color(0.15, 0.95, 1.0, 0.65)}]
const SWAY := {"angle": 0.05, "speed": 1.7, "hop": 7.0, "punch": 0.04}
const POPUP_AT := Vector2(760, 140)

var _texts: Array[Dictionary] = []
var _banner := {}
var _strum := 9.0
var _glow := GradientTexture2D.new()


func _ready() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	_glow.gradient = gradient
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(1.0, 0.5)


func reset() -> void:
	_texts.clear()
	_banner = {"text": "Поехали!", "sub": START_HINT["touch" if Game.touch else "keys"] if Game.state == "song" else "играй что хочешь",
		"tint": Color.WHITE, "t": 0.0}


func on_fact(kind: String, data: Dictionary) -> void:
	var method := "_on_" + kind
	if has_method(method):
		call(method, data)


func on_voiced(_note: String, _string: String, _corrected: bool) -> void:
	_strum = 0.0


static func pose() -> Dictionary:
	var base: Dictionary = Layout.GUITAR_POSES.get(Game.state, Layout.GUITAR_POSES["*"])
	var t := Time.get_ticks_msec() / 1000.0
	var heat := 1.0 + heat() * 2.0
	var pulse := beat_pulse()
	return {"at": (base["at"] as Vector2) + Vector2(0, -float(SWAY["hop"]) * pulse * heat),
		"angle": float(base["angle"]) + float(SWAY["angle"]) * sin(t * float(SWAY["speed"])) * heat - float(SWAY["punch"]) * pulse,
		"size": float(base["size"]) * (1.0 + 0.03 * pulse)}


static func neck_tip() -> Vector2:
	var p := pose()
	return (p["at"] as Vector2) + Vector2(GuitarArt.HEAD_TIP, 0).rotated(float(p["angle"])) * float(p["size"])


static func beat_pulse() -> float:
	if Game.conductor == null or not Game.conductor.running:
		return 0.0
	var beat := Game.conductor.beat_f()
	var strength := 1.0 if posmod(floori(beat), Timing.BEATS_PER_BAR) == 0 else 0.55
	return exp(-(beat - floorf(beat)) * 5.0) * strength


static func heat() -> float:
	return Game.style.heat() if Game.state == "song" and Game.style != null and Game.style.visible() else 0.0


func _process(delta: float) -> void:
	_strum += delta
	var alive: Array[Dictionary] = []
	for item in _texts:
		item["t"] = float(item["t"]) + delta
		if float(item["t"]) < float(item["dur"]):
			alive.append(item)
	_texts = alive
	if not _banner.is_empty():
		_banner["t"] = float(_banner["t"]) + delta
	queue_redraw()


func _on_hit(data: Dictionary) -> void:
	var judgement: Dictionary = data["judgement"]
	_popup(String(judgement["label"]), Vector2(0, 0), judgement["tint"], 24, 0.5)


func _on_miss(_data: Dictionary) -> void:
	_popup(String(Timing.MISS["label"]), Vector2(0, 0), RED, 24, 0.6)


func _on_wrong(_data: Dictionary) -> void:
	_popup("Не та нота", Vector2(0, 0), RED, 24, 0.6)


func _on_tech(data: Dictionary) -> void:
	_popup(String(data["label"]), Vector2(0, 50), GOLD, 30, 0.8)


func _on_finish(data: Dictionary) -> void:
	_banner = {"text": "Конец песни", "sub": "%d%% нот" % roundi(float(data["accuracy"]) * 100.0), "tint": GOLD, "t": 0.0}


func _popup(text: String, offset: Vector2, tint: Color, size: int, dur: float) -> void:
	_texts.append({"text": text, "pos": POPUP_AT + offset + Vector2(randf_range(-30, 30), 0), "tint": tint, "t": 0.0, "dur": dur, "size": size,
		"tilt": randf_range(-0.12, 0.12)})


func _draw() -> void:
	_draw_backdrop()
	_draw_guitar()
	for item in _texts:
		var k := float(item["t"]) / float(item["dur"])
		var pos: Vector2 = item["pos"] + Vector2(0, -26.0 * k)
		Glyph.neon(self, pos, String(item["text"]), int(item["size"]), Color(item["tint"] as Color, 1.0 - k * k),
			float(item["tilt"]), 1.0 + 0.25 * (1.0 - k) * (1.0 - k))
	if Game.state in ["song", "jam"]:
		_draw_banner()
	_draw_count_in()


static func _cycle(phase: float) -> Color:
	var x := fposmod(phase, 1.0) * PALETTE.size()
	var i := floori(x)
	return (PALETTE[i] as Color).lerp(PALETTE[(i + 1) % PALETTE.size()], x - i)


func _draw_backdrop() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var pulse := beat_pulse() * (1.0 + heat())
	_draw_gradient(t, pulse)
	_draw_stripes(t, pulse)
	for k in WAVES:
		_draw_wave(k, t, pulse)
	var floor_y := Layout.STAGE.end.y
	draw_line(Vector2(0, floor_y), Vector2(Layout.SCREEN.x, floor_y), Color(_cycle(t * CYCLE_SPEED + 0.7), 0.9), 3.0)


func _draw_gradient(t: float, pulse: float) -> void:
	var shade := DIM + 0.18 * pulse
	var top := _cycle(t * CYCLE_SPEED) * shade
	var bottom := _cycle(t * CYCLE_SPEED + 0.3) * (shade + 0.1)
	top.a = 1.0
	bottom.a = 1.0
	var area := PackedVector2Array([Vector2(0, Layout.TOP_H), Vector2(Layout.SCREEN.x, Layout.TOP_H),
		Vector2(Layout.SCREEN.x, Layout.STAGE.end.y), Vector2(0, Layout.STAGE.end.y)])
	draw_polygon(area, PackedColorArray([top, top, bottom, bottom]))


func _draw_stripes(t: float, pulse: float) -> void:
	var stripe := Color(_cycle(t * CYCLE_SPEED + 0.55), 0.08 + 0.1 * pulse)
	var step := float(STRIPES["step"])
	var width := float(STRIPES["width"])
	var skew := float(STRIPES["skew"])
	var shift := fposmod(t * float(STRIPES["speed"]), step)
	var top := Layout.TOP_H
	var bottom := Layout.STAGE.end.y
	for k in range(-2, ceili(Layout.SCREEN.x / step) + 3):
		var x := k * step + shift
		draw_colored_polygon(PackedVector2Array([Vector2(x, top), Vector2(x + width, top), Vector2(x + width - skew, bottom),
			Vector2(x - skew, bottom)]), stripe)


func _draw_wave(k: int, t: float, pulse: float) -> void:
	var points := PackedVector2Array()
	var base := Layout.STAGE.end.y - 14 - k * 13
	var x := 0.0
	while x <= Layout.SCREEN.x:
		points.append(Vector2(x, base + sin(x * 0.011 + t * (1.4 + k * 0.5)) * (5.0 + 6.0 * pulse)))
		x += 16.0
	draw_polyline(points, Color(_cycle(t * CYCLE_SPEED + 0.2 * k + 0.4), 0.45 + 0.3 * pulse), 3.0, true)


func _draw_guitar() -> void:
	var skin: Dictionary = Shop.SKINS[Game.shop_index] if Game.state == "shop" else Shop.current()
	var p := pose()
	var at: Vector2 = p["at"]
	var angle := float(p["angle"])
	var size := float(p["size"])
	var pulse := beat_pulse()
	var spot := Vector2(560, 300) * size * (1.0 + 0.1 * pulse)
	var center := at + Vector2(80, 0).rotated(angle) * size
	draw_texture_rect(_glow, Rect2(center - spot * 0.5, spot), false,
		Color(_cycle(Time.get_ticks_msec() / 1000.0 * CYCLE_SPEED + 0.1), 0.35 + 0.3 * pulse))
	for shadow: Dictionary in SHADOWS:
		GuitarArt.silhouette(self, skin, at + (shadow["shift"] as Vector2) * size, angle, size, shadow["tint"])
	GuitarArt.draw(self, skin, at, angle, size, clampf(1.0 - _strum / 0.18, 0.0, 1.0))


func _draw_banner() -> void:
	if _banner.is_empty() or float(_banner["t"]) > BANNER_TIME:
		return
	var t := float(_banner["t"])
	var alpha := clampf(minf(t / 0.15, (BANNER_TIME - t) / 0.4), 0.0, 1.0)
	Glyph.neon(self, Vector2(760, 132), String(_banner["text"]), 52, Color(_banner["tint"] as Color, alpha), sin(t * 4.0) * 0.06,
		1.0 + 0.4 * maxf(0.0, 1.0 - t * 5.0))
	Glyph.text_center(self, 760, 186, String(_banner["sub"]), 18, Color(1, 1, 1, 0.85 * alpha))


func _draw_count_in() -> void:
	if Game.state != "song":
		return
	var beats_left := (Songs.LEAD_IN * Timing.SLOTS_PER_BAR - Game.conductor.slot_f()) / Timing.SLOTS_PER_BEAT
	if beats_left <= 0.0 or beats_left > Timing.BEATS_PER_BAR:
		return
	var count := ceili(beats_left)
	var pop := 1.0 - (float(count) - beats_left)
	Glyph.neon(self, Vector2(760, 200), str(count), 56, Color(1, 1, 1, 0.95), (count % 2 * 2 - 1) * 0.08, 0.8 + 0.5 * (1.0 - pop))
