class_name ProgressionTests
extends TestSuite

const TECHNIQUE_COST := 0.5


func test_songs_go_from_easy_to_hard() -> void:
	var previous := {"name": "", "effort": 0.0}
	for song: Dictionary in SongBook.SONGS:
		if song["lesson"]:
			continue
		var effort := effort_of(song)
		check(effort >= previous["effort"], "«%s» (%.2f) не легче «%s» (%.2f)" % [song["name"], effort, previous["name"],
			previous["effort"]])
		previous = {"name": song["name"], "effort": effort}


func test_lessons_teach_before_songs_use() -> void:
	var taught := {}
	for song: Dictionary in SongBook.SONGS:
		var used := techniques_of(Songs.notes_of(song))
		if song["lesson"]:
			taught.merge(used)
			continue
		for technique: String in used:
			check(taught.has(technique), "«%s»: «%s» есть в уроке раньше" % [song["name"], technique])


func test_lessons_teach_at_every_level() -> void:
	for song: Dictionary in SongBook.SONGS:
		if not song["lesson"]:
			continue
		var taught := techniques_of(Songs.notes_of(song))
		for level: Dictionary in Difficulty.LEVELS:
			var rules := Difficulty.rules_for(song, level)
			var kept := techniques_of(Difficulty.simplify(Songs.notes_of(song), rules))
			eq(kept.keys(), taught.keys(), "«%s» на уровне «%s»: техника урока на месте" % [song["name"], level["name"]])
			if taught.has("сдвиг руки"):
				check(not rules["auto_hand"], "«%s» на уровне «%s»: руку двигаешь сам" % [song["name"], level["name"]])


func test_lessons_come_first() -> void:
	var lessons := SongBook.SONGS.filter(func(song: Dictionary) -> bool: return song["lesson"]).size()
	for i in SongBook.SONGS.size():
		eq(bool(SongBook.SONGS[i]["lesson"]), i < lessons, "%s: уроки — в начале списка" % SongBook.SONGS[i]["id"])


func test_lessons_stay_out_of_jam() -> void:
	var jam_ids := MusicLoader.jam_choices().map(func(choice: Dictionary) -> String: return choice["id"])
	for song: Dictionary in SongBook.SONGS:
		eq(jam_ids.has(song["backing"]), not song["lesson"], "%s: подложка в джеме только у песен" % song["id"])


static func effort_of(song: Dictionary) -> float:
	var notes := Songs.notes_of(song)
	var per_bar := {}
	for slot: int in _hit_slots(notes):
		var bar := slot / Timing.SLOTS_PER_BAR
		per_bar[bar] = int(per_bar.get(bar, 0)) + 1
	var bar_time := 240.0 / Songs.bpm_of(song)
	var average := _hit_slots(notes).size() / ((song["bars"] as Array).size() * bar_time)
	var peak := float(per_bar.values().max()) / bar_time
	return 0.5 * (average + peak) + TECHNIQUE_COST * techniques_of(notes).size()


static func techniques_of(notes: Array[Dictionary]) -> Dictionary:
	var used := {}
	var slots := {}
	var positions := {}
	for note in notes:
		if note["legato"]:
			used["легато"] = true
		if note["bend"]:
			used["бенд"] = true
		if note["fret"] == Notes.MUTE:
			used["глушняк"] = true
		if slots.has(note["slot"]):
			used["аккорд"] = true
		slots[note["slot"]] = true
		positions[note["pos"]] = true
	if positions.size() > 1:
		used["сдвиг руки"] = true
	return used


static func _hit_slots(notes: Array[Dictionary]) -> Dictionary:
	var slots := {}
	for note in notes:
		slots[int(note["slot"])] = true
	return slots
