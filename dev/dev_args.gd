class_name DevArgs
## Аргументы командной строки после «--»: godot --path . -- --test
##   --test               прогнать тесты логики и выйти (код возврата 0/1)
##   --sim                бот играет все встроенные песни, затем сводка и PASS/FAIL (лучше с --headless --fixed-fps 120)
##   --screenshot=<png>   снять кадр и выйти: --at=<сек> — момент песни или джема (по умолчанию 8),
##                        --autoplay — играет бот, --jam — джем, --menu — меню песен
##   --song=<N>           песня из списка (с 1) для --play и снимка
##   --play               сразу играть песню, без меню
##   --jam                сразу джем
##   --backing=<id>       подложка джема: стиль Backing.STYLES или трек Tracks (rock, funked_up, user:<файл>…)
##   --touch              сенсорное управление на компьютере (мышь — как палец)
##   --gesture=<имя>      снимок с --touch: пальцы делают жест DevTools.GESTURES (bend, vibrato, slide)
##   --metronome          метроном включён с запуска
##   --more               в джеме сразу открыта панель «Ещё»
##   --shop               снимок: магазин гитар; --skin=<N> — какая гитара выбрана (с 0)
##   --tones              замер громкости звука каждой гитары (в окне, динамики молчат) и выйти

static var values: Dictionary = {}


static func parse() -> void:
	values.clear()
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var kv := arg.substr(2).split("=", true, 1)
		values[kv[0]] = kv[1] if kv.size() > 1 else "true"


static func has(key: String) -> bool:
	return values.has(key)


static func get_str(key: String, fallback := "") -> String:
	return values.get(key, fallback)


static func get_int(key: String, fallback := 0) -> int:
	return int(values[key]) if values.has(key) else fallback
