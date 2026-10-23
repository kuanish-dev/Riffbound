class_name MidiFile

const PPQ := 480
const VELOCITY := 96


static func save(path: String, layers: Array) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(build(layers))
	return OK


static func build(layers: Array) -> PackedByteArray:
	var out := PackedByteArray()
	out.append_array("MThd".to_ascii_buffer())
	out.append_array(_u32(6))
	out.append_array(_u16(1))
	out.append_array(_u16(layers.size() + 1))
	out.append_array(_u16(PPQ))
	out.append_array(_track(_tempo_events()))
	for layer: Array in layers:
		out.append_array(_track(_layer_events(layer)))
	return out


static func vlq(value: int) -> PackedByteArray:
	var bytes := PackedByteArray([value & 0x7F])
	value >>= 7
	while value > 0:
		bytes.insert(0, (value & 0x7F) | 0x80)
		value >>= 7
	return bytes


static func bend_range() -> int:
	return ceili(Tuning.BEND_SEMITONES * Tuning.BEND_MAX)


static func ticks(seconds: float) -> int:
	return roundi(seconds / Timing.beat_len() * PPQ)


static func _tempo_events() -> Array:
	var tempo := roundi(Timing.beat_len() * 1000000.0)
	return [
		[0, 0, PackedByteArray([0xFF, 0x51, 0x03, (tempo >> 16) & 0xFF, (tempo >> 8) & 0xFF, tempo & 0xFF])],
		[0, 0, PackedByteArray([0xFF, 0x58, 0x04, 0x04, 0x02, 0x18, 0x08])],
	]


static func _layer_events(layer: Array) -> Array:
	var events: Array = []
	var sounding := {}
	for channel in Notes.STRINGS.size():
		events.append_array(_bend_range_setup(channel))
		sounding[channel] = []
	for event: Dictionary in layer:
		var channel := Notes.STRINGS.find(String(event["string"]))
		var at := ticks(float(event["t"]))
		if event["kind"] == "bend":
			events.append(_pitch_bend(at, channel, float(event["amount"])))
		else:
			events.append_array(_note_events(at, channel, event, sounding))
	var end := ticks(Looper.BARS * Timing.bar_len())
	for channel: int in sounding:
		events.append_array(_notes_off(end, channel, sounding[channel]))
	return events


static func _bend_range_setup(channel: int) -> Array:
	var events: Array = []
	for cc: Array in [[101, 0], [100, 0], [6, bend_range()], [38, 0]]:
		events.append([0, 0, PackedByteArray([0xB0 | channel, cc[0], cc[1]])])
	return events


static func _pitch_bend(at: int, channel: int, amount: float) -> Array:
	var value := clampi(8192 + roundi(amount * Tuning.BEND_SEMITONES / bend_range() * 8191.0), 0, 16383)
	return [at, 2, PackedByteArray([0xE0 | channel, value & 0x7F, (value >> 7) & 0x7F])]


static func _note_events(at: int, channel: int, event: Dictionary, sounding: Dictionary) -> Array:
	var events := _notes_off(at, channel, sounding[channel])
	sounding[channel] = []
	if event["kind"] == "mute":
		return events
	for midi: int in event.get("midis", []):
		events.append([at, 3, PackedByteArray([0x90 | channel, midi, VELOCITY])])
		sounding[channel].append(midi)
	return events


static func _notes_off(at: int, channel: int, midis: Array) -> Array:
	var events: Array = []
	for midi: int in midis:
		events.append([at, 1, PackedByteArray([0x80 | channel, midi, 0])])
	return events


static func _track(events: Array) -> PackedByteArray:
	events.sort_custom(_earlier)
	var body := PackedByteArray()
	var last := 0
	for event: Array in events:
		body.append_array(vlq(int(event[0]) - last))
		body.append_array(event[2])
		last = int(event[0])
	body.append_array(vlq(0))
	body.append_array(PackedByteArray([0xFF, 0x2F, 0x00]))
	var out := "MTrk".to_ascii_buffer()
	out.append_array(_u32(body.size()))
	out.append_array(body)
	return out


static func _earlier(a: Array, b: Array) -> bool:
	return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1])


static func _u32(value: int) -> PackedByteArray:
	return PackedByteArray([(value >> 24) & 0xFF, (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF])


static func _u16(value: int) -> PackedByteArray:
	return PackedByteArray([(value >> 8) & 0xFF, value & 0xFF])
