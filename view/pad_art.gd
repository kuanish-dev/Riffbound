class_name PadArt
## Сенсорные кнопки в неоне, как сцена: стеклянные панели со срезанными углами и скобками по углам.
## Кнопки гитары — части инструмента:
## - струна — сама струна между двух стоек: дрожит от удара, при бенде выгибается к пальцу (справа — шкала
##   «½ · 1 · 1½ тона», сверху — нота, которая звучит), от вибрато бежит рябь;
## - лады — гриф: порожки в промежутках между кнопками, три струны поперёк (верхняя сверху, как на дорожке),
##   звенящая струна светится от зажатого лада к струнам-кнопкам, по ней пробегает след слайда; точки —
##   ноты аккорда в джеме или куда жать дальше в песне;
## - позиция — стрелки.
## Только рисование: что показать, приносит Hud (словари состояний).

const CUT := 16.0                         ## срез углов панели
const GLASS := [Color(0.13, 0.11, 0.22), Color(0.045, 0.04, 0.08)]   ## заливка панели сверху и снизу
const NEON := Color(0.3, 0.92, 1.0)       ## края, струны, порожки
const HOT := Color(1.0, 0.27, 0.66)       ## бенд, вибрато, слайд
const GOLD := Color(1.0, 0.82, 0.3)       ## подсказка «жми» и корень аккорда
const IDLE := Color(0.46, 0.43, 0.62)     ## край панели в покое
const STRINGS := {"high": 2.0, "mid": 3.0, "low": 4.2}       ## толщина струны
const NECK_ROWS := {"high": 0.2, "mid": 0.38, "low": 0.56}   ## где струна идёт поперёк ладов (доля высоты)
const BEND_MARKS := {0.5: "½", 1.0: "1", 1.5: "1½"}          ## деления шкалы бенда (тона)
const STRING_AT := 0.66                   ## струна в кнопке — на этой доле высоты
const BOW := 0.32                         ## на сколько высоты кнопки выгибается струна при бенде на BEND_MAX
## Дрожь струны: от удара (как у струн дорожки) и рябь вибрато — амплитуда (px), волн на струну, скорость.
const SHAKE := {"amp": 6.0, "waves": 4.5, "speed": 70.0}
const RIPPLE := {"amp": 7.0, "waves": 2.0, "speed": 28.0}
const SLIDE_RUN := 0.16                   ## за сколько секунд след слайда добегает до нового лада
const SLIDE_FADE := 0.3                   ## и сколько потом гаснет


## Стеклянная панель: срезаны левый верхний и правый нижний углы, на целых углах — скобки.
static func panel(ci: CanvasItem, rect: Rect2, edge: Color, glow := 0.0) -> void:
	var shape := _outline(rect)
	var top: Color = (GLASS[0] as Color).lerp(edge.darkened(0.35), glow)
	var bottom: Color = (GLASS[1] as Color).lerp(edge.darkened(0.6), glow)
	var colors := PackedColorArray()
	for v in shape:
		colors.append(top.lerp(bottom, (v.y - rect.position.y) / rect.size.y))
	ci.draw_polygon(shape, colors)
	var loop := shape.duplicate()
	loop.append(shape[0])
	ci.draw_polyline(loop, Color(edge, 0.16 + 0.3 * glow), 7.0, true)
	ci.draw_polyline(loop, edge, 2.0, true)
	var bright := edge.lightened(0.35)
	var arm := minf(18.0, rect.size.y * 0.2)
	for corner: Array in [[Vector2(rect.end.x, rect.position.y), Vector2(-1, 1)], [Vector2(rect.position.x, rect.end.y), Vector2(1, -1)]]:
		var at: Vector2 = corner[0]
		var dir: Vector2 = corner[1]
		ci.draw_polyline(PackedVector2Array([at + Vector2(dir.x * arm, 0), at, at + Vector2(0, dir.y * arm)]), bright, 3.0, true)


## Обычная кнопка: панель и подпись по центру (шрифт по высоте, но чтобы влезла в ширину).
static func button(ci: CanvasItem, rect: Rect2, label: String, edge: Color, glow := 0.0) -> void:
	panel(ci, rect, edge, glow)
	var size := clampi(int(minf(rect.size.y * 0.32, rect.size.x / maxf(1.0, label.length()) * 1.3)), 14, 48)
	Glyph.text_center(ci, rect.get_center().x, rect.get_center().y + size * 0.35, label, size, Color.WHITE)


## Сдвиг позиции: двойная стрелка в сторону dir и подпись под ней.
static func shift(ci: CanvasItem, rect: Rect2, label: String, dir: float, edge: Color, glow := 0.0) -> void:
	panel(ci, rect, edge, glow)
	var c := rect.get_center() - Vector2(0, rect.size.y * 0.08)
	for i in 2:
		var tip := c + Vector2(dir * (8.0 + i * 26.0), 0)
		ci.draw_polyline(PackedVector2Array([tip + Vector2(-dir * 20, -26), tip, tip + Vector2(-dir * 20, 26)]),
			Color(NEON, 0.55 + 0.45 * i), 6.0, true)
	Glyph.text_center(ci, rect.get_center().x, rect.end.y - 26, label, 22, Color(Color.WHITE, 0.8))


## Струна-кнопка. s: string, name, note (звучит сейчас, может быть пусто), edge, glow (вспышка удара),
## amount (бенд, 0…BEND_MAX), apex (x, где палец взял струну, или −1), wobble (вибрато 0…1),
## shake (дрожь от удара 0…1), meter (видимость шкалы бенда 0…1), t (время, с).
static func string_button(ci: CanvasItem, rect: Rect2, s: Dictionary) -> void:
	panel(ci, rect, s["edge"], float(s["glow"]) * 0.6)
	var meter := Rect2(rect.end.x - 30, rect.position.y + 16, 12, rect.size.y - 32)
	var x0 := rect.position.x + 18
	var x1 := meter.position.x - 40
	var y := rect.position.y + rect.size.y * STRING_AT
	var amount := float(s["amount"])
	var wobble := float(s["wobble"])
	var shake := float(s["shake"])
	var t := float(s["t"])
	var apex := 0.5 if float(s["apex"]) < 0.0 else clampf((float(s["apex"]) - x0) / (x1 - x0), 0.2, 0.8)
	var bow := rect.size.y * BOW * amount / Tuning.BEND_MAX
	var points := PackedVector2Array()
	var steps := 48
	for i in steps + 1:
		var u := float(i) / steps
		# выгиб бенда: от стоек к пальцу, вершина там, где палец
		var lift := sin(PI * 0.5 * (u / apex if u < apex else (1.0 - u) / (1.0 - apex)))
		var ends := sin(PI * u)
		var dy := -bow * lift
		dy += shake * float(SHAKE["amp"]) * ends * sin(u * TAU * float(SHAKE["waves"]) - t * float(SHAKE["speed"]))
		dy += wobble * float(RIPPLE["amp"]) * ends * sin(u * TAU * float(RIPPLE["waves"]) - t * float(RIPPLE["speed"]))
		points.append(Vector2(lerpf(x0, x1, u), y + dy))
	var heat := clampf(maxf(amount / 0.5, wobble), 0.0, 1.0)
	var ink := NEON.lerp(HOT, heat)
	var width := float(STRINGS[s["string"]])
	var energy := maxf(maxf(shake, heat), float(s["glow"]))
	ci.draw_polyline(points, Color(ink, 0.15 + 0.4 * energy), width * 3.0 + 6.0, true)
	ci.draw_polyline(points, Color.WHITE.lerp(ink, 0.4), width, true)
	for x in [x0, x1]:
		ci.draw_line(Vector2(x, y - 13), Vector2(x, y + 13), IDLE.lightened(0.2), 4.0, true)
	if float(s["apex"]) >= 0.0:
		var tip := Vector2(lerpf(x0, x1, apex), y - bow)
		ci.draw_circle(tip, 16.0, Color(HOT, 0.25), true, -1.0, true)
		ci.draw_circle(tip, 7.0, HOT, true, -1.0, true)
	Glyph.text(ci, rect.position + Vector2(18, 32), String(s["name"]), 20, Color(Color.WHITE, 0.75))
	if not String(s["note"]).is_empty():
		var size := 24
		var w := Glyph.TITLE.get_string_size(String(s["note"]), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		Glyph.title(ci, Vector2(x1 - w, rect.position.y + 34), String(s["note"]), size, Color.WHITE.lerp(HOT, heat))
	_bend_meter(ci, meter, amount, float(s["meter"]))


## Шкала бенда: снизу вверх до Tuning.BEND_MAX, деления — полтона, тон, полтора; заполнена до силы бенда.
static func _bend_meter(ci: CanvasItem, rect: Rect2, amount: float, alpha: float) -> void:
	if alpha <= 0.01:
		return
	ci.draw_rect(rect, Color(IDLE, 0.35 * alpha), false, 2.0)
	var fill := rect.size.y * amount / Tuning.BEND_MAX
	ci.draw_rect(Rect2(rect.position.x, rect.end.y - fill, rect.size.x, fill), Color(HOT, alpha))
	for mark: float in BEND_MARKS:
		var y := rect.end.y - rect.size.y * mark / Tuning.BEND_MAX
		var reached := amount >= mark - 0.05
		ci.draw_line(Vector2(rect.position.x - 6, y), Vector2(rect.end.x, y), Color(Color.WHITE, 0.5 * alpha), 2.0)
		Glyph.text(ci, Vector2(rect.position.x - 24, y + 6), String(BEND_MARKS[mark]), 14,
			Color(HOT.lightened(0.4) if reached else Color.WHITE, alpha * (1.0 if reached else 0.55)))


## Гриф из кнопок ладов. cells — {fret → Rect2}. s: held (лад → true), cued (лады подсказки), pulse (0…1),
## ringing (струна → {fret, shake}), dots [{fret, string, ink}], slides [{from, to, string, age}],
## fingers [Vector2], t (время, с).
static func neck(ci: CanvasItem, cells: Dictionary, s: Dictionary) -> void:
	var frets: Array = cells.keys()
	var first: Rect2 = cells[frets.front()]
	var last: Rect2 = cells[frets.back()]
	var whole := Rect2(first.position, Vector2(last.end.x - first.position.x, first.size.y))
	panel(ci, whole, IDLE)
	var held: Dictionary = s["held"]
	var cued: Array = s["cued"]
	for fret: String in frets:
		var cell: Rect2 = cells[fret]
		var inner := cell.grow(-7.0)
		if held.has(fret):
			ci.draw_rect(inner, Color(NEON, 0.22))
			ci.draw_rect(inner, NEON, false, 3.0)
		elif cued.has(fret):
			ci.draw_rect(inner, Color(GOLD, 0.25 * float(s["pulse"])))
			ci.draw_rect(inner, Color(GOLD, 0.5 + 0.5 * float(s["pulse"])), false, 4.0)
		Glyph.title_center(ci, cell.get_center().x, cell.end.y - 22, fret, 38, Color.WHITE if held.has(fret) else Color(Color.WHITE, 0.8))
	# порожек у начала грифа и лады в промежутках между кнопками
	ci.draw_line(Vector2(whole.position.x + 7, whole.position.y + 10), Vector2(whole.position.x + 7, whole.end.y - 10),
		IDLE.lightened(0.4), 6.0)
	for i in range(1, frets.size()):
		var x := ((cells[frets[i - 1]] as Rect2).end.x + (cells[frets[i]] as Rect2).position.x) * 0.5
		ci.draw_line(Vector2(x, whole.position.y + 10), Vector2(x, whole.end.y - 10), Color(NEON, 0.18), 10.0)
		ci.draw_line(Vector2(x, whole.position.y + 10), Vector2(x, whole.end.y - 10), NEON.darkened(0.25), 3.0)
	# струны поперёк: звенящая светится и дрожит от своего лада до конца грифа (к струнам-кнопкам)
	var ringing: Dictionary = s["ringing"]
	for string: String in NECK_ROWS:
		var y := _neck_y(whole, string)
		var width := float(STRINGS[string]) * 0.8
		ci.draw_line(Vector2(whole.position.x + 7, y), Vector2(whole.end.x, y), Color(IDLE.lightened(0.15), 0.8), width, true)
		if not ringing.has(string) or not cells.has(ringing[string]["fret"]):
			continue
		var from := (cells[ringing[string]["fret"]] as Rect2).get_center().x
		var shake := float(ringing[string]["shake"])
		var points := PackedVector2Array()
		for i in 33:
			var u := i / 32.0
			var wave := shake * 4.0 * sin(PI * u) * sin(u * TAU * 6.0 - float(s["t"]) * 70.0)
			points.append(Vector2(lerpf(from, whole.end.x, u), y + wave))
		ci.draw_polyline(points, Color(NEON, 0.3), width * 3.0 + 4.0, true)
		ci.draw_polyline(points, NEON.lightened(0.5), width, true)
	for dot: Dictionary in s["dots"]:
		if cells.has(dot["fret"]):
			var at := Vector2((cells[dot["fret"]] as Rect2).get_center().x, _neck_y(whole, String(dot["string"])))
			ci.draw_circle(at, 12.0, Color(dot["ink"] as Color, 0.3), true, -1.0, true)
			ci.draw_circle(at, 7.0, dot["ink"], true, -1.0, true)
	for slide: Dictionary in s["slides"]:
		_slide_trail(ci, cells, whole, slide)
	for finger: Vector2 in s["fingers"]:
		if whole.has_point(finger):
			ci.draw_arc(finger, 30.0, 0.0, TAU, 32, Color(NEON, 0.5), 3.0, true)


## След слайда: огонёк бежит по струне от старого лада к новому, хвост гаснет.
static func _slide_trail(ci: CanvasItem, cells: Dictionary, whole: Rect2, slide: Dictionary) -> void:
	if not cells.has(slide["from"]) or not cells.has(slide["to"]):
		return
	var age := float(slide["age"])
	var fade := 1.0 - clampf((age - SLIDE_RUN) / SLIDE_FADE, 0.0, 1.0)
	var y := _neck_y(whole, String(slide["string"]))
	var a := Vector2((cells[slide["from"]] as Rect2).get_center().x, y)
	var b := Vector2((cells[slide["to"]] as Rect2).get_center().x, y)
	var head := a.lerp(b, ease(clampf(age / SLIDE_RUN, 0.0, 1.0), 0.4))
	var parts := 12
	for i in parts:
		var p0 := a.lerp(head, float(i) / parts)
		var p1 := a.lerp(head, float(i + 1) / parts)
		ci.draw_line(p0, p1, Color(HOT, fade * float(i + 1) / parts), 8.0, true)
	ci.draw_circle(head, 13.0 * fade + 1.0, Color(HOT, 0.35 * fade), true, -1.0, true)
	ci.draw_circle(head, 7.0, Color(Color.WHITE, fade), true, -1.0, true)


static func _neck_y(whole: Rect2, string: String) -> float:
	return whole.position.y + whole.size.y * float(NECK_ROWS[string])


static func _outline(rect: Rect2) -> PackedVector2Array:
	var cut := minf(CUT, minf(rect.size.x, rect.size.y) * 0.25)
	var p := rect.position
	var e := rect.end
	return PackedVector2Array([Vector2(p.x + cut, p.y), Vector2(e.x, p.y), Vector2(e.x, e.y - cut), Vector2(e.x - cut, e.y),
		Vector2(p.x, e.y), Vector2(p.x, p.y + cut)])
