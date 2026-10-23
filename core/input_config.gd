class_name InputConfig
## Клавиши. Берутся по физическому положению, поэтому работают и в русской раскладке.
## Лады — по номеру пальца (Notes.FRETS): fret_1…fret_4 под A S D F; удары — по струне (Notes.STRINGS) под J K L;
## бенд — пробел, его жмёт большой палец левой руки. «bend_pull» — бенд любой силы (тяга струны пальцем на
## сенсоре): клавиш у него нет, сила — strength действия (доля Tuning.BEND_MAX). «slide» — палец едет по ладам,
## не отрываясь (сенсор держит его на время перехода): смена лада — слайд.

const KEYS := {
	"fret_1": [KEY_A],
	"fret_2": [KEY_S],
	"fret_3": [KEY_D],
	"fret_4": [KEY_F],
	"strike_low": [KEY_J],
	"strike_mid": [KEY_K],
	"strike_high": [KEY_L],
	"bend": [KEY_SPACE],
	"bend_pull": [],
	"slide": [],
	"position_down": [KEY_Q],
	"position_up": [KEY_E],
	"start": [KEY_ENTER],
	"jam": [KEY_TAB],
	"record": [KEY_R],
	"undo_layer": [KEY_BACKSPACE],
	"save_song": [KEY_ENTER],
	"delete_song": [KEY_MINUS],
	"menu_up": [KEY_UP],
	"menu_down": [KEY_DOWN],
	"export_midi": [KEY_M],
	"key_down": [KEY_Z],
	"key_up": [KEY_X],
	"scale": [KEY_C],
	"backing": [KEY_V],
	"tap_tempo": [KEY_T],
	"metronome": [KEY_N],
	"shop": [KEY_G],
	"listen": [KEY_P],
	"offset_down": [KEY_BRACKETLEFT],
	"offset_up": [KEY_BRACKETRIGHT],
	"quit": [KEY_ESCAPE],
}


static func register() -> void:
	for action: String in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key as Key
			InputMap.action_add_event(action, ev)


static func fret_action(fret: String) -> String:
	return "fret_" + fret


static func strike_action(string: String) -> String:
	return "strike_" + string


## Подпись первой клавиши действия для подсказок («A», «J»).
static func key_label(action: String) -> String:
	var keys: Array = KEYS[action]
	return OS.get_keycode_string(keys[0] as Key)
