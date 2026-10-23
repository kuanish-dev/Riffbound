class_name SongJudge
extends RefCounted

signal fact(kind: String, data: Dictionary)

const TECH_BONUS := 50
const SUSTAIN_POINTS := 20
const STREAK_STEP := 10
const MULT_MAX := 4
const STARS := [0.5, 0.7, 0.85, 0.95, 1.0]
const WRONG_RANGE := 0.3
const TECH_NAMES := {"h": "Хаммер-он!", "p": "Пулл-офф!", "bend": "Бенд!"}
const BEND_COUNTS := 0.5

var song := {}
var notes: Array[Dictionary] = []
var score := 0
var streak := 0
var best_streak := 0
var hits := 0
var misses := 0
var wrongs := 0
var techs := 0
var tech_total := 0
var finished := false
var end_time := 0.0
var _sounding := {}
var _bent := {}
var _last_hit := {}


func start(song_def: Dictionary) -> void:
	song = song_def
	notes = Songs.notes_of(song)
	var tuning := Tuning.new()
	tuning.set_key(int(song["key"]), String(song["scale"]))
	for note in notes:
		_prepare(note, tuning)
	tech_total = notes.filter(func(note: Dictionary) -> bool: return note["legato"] or note["bend"]).size()
	end_time = Songs.end_slot(song) * Timing.slot_len()
	_reset_counters()


func _prepare(note: Dictionary, tuning: Tuning) -> void:
	note["t"] = int(note["slot"]) * Timing.slot_len()
	note["end"] = (int(note["slot"]) + int(note["len"])) * Timing.slot_len()
	tuning.position = int(note["pos"])
	note["midi"] = -1 if note["fret"] == Notes.MUTE else tuning.midi(String(note["fret"]), String(note["string"]))
	note["state"] = "wait"
	note["tech_ok"] = false


func _reset_counters() -> void:
	score = 0
	streak = 0
	best_streak = 0
	hits = 0
	misses = 0
	wrongs = 0
	techs = 0
	finished = false
	_sounding.clear()
	_bent.clear()
	_last_hit.clear()


@warning_ignore("integer_division")
func multiplier() -> int:
	return mini(1 + streak / STREAK_STEP, MULT_MAX)


func accuracy() -> float:
	return float(hits) / (hits + misses) if hits + misses > 0 else 1.0


func stars() -> int:
	var count := 0
	for level: float in STARS:
		if accuracy() >= level - 0.0001:
			count += 1
	return count


func result() -> Dictionary:
	return {"score": score, "stars": stars(), "accuracy": accuracy()}


func next_note() -> Dictionary:
	for note in notes:
		if note["state"] == "wait":
			return note
	return {}


func play(string: String, midi: int, time: float, legato: bool) -> void:
	if finished:
		return
	var last: Dictionary = _last_hit.get(string, {})
	if not last.is_empty() and int(last["midi"]) == midi and time - float(last["time"]) <= Timing.widest_window() * 2.0:
		return
	_release(string, time)
	var best := _closest_waiting(string, midi, time)
	if best >= 0:
		_hit(best, time, legato)
	elif not legato and _wrong_nearby(string, midi, time):
		wrongs += 1
		streak = 0
		fact.emit("wrong", {"string": string, "midi": midi})


func _closest_waiting(string: String, midi: int, time: float) -> int:
	var best := -1
	var best_error := INF
	for i in notes.size():
		var note := notes[i]
		if note["string"] != string or note["state"] != "wait" or int(note["midi"]) != midi:
			continue
		var error := absf(float(note["t"]) - time)
		if error <= Timing.widest_window() and error < best_error:
			best = i
			best_error = error
	return best


func bend(string: String, amount: float, _time: float) -> void:
	_bent[string] = amount >= BEND_COUNTS
	if amount > 0.0 and _sounding.has(string):
		_check_bend(notes[int(_sounding[string])])


func mute(string: String, time: float) -> void:
	_release(string, time)


func update(time: float) -> void:
	if finished:
		return
	for note in notes:
		if note["state"] == "wait" and time > float(note["t"]) + Timing.widest_window():
			note["state"] = "miss"
			misses += 1
			streak = 0
			fact.emit("miss", {"note": note})
	for string: String in _sounding.keys():
		if time >= float(notes[int(_sounding[string])]["end"]):
			_release(string, time)
	if time >= end_time:
		finished = true
		fact.emit("finish", result())


func _hit(index: int, time: float, legato: bool) -> void:
	var note := notes[index]
	var judgement := Timing.grade(time - float(note["t"]))
	note["state"] = "hit"
	hits += 1
	streak += 1
	best_streak = maxi(best_streak, streak)
	score += int(judgement["score"]) * multiplier()
	_sounding[note["string"]] = index
	_last_hit[note["string"]] = {"midi": note["midi"], "time": time}
	fact.emit("hit", {"note": note, "judgement": judgement})
	if note["legato"] and legato:
		_tech(note, String(note["tech"]))
	_check_bend(note)


func _check_bend(note: Dictionary) -> void:
	if note["bend"] and _bent.get(note["string"], false):
		_tech(note, "bend")


func _tech(note: Dictionary, kind: String) -> void:
	if note["tech_ok"]:
		return
	note["tech_ok"] = true
	techs += 1
	score += TECH_BONUS * multiplier()
	fact.emit("tech", {"note": note, "label": TECH_NAMES.get(kind, "")})


func _release(string: String, time: float) -> void:
	if not _sounding.has(string):
		return
	var note := notes[int(_sounding[string])]
	_sounding.erase(string)
	if int(note["len"]) < 2:
		return
	var ratio := clampf((minf(time, float(note["end"])) - float(note["t"])) / (float(note["end"]) - float(note["t"])), 0.0, 1.0)
	score += roundi(SUSTAIN_POINTS * (int(note["len"]) - 1) * ratio)
	fact.emit("sustain", {"note": note, "ratio": ratio})


func _wrong_nearby(string: String, midi: int, time: float) -> bool:
	for note in notes:
		if note["string"] == string and note["state"] == "wait" and absf(float(note["t"]) - time) <= WRONG_RANGE \
				and int(note["midi"]) != midi:
			return true
	return false
