class_name FxLayer
extends Node2D
## Свет поверх картинки — смешивание сложением, текстуры Kenney Particle Pack (CC0, см. CREDITS.md).
## Два слоя: «stage» — под интерфейсом (лучи прожекторов и пятна света в долю, искры у грифа),
## «top» — над дорожкой (вспышка на линии удара, ореол у подходящих нот). Слой рисует _draw_<слой>.
## Проигрывает удары по струнам (on_voiced) и факты песни (_on_<факт>).

const TEX := {
	"flash": preload("res://assets/fx/flare_01.png"),
	"glow": preload("res://assets/fx/circle_05.png"),
	"star": preload("res://assets/fx/star_05.png"),
	"bolt": preload("res://assets/fx/spark_04.png"),
	"ring": preload("res://assets/fx/light_03.png"),
	"smoke": preload("res://assets/fx/smoke_03.png"),
}
const SPOTS := [
	{"x": 260.0, "tint": Color(1.0, 0.75, 0.45)},
	{"x": 640.0, "tint": Color(0.6, 0.55, 1.0)},
	{"x": 1020.0, "tint": Color(1.0, 0.45, 0.6)},
]
const GLOW_SLOTS := 3.0                ## за сколько восьмых до линии удара нота начинает светиться

var layer := "top"
var _items: Array[Dictionary] = []     ## вспышки и искры: {tex, pos, vel, size, grow, tint, t, dur, spin}


func _init(which := "top") -> void:
	layer = which


func _ready() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive


func on_voiced(_note: String, string: String, corrected: bool) -> void:
	if corrected or layer != "top" or not Game.state in ["song", "jam"]:
		return
	var at := Vector2(Layout.HIT_X, Hud.lane_y(string))
	_spawn("flash", at, Vector2.ZERO, 150.0, 60.0, Color(1.0, 0.9, 0.7, 0.9), 0.22)
	_spawn("ring", at, Vector2.ZERO, 30.0, 180.0, Color(0.6, 0.7, 1.0, 0.5), 0.3)


func on_fact(kind: String, data: Dictionary) -> void:
	var method := "_on_" + kind
	if has_method(method):
		call(method, data)


func _on_hit(data: Dictionary) -> void:
	var tint: Color = data["judgement"]["tint"]
	if layer == "top":
		var at := Vector2(Layout.HIT_X, Hud.lane_y(String(data["note"]["string"])))
		_spawn("glow", at, Vector2.ZERO, 50.0, 90.0, Color(tint, 0.8), 0.25)
	else:
		_burst(Layout.NECK_TIP, tint, 7)


func _on_tech(_data: Dictionary) -> void:
	if layer == "stage":
		_spawn("bolt", Layout.NECK_TIP + Vector2(30, -10), Vector2.ZERO, 120.0, 40.0, Color(0.7, 0.8, 1.0, 0.9), 0.35)
		_burst(Layout.NECK_TIP, Color(1.0, 0.82, 0.3), 14)


func _on_miss(data: Dictionary) -> void:
	if layer == "top":
		var at := Vector2(Layout.HIT_X, Hud.lane_y(String(data["note"]["string"])))
		_spawn("ring", at, Vector2.ZERO, 40.0, -30.0, Color(1.0, 0.25, 0.2, 0.45), 0.25)


func _burst(at: Vector2, tint: Color, count: int) -> void:
	for i in count:
		var dir := Vector2.from_angle(randf_range(-PI * 0.95, -PI * 0.05))
		_spawn("star", at, dir * randf_range(140, 340), randf_range(14, 26), -10.0, Color(tint, 0.9), randf_range(0.35, 0.65))


func _spawn(tex: String, pos: Vector2, vel: Vector2, size: float, grow: float, tint: Color, dur: float) -> void:
	_items.append({"tex": tex, "pos": pos, "vel": vel, "size": size, "grow": grow, "tint": tint, "t": 0.0, "dur": dur,
		"spin": randf() * TAU})


func _process(delta: float) -> void:
	var alive: Array[Dictionary] = []
	for item in _items:
		item["t"] = float(item["t"]) + delta
		item["pos"] = (item["pos"] as Vector2) + (item["vel"] as Vector2) * delta
		item["vel"] = (item["vel"] as Vector2) * 0.93 + Vector2(0, 300) * delta
		if float(item["t"]) < float(item["dur"]):
			alive.append(item)
	_items = alive
	queue_redraw()


func _draw() -> void:
	call("_draw_" + layer)
	for item in _items:
		var k := float(item["t"]) / float(item["dur"])
		var size := float(item["size"]) + float(item["grow"]) * k
		var tint: Color = item["tint"]
		draw_set_transform(item["pos"], float(item["spin"]), Vector2.ONE)
		draw_texture_rect(TEX[item["tex"]], Rect2(-size * 0.5, -size * 0.5, size, size), false,
			Color(tint, tint.a * (1.0 - k)))
	draw_set_transform(Vector2.ZERO)


## Сцена: лучи прожекторов сверху и пятна света на полу, вспыхивают в долю.
func _draw_stage() -> void:
	var pulse := _pulse()
	for spot: Dictionary in SPOTS:
		var x := float(spot["x"])
		var tint: Color = spot["tint"]
		var top := Color(tint, 0.10 + 0.16 * pulse)
		var bottom := Color(tint, 0.0)
		draw_polygon(PackedVector2Array([Vector2(x - 12, Layout.TOP_H), Vector2(x + 12, Layout.TOP_H),
			Vector2(x + 140, Layout.FLOOR_Y), Vector2(x - 140, Layout.FLOOR_Y)]), PackedColorArray([top, top, bottom, bottom]))
		draw_texture_rect(TEX["glow"], Rect2(x - 160, Layout.FLOOR_Y - 28, 320, 56), false, Color(tint, 0.18 + 0.3 * pulse))
		draw_texture_rect(TEX["glow"], Rect2(x - 22, Layout.TOP_H - 14, 44, 30), false, Color(tint, 0.5 + 0.4 * pulse))
	draw_texture_rect(TEX["smoke"], Rect2(-60, Layout.FLOOR_Y - 70, 520, 110), false, Color(0.5, 0.45, 0.7, 0.10))
	draw_texture_rect(TEX["smoke"], Rect2(820, Layout.FLOOR_Y - 60, 520, 100), false, Color(0.5, 0.45, 0.7, 0.08))


## Дорожка: ореол у нот песни, подходящих к линии удара.
func _draw_top() -> void:
	if Game.state != "song":
		return
	var slot_now := Game.conductor.player_time() / Timing.slot_len()
	for note: Dictionary in Game.performance.notes:
		var ahead := float(note["slot"]) - slot_now
		if ahead > GLOW_SLOTS:
			break
		if ahead < -0.5 or note["state"] != "wait":
			continue
		var k := 1.0 - clampf(ahead / GLOW_SLOTS, 0.0, 1.0)
		var pos := Vector2(Hud.slot_x(float(note["slot"]), slot_now), Hud.lane_y(String(note["string"])))
		var size := Hud.NOTE_R * (3.0 + 1.5 * k)
		draw_texture_rect(TEX["glow"], Rect2(pos - Vector2(size, size) * 0.5, Vector2(size, size)), false,
			Color(1.0, 0.85, 0.5, 0.35 * k))


## Пульс на каждую долю, сильнее — на первую долю такта.
func _pulse() -> float:
	if not Game.conductor.running:
		return 0.0
	var beat := Game.conductor.beat_f()
	var strength := 1.0 if posmod(floori(beat), Timing.BEATS_PER_BAR) == 0 else 0.55
	return exp(-(beat - floorf(beat)) * 5.0) * strength
