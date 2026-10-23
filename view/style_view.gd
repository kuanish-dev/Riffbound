class_name StyleView
extends Node2D
## Ранг стиля (Game.style) в углу сцены, как в слэшерах: большая буква цвета ранга с ореолом, подпись
## и шкала, которая тает на глазах. Рост ранга — буква выскакивает, падение — старая буква валится и гаснет.
## На высоких рангах буква дрожит. Только в песне.

const AT := Vector2(1130, 142)                ## центр буквы
const LETTER_SIZE := {1: 104, 2: 90, 3: 74}   ## кегль по числу букв
const TILT := -0.08
const POP_SPEED := 9.0                        ## как быстро гаснет «выскок» (1/с)
const FALL_TIME := 0.7
const BAR := Rect2(1030, 210, 200, 8)
const DOWN := Color(1.0, 0.25, 0.2)

var _pop := 9.0                               ## секунд с роста ранга
var _shown := -1                              ## ранг, который сейчас нарисован
var _fall := {}                               ## падающая буква: {rank, t}
var _t := 0.0
var _glow := Node2D.new()                     ## ореол за буквой — сложением цветов (у текстуры чёрные края)


func _ready() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = additive
	_glow.show_behind_parent = true
	_glow.draw.connect(_draw_glow)
	add_child(_glow)


func reset() -> void:
	_pop = 9.0
	_shown = -1
	_fall = {}


func on_ranked(rank: int, up: bool) -> void:
	if up:
		_pop = 0.0
	elif _shown >= 0:
		_fall = {"rank": _shown, "t": 0.0}
	_shown = rank


func _process(delta: float) -> void:
	_t += delta
	_pop += delta
	if not _fall.is_empty():
		_fall["t"] = float(_fall["t"]) + delta
		if float(_fall["t"]) > FALL_TIME:
			_fall = {}
	queue_redraw()
	_glow.queue_redraw()


func _draw() -> void:
	var style := Game.style
	if Game.state != "song" or style == null or not style.visible():
		return
	var info: Dictionary = StyleMeter.RANKS[style.rank()]
	var tint: Color = info["tint"]
	var pop := exp(-_pop * POP_SPEED)
	var jitter := Vector2(sin(_t * 47.0), cos(_t * 39.0)) * style.heat() * 3.0
	_letter(String(info["id"]), AT + jitter, TILT, 1.0 + 0.7 * pop, tint)
	Glyph.text_center(self, AT.x, BAR.position.y - 8, String(info["name"]), 16, tint.lightened(0.35))
	draw_rect(BAR, Color(0, 0, 0, 0.55))
	draw_rect(Rect2(BAR.position, Vector2(BAR.size.x * style.fill(), BAR.size.y)), tint)
	if not _fall.is_empty():
		var k := float(_fall["t"]) / FALL_TIME
		var id := String(StyleMeter.RANKS[int(_fall["rank"])]["id"])
		_letter(id, AT + Vector2(40.0 * k, 150.0 * k * k), TILT + 0.9 * k, 1.0 - 0.3 * k, Color(DOWN, 1.0 - k))


## Ореол цвета ранга: вспыхивает при росте и дышит в долю на высоком стиле.
func _draw_glow() -> void:
	var style := Game.style
	if Game.state != "song" or style == null or not style.visible():
		return
	var tint: Color = StyleMeter.RANKS[style.rank()]["tint"]
	var pop := exp(-_pop * POP_SPEED)
	var beat := Game.conductor.beat_f()
	var pulse := exp(-(beat - floorf(beat)) * 6.0) * style.heat()
	var size := 190.0 + 110.0 * pop + 60.0 * pulse
	_glow.draw_texture_rect(FxLayer.TEX["glow"], Rect2(AT - Vector2(size, size) * 0.5, Vector2(size, size)), false,
		Color(tint, minf(1.0, 0.6 + 0.6 * pop + 0.3 * pulse)))


## Буква ранга неоновыми слоями: центр, наклон, масштаб.
func _letter(id: String, center: Vector2, angle: float, scale: float, tint: Color) -> void:
	Glyph.neon(self, center, id, int(LETTER_SIZE.get(id.length(), 74)), tint, angle, scale)
