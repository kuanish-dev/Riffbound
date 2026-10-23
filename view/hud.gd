class_name Hud
extends Node2D
## Интерфейс — минимальный: на экране только то, что нужно сейчас. Посередине — дорожка-таб: три струны
## (верхняя сверху), ноты едут справа к белой линии; на ноте — что зажать (на клавиатуре — клавиша лада,
## на сенсоре — цифра кнопки). Перед нотой мигают ровно те клавиши/кнопки, которые надо нажать (_cue).
## Над дорожкой — сцена (StageView), под ней на клавиатуре — клавиши ладов, струн и бенда (бенд — если нужен
## в песне), внизу — одна строка подсказки (HINTS). Меню — названия песен и звёзды, итог — звёзды, счёт,
## монеты и стиль, джем — лупер и музыка, остальное — в панели «Ещё» (Game.more). Всплывающие сообщения — toast.
## Струна после удара дрожит (VIBRATO), свечение рисует FxLayer.

const PLAYED_MAX := 48
const TOAST_TIME := 3.0
const GOLD := Color(1.0, 0.82, 0.3)
const RED := Color(1.0, 0.38, 0.35)
const PANEL := Color(0.075, 0.065, 0.11)
const DIM := Color(0.68, 0.66, 0.76)
const KEY_FILL := Color(0.16, 0.15, 0.22)
const KEY_ON := Color(0.85, 0.85, 0.92)
const STRING_LINE := Color(0.78, 0.74, 0.66, 0.45)
const LANE := {"high": -1.0, "mid": 0.0, "low": 1.0}   ## струна на дорожке, в шагах LANE_GAP
const NOTE_R := 16.0
const LABELS_W := 60.0                                 ## слева на дорожке — клавиши струн
const LOOKAHEAD := 1.2                                 ## за сколько секунд до ноты мигать «что жать»
## Дрожь струны после удара: амплитуда (px), сколько секунд гаснет, волн на длину струны, скорость.
const VIBRATO := {"amp": 5.0, "decay": 0.9, "waves": 9.0, "speed": 70.0}
## Одна строка подсказки клавиш по режиму («jam+» — с открытой панелью «Ещё»). На сенсоре не нужна — кнопки подписаны.
const HINTS := {
	"menu": "↑ ↓  выбрать      Enter  играть      Tab  джем      G  магазин",
	"song": "Esc  выйти",
	"results": "Enter  ещё раз      Esc  к песням",
	"jam": "R  запись      V  музыка      Tab  ещё      Esc  выйти",
	"jam+": "Backspace стереть   Enter в песню   M MIDI   Z/X тон   C гамма   N метроном   T тап   Q/E позиция",
	"shop": "↑ ↓  выбрать      Enter  взять      P  послушать      Esc  назад",
}
## Клавиши под дорожкой: группа, подпись под ней. Бенд — только если нужен.
const KEY_SIZE := Vector2(62, 58)
const KEY_GAP := 8.0
const GROUP_GAP := 44.0

var _played: Array[Dictionary] = []    ## джем: {note, string, t, legato}
var _strike_flash := {}                ## струна → секунды с удара
var _toast := {}                       ## {text, t}
var _t := 0.0


func reset() -> void:
	_played.clear()


func toast(text: String) -> void:
	_toast = {"text": text, "t": 0.0}


func on_fact(_kind: String, _data: Dictionary) -> void:
	pass


func on_voiced(_note: String, string: String, corrected: bool) -> void:
	if not corrected:
		_strike_flash[string] = 0.0


## Сыгранная нота — на дорожку джема по своему времени.
func played_note(note: String, string: String, time: float, legato: bool) -> void:
	if Game.state != "jam":
		return
	_played.append({"note": note, "string": string, "t": time, "legato": legato})
	if _played.size() > PLAYED_MAX:
		_played.pop_front()


func _process(delta: float) -> void:
	_t += delta
	for key: String in _strike_flash:
		_strike_flash[key] = float(_strike_flash[key]) + delta
	if not _toast.is_empty():
		_toast["t"] = float(_toast["t"]) + delta
	queue_redraw()


func _draw() -> void:
	call("_draw_top_" + Game.state)
	call("_draw_highway_" + Game.state)
	if Game.state == "jam":
		if Game.more and not Game.touch:
			_draw_map()
		_draw_loop()
	if Game.touch:
		_draw_touch()
	else:
		_draw_controls()
		_draw_hint()
	_draw_toast()


# --- что жать ---------------------------------------------------------------

## Ближайшая нота песни (с аккордом на том же месте): {frets, strings, bend, power 0…1} или пусто.
## Легато бьётся без удара — струна не мигает; глушняк — без лада.
func _cue() -> Dictionary:
	if Game.state != "song":
		return {}
	var now := Game.conductor.player_time()
	var cue := {"frets": [], "strings": [], "bend": false, "power": 0.0}
	var slot := -1
	for note: Dictionary in Game.performance.notes:
		if note["state"] != "wait":
			continue
		var ahead := float(note["t"]) - now
		if (slot >= 0 and int(note["slot"]) != slot) or ahead > LOOKAHEAD:
			break
		slot = int(note["slot"])
		if note["fret"] != Notes.MUTE:
			cue["frets"].append(note["fret"])
		if not note["legato"]:
			cue["strings"].append(note["string"])
		cue["bend"] = cue["bend"] or note["bend"]
		cue["power"] = 1.0 - clampf(ahead / LOOKAHEAD, 0.0, 1.0)
	return cue if slot >= 0 else {}


## Насколько мигать подсказкой: сильнее, чем ближе нота.
func _cue_glow(cue: Dictionary) -> float:
	return float(cue.get("power", 0.0)) * (0.65 + 0.35 * sin(_t * 14.0))


# --- верхняя полоса ---------------------------------------------------------

func _draw_top_menu() -> void:
	_top_panel()
	Glyph.neon_left(self, Vector2(20, 37), "RIFFBOUND", 26, GOLD)
	_draw_coins(Vector2(1110, 35))


func _draw_top_shop() -> void:
	_top_panel()
	Glyph.neon_left(self, Vector2(20, 37), "МАГАЗИН", 24, GOLD)
	_draw_coins(Vector2(820, 35))


func _draw_coins(pos: Vector2) -> void:
	draw_circle(pos + Vector2(8, -7), 9, GOLD, true, -1.0, true)
	draw_circle(pos + Vector2(8, -7), 6, GOLD.darkened(0.25), false, 1.5, true)
	Glyph.text(self, pos + Vector2(24, 0), "%d" % Shop.coins, 21, GOLD)


## Песня: название и счёт, под полосой — тонкая линия прогресса.
func _draw_top_song() -> void:
	var performance := Game.performance
	_top_panel()
	Glyph.title(self, Vector2(20, 36), String(performance.song.get("name", "")), 21, Color.WHITE)
	var score := "%d" % performance.score
	var right := 1070.0 if Game.touch else 1250.0
	Glyph.title(self, Vector2(right - Glyph.TITLE.get_string_size(score, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x, 38), score, 26, GOLD)
	var progress := clampf(Game.conductor.now() / maxf(performance.end_time, 0.001), 0.0, 1.0)
	draw_rect(Rect2(0, Layout.TOP_H - 3, Layout.SCREEN.x * progress, 3), GOLD)


func _draw_top_results() -> void:
	_draw_top_song()


func _draw_top_jam() -> void:
	_top_panel()
	Glyph.neon_left(self, Vector2(20, 36), "ДЖЕМ", 22, GOLD)
	var music := Game.music
	var bpm := float(music.get("bpm", 0.0))
	Glyph.text(self, Vector2(110, 34), "%s · %s%s" % [music.get("name", ""), "%d bpm" % roundi(bpm) if bpm > 0.0 else "темп? (Тап)",
		" + метроном" if Game.metronome else ""], 18, Color.WHITE)
	if Game.more:
		Glyph.text(self, Vector2(20, Layout.TOP_H + 26), Game.tuning.title(), 17, GOLD)


func _top_panel() -> void:
	draw_rect(Rect2(0, 0, Layout.SCREEN.x, Layout.TOP_H), PANEL)


# --- дорожка ----------------------------------------------------------------

static func slot_x(slot: float, slot_now: float) -> float:
	return Layout.HIT_X + (slot - slot_now) * Layout.SLOT_PX


## Дорожка: на сенсоре в песне и джеме уже — справа от неё столбик струн (TouchPad).
func _highway() -> Rect2:
	return Layout.HIGHWAY_TOUCH if Game.touch and Game.state in ["song", "jam"] else Layout.HIGHWAY


static func lane_y(string: String) -> float:
	return Layout.HIGHWAY.get_center().y + float(LANE.get(string, 0.0)) * Layout.LANE_GAP


## Что написать на ноте: на клавиатуре — клавишу лада, на сенсоре — цифру кнопки.
func _fret_label(fret: String) -> String:
	if Game.touch or fret == Notes.MUTE:
		return fret
	return InputConfig.key_label(InputConfig.fret_action(fret))


## Струны, такты и линия удара — общие для песни и джема.
func _draw_strings(slot_now: float) -> void:
	var rect := _highway()
	draw_rect(rect, PANEL)
	var first := floori(slot_now - (Layout.HIT_X - rect.position.x) / Layout.SLOT_PX)
	var last := ceili(slot_now + (rect.end.x - Layout.HIT_X) / Layout.SLOT_PX)
	for s in range(first, last + 1):
		var x := slot_x(s, slot_now)
		if x < rect.position.x + LABELS_W or x > rect.end.x - 2:
			continue
		var bar := posmod(s, Timing.SLOTS_PER_BAR) == 0
		var beat := posmod(s, Timing.SLOTS_PER_BEAT) == 0
		if bar or beat:
			draw_line(Vector2(x, rect.position.y + 12), Vector2(x, rect.end.y - 12), Color(1, 1, 1, 0.16 if bar else 0.05), 2.0 if bar else 1.0)
	var cue := _cue()
	for string: String in Notes.STRINGS:
		var y := lane_y(string)
		# нижняя струна толще, как на гитаре
		_draw_string_line(string, rect.position.x + LABELS_W, rect.end.x, y, 3.0 - Notes.STRINGS.find(string) * 0.5)
		if not Game.touch:
			var lit: bool = cue.get("strings", []).has(string)
			Glyph.title(self, Vector2(rect.position.x + 16, y + 9), InputConfig.key_label(InputConfig.strike_action(string)), 24,
				Color.WHITE.lerp(GOLD, _cue_glow(cue)) if lit else DIM)
	draw_line(Vector2(Layout.HIT_X, rect.position.y + 8), Vector2(Layout.HIT_X, rect.end.y - 8), Color(1, 1, 1, 0.9), 4.0)


## Струна от x0 до x1: после удара дрожит стоячей волной (концы на месте), дрожь гаснет за VIBRATO.decay.
func _draw_string_line(string: String, x0: float, x1: float, y: float, width: float) -> void:
	var t := float(_strike_flash.get(string, 9.0))
	var amp := float(VIBRATO["amp"]) * maxf(0.0, 1.0 - t / float(VIBRATO["decay"]))
	if amp <= 0.05:
		draw_line(Vector2(x0, y), Vector2(x1, y), STRING_LINE, width)
		return
	var points := PackedVector2Array()
	var steps := 96
	for i in steps + 1:
		var k := float(i) / steps
		var wave := sin(k * TAU * float(VIBRATO["waves"]) - t * float(VIBRATO["speed"]))
		points.append(Vector2(lerpf(x0, x1, k), y + amp * sin(k * PI) * wave))
	draw_polyline(points, STRING_LINE.lerp(Color(1.0, 0.92, 0.7, 0.9), amp / float(VIBRATO["amp"])), width, true)


func _draw_highway_song() -> void:
	var performance := Game.performance
	var slot_now := Game.conductor.player_time() / Timing.slot_len()
	var rect := _highway()
	_draw_strings(slot_now)
	var previous := {}                    ## струна → прошлая нота (для дуги легато)
	var last_pos := -1
	for note in performance.notes:
		var string := String(note["string"])
		var x := slot_x(float(note["slot"]), slot_now)
		var end_x := slot_x(float(note["slot"]) + float(note["len"]), slot_now) - 8.0
		var y := lane_y(string)
		var visible := end_x > rect.position.x + LABELS_W and x < rect.end.x + NOTE_R
		var pos := int(note["pos"])
		if visible and pos != last_pos and last_pos >= 0 and x > rect.position.x + LABELS_W:
			draw_dashed_line(Vector2(x - NOTE_R - 6, rect.position.y + 6), Vector2(x - NOTE_R - 6, rect.end.y - 6), GOLD, 2.0, 6.0)
		last_pos = pos
		if visible and not (note["state"] == "hit" and end_x < Layout.HIT_X):
			var ink := _note_ink(note)
			if int(note["len"]) > 1:
				draw_line(Vector2(maxf(x, Layout.HIT_X if note["state"] == "hit" else x), y), Vector2(end_x, y), Color(ink, 0.55), 8.0, true)
			if note["legato"] and previous.has(string):
				var from := slot_x(float(previous[string]["slot"]), slot_now)
				draw_arc(Vector2((from + x) * 0.5, y - NOTE_R), (x - from) * 0.5, PI, TAU, 16, Color(ink, 0.7), 2.0, true)
			if note["bend"]:
				draw_line(Vector2(x + 10, y - 6), Vector2(x + 22, y - 26), ink, 2.0, true)
				draw_line(Vector2(x + 22, y - 26), Vector2(x + 14, y - 22), ink, 2.0, true)
				draw_line(Vector2(x + 22, y - 26), Vector2(x + 22, y - 17), ink, 2.0, true)
			if not (note["state"] == "hit" and x < Layout.HIT_X):
				Glyph.note(self, Vector2(x, y), _fret_label(String(note["fret"])), NOTE_R, ink)
		previous[string] = note
	# подсказка: следующей ноте нужна другая позиция руки
	var next := performance.next_note()
	if not next.is_empty() and int(next["pos"]) != Game.tuning.position:
		var up := int(next["pos"]) > Game.tuning.position
		var key := "поз →" if Game.touch and up else "← поз" if Game.touch else InputConfig.key_label("position_up" if up else "position_down")
		Glyph.neon(self, Vector2(Layout.HIT_X + 120, rect.end.y - 22), "жми %s" % key, 22, GOLD)


func _note_ink(note: Dictionary) -> Color:
	if note["state"] == "hit":
		return GOLD
	if note["state"] == "miss":
		return RED
	return Glyph.INK


func _draw_highway_jam() -> void:
	var slot_now := Game.conductor.player_time() / Timing.slot_len()
	_draw_strings(slot_now)
	for item in _played:
		var x := slot_x(float(item["t"]) / Timing.slot_len(), slot_now)
		if x < _highway().position.x + LABELS_W or x > _highway().end.x:
			continue
		Glyph.note(self, Vector2(x, lane_y(String(item["string"]))), _fret_label(String(item["note"])),
			NOTE_R * (0.7 if item["legato"] else 1.0))


## Меню: названия песен и звёзды; у выбранной — треугольник «играть».
func _draw_highway_menu() -> void:
	var look := TouchPad.list_layout("menu")
	var rect: Rect2 = look["rect"]
	var songs := Songs.all()
	draw_rect(rect, PANEL)
	if float(look["top"]) > 0.0:
		Glyph.text(self, rect.position + Vector2(16, 24), "ВЫБЕРИ ПЕСНЮ", 16, DIM)
	for item: Dictionary in TouchPad.list_rows("menu"):
		var i := int(item["index"])
		var song: Dictionary = songs[i]
		var row: Rect2 = item["rect"]
		var selected := i == Game.menu_index
		var big := row.size.y / 30.0                     ## во сколько раз строка крупнее строки клавиатуры
		draw_rect(row, Color(0.24, 0.22, 0.36) if selected else Color(0.12, 0.11, 0.17))
		if selected:
			draw_rect(row, GOLD, false, 2.0)
		var mine := String(song["id"]).begins_with("my_")
		var size := int(clampf(19.0 * big * 0.55, 19.0, 34.0))
		Glyph.text(self, row.position + Vector2(14 * big * 0.6, row.size.y * 0.5 + size * 0.36), String(song["name"]), size,
			GOLD if mine else Color.WHITE)
		var r := clampf(7.0 * big * 0.5, 7.0, 12.0)
		_draw_stars(row.position + Vector2(row.size.x - 70 - r * 13.0, row.size.y * 0.5), int(Songs.best(String(song["id"])).get("stars", 0)), r)
		if selected or Game.touch:
			var c := row.position + Vector2(row.size.x - 34, row.size.y * 0.5)
			var k := clampf(big * 0.6, 1.0, 2.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -9) * k, c + Vector2(9, 0) * k, c + Vector2(-7, 9) * k]),
				GOLD if selected else DIM)


## Итог: звёзды, счёт, монеты, стиль.
func _draw_highway_results() -> void:
	var rect := Layout.HIGHWAY
	var result := Game.last_result
	draw_rect(rect, PANEL)
	Glyph.neon(self, Vector2(640, rect.position.y + 40), String(Game.performance.song.get("name", "")), 28, Color.WHITE)
	_draw_stars(Vector2(640 - 78, rect.position.y + 92), int(result.get("stars", 0)), 15.0)
	Glyph.title_center(self, 640, rect.position.y + 160, "%d" % int(result.get("score", 0)), 40, GOLD)
	var extra := "+%d монет" % int(result.get("coins", 0))
	if result.get("record", false):
		extra = "новый рекорд!   " + extra
	Glyph.text_center(self, 640, rect.position.y + 200, extra, 20, Color.WHITE)
	var style := String(result.get("style", ""))
	if not style.is_empty():
		var rank: Dictionary = StyleMeter.RANKS[_rank_index(style)]
		Glyph.neon(self, Vector2(1050, rect.position.y + 118), style, 84, rank["tint"], -0.08)


func _rank_index(id: String) -> int:
	for i in StyleMeter.RANKS.size():
		if StyleMeter.RANKS[i]["id"] == id:
			return i
	return 0


## Магазин: список гитар (цвет, имя, цена или «надета») и примерка выбранной справа.
func _draw_highway_shop() -> void:
	var look := TouchPad.list_layout("shop")
	var list: Rect2 = look["rect"]
	draw_rect(list, PANEL)
	if float(look["top"]) > 0.0:
		Glyph.text(self, list.position + Vector2(16, 24), "ГИТАРЫ", 16, DIM)
	for item: Dictionary in TouchPad.list_rows("shop"):
		var i := int(item["index"])
		var skin: Dictionary = Shop.SKINS[i]
		var row: Rect2 = item["rect"]
		var selected := i == Game.shop_index
		var tall := row.size.y > 40.0                    ## на сенсоре: звук — второй строкой под именем
		draw_rect(row, Color(0.24, 0.22, 0.36) if selected else Color(0.12, 0.11, 0.17))
		if selected:
			draw_rect(row, GOLD, false, 2.0)
		var swatch := Rect2(row.position + Vector2(8, row.size.y * 0.5 - (12 if tall else 8)), Vector2.ONE * (24 if tall else 16))
		draw_rect(swatch, skin["body"])
		draw_rect(swatch, skin.get("edge", skin["body"]), false, 2.0)
		var name_x := 44.0 if tall else 34.0
		Glyph.text(self, row.position + Vector2(name_x, row.size.y * 0.5 + (0 if tall else 7)), String(skin["name"]), 23 if tall else 18,
			Color.WHITE)
		var tone := Vector2(name_x, row.size.y * 0.5 + 22) if tall else Vector2(190, 20)
		Glyph.text(self, row.position + tone, String(skin["tone"]["name"]), 15 if tall else 14, DIM)
		var status := _skin_status(skin)
		var status_size := 18 if tall else 15
		Glyph.text(self, row.position + Vector2(row.size.x - 12 - Glyph.width(status[0], status_size), row.size.y * 0.5 + status_size * 0.36),
			status[0], status_size, status[1])
	var rect := Layout.SHOP_PREVIEW
	draw_rect(rect, PANEL)
	var chosen: Dictionary = Shop.SKINS[Game.shop_index]
	var span := GuitarArt.extent(String(chosen["shape"]))
	var size := (rect.size.x - 40.0) / (span.y - span.x)
	GuitarArt.draw(self, chosen, Vector2(rect.position.x + 20.0 - span.x * size, rect.get_center().y + 16.0), 0.0, size)
	Glyph.title(self, rect.position + Vector2(16, 30), String(chosen["name"]), 22, Color.WHITE)
	var status := _skin_status(chosen)
	Glyph.text(self, rect.position + Vector2(rect.size.x - 16 - Glyph.width(status[0], 17), 28), status[0], 17, status[1])


## Что написать про гитару: [текст, цвет] — надета, своя или цена (красная, если монет не хватает).
func _skin_status(skin: Dictionary) -> Array:
	if skin["id"] == Shop.equipped:
		return ["надета", GOLD]
	if Shop.owned.has(skin["id"]):
		return ["своя", Color.WHITE]
	return ["%d монет" % int(skin["price"]), Color.WHITE if Shop.coins >= int(skin["price"]) else RED]


## Сенсорные кнопки режима (TouchPad): лады светятся, пока зажаты, струны вспыхивают от удара, а перед нотой
## мигают золотом те, что надо нажать.
func _draw_touch() -> void:
	var fretboard := Game.fretboard
	var cue := _cue()
	var pulse := _cue_glow(cue)
	for button: Dictionary in TouchPad.buttons(Game.state):
		if button["kind"] == "row":
			continue
		var rect: Rect2 = button["rect"]
		var glow := 0.0
		var cued := false
		if button.has("fret"):
			glow = 1.0 if fretboard.held.has(button["fret"]) else 0.0
			cued = cue.get("frets", []).has(button["fret"])
		elif button.has("string"):
			glow = clampf(1.0 - float(_strike_flash.get(button["string"], 9.0)) / 0.15, 0.0, 1.0)
			cued = cue.get("strings", []).has(button["string"])
		elif button.has("bend"):
			glow = 1.0 if fretboard.bending else 0.0
			cued = cue.get("bend", false)
		elif button.has("lit"):
			glow = 1.0 if Game.get(String(button["lit"])) else 0.0
		var fill := KEY_FILL.lerp(GOLD.darkened(0.35), pulse) if cued else KEY_FILL
		draw_rect(rect, fill.lerp(KEY_ON, glow))
		draw_rect(rect, GOLD if cued else Color(0.6, 0.58, 0.7), false, 5.0 if cued else 2.0)
		# шрифт по высоте кнопки, но чтобы подпись влезла в ширину
		var label := String(button["label"])
		var size := clampi(int(minf(rect.size.y * 0.32, rect.size.x / maxf(1.0, label.length()) * 1.3)), 14, 48)
		var ink := Color.WHITE.lerp(Color(0.05, 0.05, 0.08), glow)
		Glyph.text_center(self, rect.get_center().x, rect.get_center().y + size * 0.35, label, size, ink)


func _draw_stars(origin: Vector2, count: int, r := 7.0) -> void:
	for i in SongJudge.STARS.size():
		var center := origin + Vector2(i * (r * 2.6), 0)
		draw_circle(center, r, GOLD if i < count else Color(0.3, 0.28, 0.36), true, -1.0, true)


# --- клавиши (клавиатура) ---------------------------------------------------

## Клавиши под дорожкой по центру: лады («держи»), струны («бей»), бенд («тяни», если нужен в песне).
## Зажатые светятся, перед нотой нужные мигают золотом.
func _draw_controls() -> void:
	if not Game.state in ["song", "jam"]:
		return
	var fretboard := Game.fretboard
	var cue := _cue()
	var groups: Array = [
		{"caption": "держи", "keys": Notes.FRETS.map(func(f: String) -> Dictionary: return {
			"label": InputConfig.key_label(InputConfig.fret_action(f)), "on": fretboard.held.has(f),
			"cued": cue.get("frets", []).has(f), "w": KEY_SIZE.x})},
		{"caption": "бей", "keys": Notes.STRINGS.map(func(s: String) -> Dictionary: return {
			"label": InputConfig.key_label(InputConfig.strike_action(s)),
			"on": float(_strike_flash.get(s, 9.0)) < 0.15, "cued": cue.get("strings", []).has(s), "w": KEY_SIZE.x})},
	]
	if Game.needs.get("bend", true):
		groups.append({"caption": "тяни", "keys": [{"label": "Пробел", "on": fretboard.bending, "cued": cue.get("bend", false),
			"w": KEY_SIZE.x * 2.2}]})
	var widths: Array = groups.map(func(g: Dictionary) -> float:
		return (g["keys"] as Array).reduce(func(acc: float, k: Dictionary) -> float: return acc + float(k["w"]) + KEY_GAP, -KEY_GAP))
	var total: float = widths.reduce(func(a: float, b: float) -> float: return a + b, 0.0) + GROUP_GAP * (groups.size() - 1)
	var x := (Layout.SCREEN.x - total) * 0.5
	var pulse := _cue_glow(cue)
	for g in groups.size():
		var start := x
		for key: Dictionary in groups[g]["keys"]:
			var cell := Rect2(x, Layout.CONTROLS_Y, float(key["w"]), KEY_SIZE.y)
			var fill := KEY_FILL.lerp(GOLD.darkened(0.35), pulse) if key["cued"] else KEY_FILL
			draw_rect(cell, KEY_ON if key["on"] else fill)
			draw_rect(cell, GOLD if key["cued"] else Color(0.6, 0.58, 0.7), false, 4.0 if key["cued"] else 2.0)
			Glyph.title_center(self, cell.get_center().x, cell.get_center().y + 10, String(key["label"]),
				26 if String(key["label"]).length() == 1 else 18, Color(0.05, 0.05, 0.08) if key["on"] else Color.WHITE)
			x += float(key["w"]) + KEY_GAP
		Glyph.text_center(self, start + float(widths[g]) * 0.5, Layout.CONTROLS_Y + KEY_SIZE.y + 24, String(groups[g]["caption"]), 16, DIM)
		x += GROUP_GAP - KEY_GAP


# --- джем: карта грифа и лупер ----------------------------------------------

## Что звучит на каждой клавише (панель «Ещё»): строки — струны (верхняя сверху), столбцы — лады.
func _draw_map() -> void:
	var tuning := Game.tuning
	var fretboard := Game.fretboard
	var map := Layout.MAP
	draw_rect(map, Color(PANEL, 0.92))
	var strings := Notes.STRINGS.duplicate()
	strings.reverse()
	var cell := Vector2(map.size.x / (Notes.FRETS.size() + 1.0), map.size.y / strings.size())
	for r in strings.size():
		var string: String = strings[r]
		var top := map.position.y + r * cell.y
		var ringing: Dictionary = fretboard.ringing.get(string, {})
		Glyph.text(self, Vector2(map.position.x + 12, top + cell.y * 0.5 + 6), InputConfig.key_label(InputConfig.strike_action(string)),
			18, DIM)
		for c in Notes.FRETS.size():
			var fret: String = Notes.FRETS[c]
			var box := Rect2(map.position.x + (c + 1) * cell.x + 4, top + 4, cell.x - 8, cell.y - 8)
			var lit: bool = not ringing.is_empty() and ringing["note"] == fret
			draw_rect(box, Color(0.4, 0.36, 0.2) if lit else Color(0.14, 0.13, 0.2))
			draw_rect(box, GOLD if lit else Color(0.5, 0.48, 0.6), false, 2.0)
			var midi := tuning.midi(fret, string)
			Glyph.text_center(self, box.get_center().x, box.position.y + box.size.y * 0.5 + 2, Tuning.note_name(midi), 20, Color.WHITE)
			Glyph.text_center(self, box.get_center().x, box.end.y - 6, "%s · %s" % [InputConfig.key_label(InputConfig.fret_action(fret)),
				Tuning.solfege(midi)], 12, DIM)


func _draw_loop() -> void:
	var looper := Game.looper
	var now := Game.conductor.now()
	var rect := Layout.LOOP_BAR
	draw_rect(rect, PANEL)
	var bar := Rect2(rect.position + Vector2(110, 12), Vector2(rect.size.x - 124, 16))
	draw_rect(bar, Color(0.18, 0.16, 0.24))
	for i in range(1, Looper.BARS):
		var x := bar.position.x + bar.size.x * i / Looper.BARS
		draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Color(1, 1, 1, 0.25), 1.0)
	if looper.recording:
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * looper.progress(now), bar.size.y)), Color(1, 0.3, 0.3, 0.7))
	var head := bar.position.x + bar.size.x * fposmod(now, looper.length) / looper.length
	draw_line(Vector2(head, bar.position.y - 4), Vector2(head, bar.end.y + 4), Color.WHITE, 2.0)
	var label := "● ЗАПИСЬ" if looper.recording else "ЛУП %d/%d" % [looper.layers.size(), Looper.MAX_LAYERS]
	Glyph.text(self, rect.position + Vector2(10, 26), label, 16, RED if looper.recording else DIM)


# --- подсказки --------------------------------------------------------------

## Одна строка подсказки клавиш (только на клавиатуре).
func _draw_hint() -> void:
	var key := Game.state + ("+" if Game.more and HINTS.has(Game.state + "+") else "")
	Glyph.text_center(self, 640, Layout.HINT_Y, String(HINTS.get(key, "")), 17, DIM)


func _draw_toast() -> void:
	if _toast.is_empty() or float(_toast["t"]) > TOAST_TIME:
		return
	var alpha := clampf((TOAST_TIME - float(_toast["t"])) / 0.5, 0.0, 1.0)
	var width := Glyph.width(String(_toast["text"]), 17)
	var box := Rect2(640 - width * 0.5 - 14, 62, width + 28, 30)
	draw_rect(box, Color(0.05, 0.04, 0.08, 0.85 * alpha))
	Glyph.text_center(self, 640, 83, String(_toast["text"]), 17, Color(1, 1, 1, alpha))
