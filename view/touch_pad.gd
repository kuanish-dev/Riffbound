class_name TouchPad
extends Node
## Сенсорное управление. Пальцы превращаются в те же действия ввода, что и клавиши (InputConfig),
## поэтому гитара, песни и джем ничего не знают о сенсоре. Кнопки режима — buttons(state):
## - hold — держится пальцем (лады); палец едет на соседний лад, не отрываясь, — слайд: на время перехода
##   держится «slide», новый лад жмётся раньше, чем отпускается старый (звук съезжает плавно); второй палец
##   на лад выше — хаммер-он;
## - tap — срабатывает при касании и когда палец въезжает в кнопку: удар по струне (проведи через
##   струны сверху вниз — бой), позиция, кнопки меню и джема. Ударил по струне и, не отпуская, потянул палец
##   вбок — бенд («bend_pull»): дальше BEND_DEAD нота поднимается, и чем дальше тянешь, тем выше (BEND_RANGE —
##   на тон, до Tuning.BEND_MAX); держишь палец на струне и покачиваешь — вибрато; вернул к точке удара или
##   отпустил — струна отпущена; поехал на другую струну — это бой, бенд отпущен;
## - row — строка списка (песни в меню, гитары в магазине — lists()). Список листается пальцем вверх-вниз
##   (Game.scroll); касание без сдвига (меньше SCROLL_SLOP) срабатывает при отпускании: в меню сразу запускает
##   песню («instant»), в магазине — выбирает, повторное — «start».
## «lit» — флаг Game, при котором кнопка подсвечена (переключатель вроде метронома); «needs» — кнопка нужна,
## только если песне нужно это умение (Game.needs: бенд, сдвиг позиции); «more» — кнопка панели «Ещё» в джеме
## (видна, пока Game.more). Так на экране только то, что нужно сейчас.
## Рисует их Hud через PadArt: лады («fret») собираются в гриф, «art» — как рисовать остальные (струна, стрелки
## позиции; нет — обычная панель).
## Включается на сенсорных устройствах или флагом --touch (мышь тогда работает как палец).

signal row_selected                 ## касание выбрало другую строку списка (для звука)
signal slid(from_fret: String, to_fret: String)   ## палец проехал по ладам (для следа слайда)

const SCROLL_SLOP := 14.0           ## палец сдвинулся меньше — касание, больше — прокрутка списка
const BEND_DEAD := 6.0              ## тяга вбок меньше этого — ещё не бенд; мало, чтобы покачивание давало вибрато
const BEND_RANGE := 110.0           ## ещё столько вбок — струна поднята на тон; дальше — до Tuning.BEND_MAX
const BEND_STEP := 0.02             ## сила бенда меняется хотя бы на столько — передаём (не засыпать событиями)
const BEND_SIDEWAYS := 1.5          ## тянуть надо вбок: сдвиг по x больше сдвига по y во столько раз (иначе это бой)

## Кнопки, которые есть при игре на гитаре (песня и джем). Струны — столбиком справа на всю высоту от
## дорожки до низа, в порядке дорожки (верхняя сверху), с широкими промежутками, чтобы палец не задевал
## соседнюю; бой — провести пальцем сверху вниз, бенд — потянуть вбок. Лады и позиция — внизу слева, под дорожкой.
const GUITAR := [
	{"kind": "hold", "action": "fret_1", "fret": "1", "label": "1", "rect": Rect2(20, 520, 152, 190)},
	{"kind": "hold", "action": "fret_2", "fret": "2", "label": "2", "rect": Rect2(182, 520, 152, 190)},
	{"kind": "hold", "action": "fret_3", "fret": "3", "label": "3", "rect": Rect2(344, 520, 152, 190)},
	{"kind": "hold", "action": "fret_4", "fret": "4", "label": "4", "rect": Rect2(506, 520, 152, 190)},
	{"kind": "tap", "art": "shift", "action": "position_down", "needs": "positions", "label": "поз", "dir": -1.0,
		"rect": Rect2(676, 520, 146, 190)},
	{"kind": "tap", "art": "shift", "action": "position_up", "needs": "positions", "label": "поз", "dir": 1.0,
		"rect": Rect2(834, 520, 146, 190)},
	{"kind": "tap", "art": "string", "action": "strike_high", "string": "high", "label": "верхняя", "rect": Rect2(996, 262, 264, 140)},
	{"kind": "tap", "art": "string", "action": "strike_mid", "string": "mid", "label": "средняя", "rect": Rect2(996, 416, 264, 140)},
	{"kind": "tap", "art": "string", "action": "strike_low", "string": "low", "label": "нижняя", "rect": Rect2(996, 570, 264, 140)},
]
const BACK := {"kind": "tap", "action": "quit", "label": "← меню", "rect": Rect2(1090, 2, 186, 64)}
## Кнопки режима сверх гитары.
const EXTRA := {
	"menu": [
		{"kind": "tap", "action": "jam", "label": "Джем", "rect": Rect2(20, 548, 610, 162)},
		{"kind": "tap", "action": "shop", "label": "Магазин", "rect": Rect2(650, 548, 610, 162)},
	],
	"shop": [
		BACK,
		{"kind": "tap", "action": "listen", "label": "Послушать", "rect": Rect2(20, 530, 600, 170)},
		{"kind": "tap", "action": "start", "label": "Купить / надеть", "rect": Rect2(660, 530, 600, 170)},
	],
	"results": [
		{"kind": "tap", "action": "start", "label": "Ещё раз", "rect": Rect2(20, 520, 610, 190)},
		{"kind": "tap", "action": "quit", "label": "К песням", "rect": Rect2(650, 520, 610, 190)},
	],
	"song": [BACK],
	"jam": [
		BACK,
		{"kind": "tap", "action": "record", "label": "● Запись", "rect": Rect2(300, 66, 300, 76)},
		{"kind": "tap", "action": "backing", "label": "Музыка", "rect": Rect2(616, 66, 300, 76)},
		{"kind": "tap", "action": "jam", "label": "Ещё", "lit": "more", "rect": Rect2(932, 66, 200, 76)},
		{"kind": "tap", "action": "undo_layer", "more": true, "label": "Стереть", "rect": Rect2(24, 158, 146, 78)},
		{"kind": "tap", "action": "save_song", "more": true, "label": "В песню", "rect": Rect2(178, 158, 146, 78)},
		{"kind": "tap", "action": "export_midi", "more": true, "label": "MIDI", "rect": Rect2(332, 158, 146, 78)},
		{"kind": "tap", "action": "key_down", "more": true, "label": "Тон −", "rect": Rect2(486, 158, 146, 78)},
		{"kind": "tap", "action": "key_up", "more": true, "label": "Тон +", "rect": Rect2(640, 158, 146, 78)},
		{"kind": "tap", "action": "scale", "more": true, "label": "Гамма", "rect": Rect2(794, 158, 146, 78)},
		{"kind": "tap", "action": "metronome", "more": true, "label": "Метроном", "lit": "metronome",
			"rect": Rect2(948, 158, 146, 78)},
		{"kind": "tap", "action": "tap_tempo", "more": true, "label": "Тап", "rect": Rect2(1102, 158, 154, 78)},
	],
}

var active := false
## Куда уходят действия: (action, pressed, strength). По умолчанию — в Input, как от клавиатуры; тесты подменяют.
var sink: Callable = _to_input
var _touches := {}                  ## палец → кнопка под ним (или пусто)
var _holds := {}                    ## действие hold → сколько пальцев держат
var points := {}                    ## палец → где он сейчас (для показа)
var _press := {}                    ## палец на списке: {row, from, scroll (прокрутка в начале), moved}
var _bends := {}                    ## палец, ударивший по струне: {string, from (точка удара), pos, on (тянет ли), amount}


static func buttons(state: String) -> Array:
	var out: Array = []
	for button: Dictionary in (GUITAR if state in ["song", "jam"] else []) + EXTRA.get(state, []):
		if shown(button):
			out.append(button)
	out.append_array(list_rows(state))
	return out


## Нужна ли кнопка сейчас: умение песне нужно («needs»), панель «Ещё» открыта («more»).
static func shown(button: Dictionary) -> bool:
	if button.has("needs") and not bool(Game.needs.get(button["needs"], true)):
		return false
	return not button.get("more", false) or Game.more


## Списки по строкам: режим → поле Game с выбранным индексом, сколько строк, мгновенно ли касание.
## Раскладка — Layout.LISTS (на клавиатуре и на сенсоре своя).
static func lists() -> Dictionary:
	return {
		"menu": {"field": "menu_index", "count": Songs.all().size(), "instant": true},
		"shop": {"field": "shop_index", "count": Shop.SKINS.size(), "instant": false},
	}


## Раскладка списка режима сейчас: на сенсоре — крупная.
static func list_layout(state: String) -> Dictionary:
	return Layout.LISTS[state]["touch" if Game.touch else "keys"]


## Самая верхняя видимая строка: на сенсоре — прокрутка пальцем (Game.scroll), на клавиатуре — список едет за выбором.
static func first_row(state: String) -> int:
	var list: Dictionary = lists()[state]
	var rows := int(list_layout(state)["rows"])
	var last := maxi(0, int(list["count"]) - rows)
	@warning_ignore("integer_division")
	var follow := int(Game.get(list["field"])) - rows / 3
	return clampi(roundi(float(Game.scroll.get(state, 0.0))) if Game.touch else follow, 0, last)


## Прокрутить список так, чтобы выбранная строка была видна (вход в магазин).
static func reveal(state: String) -> void:
	var list: Dictionary = lists()[state]
	var rows := int(list_layout(state)["rows"])
	var selected := int(Game.get(list["field"]))
	var first := clampi(roundi(float(Game.scroll.get(state, 0.0))), selected - rows + 1, selected)
	Game.scroll[state] = float(clampi(first, 0, maxi(0, int(list["count"]) - rows)))


## Видимые строки списка режима (их же рисует Hud): {kind: row, index, field, rect}.
static func list_rows(state: String) -> Array:
	var list: Dictionary = lists().get(state, {})
	var out: Array = []
	if list.is_empty():
		return out
	var look := list_layout(state)
	var rect: Rect2 = look["rect"]
	var rows := int(look["rows"])
	var step := float(look["row_h"]) + float(look["gap"])
	var count := int(list["count"])
	var first := first_row(state)
	for i in range(first, mini(count, first + rows)):
		out.append({"kind": "row", "index": i, "field": list["field"], "instant": list["instant"],
			"rect": Rect2(rect.position.x + 10, rect.position.y + float(look["top"]) + (i - first) * step, rect.size.x - 20,
				float(look["row_h"]))})
	return out


static func button_at(state: String, pos: Vector2) -> Dictionary:
	for button: Dictionary in buttons(state):
		if (button["rect"] as Rect2).has_point(pos):
			return button
	return {}


## Держит ли сейчас какой-то палец действие hold (для подсветки).
func holding(action: String) -> bool:
	return int(_holds.get(action, 0)) > 0


## Палец, который ударил по струне и, может быть, тянет её: {string, from, pos, on, amount} или пусто.
func pull_of(string: String) -> Dictionary:
	for bend: Dictionary in _bends.values():
		if bend["string"] == string:
			return bend
	return {}


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_press_at(touch.index, touch.position)
		else:
			_lift(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_drag_to(drag.index, drag.position)
	else:
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _press_at(index: int, pos: Vector2) -> void:
	points[index] = pos
	var button := button_at(Game.state, pos)
	if button.get("kind") == "row":
		_press[index] = {"row": button, "from": pos, "scroll": float(Game.scroll.get(Game.state, 0.0)), "moved": false}
		return
	_move(index, button)
	_aim_bend(index, button, pos)


func _drag_to(index: int, pos: Vector2) -> void:
	points[index] = pos
	if _press.has(index):
		_scroll(index, pos)
		return
	var button := button_at(Game.state, pos)
	var old: Dictionary = _touches.get(index, {})
	# тянет струну: выход за кнопку и возврат — не новый удар; переход на другую струну — бой
	var bending: bool = _bends.get(index, {}).get("on", false)
	if button != old and (not bending or button.has("string")):
		var slide := button.has("fret") and old.has("fret")
		if slide:
			sink.call("slide", true, 1.0)
		_move(index, button)
		if slide:
			sink.call("slide", false, 0.0)
			slid.emit(String(old["fret"]), String(button["fret"]))
		if button.has("string"):
			_aim_bend(index, button, pos)
	_track_bend(index, pos)


func _lift(index: int) -> void:
	points.erase(index)
	if _press.has(index):
		if not _press[index]["moved"]:
			_begin_row(_press[index]["row"])
		_press.erase(index)
		return
	_move(index, {})
	_touches.erase(index)
	_release_bend(index)


## Прокрутка списка пальцем: строки едут вслед за ним.
func _scroll(index: int, pos: Vector2) -> void:
	var press: Dictionary = _press[index]
	var dy := pos.y - (press["from"] as Vector2).y
	if not press["moved"] and absf(dy) < SCROLL_SLOP:
		return
	press["moved"] = true
	var look := list_layout(Game.state)
	var rows := int(look["rows"])
	var count := int(lists()[Game.state]["count"])
	Game.scroll[Game.state] = clampf(float(press["scroll"]) - dy / (float(look["row_h"]) + float(look["gap"])),
		0.0, float(maxi(0, count - rows)))


## Удар по струне — отсюда и меряем, на сколько палец тянет вбок.
func _aim_bend(index: int, button: Dictionary, pos: Vector2) -> void:
	_release_bend(index)
	if button.has("string"):
		_bends[index] = {"string": button["string"], "from": pos, "pos": pos, "on": false, "amount": 0.0}


## Тяга пальца вбок от точки удара → сила бенда. Начать тянуть надо вбок (иначе это бой), дальше — как угодно.
func _track_bend(index: int, pos: Vector2) -> void:
	if not _bends.has(index):
		return
	var bend: Dictionary = _bends[index]
	bend["pos"] = pos
	var shift := pos - (bend["from"] as Vector2)
	if not bend["on"]:
		bend["on"] = absf(shift.x) >= BEND_DEAD and absf(shift.x) >= absf(shift.y) * BEND_SIDEWAYS
	if not bend["on"]:
		return
	var amount := clampf((absf(shift.x) - BEND_DEAD) / BEND_RANGE, 0.0, Tuning.BEND_MAX)
	if absf(amount - float(bend["amount"])) >= BEND_STEP or (amount == 0.0) != (float(bend["amount"]) == 0.0):
		bend["amount"] = amount
		sink.call("bend_pull", amount > 0.0, amount / Tuning.BEND_MAX)
	if amount == 0.0:
		bend["on"] = false


func _release_bend(index: int) -> void:
	if float(_bends.get(index, {}).get("amount", 0.0)) > 0.0:
		sink.call("bend_pull", false, 0.0)
	_bends.erase(index)


## Палец перешёл на другую кнопку (или поднят): сначала новая, потом отпускается старая.
func _move(index: int, button: Dictionary) -> void:
	var old: Dictionary = _touches.get(index, {})
	_touches[index] = button
	if not button.is_empty():
		call("_begin_" + String(button["kind"]), button)
	if not old.is_empty() and old["kind"] == "hold":
		_hold(String(old["action"]), -1)


func _begin_hold(button: Dictionary) -> void:
	_hold(String(button["action"]), 1)


func _begin_tap(button: Dictionary) -> void:
	sink.call(String(button["action"]), true, 1.0)
	sink.call(String(button["action"]), false, 0.0)


func _begin_row(button: Dictionary) -> void:
	if int(Game.get(button["field"])) == int(button["index"]) or button["instant"]:
		Game.set(button["field"], int(button["index"]))
		_begin_tap({"action": "start"})
	else:
		Game.set(button["field"], int(button["index"]))
		row_selected.emit()


func _hold(action: String, delta: int) -> void:
	var before := int(_holds.get(action, 0))
	var after := maxi(0, before + delta)
	_holds[action] = after
	if before == 0 and after > 0:
		sink.call(action, true, 1.0)
	elif before > 0 and after == 0:
		sink.call(action, false, 0.0)


func _to_input(action: String, pressed: bool, strength: float) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = strength
	Input.parse_input_event(event)
