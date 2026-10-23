class_name TouchButtons
extends RefCounted

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
const EXTRA := {
	"menu": [
		{"kind": "tap", "action": "easier", "label": "‹", "rect": Rect2(420, 0, 120, 64)},
		{"kind": "tap", "action": "harder", "label": "›", "rect": Rect2(740, 0, 120, 64)},
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


static func buttons(state: String) -> Array:
	var out: Array = []
	for button: Dictionary in (GUITAR if state in ["song", "jam"] else []) + EXTRA.get(state, []):
		if shown(button):
			out.append(button)
	out.append_array(TouchLists.rows(state))
	return out


static func shown(button: Dictionary) -> bool:
	if button.has("needs") and not bool(Game.needs.get(button["needs"], true)):
		return false
	return not button.get("more", false) or Game.more


static func at(state: String, pos: Vector2) -> Dictionary:
	for button: Dictionary in buttons(state):
		if (button["rect"] as Rect2).has_point(pos):
			return button
	return {}


static func center(action: String) -> Vector2:
	for button: Dictionary in GUITAR:
		if button["action"] == action:
			return (button["rect"] as Rect2).get_center()
	return Vector2.ZERO
