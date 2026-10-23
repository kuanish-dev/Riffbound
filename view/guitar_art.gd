class_name GuitarArt
## Электрогитара кодом. Свои координаты: гриф вдоль +x, корпус около нуля, порожек на NUT_X, вся гитара
## ~320 в длину; draw() ставит место, поворот и масштаб. Облик — скин Shop.SKINS.
## Корпус — контур SHAPES (гладкий — кривая Катмулла–Рома через точки, угловатый — как есть), отделка
## скина (кольца санбёрста, блики, искры, неоновый кант), накладка, звукосниматели PICKUPS, бридж,
## ручки; гриф с ладами по правилу «каждый лад — 2^(1/12)» и метками, голова HEADS с колками, шесть струн.

const NUT_X := 200.0
const HEAD_TIP := 250.0                 ## кончик головы грифа
const BRIDGE_X := -30.0
const NECK_FROM := 30.0
const NECK_W := Vector2(19.0, 16.0)     ## ширина грифа у корпуса и у порожка
const FRETS := 21
const INLAYS := [3, 5, 7, 9, 12, 15, 17, 19, 21]
const DOUBLE_INLAY := 12
const STRINGS := 6
const STRING_SPAN := Vector2(13.0, 11.0) ## разлёт струн у бридж и у порожка
const SMOOTH_STEPS := 8
const SHADOW := Vector2(2.5, 3.5)
const SHAPES := {
	"strat": {"name": "классическая", "smooth": true, "head": "inline", "tailpiece": false, "center": Vector2(-14, 0),
		"body": [Vector2(55, -33), Vector2(46, -26), Vector2(38, -15), Vector2(36, -9), Vector2(36, 9), Vector2(38, 16),
			Vector2(41, 25), Vector2(35, 34), Vector2(22, 36), Vector2(8, 32), Vector2(-14, 42), Vector2(-40, 45),
			Vector2(-60, 34), Vector2(-68, 10), Vector2(-66, -16), Vector2(-55, -36), Vector2(-34, -44), Vector2(-10, -40),
			Vector2(8, -34), Vector2(28, -40), Vector2(45, -40)],
		"guard": [Vector2(34, -9), Vector2(27, -20), Vector2(10, -23), Vector2(-12, -20), Vector2(-26, -15),
			Vector2(-32, -5), Vector2(-32, 7), Vector2(-48, 21), Vector2(-44, 31), Vector2(-26, 30), Vector2(-6, 25),
			Vector2(16, 21), Vector2(30, 15), Vector2(34, 9)],
		"knobs": [Vector2(-22, 22), Vector2(-35, 26), Vector2(-47, 29)], "switch": Vector2(2, 23)},
	"lp": {"name": "одиночный вырез", "smooth": true, "head": "three", "tailpiece": true, "center": Vector2(-18, 4),
		"body": [Vector2(34, -10), Vector2(30, -25), Vector2(16, -35), Vector2(0, -34), Vector2(-18, -38),
			Vector2(-40, -46), Vector2(-60, -38), Vector2(-70, -14), Vector2(-70, 12), Vector2(-62, 36), Vector2(-42, 48),
			Vector2(-18, 46), Vector2(0, 40), Vector2(18, 40), Vector2(34, 34), Vector2(40, 26), Vector2(36, 16),
			Vector2(34, 10)],
		"guard": [Vector2(30, 13), Vector2(35, 19), Vector2(29, 30), Vector2(15, 32), Vector2(9, 24), Vector2(17, 15)],
		"knobs": [Vector2(-30, 22), Vector2(-44, 25), Vector2(-32, 33), Vector2(-46, 36)], "switch": Vector2(14, -26)},
	"sg": {"name": "двурогая", "smooth": true, "head": "three", "tailpiece": true, "center": Vector2(-16, 0),
		"body": [Vector2(36, -9), Vector2(38, -16), Vector2(48, -30), Vector2(38, -33), Vector2(20, -29),
			Vector2(2, -33), Vector2(-24, -40), Vector2(-50, -38), Vector2(-66, -20), Vector2(-69, 0), Vector2(-66, 20),
			Vector2(-50, 38), Vector2(-24, 40), Vector2(2, 33), Vector2(20, 29), Vector2(38, 33), Vector2(48, 30),
			Vector2(38, 16), Vector2(36, 9)],
		"guard": [Vector2(34, -9), Vector2(26, -17), Vector2(-4, -18), Vector2(-24, -14), Vector2(-30, 0),
			Vector2(-24, 14), Vector2(-4, 18), Vector2(26, 17), Vector2(34, 9)],
		"knobs": [Vector2(-34, 20), Vector2(-48, 22), Vector2(-36, 30), Vector2(-50, 32)], "switch": Vector2(20, -23)},
	"super": {"name": "суперстрат", "smooth": true, "head": "inline", "tailpiece": false, "center": Vector2(-14, 0),
		"body": [Vector2(60, -33), Vector2(50, -27), Vector2(40, -14), Vector2(36, -9), Vector2(36, 9), Vector2(40, 15),
			Vector2(48, 24), Vector2(52, 32), Vector2(40, 35), Vector2(24, 33), Vector2(8, 31), Vector2(-14, 41),
			Vector2(-40, 44), Vector2(-60, 33), Vector2(-68, 10), Vector2(-66, -16), Vector2(-55, -36), Vector2(-34, -43),
			Vector2(-10, -39), Vector2(8, -33), Vector2(30, -38), Vector2(48, -39)],
		"guard": [],
		"knobs": [Vector2(-28, 24), Vector2(-44, 28)], "switch": Vector2(-8, 27)},
	"v": {"name": "V-образная", "smooth": false, "head": "three", "tailpiece": false, "center": Vector2(8, 0),
		"body": [Vector2(44, -10), Vector2(-66, -52), Vector2(-76, -42), Vector2(-34, 0), Vector2(-76, 42),
			Vector2(-66, 52), Vector2(44, 10)],
		"guard": [Vector2(42, -9), Vector2(8, -16), Vector2(-24, -12), Vector2(-30, 0), Vector2(-24, 12), Vector2(8, 16),
			Vector2(42, 9)],
		"knobs": [Vector2(-46, 26), Vector2(-60, 36)], "switch": Vector2(-50, -30)},
	"explorer": {"name": "угловатая", "smooth": false, "head": "inline", "tailpiece": true, "center": Vector2(-16, 2),
		"body": [Vector2(44, -10), Vector2(36, -13), Vector2(42, -30), Vector2(30, -38), Vector2(-62, -12),
			Vector2(-70, 6), Vector2(-58, 12), Vector2(-78, 36), Vector2(-36, 42), Vector2(10, 30), Vector2(30, 22),
			Vector2(38, 13), Vector2(44, 10)],
		"guard": [Vector2(42, -9), Vector2(30, -14), Vector2(0, -20), Vector2(-30, -14), Vector2(-36, 0),
			Vector2(-20, 14), Vector2(10, 22), Vector2(30, 16), Vector2(40, 9)],
		"knobs": [Vector2(-40, 30), Vector2(-54, 32), Vector2(-66, 30)], "switch": Vector2(10, -24)},
}
## Голова грифа: контур, колки (стойки струн) и куда торчат ключи колков от стойки.
const HEADS := {
	"inline": {"outline": [Vector2(198, -8), Vector2(204, -12), Vector2(214, -17), Vector2(232, -20), Vector2(246, -18),
			Vector2(250, -12), Vector2(244, -7), Vector2(230, -4), Vector2(218, 2), Vector2(208, 9), Vector2(198, 8)],
		"posts": [Vector2(207, -11.5), Vector2(214, -12.5), Vector2(221, -13.5), Vector2(228, -14.5), Vector2(235, -15.3),
			Vector2(242, -15.8)],
		"keys": [Vector2(0, -9), Vector2(0, -9), Vector2(0, -9), Vector2(0, -9), Vector2(0, -8), Vector2(0, -7)]},
	"three": {"outline": [Vector2(198, -8), Vector2(206, -12), Vector2(238, -15), Vector2(248, -11), Vector2(250, 0),
			Vector2(248, 11), Vector2(238, 15), Vector2(206, 12), Vector2(198, 8)],
		"posts": [Vector2(212, -8), Vector2(225, -9.5), Vector2(238, -11), Vector2(238, 11), Vector2(225, 9.5),
			Vector2(212, 8)],
		"keys": [Vector2(0, -8), Vector2(0, -8), Vector2(0, -8), Vector2(0, 8), Vector2(0, 8), Vector2(0, 8)]},
}
## Звукосниматели: где стоят (x) и какие. Сингл — один ряд магнитов, хамбакер — два.
const PICKUPS := {
	"sss": [{"kind": "single", "x": 24.0}, {"kind": "single", "x": 7.0}, {"kind": "single", "x": -12.0}],
	"hh": [{"kind": "humbucker", "x": 20.0}, {"kind": "humbucker", "x": -12.0}],
	"hsh": [{"kind": "humbucker", "x": 22.0}, {"kind": "single", "x": 6.0}, {"kind": "humbucker", "x": -12.0}],
}
const PICKUP_KINDS := {"single": {"size": Vector2(7, 30), "rows": [0.0]}, "humbucker": {"size": Vector2(15, 32), "rows": [-3.5, 3.5]}}

static var _cache := {}                ## контуры и слои отделки — считаются один раз


## Гитара скина skin: at — где центр корпуса, angle — поворот грифа, size — масштаб (1 — ~320 px в длину),
## glow (0…1) — вспышка от удара.
static func draw(ci: CanvasItem, skin: Dictionary, at: Vector2, angle: float, size: float, glow := 0.0) -> void:
	var shape: Dictionary = SHAPES[skin["shape"]]
	var body := outline(String(skin["shape"]), "body")
	ci.draw_set_transform(at, angle, Vector2(size, size))
	ci.draw_colored_polygon(_shifted(body, SHADOW), Color(0, 0, 0, 0.35))
	_draw_neck(ci, skin)
	_draw_head(ci, skin, HEADS[shape["head"]])
	_draw_body(ci, skin, body)
	if skin.has("guard") and not (shape["guard"] as Array).is_empty():
		var guard := outline(String(skin["shape"]), "guard")
		ci.draw_colored_polygon(guard, skin["guard"])
		ci.draw_polyline(_closed(guard), (skin["guard"] as Color).darkened(0.35), 0.8, true)
	_draw_fretboard(ci, skin)
	for pickup: Dictionary in PICKUPS[skin["pickups"]]:
		_draw_pickup(ci, skin, pickup)
	_draw_bridge(ci, skin, shape)
	for knob: Vector2 in shape["knobs"]:
		ci.draw_circle(knob, 4.2, skin["hardware"], true, -1.0, true)
		ci.draw_circle(knob, 2.6, (skin["hardware"] as Color).darkened(0.35), true, -1.0, true)
		ci.draw_line(knob, knob + Vector2(0, -3.6), (skin["hardware"] as Color).lightened(0.4), 0.8, true)
	var switch: Vector2 = shape["switch"]
	ci.draw_circle(switch, 2.4, (skin["hardware"] as Color).darkened(0.2), true, -1.0, true)
	ci.draw_circle(switch, 1.2, Color(0.95, 0.92, 0.85), true, -1.0, true)
	_draw_strings(ci, HEADS[shape["head"]])
	if glow > 0.0:
		ci.draw_polyline(_closed(body), Color(1.0, 0.9, 0.7, 0.7 * glow), 3.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Плоский силуэт гитары (корпус, гриф, голова) одним цветом — для неоновых «теней».
static func silhouette(ci: CanvasItem, skin: Dictionary, at: Vector2, angle: float, size: float, tint: Color) -> void:
	var shape: Dictionary = SHAPES[skin["shape"]]
	ci.draw_set_transform(at, angle, Vector2(size, size))
	var w0 := _half_width(NECK_FROM) + 1.0
	var w1 := _half_width(NUT_X) + 1.0
	ci.draw_colored_polygon(PackedVector2Array([Vector2(NECK_FROM, -w0), Vector2(NUT_X, -w1), Vector2(NUT_X, w1),
		Vector2(NECK_FROM, w0)]), tint)
	ci.draw_colored_polygon(head_outline(String(shape["head"])), tint)
	ci.draw_colored_polygon(outline(String(skin["shape"]), "body"), tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Контур части (body / guard) формы корпуса, сглаженный и закешированный.
static func outline(shape_id: String, part: String) -> PackedVector2Array:
	var key := "%s:%s" % [shape_id, part]
	if not _cache.has(key):
		var shape: Dictionary = SHAPES[shape_id]
		_cache[key] = _smooth(shape[part]) if shape["smooth"] else PackedVector2Array(shape[part])
	return _cache[key]


static func head_outline(head_id: String) -> PackedVector2Array:
	var key := "head:" + head_id
	if not _cache.has(key):
		_cache[key] = _smooth(HEADS[head_id]["outline"])
	return _cache[key]


## Длина гитары от заднего края корпуса до кончика головы (для раскладки превью).
static func extent(shape_id: String) -> Vector2:
	var back := 0.0
	for p: Vector2 in outline(shape_id, "body"):
		back = minf(back, p.x)
	return Vector2(back, HEAD_TIP)


# --- корпус -------------------------------------------------------------------

static func _draw_body(ci: CanvasItem, skin: Dictionary, body: PackedVector2Array) -> void:
	ci.draw_colored_polygon(body, skin["body"])
	for layer: Array in _layers(skin):
		for poly: PackedVector2Array in layer[0]:
			ci.draw_colored_polygon(poly, layer[1])
	for dot: Vector3 in _sparkles(skin):
		ci.draw_circle(Vector2(dot.x, dot.y), dot.z, Color(1, 1, 1, 0.35 + dot.z * 0.4), true, -1.0, true)
	if skin.get("neon", false):
		ci.draw_polyline(_closed(body), Color(skin["edge"] as Color, 0.25), 7.0, true)
		ci.draw_polyline(_closed(body), skin["edge"], 2.2, true)
	else:
		ci.draw_polyline(_closed(body), (skin["body"] as Color).darkened(0.45), 1.2, true)


## Слои отделки: [[многоугольники], цвет]. Санбёрст — кольца, уменьшенные копии корпуса от края к центру;
## блики — косые полосы. Всё обрезано по корпусу (у вогнутых форм копии иначе вылезают).
static func _layers(skin: Dictionary) -> Array:
	var key := "layers:" + String(skin["id"])
	if _cache.has(key):
		return _cache[key]
	var body := outline(String(skin["shape"]), "body")
	var center: Vector2 = SHAPES[skin["shape"]]["center"]
	var layers: Array = []
	var rings := int(skin.get("rings", 0))
	for k in rings:
		var t := float(k) / maxf(1.0, rings - 1.0)
		var scaled := PackedVector2Array()
		for p in body:
			scaled.append(center + (p - center) * (1.0 - 0.72 * t))
		var tint: Color = (skin["edge"] as Color).lerp(skin["body"], ease(t, 0.6))
		layers.append([Geometry2D.intersect_polygons(scaled, body), tint])
	for k in int(skin.get("stripes", 0)):
		var x := -60.0 + k * 34.0
		var band := PackedVector2Array([Vector2(x, -60), Vector2(x + 12, -60), Vector2(x - 18, 60), Vector2(x - 30, 60)])
		layers.append([Geometry2D.intersect_polygons(band, body), Color(1, 1, 1, 0.13)])
	_cache[key] = layers
	return layers


## Искры (x, y, радиус) внутри корпуса — одни и те же для скина.
static func _sparkles(skin: Dictionary) -> Array:
	var key := "sparkle:" + String(skin["id"])
	if _cache.has(key):
		return _cache[key]
	var body := outline(String(skin["shape"]), "body")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(skin["id"])
	var dots: Array = []
	while dots.size() < int(skin.get("sparkle", 0)):
		var p := Vector2(rng.randf_range(-80, 60), rng.randf_range(-55, 55))
		if Geometry2D.is_point_in_polygon(p, body):
			dots.append(Vector3(p.x, p.y, rng.randf_range(0.4, 1.1)))
	_cache[key] = dots
	return dots


# --- гриф, голова, железо -----------------------------------------------------

static func _half_width(x: float) -> float:
	return lerpf(NECK_W.x, NECK_W.y, (x - NECK_FROM) / (NUT_X - NECK_FROM)) * 0.5


static func _fret_x(n: int) -> float:
	return NUT_X - (NUT_X - BRIDGE_X) * (1.0 - pow(2.0, -n / 12.0))


static func _draw_neck(ci: CanvasItem, skin: Dictionary) -> void:
	var w0 := _half_width(NECK_FROM) + 1.0
	var w1 := _half_width(NUT_X) + 1.0
	ci.draw_colored_polygon(PackedVector2Array([Vector2(NECK_FROM, -w0), Vector2(NUT_X, -w1), Vector2(NUT_X, w1),
		Vector2(NECK_FROM, w0)]), skin["neck"])


static func _draw_fretboard(ci: CanvasItem, skin: Dictionary) -> void:
	var w0 := _half_width(NECK_FROM)
	var w1 := _half_width(NUT_X)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(NECK_FROM, -w0), Vector2(NUT_X, -w1), Vector2(NUT_X, w1),
		Vector2(NECK_FROM, w0)]), skin["board"])
	for n in range(1, FRETS + 1):
		var x := _fret_x(n)
		var w := _half_width(x)
		ci.draw_line(Vector2(x, -w), Vector2(x, w), Color(0.82, 0.82, 0.86), 0.8, true)
	for n: int in INLAYS:
		var x := (_fret_x(n) + _fret_x(n - 1)) * 0.5
		for y: float in ([-4.5, 4.5] if n == DOUBLE_INLAY else [0.0]):
			ci.draw_circle(Vector2(x, y), 1.7, skin["inlay"], true, -1.0, true)
	ci.draw_rect(Rect2(NUT_X - 1.5, -w1, 3.0, w1 * 2.0), Color(0.95, 0.93, 0.85))


static func _draw_head(ci: CanvasItem, skin: Dictionary, head: Dictionary) -> void:
	var face: Color = skin.get("head", skin["neck"])
	var shape := head_outline(String(SHAPES[skin["shape"]]["head"]))
	ci.draw_colored_polygon(_shifted(shape, SHADOW), Color(0, 0, 0, 0.3))
	ci.draw_colored_polygon(shape, face)
	ci.draw_polyline(_closed(shape), face.darkened(0.4), 1.0, true)
	var posts: Array = head["posts"]
	for i in posts.size():
		var post: Vector2 = posts[i]
		var key: Vector2 = post + (head["keys"][i] as Vector2)
		ci.draw_line(post, key, (skin["hardware"] as Color).darkened(0.2), 1.6, true)
		ci.draw_rect(Rect2(key - Vector2(2.2, 1.6), Vector2(4.4, 3.2)), skin["hardware"])
		ci.draw_circle(post, 1.7, skin["hardware"], true, -1.0, true)


static func _draw_pickup(ci: CanvasItem, skin: Dictionary, pickup: Dictionary) -> void:
	var kind: Dictionary = PICKUP_KINDS[pickup["kind"]]
	var size: Vector2 = kind["size"]
	var x := float(pickup["x"])
	var cover: Color = skin["cover"]
	ci.draw_rect(Rect2(Vector2(x, 0) - size * 0.5 - Vector2(1, 1), size + Vector2(2, 2)), cover.darkened(0.5))
	ci.draw_rect(Rect2(Vector2(x, 0) - size * 0.5, size), cover)
	for row: float in kind["rows"]:
		for i in STRINGS:
			ci.draw_circle(Vector2(x + row, _string_y(i, x)), 0.9, (skin["hardware"] as Color).darkened(0.15), true, -1.0, true)


static func _draw_bridge(ci: CanvasItem, skin: Dictionary, shape: Dictionary) -> void:
	var metal: Color = skin["hardware"]
	ci.draw_rect(Rect2(BRIDGE_X - 5, -10, 9, 20), metal.darkened(0.25))
	for i in STRINGS:
		ci.draw_rect(Rect2(BRIDGE_X - 2, _string_y(i, BRIDGE_X) - 0.9, 5, 1.8), metal)
	if shape["tailpiece"]:
		ci.draw_rect(Rect2(BRIDGE_X - 17, -11, 5, 22), metal)


static func _string_y(i: int, x: float) -> float:
	var span := lerpf(STRING_SPAN.x, STRING_SPAN.y, (x - BRIDGE_X) / (NUT_X - BRIDGE_X))
	return -span * 0.5 + span * i / (STRINGS - 1)


static func _draw_strings(ci: CanvasItem, head: Dictionary) -> void:
	for i in STRINGS:
		var nut := Vector2(NUT_X, _string_y(i, NUT_X))
		var tint := Color(0.88, 0.88, 0.92, 0.85)
		var width := 0.95 - i * 0.1
		ci.draw_line(Vector2(BRIDGE_X, _string_y(i, BRIDGE_X)), nut, tint, width, true)
		ci.draw_line(nut, head["posts"][i], tint, width, true)


# --- геометрия ----------------------------------------------------------------

## Замкнутая кривая Катмулла–Рома через точки.
static func _smooth(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := points.size()
	for i in n:
		var p0: Vector2 = points[(i - 1 + n) % n]
		var p1: Vector2 = points[i]
		var p2: Vector2 = points[(i + 1) % n]
		var p3: Vector2 = points[(i + 2) % n]
		for s in SMOOTH_STEPS:
			var t := float(s) / SMOOTH_STEPS
			out.append(0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
				+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t))
	return out


static func _shifted(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(p + by)
	return out


static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var out := points.duplicate()
	out.append(points[0])
	return out
