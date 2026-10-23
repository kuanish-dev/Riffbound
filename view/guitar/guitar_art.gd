class_name GuitarArt

const NUT_X := 200.0
const HEAD_TIP := 250.0
const BRIDGE_X := -30.0
const NECK_FROM := 30.0
const NECK_W := Vector2(19.0, 16.0)
const FRETS := 21
const INLAYS := [3, 5, 7, 9, 12, 15, 17, 19, 21]
const DOUBLE_INLAY := 12
const STRINGS := 6
const STRING_SPAN := Vector2(13.0, 11.0)
const SMOOTH_STEPS := 8
const SHADOW := Vector2(2.5, 3.5)

static var _cache := {}


static func draw(ci: CanvasItem, skin: Dictionary, at: Vector2, angle: float, size: float, glow := 0.0) -> void:
	var shape: Dictionary = GuitarShapes.SHAPES[skin["shape"]]
	var body := outline(String(skin["shape"]), "body")
	ci.draw_set_transform(at, angle, Vector2(size, size))
	ci.draw_colored_polygon(_shifted(body, SHADOW), Color(0, 0, 0, 0.35))
	_draw_neck(ci, skin)
	_draw_head(ci, skin, GuitarShapes.HEADS[shape["head"]])
	_draw_body(ci, skin, body)
	_draw_guard(ci, skin, shape)
	_draw_fretboard(ci, skin)
	for pickup: Dictionary in GuitarShapes.PICKUPS[skin["pickups"]]:
		_draw_pickup(ci, skin, pickup)
	_draw_bridge(ci, skin, shape)
	_draw_controls(ci, skin["hardware"], shape)
	_draw_strings(ci, GuitarShapes.HEADS[shape["head"]])
	if glow > 0.0:
		ci.draw_polyline(_closed(body), Color(1.0, 0.9, 0.7, 0.7 * glow), 3.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_guard(ci: CanvasItem, skin: Dictionary, shape: Dictionary) -> void:
	if not skin.has("guard") or (shape["guard"] as Array).is_empty():
		return
	var guard := outline(String(skin["shape"]), "guard")
	ci.draw_colored_polygon(guard, skin["guard"])
	ci.draw_polyline(_closed(guard), (skin["guard"] as Color).darkened(0.35), 0.8, true)


static func _draw_controls(ci: CanvasItem, hardware: Color, shape: Dictionary) -> void:
	for knob: Vector2 in shape["knobs"]:
		ci.draw_circle(knob, 4.2, hardware, true, -1.0, true)
		ci.draw_circle(knob, 2.6, hardware.darkened(0.35), true, -1.0, true)
		ci.draw_line(knob, knob + Vector2(0, -3.6), hardware.lightened(0.4), 0.8, true)
	var switch: Vector2 = shape["switch"]
	ci.draw_circle(switch, 2.4, hardware.darkened(0.2), true, -1.0, true)
	ci.draw_circle(switch, 1.2, Color(0.95, 0.92, 0.85), true, -1.0, true)


static func silhouette(ci: CanvasItem, skin: Dictionary, at: Vector2, angle: float, size: float, tint: Color) -> void:
	var shape: Dictionary = GuitarShapes.SHAPES[skin["shape"]]
	ci.draw_set_transform(at, angle, Vector2(size, size))
	var w0 := _half_width(NECK_FROM) + 1.0
	var w1 := _half_width(NUT_X) + 1.0
	ci.draw_colored_polygon(PackedVector2Array([Vector2(NECK_FROM, -w0), Vector2(NUT_X, -w1), Vector2(NUT_X, w1),
		Vector2(NECK_FROM, w0)]), tint)
	ci.draw_colored_polygon(head_outline(String(shape["head"])), tint)
	ci.draw_colored_polygon(outline(String(skin["shape"]), "body"), tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func outline(shape_id: String, part: String) -> PackedVector2Array:
	var key := "%s:%s" % [shape_id, part]
	if not _cache.has(key):
		var shape: Dictionary = GuitarShapes.SHAPES[shape_id]
		_cache[key] = _smooth(shape[part]) if shape["smooth"] else PackedVector2Array(shape[part])
	return _cache[key]


static func head_outline(head_id: String) -> PackedVector2Array:
	var key := "head:" + head_id
	if not _cache.has(key):
		_cache[key] = _smooth(GuitarShapes.HEADS[head_id]["outline"])
	return _cache[key]


static func extent(shape_id: String) -> Vector2:
	var back := 0.0
	for p: Vector2 in outline(shape_id, "body"):
		back = minf(back, p.x)
	return Vector2(back, HEAD_TIP)


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


static func _layers(skin: Dictionary) -> Array:
	var key := "layers:" + String(skin["id"])
	if not _cache.has(key):
		var body := outline(String(skin["shape"]), "body")
		_cache[key] = _ring_layers(skin, body) + _stripe_layers(skin, body)
	return _cache[key]


static func _ring_layers(skin: Dictionary, body: PackedVector2Array) -> Array:
	var center: Vector2 = GuitarShapes.SHAPES[skin["shape"]]["center"]
	var layers: Array = []
	var rings := int(skin.get("rings", 0))
	for k in rings:
		var t := float(k) / maxf(1.0, rings - 1.0)
		var scaled := PackedVector2Array()
		for p in body:
			scaled.append(center + (p - center) * (1.0 - 0.72 * t))
		var tint: Color = (skin["edge"] as Color).lerp(skin["body"], ease(t, 0.6))
		layers.append([Geometry2D.intersect_polygons(scaled, body), tint])
	return layers


static func _stripe_layers(skin: Dictionary, body: PackedVector2Array) -> Array:
	var layers: Array = []
	for k in int(skin.get("stripes", 0)):
		var x := -60.0 + k * 34.0
		var band := PackedVector2Array([Vector2(x, -60), Vector2(x + 12, -60), Vector2(x - 18, 60), Vector2(x - 30, 60)])
		layers.append([Geometry2D.intersect_polygons(band, body), Color(1, 1, 1, 0.13)])
	return layers


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
	var shape := head_outline(String(GuitarShapes.SHAPES[skin["shape"]]["head"]))
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
	var kind: Dictionary = GuitarShapes.PICKUP_KINDS[pickup["kind"]]
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
