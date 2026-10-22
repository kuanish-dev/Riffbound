class_name JamTests
extends TestSuite
## Джем: лупер и экспорт в MIDI. Файлы не пишутся.


func test_looper_records_one_loop() -> void:
	var looper := Looper.new()
	looper.length = 4.0
	looper.tick(1.0)
	check(looper.start_recording(1.0), "запись началась")
	looper.capture({"kind": "pluck", "string": "low", "midis": [52]}, 1.5)
	looper.capture({"kind": "mute", "string": "low"}, 4.5)
	looper.tick(4.9)
	check(looper.recording, "круг ещё не прошёл")
	looper.tick(5.1)
	eq(looper.layers.size(), 1, "после круга — слой")
	var due := looper.tick(5.6)
	eq(due.size(), 1, "на 1.6 с круга слой играет щипок")
	eq(due[0]["event"]["kind"], "pluck", "щипок")
	due = looper.tick(8.6)
	eq(due.size(), 1, "через стык круга — глушение на 0.5 с")


func test_midi_file() -> void:
	eq(MidiFile.vlq(0), PackedByteArray([0x00]), "VLQ 0")
	eq(MidiFile.vlq(127), PackedByteArray([0x7F]), "VLQ 127")
	eq(MidiFile.vlq(128), PackedByteArray([0x81, 0x00]), "VLQ 128")
	eq(MidiFile.vlq(0x3FFF), PackedByteArray([0xFF, 0x7F]), "VLQ 16383")
	var layer := [{"t": 0.0, "kind": "pluck", "string": "mid", "midis": [59]}, {"t": 0.3, "kind": "slur", "string": "mid", "midis": [62]},
		{"t": 0.5, "kind": "bend", "string": "mid", "amount": 1.0}, {"t": 0.9, "kind": "mute", "string": "mid"}]
	var bytes := MidiFile.build([layer])
	eq(bytes.slice(0, 4).get_string_from_ascii(), "MThd", "заголовок")
	eq(bytes[11], 2, "дорожки: темп и слой")
	var hex := bytes.hex_encode()
	check(hex.contains("913b60") and hex.contains("913e60"), "ноты B3 и D4 на канале средней струны")
	check(hex.contains("e17f7f"), "бенд до упора")
