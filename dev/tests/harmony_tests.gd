class_name HarmonyTests
extends TestSuite


func after_all() -> void:
	Timing.bpm = Timing.DEFAULT_BPM


func test_chord_names() -> void:
	eq(Harmony.parse("Am"), {"root": 9, "quality": "m", "tones": [9, 0, 4]}, "ля минор")
	eq(Harmony.parse("F#m")["root"], 6, "диез")
	eq(Harmony.parse("Bb")["tones"], [10, 2, 5], "бемоль")
	eq(Harmony.parse("E5")["tones"], [4, 11], "пауэр-аккорд — корень и квинта")
	eq(Harmony.parse("B7")["tones"], [11, 3, 6, 9], "септаккорд")
	for bad: String in ["", "H", "am", "Cmaj9"]:
		eq(Harmony.parse(bad), {}, "«%s» — не аккорд" % bad)


func test_progression_of_key() -> void:
	eq(Harmony.progression(4, true), ["Em", "Em", "C", "D"], "ми минор: i–i–VI–VII")
	eq(Harmony.progression(9, false), ["A", "A", "D", "E"], "ля мажор: I–I–IV–V")


func test_chord_at_beat() -> void:
	var bars := ["Am E", "C"]
	eq([Harmony.at(bars, 0.0), Harmony.at(bars, 1.9), Harmony.at(bars, 2.0), Harmony.at(bars, 4.5)], ["Am", "Am", "E", "C"],
		"два аккорда делят такт пополам")
	eq([Harmony.at(bars, 8.0), Harmony.at(bars, -1.0)], ["Am", "C"], "такты идут по кругу")
	eq(Harmony.at([], 3.0), "", "без аккордов — пусто")
	eq([Harmony.in_bar("Am E", 3), Harmony.in_bar("Am E", 4), Harmony.in_bar("C", 7)], ["Am", "E", "C"], "аккорд на восьмой")


func test_degree_and_role() -> void:
	eq(Harmony.degree(Harmony.parse("Bdim"), "fifth"), 6, "у уменьшённого квинта пониженная")
	eq(Harmony.degree(Harmony.parse("E5"), "fifth"), 7, "чистая квинта")
	eq(Harmony.degree(Harmony.parse("Am"), "octave"), 12, "октава")
	var am := Harmony.parse("Am")
	eq([Harmony.role(am, 57), Harmony.role(am, 72), Harmony.role(am, 64), Harmony.role(am, 62)], ["root", "tone", "tone", ""],
		"корень, ноты аккорда, чужая нота")
	eq(Harmony.role({}, 57), "", "аккорда нет — подсветки нет")


func test_song_chords() -> void:
	for song: Dictionary in SongBook.SONGS:
		var own: Array = song["chords"]
		eq(own.size(), (song["bars"] as Array).size(), "%s: аккорд на каждый такт" % song["id"])
		for spec: String in own:
			for name in spec.split(" ", false):
				check(not Harmony.parse(name).is_empty(), "%s: «%s» — аккорд" % [song["id"], name])
		var all := Songs.chords_of(song)
		@warning_ignore("integer_division")
		eq(all.size(), Songs.end_slot(song) / Timing.SLOTS_PER_BAR, "%s: аккорды на всю песню" % song["id"])
		eq(all.slice(0, Songs.LEAD_IN + 1), [own[0], own[0], own[0]], "%s: отсчёт — на первом аккорде" % song["id"])
		eq(all.back(), own.back(), "%s: хвост — на последнем" % song["id"])


func test_song_without_chords_follows_key() -> void:
	var song := {"id": "test", "key": 9, "scale": "major", "bars": [{"low": "1 = = = = = = ="}]}
	eq(Songs.chords_of(song), ["A", "A", "A", "A"], "круг ля мажора, отсчёт и хвост")


func test_track_chords() -> void:
	for track: Dictionary in Tracks.BUILT_IN:
		var bars := String(track["chords"]).split("|", false)
		eq(bars.size(), int(track["bars"]), "%s: аккорд на каждый такт" % track["id"])
		for spec in bars:
			for name in spec.split(" ", false):
				check(not Harmony.parse(name).is_empty(), "%s: «%s» — аккорд" % [track["id"], name])


func test_song_tracks_match_songs() -> void:
	var songs := 0
	for song: Dictionary in SongBook.SONGS:
		var track := Tracks.find(String(song["backing"]))
		if track.is_empty():
			continue
		songs += 1
		var chords := Songs.chords_of(song)
		eq(int(track["bars"]), chords.size(), "%s: трек длиной в песню" % song["id"])
		eq(String(track["chords"]), "|".join(chords), "%s: аккорды трека — аккорды песни" % song["id"])
		eq(float(track["bpm"]), Songs.bpm_of(song), "%s: темп трека — темп песни" % song["id"])
	check(songs >= 6, "песни пака играют под свои треки")


func test_backing_plays_chords() -> void:
	Timing.bpm = 120.0
	var wav := Backing.render("rock", ["Am", "E", "C"], Timing.bpm)
	eq(wav.loop_end, roundi(3 * Timing.bar_len() * Backing.RATE), "такт на аккорд")
	check(Backing.has_harmony("rock") and not Backing.has_harmony("none"), "гармония есть у стилей с басом и клавишами")
	Timing.bpm = Timing.DEFAULT_BPM
