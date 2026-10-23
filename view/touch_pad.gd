class_name TouchPad
extends Node
## Сенсорное управление. Пальцы превращаются в те же действия ввода, что и клавиши (InputConfig),
## поэтому гитара, песни и джем ничего не знают о сенсоре. Кнопки режима — buttons(state):
## - hold — держится пальцем (лады, бенд); скольжение пальца на соседний лад сначала жмёт новый,
##   потом отпускает старый — получается легато, как на грифе;
## - tap — срабатывает при касании и когда палец въезжает в кнопку: удар по струне (проведи через
##   струны сверху вниз — бой), позиция, кнопки меню и джема;
## - row — строка списка (песни в меню, гитары в магазине — lists()): в меню касание сразу запускает песню
##   («instant»), в магазине — выбирает, повторное — «start».
## «lit» — флаг Game, при котором кнопка подсвечена (переключатель вроде метронома); «needs» — кнопка нужна,
## только если песне нужно это умение (Game.needs: бенд, сдвиг позиции); «more» — кнопка панели «Ещё» в джеме
## (видна, пока Game.more). Так на экране только то, что нужно сейчас.
## Включается на сенсорных устройствах или флагом --touch (мышь тогда работает как палец).

const PAD := Rect2(20, 520, 1240, 190)
signal row_selected                 ## касание выбрало другую строку списка (для звука)

## Кнопки, которые есть при игре на гитаре (песня и джем). Струны — столбиком справа на всю высоту от
## дорожки до низа, в порядке дорожки (верхняя сверху), с широкими промежутками, чтобы палец не задевал
## соседнюю; бой — провести пальцем сверху вниз. Лады, бенд и позиция — внизу слева, под дорожкой.
const GUITAR := [
	{"kind": "hold", "action": "fret_1", "fret": "1", "label": "1", "rect": Rect2(20, 520, 152, 190)},
	{"kind": "hold", "action": "fret_2", "fret": "2", "label": "2", "rect": Rect2(182, 520, 152, 190)},
	{"kind": "hold", "action": "fret_3", "fret": "3", "label": "3", "rect": Rect2(344, 520, 152, 190)},
	{"kind": "hold", "action": "fret_4", "fret": "4", "label": "4", "rect": Rect2(506, 520, 152, 190)},
	{"kind": "hold", "action": "bend", "bend": true, "needs": "bend", "label": "бенд", "rect": Rect2(676, 520, 304, 90)},
	{"kind": "tap", "action": "position_down", "needs": "positions", "label": "← поз", "rect": Rect2(676, 620, 146, 90)},
	{"kind": "tap", "action": "position_up", "needs": "positions", "label": "поз →", "rect": Rect2(834, 620, 146, 90)},
	{"kind": "tap", "action": "strike_high", "string": "high", "label": "верхняя", "rect": Rect2(996, 262, 264, 140)},
	{"kind": "tap", "action": "strike_mid", "string": "mid", "label": "средняя", "rect": Rect2(996, 416, 264, 140)},
	{"kind": "tap", "action": "strike_low", "string": "low", "label": "нижняя", "rect": Rect2(996, 570, 264, 140)},
]
const BACK := {"kind": "tap", "action": "quit", "label": "← меню", "rect": Rect2(1090, 2, 186, 64)}
## Прокрутка списков на сенсоре: те же действия, что стрелки на клавиатуре (выбор едет, список за ним).
const SCROLL := {
	"menu": [{"kind": "tap", "action": "menu_up", "label": "▲", "rect": Rect2(1124, 262, 136, 130)},
		{"kind": "tap", "action": "menu_down", "label": "▼", "rect": Rect2(1124, 402, 136, 130)}],
	"shop": [{"kind": "tap", "action": "menu_up", "label": "▲", "rect": Rect2(500, 262, 120, 112)},
		{"kind": "tap", "action": "menu_down", "label": "▼", "rect": Rect2(500, 386, 120, 112)}],
}
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
## Куда уходят действия: (action, pressed). По умолчанию — в Input, как от клавиатуры; тесты подменяют.
var sink: Callable = _to_input
var _touches := {}                  ## палец → кнопка под ним (или пусто)
var _holds := {}                    ## действие hold → сколько пальцев держат


static func buttons(state: String) -> Array:
	var out: Array = []
	for button: Dictionary in (GUITAR if state in ["song", "jam"] else []) + EXTRA.get(state, []) + SCROLL.get(state, []):
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


## Видимые строки списка режима (их же рисует Hud): {kind: row, index, field, rect}. Список едет за выбором.
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
	@warning_ignore("integer_division")
	var first := clampi(int(Game.get(list["field"])) - rows / 3, 0, maxi(0, count - rows))
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


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_move(touch.index, button_at(Game.state, touch.position))
		else:
			_move(touch.index, {})
			_touches.erase(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		var button := button_at(Game.state, drag.position)
		if button != _touches.get(drag.index, {}):
			_move(drag.index, button)
	else:
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()


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
	sink.call(String(button["action"]), true)
	sink.call(String(button["action"]), false)


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
		sink.call(action, true)
	elif before > 0 and after == 0:
		sink.call(action, false)


func _to_input(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
