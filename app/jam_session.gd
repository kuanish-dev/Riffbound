class_name JamSession
extends RefCounted

var tuning := Tuning.one_string()
var _bpm := Timing.DEFAULT_BPM
var _tap := TapTempo.new()
var _asked_permissions := false
var _main: Main


func _init(main: Main) -> void:
	_main = main


func start() -> void:
	_scan_tracks()
	_load_music(true)


func leave() -> void:
	_tap.clear()


func tick() -> void:
	var bpm := _tap.take(_clock())
	if bpm > 0.0:
		call("_tap_" + String(Game.music["kind"]), bpm)


func record() -> void:
	var looper := Game.looper
	if looper.start_recording(Game.conductor.now()):
		_say("record", "Запись: один круг, %d такта" % Looper.BARS)
	elif looper.recording:
		_say("deny", "Запись уже идёт")
	else:
		_say("deny", "Слоёв уже %d — сотри последний (Backspace)" % Looper.MAX_LAYERS)


func undo() -> void:
	if Game.looper.undo():
		_main.layers.sync(Game.looper.layers.size())
		_say("undo", "Слой стёрт, осталось %d" % Game.looper.layers.size())
	else:
		_say("deny", "Стирать нечего")


func save_song() -> void:
	if Game.looper.layers.is_empty():
		_say("deny", "Сначала запиши луп (R)")
		return
	var song := Songs.from_layer(Game.looper.layers.back(), tuning, Game.jam_backing, Game.chords)
	if (song["notes"] as Array).is_empty():
		_say("deny", "В слое нет нот")
		return
	Songs.add_my(song)
	_say("save", "«%s» в списке песен: %s" % [song["name"], song["text"]])


func delete_song() -> void:
	var removed := Songs.remove_last_my()
	Game.menu_index = clampi(Game.menu_index, 0, Songs.all().size() - 1)
	if removed.is_empty():
		_say("deny", "Своих песен нет")
	else:
		_say("delete", "«%s» удалена" % removed["name"])


func export_midi() -> void:
	if Game.looper.layers.is_empty():
		_say("deny", "Сначала запиши луп (R)")
		return
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := Tracks.user_dir().path_join("riffbound-%s.mid" % stamp)
	var error := MidiFile.save(path, Game.looper.layers)
	if error == OK:
		_say("save", "MIDI сохранён: %s" % path)
	else:
		_say("deny", "Не удалось сохранить MIDI (%s)" % error_string(error))


func toggle_more() -> void:
	Game.more = not Game.more
	_main.feedback.play("toggle_on" if Game.more else "toggle_off")


func key_down() -> void:
	tuning.shift_key(-1)
	_retune("Тональность")


func key_up() -> void:
	tuning.shift_key(1)
	_retune("Тональность")


func next_scale() -> void:
	tuning.cycle_scale()
	_retune("Гамма")


func next_backing() -> void:
	var all := MusicLoader.jam_choices()
	var next := (maxi(0, MusicLoader.index_of(all, Game.jam_backing)) + 1) % all.size()
	Game.jam_backing = String(all[next]["id"])
	_restart_music(true)
	_main.hud.toast("Подложка: %s · %s%s" % [Game.music["name"], tuning.title(), _backing_hint(next == all.size() - 1)])


func tap() -> void:
	_tap.tap(_clock(), Game.conductor.music_position())
	_main.feedback.play("tap")
	var status := _tap.status()
	if not status.is_empty():
		_main.hud.toast(status)


func on_permission(_permission: String, granted: bool) -> void:
	if granted:
		Tracks.scan_user()


func _backing_hint(last: bool) -> String:
	if Game.music.has("problem"):
		return " · " + String(Game.music["problem"])
	if float(Game.music.get("bpm", 1.0)) <= 0.0:
		return " · темп неизвестен — тапни T в такт с сильной доли"
	if last:
		return " · свои треки — в папку %s" % Tracks.user_dir()
	return ""


func _retune(what: String) -> void:
	var track := Tracks.find(Game.jam_backing)
	if track.get("user", false):
		track["key"] = tuning.key
		track["scale"] = Tuning.SCALES[tuning.scale]["id"]
		Tracks.remember(track, Songs.persist)
	if Game.music["kind"] == "style":
		_restart_music(false)
	_main.hud.toast("%s · %s" % [what, tuning.title()])


func _restart_music(retune: bool) -> void:
	Game.looper.cancel_recording()
	Game.conductor.stop()
	_load_music(retune)
	_main.music.start_clock()


func _load_music(retune: bool) -> void:
	var choice := MusicLoader.find(Game.jam_backing)
	Game.music = choice
	if retune and int(choice.get("key", -1)) >= 0:
		tuning.set_key(int(choice["key"]), String(choice["scale"]))
	var before := Timing.bpm
	_main.music.load_music(choice, _bpm, Harmony.progression(tuning.key, tuning.is_minor()))
	Game.music["bpm"] = Timing.bpm if float(choice.get("bpm", 1.0)) > 0.0 else 0.0
	if not is_equal_approx(before, Timing.bpm):
		Game.looper.reset()
		_main.layers.sync(0)
	Game.looper.length = Looper.BARS * Timing.bar_len()


func _scan_tracks() -> void:
	if OS.has_feature("android") and not _asked_permissions:
		_asked_permissions = true
		OS.request_permissions()
	Tracks.scan_user()


func _tap_style(bpm: float) -> void:
	_bpm = bpm
	_restart_music(false)
	_say("save", "Темп джема: %s bpm" % bpm)


func _tap_track(bpm: float) -> void:
	var track := Tracks.find(Game.jam_backing)
	if not track.get("user", false):
		_say("deny", "У этого трека темп известен: %s bpm" % track["bpm"])
		return
	track["bpm"] = bpm
	track["start"] = Tracks.first_downbeat(_tap.music_from, bpm)
	Tracks.remember(track, Songs.persist)
	_restart_music(false)
	_say("save", "«%s»: %s bpm, сильная доля на %.2f с — запомнено" % [track["name"], bpm, track["start"]])


func _say(sound: String, text: String) -> void:
	_main.feedback.say(sound, text)


static func _clock() -> float:
	return Time.get_ticks_msec() / 1000.0
