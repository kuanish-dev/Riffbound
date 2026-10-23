class_name MusicTests
extends TestSuite
## Музыка: переменный темп, треки (встроенные петли и разбор имён своих файлов), подложка из сэмплов,
## выбор сэмпла гитары. Файлы не пишутся.


func after_all() -> void:
	Timing.bpm = Timing.DEFAULT_BPM


func test_tempo_scales_grid() -> void:
	Timing.bpm = 120.0
	eq(Timing.slot_len(), 0.25, "восьмая на 120 bpm")
	eq(Timing.bar_len(), 2.0, "такт на 120 bpm")
	eq(Timing.judge(0.76)["slot"], 3, "сетка по новому темпу")
	Timing.bpm = Timing.DEFAULT_BPM
	eq(Timing.slot_len(), 0.3, "по умолчанию — 100 bpm")


func test_track_names() -> void:
	eq(Tracks.parse_name("Blues Jam 120bpm Am"), {"bpm": 120.0, "key": 9, "scale": "minor_pentatonic"}, "темп и ля минор")
	eq(Tracks.parse_name("Backing Track in F#m - 95 BPM"), {"bpm": 95.0, "key": 6, "scale": "minor_pentatonic"}, "фа-диез минор")
	eq(Tracks.parse_name("slow_ballad_Eb_major_70bpm"), {"bpm": 70.0, "key": 3, "scale": "major_pentatonic"}, "ми-бемоль мажор")
	eq(Tracks.parse_name("Rock - E"), {"key": 4, "scale": "major_pentatonic"}, "одна буква в конце — тональность")
	eq(Tracks.parse_name("A Day in Life"), {}, "буква в начале — артикль, не тональность")
	eq(Tracks.parse_name("Dub Amazing 87.5 bpm"), {"bpm": 87.5}, "буквы внутри слов не считаются")


func test_user_track_memory_wins() -> void:
	var track := Tracks.user_track("Jam 120bpm Am.mp3", {"bpm": 118.5, "start": 0.42})
	eq(track["bpm"], 118.5, "темп из тапа главнее имени")
	eq(track["start"], 0.42, "сильная доля из тапа")
	eq(track["key"], 9, "тональность — из имени")
	eq(Tracks.fit_bars(30.0, 0.5, 2.0), 14, "тактов от сильной доли до конца файла")


func test_tap_tempo() -> void:
	var taps: Array[float] = [10.0, 10.5, 11.01, 11.49, 12.0, 12.5]
	eq(roundi(Main.tap_bpm(taps)), 120, "шесть ударов по полсекунды — 120 bpm")
	eq(Tracks.first_downbeat(9.3, 120.0), 1.3, "тап с «раз» на 9.3 с — первая сильная доля на 1.3 с")


func test_built_in_tracks_loop_whole_bars() -> void:
	for track: Dictionary in Tracks.BUILT_IN:
		var stream := Tracks.load_stream(track)
		check(stream != null, "%s: файл есть" % track["id"])
		if stream == null:
			continue
		var loop := int(track["bars"]) * 60.0 / float(track["bpm"]) * Timing.BEATS_PER_BAR
		check(absf(stream.get_length() - loop) < 0.002, "%s: петля = %d тактов (%.3f с, файл %.3f с)" % [track["id"],
			track["bars"], loop, stream.get_length()])
		check(Tuning.SCALES[Tuning.scale_index(String(track["scale"]))]["id"] == track["scale"], "%s: гамма из таблицы" % track["id"])


func test_backing_styles() -> void:
	Timing.bpm = 120.0
	for style: Dictionary in Backing.STYLES:
		var started := Time.get_ticks_msec()
		var wav := Backing.render(String(style["id"]), 4, true)
		var spent := Time.get_ticks_msec() - started
		eq(wav.loop_end, roundi(Looper.BARS * Timing.bar_len() * Backing.RATE), "%s: луп на %d такта" % [style["id"], Looper.BARS])
		eq(wav.data.size() / 2, wav.loop_end + Backing.LOOP_PAD, "%s: за концом петли — её начало" % style["id"])
		var loud := false
		for i in range(0, wav.data.size(), 512):
			loud = loud or absi(wav.data.decode_s16(i)) > 1000
		check(loud == not (style["bars"] as Dictionary).is_empty(), "%s: звучит, если есть партии" % style["id"])
		check(spent < 2000, "%s: собирается быстро (%d мс)" % [style["id"], spent])
	Timing.bpm = Timing.DEFAULT_BPM


func test_music_choices() -> void:
	var choices := Main.music_choices()
	eq(choices.size(), Backing.STYLES.size() + Tracks.all().size(), "стили и треки по кругу")
	eq(Main.music("funked_up")["kind"], "track", "трек")
	eq(Main.music("нет такой")["id"], Backing.STYLES[0]["id"], "неизвестная подложка — первый стиль")


func test_nearest_guitar_sample() -> void:
	eq(SampleBank.sample_midi(41), 40, "между сэмплами — ближний снизу")
	eq(SampleBank.sample_midi(44), 45, "ближний сверху")
	eq(SampleBank.sample_midi(88), 86, "выше последнего — последний")
	for midi in range(Tuning.MIDI_MIN, Tuning.MIDI_MAX + 1):
		check(absi(SampleBank.sample_midi(midi) - midi) <= 2, "нота %d тянется не больше чем на тон" % midi)
