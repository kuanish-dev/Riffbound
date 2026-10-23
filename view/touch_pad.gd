class_name TouchPad
extends Node
## Сенсорное управление. Пальцы превращаются в те же действия ввода, что и клавиши (InputConfig),
## поэтому гитара, песни и джем ничего не знают о сенсоре. Кнопки режима — buttons(state):
## - hold — держится пальцем (лады, бенд); скольжение пальца на соседний лад сначала жмёт новый,
##   потом отпускает старый — получается легато, как на грифе;
## - tap — срабатывает при касании и когда палец въезжает в кнопку: удар по струне (проведи через
##   струны сверху вниз — бой), позиция, кнопки меню и джема;
## - row — строка меню: касание выбирает песню, повторное — запускает.
## Включается на сенсорных устройствах или флагом --touch (мышь тогда работает как палец).

const PAD := Rect2(20, 520, 1240, 190)
const MENU_ROWS := 6
## Кнопки, которые есть при игре на гитаре (песня и джем). Струны — столбиком справа на всю высоту от
## дорожки до низа, в порядке дорожки (верхняя сверху), с широкими промежутками, чтобы палец не задевал
## соседнюю; бой — провести пальцем сверху вниз. Лады, бенд и позиция — внизу слева, под дорожкой.
const GUITAR := [
	{"kind": "hold", "action": "fret_1", "fret": "1", "label": "1", "rect": Rect2(20, 520, 152, 190)},
	{"kind": "hold", "action": "fret_2", "fret": "2", "label": "2", "rect": Rect2(182, 520, 152, 190)},
	{"kind": "hold", "action": "fret_3", "fret": "3", "label": "3", "rect": Rect2(344, 520, 152, 190)},
	{"kind": "hold", "action": "fret_4", "fret": "4", "label": "4", "rect": Rect2(506, 520, 152, 190)},
	{"kind": "hold", "action": "bend", "bend": true, "label": "бенд", "rect": Rect2(676, 520, 304, 90)},
	{"kind": "tap", "action": "position_down", "label": "← поз", "rect": Rect2(676, 620, 146, 90)},
	{"kind": "tap", "action": "position_up", "label": "поз →", "rect": Rect2(834, 620, 146, 90)},
	{"kind": "tap", "action": "strike_high", "string": "high", "label": "верхняя", "rect": Rect2(996, 262, 264, 140)},
	{"kind": "tap", "action": "strike_mid", "string": "mid", "label": "средняя", "rect": Rect2(996, 416, 264, 140)},
	{"kind": "tap", "action": "strike_low", "string": "low", "label": "нижняя", "rect": Rect2(996, 570, 264, 140)},
]
const BACK := {"kind": "tap", "action": "quit", "label": "← меню", "rect": Rect2(1160, 8, 110, 38)}
## Кнопки режима сверх гитары.
const EXTRA := {
	"menu": [
		{"kind": "tap", "action": "start", "label": "Играть", "rect": Rect2(20, 520, 610, 190)},
		{"kind": "tap", "action": "jam", "label": "Джем", "rect": Rect2(650, 520, 610, 190)},
	],
	"results": [
		{"kind": "tap", "action": "start", "label": "Ещё раз", "rect": Rect2(20, 520, 610, 190)},
		{"kind": "tap", "action": "quit", "label": "К песням", "rect": Rect2(650, 520, 610, 190)},
	],
	"song": [BACK],
	"jam": [
		BACK,
		{"kind": "tap", "action": "record", "label": "● Запись", "rect": Rect2(300, 62, 190, 40)},
		{"kind": "tap", "action": "undo_layer", "label": "Стереть слой", "rect": Rect2(498, 62, 190, 40)},
		{"kind": "tap", "action": "save_song", "label": "Луп → песня", "rect": Rect2(300, 108, 190, 40)},
		{"kind": "tap", "action": "export_midi", "label": "В MIDI", "rect": Rect2(498, 108, 190, 40)},
		{"kind": "tap", "action": "key_down", "label": "Тон −", "rect": Rect2(300, 154, 92, 40)},
		{"kind": "tap", "action": "key_up", "label": "Тон +", "rect": Rect2(398, 154, 92, 40)},
		{"kind": "tap", "action": "scale", "label": "Гамма", "rect": Rect2(498, 154, 190, 40)},
		{"kind": "tap", "action": "backing", "label": "Подложка", "rect": Rect2(300, 200, 190, 40)},
		{"kind": "tap", "action": "tap_tempo", "label": "Тап-темп", "rect": Rect2(498, 200, 190, 40)},
	],
}

var active := false
## Куда уходят действия: (action, pressed). По умолчанию — в Input, как от клавиатуры; тесты подменяют.
var sink: Callable = _to_input
var _touches := {}                  ## палец → кнопка под ним (или пусто)
var _holds := {}                    ## действие hold → сколько пальцев держат


static func buttons(state: String) -> Array:
	var out: Array = []
	if state in ["song", "jam"]:
		out.append_array(GUITAR)
	out.append_array(EXTRA.get(state, []))
	if state == "menu":
		out.append_array(menu_rows())
	return out


## Строки списка песен (их же рисует Hud): {kind: row, index, rect}.
static func menu_rows() -> Array:
	var rect := Layout.HIGHWAY
	var count := Songs.all().size()
	var first := clampi(Game.menu_index - 2, 0, maxi(0, count - MENU_ROWS))
	var out: Array = []
	for i in range(first, mini(count, first + MENU_ROWS)):
		out.append({"kind": "row", "index": i,
			"rect": Rect2(rect.position.x + 10, rect.position.y + 32 + (i - first) * 33, rect.size.x - 20, 30)})
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
	if Game.menu_index == int(button["index"]):
		_begin_tap({"action": "start"})
	else:
		Game.menu_index = int(button["index"])


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
