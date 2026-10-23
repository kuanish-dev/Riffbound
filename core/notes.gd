class_name Notes
## Ноты гитары. Лады — четыре пальца в позиции руки (FRETS: «1»…«4»), струн три (STRINGS).
## Как на настоящей гитаре, на струне звучит верхний из зажатых ладов; без ладов удар — глушняк
## (мёртвый звук, в табах «x»). Высоту лада на струне даёт строй (Tuning).

const FRETS := ["1", "2", "3", "4"]
const STRINGS := ["low", "mid", "high"]
const MUTE := "X"

const STRING_NAMES := {"low": "нижняя", "mid": "средняя", "high": "верхняя"}


## Звучащий лад по зажатым (словарь лад → true): верхний из них, или глушняк.
static func from_frets(held: Dictionary) -> String:
	var top := MUTE
	for fret: String in FRETS:
		if held.get(fret, false):
			top = fret
	return top


## Лады ноты: у лада — он сам, у глушняка — ничего.
static func parts(id: String) -> Array:
	return [] if id == MUTE else [id]


static func title(id: String) -> String:
	return "глушняк" if id == MUTE else "лад %s" % id
