class_name FxLayer
extends Node2D
## Свет поверх картинки — смешивание сложением, текстуры Kenney Particle Pack (CC0, см. CREDITS.md).
## Два слоя: «stage» — под интерфейсом (искры и молнии у головы грифа),
## «top» — над дорожкой (вспышка на линии удара, ореол у подходящих нот). Слой рисует _draw_<слой>.
## Проигрывает удары по струнам (on_voiced), факты песни (_on_<факт>) и смену ранга стиля (on_ranked):
## вспышка на весь экран цвета ранга, сноп искр; чем выше стиль, тем больше искр.

const TEX := {
	"flash": preload("res://assets/fx/flare_01.png"),
	"glow": preload("res://assets/fx/circle_05.png"),
	"star": preload("res://assets/fx/star_05.png"),
	"bolt": preload("res://assets/fx/spark_04.png"),
	"ring": preload("res://assets/fx/light_03.png"),
}
const GLOW_SLOTS := 3.0                ## за сколько восьмых до линии удара нота начинает светиться
const FLASH := {"up": 0.24, "down": 0.16, "time": 0.28}
const DOWN := Color(1.0, 0.2, 0.15)

var layer := "top"
var _items: Array[Dictionary] = []     ## вспышки и искры: {tex, pos, vel, size, grow, tint, t, dur, spin}
var _flash := {}                       ## вспышка экрана: {tint, alpha, t}


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


func on_ranked(rank: int, up: bool) -> void:
	var tint: Color = StyleMeter.RANKS[rank]["tint"] if up else DOWN
	if layer == "top":
		_flash = {"tint": tint, "alpha": FLASH["up" if up else "down"], "t": 0.0}
	elif up:
		_burst(StageView.neck_tip(), tint, 10 + rank * 4)


func _on_hit(data: Dictionary) -> void:
	var tint: Color = data["judgement"]["tint"]
	if layer == "top":
		var at := Vector2(Layout.HIT_X, Hud.lane_y(String(data["note"]["string"])))
		_spawn("glow", at, Vector2.ZERO, 50.0, 90.0, Color(tint, 0.8), 0.25)
	else:
		_burst(StageView.neck_tip(), tint, 6 + 2 * _rank())


func _on_tech(_data: Dictionary) -> void:
	if layer == "stage":
		_spawn("bolt", StageView.neck_tip() + Vector2(30, -10), Vector2.ZERO, 120.0, 40.0, Color(0.7, 0.8, 1.0, 0.9), 0.35)
		_burst(StageView.neck_tip(), Color(1.0, 0.82, 0.3), 14)


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
	if not _flash.is_empty():
		_flash["t"] = float(_flash["t"]) + delta
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


## Сцена: свой свет не рисует — неоновый фон у StageView, здесь только искры и молнии (общий _draw).
func _draw_stage() -> void:
	pass


## Дорожка: ореол у нот песни, подходящих к линии удара; поверх — вспышка экрана от смены ранга.
func _draw_top() -> void:
	if not _flash.is_empty() and float(_flash["t"]) < float(FLASH["time"]):
		var fade := 1.0 - float(_flash["t"]) / float(FLASH["time"])
		draw_rect(Rect2(Vector2(-40, -40), Layout.SCREEN + Vector2(80, 80)), Color(_flash["tint"] as Color, float(_flash["alpha"]) * fade))
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


## Ранг стиля песни (вне песни — ноль).
func _rank() -> int:
	return Game.style.rank() if Game.state == "song" and Game.style.visible() else 0
