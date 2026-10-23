class_name TapTempo
extends RefCounted

const MIN_TAPS := 6
const RESET_AFTER := 2.0
const DONE_AFTER := 1.2
const BPM_RANGE := Vector2(50.0, 220.0)

var music_from := 0.0
var _taps: Array[float] = []


static func bpm_of(taps: Array[float]) -> float:
	return 60.0 * (taps.size() - 1) / maxf(taps.back() - taps.front(), 0.001)


func clear() -> void:
	_taps.clear()


func tap(clock: float, music_position: float) -> void:
	if not _taps.is_empty() and clock - _taps.back() > RESET_AFTER:
		_taps.clear()
	if _taps.is_empty():
		music_from = music_position
	_taps.append(clock)


func status() -> String:
	if _taps.size() < 2:
		return ""
	var left := MIN_TAPS - _taps.size()
	var hint := " · ещё %d" % left if left > 0 else " · хватит, жди"
	return "Тап-темп: %d bpm%s" % [roundi(bpm_of(_taps)), hint]


func take(clock: float) -> float:
	if _taps.is_empty() or clock - _taps.back() < DONE_AFTER:
		return 0.0
	var enough := _taps.size() >= MIN_TAPS
	var bpm := snappedf(clampf(bpm_of(_taps), BPM_RANGE.x, BPM_RANGE.y), 0.1)
	_taps.clear()
	return bpm if enough else 0.0
