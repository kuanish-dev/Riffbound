class_name Timing

const DEFAULT_BPM := 100.0
const SLOTS_PER_BEAT := 2
const BEATS_PER_BAR := 4
const SLOTS_PER_BAR := SLOTS_PER_BEAT * BEATS_PER_BAR

const JUDGEMENTS := [
	{"id": "perfect", "window": 0.045, "label": "Точно", "score": 100, "tint": Color(1.0, 0.93, 0.45)},
	{"id": "good", "window": 0.095, "label": "Хорошо", "score": 50, "tint": Color(0.65, 0.88, 1.0)},
]
const MISS := {"id": "miss", "label": "Мимо", "score": 0, "tint": Color(1.0, 0.35, 0.35)}

static var bpm := DEFAULT_BPM


static func beat_len() -> float:
	return 60.0 / bpm


static func slot_len() -> float:
	return beat_len() / SLOTS_PER_BEAT


static func bar_len() -> float:
	return beat_len() * BEATS_PER_BAR


static func widest_window() -> float:
	return float(JUDGEMENTS.back()["window"])


static func slot_of(time: float) -> int:
	return roundi(time / slot_len())


static func grade(error: float) -> Dictionary:
	for j: Dictionary in JUDGEMENTS:
		if absf(error) <= float(j["window"]):
			return j
	return MISS


static func judge(time: float) -> Dictionary:
	var slot := slot_of(time)
	var error := time - slot * slot_len()
	return {"slot": slot, "error": error, "judgement": grade(error)}
