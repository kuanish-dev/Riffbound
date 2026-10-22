class_name Hud
extends Node2D
## Интерфейс. Посередине — дорожка-таб: три струны (верхняя сверху), ноты песни едут справа к линии
## удара с номером лада, легато (h/p), бендом (b) и полосой удержания. Над ней — сцена (StageView),
## под ней — лады, струны, бенд и позиция. Меню — список песен с рекордами, итог — после песни,
## джем — строй, карта грифа и лупер. Всплывающие сообщения — toast.

const PLAYED_MAX := 48
const TOAST_TIME := 3.5
const GOLD := Color(1.0, 0.82, 0.3)
const RED := Color(1.0, 0.38, 0.35)
const PANEL := Color(0.075, 0.065, 0.11)
const DIM := Color(0.68, 0.66, 0.76)
const STRING_LINE := Color(0.78, 0.74, 0.66, 0.45)
const LANE := {"high": -1.0, "mid": 0.0, "low": 1.0}   ## струна на дорожке, в шагах LANE_GAP
const NOTE_R := 15.0
const LABELS_W := 100.0                                ## слева на дорожке — подписи струн
## Подсказки внизу по режиму; {offset} — задержка удара в мс.
const FOOTER := {
	"menu": ["↑ ↓ — выбрать песню   Enter — играть   Tab — джем   Esc — выход",
		"A S D F — лады (держать), J K L — удар по струне, пробел — бенд, Q/E — позиция руки"],
	"results": ["Enter — ещё раз   Esc — к песням",
		"A S D F — лады (держать), J K L — удар по струне, пробел — бенд, Q/E — позиция руки"],
	"song": ["Держи лад — нота тянется. Лад выше, пока звенит, — хаммер-он; сними верхний — пулл-офф. Пробел — бенд",
		"Q/E — позиция   [ ] — задержка удара {offset} мс   Esc — к песням"],
	"jam": ["R — записать луп   Backspace — стереть слой   Enter — последний слой в песни   − — удалить свою песню",
		"M — экспорт слоёв в MIDI (Документы/Riffbound)   Esc — к песням"],
}

var _played: Array[Dictionary] = []    ## джем: {note, string, t, legato}
var _strike_flash := {}                ## струна → секунды с удара
var _toast := {}                       ## {text, t}


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
	for key: String in _strike_flash:
		_strike_flash[key] = float(_strike_flash[key]) + delta
	if not _toast.is_empty():
		_toast["t"] = float(_toast["t"]) + delta
	queue_redraw()


func _draw() -> void:
	call("_draw_top_" + Game.state)
	call("_draw_highway_" + Game.state)
	if Game.state == "jam":
		_draw_map()
		_draw_loop()
	if Game.touch:
		_draw_touch()
	else:
		_draw_controls()
		_draw_footer()
	_draw_toast()


# --- верхняя полоса ---------------------------------------------------------

func _draw_top_menu() -> void:
	_top_panel()
	Glyph.text(self, Vector2(20, 36), "RIFFBOUND", 24, GOLD)
	Glyph.text(self, Vector2(170, 35), "симулятор гитары на клавиатуре", 18, DIM)


func _draw_top_song() -> void:
	var performance := Game.performance
	_top_panel()
	Glyph.text(self, Vector2(20, 35), String(performance.song.get("name", "")), 22, Color.WHITE)
	var progress := clampf(Game.conductor.now() / maxf(performance.end_time, 0.001), 0.0, 1.0)
	var bar := Rect2(260, 20, 300, 14)
	draw_rect(bar, Color(0.18, 0.16, 0.24))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), Color(0.85, 0.85, 0.95))
	Glyph.text(self, Vector2(600, 35), "СЧЁТ %d" % performance.score, 22, Color.WHITE)
	var mult := performance.multiplier()
	Glyph.text(self, Vector2(800, 35), "СЕРИЯ %d  ×%d" % [performance.streak, mult], 20, GOLD if mult > 1 else DIM)
	Glyph.text(self, Vector2(1040, 35), "НОТ %d%%" % roundi(performance.accuracy() * 100.0), 20, DIM)


func _draw_top_results() -> void:
	_draw_top_song()


func _draw_top_jam() -> void:
	var tuning := Game.tuning
	_top_panel()
	Glyph.text(self, Vector2(20, 35), "ДЖЕМ", 22, GOLD)
	var backing: String = Synth.BACKINGS[Synth.backing_index(Game.jam_backing)]["name"]
	Glyph.text(self, Vector2(110, 35), "%s   ·   подложка: %s   ·   позиция %d" % [tuning.title(), backing, tuning.position],
		20, Color.WHITE)
	if not Game.touch:
		Glyph.text(self, Vector2(860, 34), "Z/X тональность · C гамма · V подложка · Q/E позиция", 14, DIM)


func _top_panel() -> void:
	draw_rect(Rect2(0, 0, Layout.SCREEN.x, Layout.TOP_H), PANEL)


# --- дорожка ----------------------------------------------------------------

func _slot_x(slot: float, slot_now: float) -> float:
	return Layout.HIT_X + (slot - slot_now) * Layout.SLOT_PX


func _lane_y(string: String) -> float:
	return Layout.HIGHWAY.get_center().y + float(LANE.get(string, 0.0)) * Layout.LANE_GAP


## Струны, такты и линия удара — общие для песни и джема.
func _draw_strings(slot_now: float) -> void:
	var rect := Layout.HIGHWAY
	draw_rect(rect, PANEL)
	var first := floori(slot_now - (Layout.HIT_X - rect.position.x) / Layout.SLOT_PX)
	var last := ceili(slot_now + (rect.end.x - Layout.HIT_X) / Layout.SLOT_PX)
	for s in range(first, last + 1):
		var x := _slot_x(s, slot_now)
		if x < rect.position.x + LABELS_W or x > rect.end.x - 2:
			continue
		var bar := posmod(s, Timing.SLOTS_PER_BAR) == 0
		var beat := posmod(s, Timing.SLOTS_PER_BEAT) == 0
		if bar or beat:
			draw_line(Vector2(x, rect.position.y + 12), Vector2(x, rect.end.y - 12), Color(1, 1, 1, 0.22 if bar else 0.07), 2.0 if bar else 1.0)
	for string: String in Notes.STRINGS:
		var y := _lane_y(string)
		# нижняя струна толще, как на гитаре
		draw_line(Vector2(rect.position.x + LABELS_W, y), Vector2(rect.end.x, y), STRING_LINE, 3.0 - Notes.STRINGS.find(string) * 0.5)
		Glyph.text(self, Vector2(rect.position.x + 10, y + 7), InputConfig.key_label(InputConfig.strike_action(string)), 20, Color.WHITE)
		Glyph.text(self, Vector2(rect.position.x + 30, y + 6), String(Notes.STRING_NAMES[string]), 12, DIM)
	draw_line(Vector2(Layout.HIT_X, rect.position.y + 8), Vector2(Layout.HIT_X, rect.end.y - 8), Color(1, 1, 1, 0.85), 3.0)


func _draw_highway_song() -> void:
	var performance := Game.performance
	var slot_now := Game.conductor.player_time() / Timing.SLOT_LEN
	var rect := Layout.HIGHWAY
	_draw_strings(slot_now)
	var previous := {}                    ## струна → прошлая нота (для дуги легато)
	var last_pos := -1
	for note in performance.notes:
		var string := String(note["string"])
		var x := _slot_x(float(note["slot"]), slot_now)
		var end_x := _slot_x(float(note["slot"]) + float(note["len"]), slot_now) - 8.0
		var y := _lane_y(string)
		var visible := end_x > rect.position.x + LABELS_W and x < rect.end.x + NOTE_R
		var pos := int(note["pos"])
		if visible and pos != last_pos and last_pos >= 0 and x > rect.position.x + LABELS_W:
			draw_dashed_line(Vector2(x - NOTE_R - 6, rect.position.y + 6), Vector2(x - NOTE_R - 6, rect.end.y - 6), GOLD, 2.0, 6.0)
			Glyph.text(self, Vector2(x - NOTE_R - 2, rect.position.y + 18), "позиция %d" % pos, 13, GOLD)
		last_pos = pos
		if visible and not (note["state"] == "hit" and end_x < Layout.HIT_X):
			var ink := _note_ink(note)
			if int(note["len"]) > 1:
				draw_line(Vector2(maxf(x, Layout.HIT_X if note["state"] == "hit" else x), y), Vector2(end_x, y), Color(ink, 0.55), 8.0, true)
			if note["legato"] and previous.has(string):
				var from := _slot_x(float(previous[string]["slot"]), slot_now)
				draw_arc(Vector2((from + x) * 0.5, y - NOTE_R), (x - from) * 0.5, PI, TAU, 16, Color(ink, 0.7), 2.0, true)
				Glyph.text_center(self, x, y - NOTE_R - 6, String(note["tech"]), 14, ink)
			if note["bend"]:
				draw_line(Vector2(x + 10, y - 6), Vector2(x + 22, y - 26), ink, 2.0, true)
				draw_line(Vector2(x + 22, y - 26), Vector2(x + 14, y - 22), ink, 2.0, true)
				draw_line(Vector2(x + 22, y - 26), Vector2(x + 22, y - 17), ink, 2.0, true)
			if not (note["state"] == "hit" and x < Layout.HIT_X):
				Glyph.note(self, Vector2(x, y), String(note["fret"]), NOTE_R, ink)
		previous[string] = note
	# подсказка: следующей ноте нужна другая позиция руки
	var next := performance.next_note()
	if not next.is_empty() and int(next["pos"]) != Game.tuning.position:
		var keys := InputConfig.key_label("position_up" if int(next["pos"]) > Game.tuning.position else "position_down")
		Glyph.text(self, Vector2(Layout.HIT_X + 14, rect.end.y - 12), "%s → позиция %d" % [keys, int(next["pos"])], 18, GOLD)


func _note_ink(note: Dictionary) -> Color:
	if note["state"] == "hit":
		return GOLD
	if note["state"] == "miss":
		return RED
	return Glyph.INK


func _draw_highway_jam() -> void:
	var slot_now := Game.conductor.player_time() / Timing.SLOT_LEN
	_draw_strings(slot_now)
	for item in _played:
		var x := _slot_x(float(item["t"]) / Timing.SLOT_LEN, slot_now)
		if x < Layout.HIGHWAY.position.x + LABELS_W:
			continue
		Glyph.note(self, Vector2(x, _lane_y(String(item["string"]))), String(item["note"]), NOTE_R * (0.7 if item["legato"] else 1.0))


func _draw_highway_menu() -> void:
	var rect := Layout.HIGHWAY
	var songs := Songs.all()
	draw_rect(rect, PANEL)
	Glyph.text(self, rect.position + Vector2(16, 24), "ПЕСНИ" + ("  ·  коснись песни, ещё раз — играть" if Game.touch else ""), 16, DIM)
	for item: Dictionary in TouchPad.menu_rows():
		var i := int(item["index"])
		var song: Dictionary = songs[i]
		var row: Rect2 = item["rect"]
		var selected := i == Game.menu_index
		draw_rect(row, Color(0.24, 0.22, 0.36) if selected else Color(0.12, 0.11, 0.17))
		if selected:
			draw_rect(row, GOLD, false, 2.0)
		var mine := String(song["id"]).begins_with("my_")
		var level := "своя" if mine else "сложность %d" % int(song["level"])
		Glyph.text(self, row.position + Vector2(12, 21), String(song["name"]), 18, GOLD if mine else Color.WHITE)
		Glyph.text(self, row.position + Vector2(230, 20), level, 14, DIM)
		Glyph.text(self, row.position + Vector2(360, 20), String(song["text"]), 14, DIM)
		var best := Songs.best(String(song["id"]))
		_draw_stars(row.position + Vector2(row.size.x - 220, 15), int(best.get("stars", 0)))
		if not best.is_empty():
			Glyph.text(self, row.position + Vector2(row.size.x - 120, 20), "%d" % int(best["score"]), 15, DIM)


func _draw_highway_results() -> void:
	var rect := Layout.HIGHWAY
	var result := Game.last_result
	var performance := Game.performance
	draw_rect(rect, PANEL)
	Glyph.text_center(self, 640, rect.position.y + 44, "Песня «%s» сыграна" % performance.song.get("name", ""), 26, Color.WHITE)
	_draw_stars(Vector2(640 - 62, rect.position.y + 70), int(result.get("stars", 0)), 12.0)
	Glyph.text_center(self, 640, rect.position.y + 128, "Счёт %d%s" % [int(result.get("score", 0)),
		"   ·   новый рекорд!" if result.get("record", false) else ""], 22, GOLD)
	Glyph.text_center(self, 640, rect.position.y + 164, "Нот %d из %d (%d%%)   ·   лучшая серия %d   ·   техника %d из %d   ·   не тех нот %d" % [
		performance.hits, performance.notes.size(), roundi(performance.accuracy() * 100.0), performance.best_streak,
		performance.techs, performance.tech_total, performance.wrongs], 17, Color.WHITE)
	Glyph.text_center(self, 640, rect.position.y + 212, "Enter — ещё раз     Esc — к песням", 20, DIM)


## Сенсорные кнопки режима (TouchPad): лады светятся, пока зажаты, струны вспыхивают от удара.
func _draw_touch() -> void:
	var fretboard := Game.fretboard
	for button: Dictionary in TouchPad.buttons(Game.state):
		if button["kind"] == "row":
			continue
		var rect: Rect2 = button["rect"]
		var glow := 0.0
		if button.has("fret"):
			glow = 1.0 if fretboard.held.has(button["fret"]) else 0.0
		elif button.has("string"):
			glow = clampf(1.0 - float(_strike_flash.get(button["string"], 9.0)) / 0.15, 0.0, 1.0)
		elif button.has("bend"):
			glow = 1.0 if fretboard.bending else 0.0
		draw_rect(rect, Color(0.16, 0.15, 0.22).lerp(Color(0.85, 0.85, 0.92), glow))
		draw_rect(rect, GOLD if button.has("bend") else Color(0.6, 0.58, 0.7), false, 2.0)
		var size := clampi(int(rect.size.y * 0.32), 14, 44)
		var ink := Color.WHITE.lerp(Color(0.05, 0.05, 0.08), glow)
		Glyph.text_center(self, rect.get_center().x, rect.get_center().y + size * 0.35, String(button["label"]), size, ink)


func _draw_stars(origin: Vector2, count: int, r := 7.0) -> void:
	for i in SongJudge.STARS.size():
		var center := origin + Vector2(i * (r * 2.6), 0)
		draw_circle(center, r, GOLD if i < count else Color(0.3, 0.28, 0.36), true, -1.0, true)


# --- лады, струны, бенд -----------------------------------------------------

func _draw_controls() -> void:
	var fretboard := Game.fretboard
	var y := Layout.CONTROLS_Y
	for i in Notes.FRETS.size():
		var fret: String = Notes.FRETS[i]
		var cell := Rect2(20 + i * 56, y, 50, 40)
		var on := fretboard.held.has(fret)
		draw_rect(cell, Color(0.85, 0.85, 0.92) if on else Color(0.16, 0.15, 0.22))
		draw_rect(cell, Color(0.85, 0.85, 0.92), false, 2.0)
		var ink := Color(0.05, 0.05, 0.08) if on else Color.WHITE
		Glyph.text(self, cell.position + Vector2(8, 27), InputConfig.key_label(InputConfig.fret_action(fret)), 20, ink)
		Glyph.text(self, cell.position + Vector2(32, 26), fret, 14, ink)
	for i in Notes.STRINGS.size():
		var string: String = Notes.STRINGS[i]
		var cell := Rect2(256 + i * 92, y, 86, 40)
		var glow := clampf(1.0 - float(_strike_flash.get(string, 9.0)) / 0.15, 0.0, 1.0)
		draw_rect(cell, Color(0.2, 0.2, 0.27).lerp(Color.WHITE, glow))
		draw_rect(cell, Color(0.8, 0.8, 0.9), false, 2.0)
		var ink := Color(0.9, 0.9, 1.0).lerp(Color(0.05, 0.05, 0.08), glow)
		Glyph.text(self, cell.position + Vector2(8, 27), InputConfig.key_label(InputConfig.strike_action(string)), 20, ink)
		Glyph.text(self, cell.position + Vector2(26, 25), String(Notes.STRING_NAMES[string]), 13, ink)
	var bend := Rect2(538, y, 100, 40)
	draw_rect(bend, GOLD.darkened(0.2) if fretboard.bending else Color(0.2, 0.2, 0.27))
	draw_rect(bend, GOLD, false, 2.0)
	Glyph.text(self, bend.position + Vector2(8, 26), "%s бенд" % InputConfig.key_label("bend"), 14,
		Color(0.05, 0.05, 0.08) if fretboard.bending else GOLD)
	var note := Notes.from_frets(fretboard.held)
	Glyph.text(self, Vector2(654, y + 26), "%s · позиция %d (Q/E)" % [Notes.title(note), Game.tuning.position], 15, Color.WHITE)


# --- джем: карта грифа и лупер ----------------------------------------------

## Что звучит на каждой кнопке: строки — струны (верхняя сверху), столбцы — лады.
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
		Glyph.text(self, Vector2(map.position.x + 12, top + cell.y * 0.5 + 6), "%s  %s" % [
			InputConfig.key_label(InputConfig.strike_action(string)), Notes.STRING_NAMES[string]], 16, DIM)
		for c in Notes.FRETS.size():
			var fret: String = Notes.FRETS[c]
			var box := Rect2(map.position.x + (c + 1) * cell.x + 4, top + 4, cell.x - 8, cell.y - 8)
			var lit: bool = not ringing.is_empty() and ringing["note"] == fret
			draw_rect(box, Color(0.4, 0.36, 0.2) if lit else Color(0.14, 0.13, 0.2))
			draw_rect(box, GOLD if lit else Color(0.5, 0.48, 0.6), false, 2.0)
			var midi := tuning.midi(fret, string)
			Glyph.text_center(self, box.get_center().x, box.position.y + box.size.y * 0.5 + 2, Tuning.note_name(midi), 20, Color.WHITE)
			var finger := fret if Game.touch else InputConfig.key_label(InputConfig.fret_action(fret))
			Glyph.text_center(self, box.get_center().x, box.end.y - 6, "%s · %s" % [finger, Tuning.solfege(midi)], 12, DIM)


func _draw_loop() -> void:
	var looper := Game.looper
	var now := Game.conductor.now()
	var rect := Layout.LOOP_BAR_TOUCH if Game.touch else Layout.LOOP_BAR
	draw_rect(rect, PANEL)
	var bar := Rect2(rect.position + Vector2(110, 12), Vector2(rect.size.x - 124, 16))
	draw_rect(bar, Color(0.18, 0.16, 0.24))
	for i in range(1, Synth.BARS):
		var x := bar.position.x + bar.size.x * i / Synth.BARS
		draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Color(1, 1, 1, 0.25), 1.0)
	if looper.recording:
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * looper.progress(now), bar.size.y)), Color(1, 0.3, 0.3, 0.7))
	var head := bar.position.x + bar.size.x * fposmod(now, looper.length) / looper.length
	draw_line(Vector2(head, bar.position.y - 4), Vector2(head, bar.end.y + 4), Color.WHITE, 2.0)
	var label := "● ЗАПИСЬ" if looper.recording else "ЛУП %d/%d" % [looper.layers.size(), Looper.MAX_LAYERS]
	Glyph.text(self, rect.position + Vector2(10, 26), label, 16, RED if looper.recording else DIM)


# --- подсказки --------------------------------------------------------------

func _draw_footer() -> void:
	var lines: Array = FOOTER.get(Game.state, [])
	var offset := "%+d" % roundi(Game.conductor.input_offset * 1000.0)
	for i in lines.size():
		Glyph.text(self, Vector2(20, Layout.FOOTER_Y + i * 24), String(lines[i]).format({"offset": offset}), 15, DIM)


func _draw_toast() -> void:
	if _toast.is_empty() or float(_toast["t"]) > TOAST_TIME:
		return
	var alpha := clampf((TOAST_TIME - float(_toast["t"])) / 0.5, 0.0, 1.0)
	var width := ThemeDB.fallback_font.get_string_size(String(_toast["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	var box := Rect2(640 - width * 0.5 - 14, 62, width + 28, 30)
	draw_rect(box, Color(0.05, 0.04, 0.08, 0.85 * alpha))
	Glyph.text_center(self, 640, 83, String(_toast["text"]), 17, Color(1, 1, 1, alpha))
