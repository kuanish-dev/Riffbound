class_name MusicLoader
extends RefCounted

const UNREADABLE := "файл не читается — играем без подложки"

var _hud: Hud
var _cache := {}
var _prerender := {}
var _prerender_pcm := {}
var _prerender_next := 0


func _init(hud: Hud) -> void:
	_hud = hud


static func choices() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for style: Dictionary in Backing.STYLES:
		out.append({"id": style["id"], "name": style["name"], "kind": "style"})
	for track: Dictionary in Tracks.all():
		var choice := track.duplicate()
		choice["kind"] = "track"
		out.append(choice)
	return out


static func find(id: String) -> Dictionary:
	var all := choices()
	return all[maxi(0, index_of(all, id))]


static func index_of(all: Array[Dictionary], id: String) -> int:
	for i in all.size():
		if all[i]["id"] == id:
			return i
	return -1


func load_music(choice: Dictionary, bpm: float, chords: Array[String]) -> void:
	call("_load_" + String(choice["kind"]), choice, bpm, chords)


func start_clock() -> void:
	var conductor := Game.conductor
	conductor.set_click(_metronome(conductor.offset))
	conductor.set_click_on(Game.metronome)
	conductor.start()


func _load_style(choice: Dictionary, bpm: float, chords: Array[String]) -> void:
	Timing.bpm = bpm
	var id := String(choice["id"])
	Game.chords = chords if Backing.has_harmony(id) else ([] as Array[String])
	Game.conductor.set_music(_backing(id, chords), chords.size() * Timing.bar_len())


func _load_track(choice: Dictionary, bpm: float, chords: Array[String]) -> void:
	var stream := Tracks.load_stream(choice)
	if stream == null:
		_report_unreadable(choice)
		_load_style(find("none"), bpm, chords)
		return
	stream.set("loop", true)
	Game.chords = _track_chords(choice)
	Timing.bpm = float(choice["bpm"]) if float(choice["bpm"]) > 0.0 else bpm
	var start := float(choice.get("start", 0.0))
	Game.conductor.set_music(stream, _track_seconds(choice, stream), start, float(choice["offset"]))


func _report_unreadable(choice: Dictionary) -> void:
	Game.music["problem"] = UNREADABLE
	_hud.toast("«%s»: %s" % [choice["name"], UNREADABLE])


static func _track_chords(choice: Dictionary) -> Array[String]:
	var bars: Array[String] = []
	bars.assign(String(choice.get("chords", "")).split("|", false))
	return bars


static func _track_seconds(choice: Dictionary, stream: AudioStream) -> float:
	var bars := int(choice["bars"])
	if bars == 0 and float(choice["bpm"]) > 0.0:
		bars = Tracks.fit_bars(stream.get_length(), float(choice["start"]), Timing.bar_len())
	return bars * Timing.bar_len() if bars > 0 else stream.get_length()


func _metronome(offset: float) -> AudioStreamWAV:
	var key := "metronome:%.2f:%.3f" % [Timing.bpm, offset]
	if not _cache.has(key):
		_cache[key] = Backing.metronome(offset)
	return _cache[key]


func _backing(id: String, chords: Array[String]) -> AudioStreamWAV:
	var key := _key(id, chords, Timing.bpm)
	if _prerender.get("key", "") == key:
		finish_prerender()
	if not _cache.has(key):
		_cache[key] = Backing.render(id, chords, Timing.bpm)
	return _cache[key]


static func _key(id: String, chords: Array[String], bpm: float) -> String:
	return "%s:%s:%.2f" % [id, "|".join(chords), bpm]


func restart_prerender() -> void:
	_prerender_next = 0


func prerender_tick() -> void:
	if not _prerender.is_empty():
		if WorkerThreadPool.is_task_completed(int(_prerender["task"])):
			finish_prerender()
	elif Game.state == "menu":
		_prerender_next_song()


func finish_prerender() -> void:
	if _prerender.is_empty():
		return
	WorkerThreadPool.wait_for_task_completion(int(_prerender["task"]))
	for wav: AudioStreamWAV in _prerender["out"]:
		_cache[_prerender["key"]] = wav
	_prerender = {}


func _prerender_next_song() -> void:
	var songs := Songs.all()
	while _prerender_next < songs.size():
		var song: Dictionary = songs[_prerender_next]
		_prerender_next += 1
		var id := String(song["backing"])
		var chords := Songs.chords_of(song)
		var bpm := Songs.bpm_of(song)
		if Backing.is_style(id) and not _cache.has(_key(id, chords, bpm)):
			_start_prerender(id, chords, bpm)
			return


func _start_prerender(id: String, chords: Array[String], bpm: float) -> void:
	var out: Array[AudioStreamWAV] = []
	var pcm := _prerender_pcm
	var task := WorkerThreadPool.add_task(func() -> void: out.append(Backing.render(id, chords, bpm, pcm)))
	_prerender = {"key": _key(id, chords, bpm), "task": task, "out": out}
